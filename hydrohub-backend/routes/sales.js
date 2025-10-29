const express = require("express");
const router = express.Router();
const pool = require("../db");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// =======================================================
// 📸 File Upload Config
// =======================================================
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// =======================================================
// 🧩 Helper: Get station_id by staff_id
// =======================================================
async function getStationIdByStaff(staff_id) {
  const result = await pool.query(
    "SELECT station_id FROM staff WHERE staff_id = $1",
    [staff_id]
  );
  return result.rows.length > 0 ? result.rows[0].station_id : null;
}

// =======================================================
// 🧾 UNIVERSAL: Add Sale (E-wallet / Cash allowed)
// =======================================================
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

    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(404).json({ error: "Staff not found or invalid." });

    // Find product_id in this user's station
    const productQuery = await pool.query(
      `SELECT id FROM products 
       WHERE LOWER(name)=LOWER($1)
       AND LOWER(size_category)=LOWER($2)
       AND station_id=$3
       LIMIT 1`,
      [product_name, size, station_id]
    );
    if (productQuery.rowCount === 0)
      return res
        .status(404)
        .json({ error: `Product not found for this station.` });

    const product_id = productQuery.rows[0].id;

    await pool.query(
      `INSERT INTO sales 
        (product_id, quantity, total, date, payment_method, sale_type, proof, staff_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [product_id, quantity, total, date, payment_method, sale_type, proof, staff_id]
    );

    console.log(`✅ Sale created by staff ${staff_id} in station ${station_id}`);
    res.status(201).json({ message: "✅ Sale added successfully" });
  } catch (err) {
    console.error("❌ Error saving sale:", err);
    res.status(500).json({ error: "Server error while saving sale" });
  }
});

// =======================================================
// 🔍 UNIVERSAL: Fetch Sales (Supports ?station_id=&type=)
// =======================================================
router.get("/", async (req, res) => {
  try {
    const { station_id, type } = req.query;

    if (!station_id) {
      return res.status(400).json({ error: "station_id is required" });
    }

    let query = `
      SELECT 
        s.*, 
        p.name AS water_type, 
        p.size_category AS size, 
        p.price,
        sf.first_name, sf.last_name
      FROM sales s
      JOIN products p ON s.product_id = p.id
      JOIN staff sf ON s.staff_id = sf.staff_id
      WHERE sf.station_id = $1
    `;
    const values = [station_id];

    // Optional filter for onsite/delivery
    if (type) {
      query += ` AND s.sale_type = $2`;
      values.push(type);
    }

    query += ` ORDER BY s.date DESC`;

    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching sales:", err.message);
    res.status(500).json({ error: "Server error while fetching sales" });
  }
});

// =======================================================
// 👑 ADMIN — Can View All Sales
// =======================================================
router.get("/admin", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT s.*, p.name AS water_type, p.size_category AS size, p.price,
             sf.first_name, sf.last_name, ws.station_name
      FROM sales s
      JOIN products p ON s.product_id = p.id
      JOIN staff sf ON s.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      ORDER BY s.date DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Admin fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// =======================================================
// 🧑‍💼 OWNER — View Sales from Their Station
// =======================================================
router.get("/owner/:station_id", async (req, res) => {
  try {
    const { station_id } = req.params;

    const result = await pool.query(
      `
      SELECT s.*, p.name AS product_name, p.size_category, p.price,
             sf.first_name, sf.last_name
      FROM sales s
      JOIN products p ON s.product_id = p.id
      JOIN staff sf ON s.staff_id = sf.staff_id
      WHERE sf.station_id = $1
      ORDER BY s.date DESC
    `,
      [station_id]
    );

    console.log(`✅ Owner station ${station_id} fetched ${result.rows.length} sales`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Owner fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// =======================================================
// 🧍‍♂️ ONSITE STAFF — View Their Station's Onsite Sales
// =======================================================
router.get("/onsite/:staff_id", async (req, res) => {
  try {
    const { staff_id } = req.params;
    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(400).json({ error: "Invalid staff_id" });

    const result = await pool.query(
      `
      SELECT s.*, p.name AS product_name, p.size_category, p.price,
             sf.first_name, sf.last_name
      FROM sales s
      JOIN products p ON s.product_id = p.id
      JOIN staff sf ON s.staff_id = sf.staff_id
      WHERE sf.station_id = $1 AND s.sale_type = 'onsite'
      ORDER BY s.date DESC
    `,
      [station_id]
    );

    console.log(`✅ Onsite staff ${staff_id} fetched ${result.rows.length} onsite sales`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Onsite fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// =======================================================
// 🚚 DELIVERY STAFF — View Their Station's Delivery Sales
// =======================================================
router.get("/delivery/:staff_id", async (req, res) => {
  try {
    const { staff_id } = req.params;
    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(400).json({ error: "Invalid staff_id" });

    const result = await pool.query(
      `
      SELECT s.*, p.name AS product_name, p.size_category, p.price,
             sf.first_name, sf.last_name
      FROM sales s
      JOIN products p ON s.product_id = p.id
      JOIN staff sf ON s.staff_id = sf.staff_id
      WHERE sf.station_id = $1 AND s.sale_type = 'delivery'
      ORDER BY s.date DESC
    `,
      [station_id]
    );

    console.log(`✅ Delivery staff ${staff_id} fetched ${result.rows.length} delivery sales`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Delivery fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// =======================================================
// ✏️ UPDATE SALE — For Any Role in Their Station
// =======================================================
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
      staff_id,
      remove_proof,
    } = req.body;

    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(400).json({ error: "Invalid staff_id" });

    const productQuery = await pool.query(
      `SELECT id FROM products 
       WHERE LOWER(name)=LOWER($1)
       AND LOWER(size_category)=LOWER($2)
       AND station_id=$3
       LIMIT 1`,
      [water_type, size, station_id]
    );
    if (productQuery.rowCount === 0)
      return res.status(404).json({ error: "Product not found for update." });

    const product_id = productQuery.rows[0].id;
    const proof = req.file ? req.file.filename : null;

    // Base update query
    let query = `
      UPDATE sales
      SET product_id=$1, quantity=$2, total=$3, date=$4,
          payment_method=$5, sale_type=$6, staff_id=$7
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

    // Handle proof logic
    if (proof) {
      query += `, proof=$8 WHERE id=$9 RETURNING *`;
      values.push(proof, id);
    } else if (remove_proof === "true" || payment_method === "Cash") {
      const oldProof = await pool.query(`SELECT proof FROM sales WHERE id=$1`, [id]);
      if (oldProof.rowCount > 0 && oldProof.rows[0].proof) {
        const oldFile = path.join(__dirname, "../uploads", oldProof.rows[0].proof);
        if (fs.existsSync(oldFile)) fs.unlinkSync(oldFile);
      }
      query += `, proof=NULL WHERE id=$8 RETURNING *`;
      values.push(id);
    } else {
      query += ` WHERE id=$8 RETURNING *`;
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
