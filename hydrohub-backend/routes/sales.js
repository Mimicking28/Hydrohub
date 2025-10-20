const express = require("express");
const router = express.Router();
const pool = require("../db");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// 📸 Configure file upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

/* =========================================================
   ✅ POST /api/sales — Create new sale (with optional proof)
   ========================================================= */
router.post("/", upload.single("proof"), async (req, res) => {
  try {
    const {
      product_name,
      size,
      quantity,
      total,
      date,
      payment_method,
      sale_type,
      staff_id,
    } = req.body;

    const proof = req.file ? req.file.filename : null;

    // Validate required fields
    if (
      !product_name ||
      !size ||
      !quantity ||
      !total ||
      !date ||
      !payment_method ||
      !sale_type ||
      !staff_id
    ) {
      return res.status(400).json({ error: "⚠️ All fields are required." });
    }

    // Get station_id from staff_id
    const staffQuery = await pool.query(
      `SELECT station_id FROM staff WHERE staff_id = $1 LIMIT 1`,
      [staff_id]
    );
    if (staffQuery.rowCount === 0)
      return res.status(404).json({ error: "Staff not found." });

    const station_id = staffQuery.rows[0].station_id;

    // Get product_id from product + station
    const productQuery = await pool.query(
      `SELECT id FROM products 
       WHERE LOWER(name) = LOWER($1)
       AND LOWER(size_category) = LOWER($2)
       AND station_id = $3
       LIMIT 1`,
      [product_name, size, station_id]
    );

    if (productQuery.rowCount === 0) {
      return res.status(404).json({
        error: `Product not found for ${product_name} (${size}) at station ${station_id}.`,
      });
    }

    const product_id = productQuery.rows[0].id;

    // Insert sale
    await pool.query(
      `INSERT INTO sales 
        (product_id, quantity, total, date, payment_method, sale_type, proof, staff_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        product_id,
        quantity,
        total,
        date,
        payment_method,
        sale_type,
        proof,
        staff_id,
      ]
    );

    res.status(201).json({ message: "✅ Sale added successfully" });
  } catch (err) {
    console.error("❌ Error saving sale:", err);
    res.status(500).json({ error: "Server error while saving sale" });
  }
});

/* =========================================================
   ✅ GET /api/sales — Fetch all sales (with station info)
   ========================================================= */
router.get("/", async (req, res) => {
  try {
    const { type, station_id } = req.query;
    const params = [];

    let query = `
      SELECT 
        s.id AS id, 
        s.quantity, s.total, s.date, s.payment_method, s.sale_type, s.proof,
        p.name AS water_type, p.size_category AS size, p.price,
        sf.first_name, sf.last_name,
        w.station_name
      FROM sales s
      JOIN products p ON s.product_id = p.id
      JOIN staff sf ON s.staff_id = sf.staff_id
      JOIN water_refilling_stations w ON sf.station_id = w.station_id
    `;

    if (type && station_id) {
      query += " WHERE s.sale_type = $1 AND w.station_id = $2";
      params.push(type, station_id);
    } else if (type) {
      query += " WHERE s.sale_type = $1";
      params.push(type);
    } else if (station_id) {
      query += " WHERE w.station_id = $1";
      params.push(station_id);
    }

    query += " ORDER BY s.date DESC";

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching sales:", err);
    res.status(500).json({ error: "Server error while fetching sales" });
  }
});

/* =========================================================
   ✅ PUT /api/sales/:id — Update sale (with optional proof)
   ========================================================= */
router.put("/:id", upload.single("proof"), async (req, res) => {
  try {
    const { id } = req.params;
    const {
      water_type,
      size,
      quantity,
      total,
      date,
      payment_method,
      sale_type,
      station_id,
      staff_id,
      remove_proof,
    } = req.body;

    const proof = req.file ? req.file.filename : null;

    // Validate product
    const productQuery = await pool.query(
      `SELECT id FROM products 
       WHERE LOWER(name) = LOWER($1)
       AND LOWER(size_category) = LOWER($2)
       AND station_id = $3
       LIMIT 1`,
      [water_type, size, station_id]
    );

    if (productQuery.rowCount === 0)
      return res.status(404).json({ error: "Product not found for update." });

    const product_id = productQuery.rows[0].id;

    // Build dynamic query
    let query = `
      UPDATE sales
      SET product_id = $1, quantity = $2, total = $3, date = $4,
          payment_method = $5, sale_type = $6, staff_id = $7
    `;
    const values = [
      product_id,
      quantity,
      total,
      date,
      payment_method,
      sale_type,
      staff_id,
    ];

    if (proof) {
      query += `, proof = $8 WHERE id = $9 RETURNING *`;
      values.push(proof, id);
    } else if (remove_proof === "true" || payment_method === "Cash") {
      const oldProof = await pool.query(`SELECT proof FROM sales WHERE id = $1`, [id]);
      if (oldProof.rowCount > 0 && oldProof.rows[0].proof) {
        const oldFile = path.join(__dirname, "../uploads", oldProof.rows[0].proof);
        if (fs.existsSync(oldFile)) fs.unlinkSync(oldFile);
      }
      query += `, proof = NULL WHERE id = $8 RETURNING *`;
      values.push(id);
    } else {
      query += ` WHERE id = $8 RETURNING *`;
      values.push(id);
    }

    const result = await pool.query(query, values);
    if (result.rowCount === 0)
      return res.status(404).json({ error: "Sale not found." });

    res.json({ message: "✅ Sale updated successfully", sale: result.rows[0] });
  } catch (err) {
    console.error("❌ Error updating sale:", err);
    res.status(500).json({ error: "Server error while updating sale" });
  }
});

module.exports = router;
