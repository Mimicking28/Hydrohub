const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const pool = require("../db");
const router = express.Router();

/* ==========================================================
   ⚙️ MULTER CONFIG (Product Photos)
========================================================== */
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, path.join(__dirname, "../uploads")),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

/* ==========================================================
   💧 UNIVERSAL ROUTE — Fetch Products for AddSale Page
========================================================== */
// ✅ Fetch available products for a specific station (with optional type filter)
router.get("/", async (req, res) => {
  try {
    const { station_id, type } = req.query;

    if (!station_id) {
      return res.status(400).json({ error: "station_id is required" });
    }

    // Base query
    let query = `
      SELECT 
        id, name, type, size_category, price, is_archived, photo, station_id
      FROM products
      WHERE station_id = $1 AND is_archived = FALSE
    `;
    const values = [station_id];

    // Optional type filter (e.g. onsite / delivery)
    if (type) {
      query += ` AND LOWER(type) = LOWER($2)`;
      values.push(type);
    }

    query += " ORDER BY name ASC";

    const result = await pool.query(query, values);
    res.json(result.rows);
  } catch (error) {
    console.error("❌ Error fetching products:", error);
    res.status(500).json({ error: "Server error while fetching products" });
  }
});

/* ==========================================================
   🧑‍💼 ADMIN ROUTES — Read + Delete only
========================================================== */

// ✅ Fetch ALL products (Admin view)
router.get("/admin", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        p.id,
        p.name,
        p.type,
        p.size_category,
        p.price,
        p.is_archived,
        p.photo,
        p.created_at,
        s.station_name
      FROM products p
      LEFT JOIN water_refilling_stations s 
        ON p.station_id = s.station_id
      ORDER BY s.station_name, p.id DESC
    `);
    res.json(result.rows);
  } catch (error) {
    console.error("❌ Error fetching admin products:", error);
    res.status(500).json({ error: "Server error fetching admin products" });
  }
});

// ✅ Delete Product (Admin only)
router.delete("/admin/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      "DELETE FROM products WHERE id = $1 RETURNING *",
      [id]
    );
    if (result.rowCount === 0)
      return res.status(404).json({ error: "Product not found" });

    res.json({ message: "🗑️ Product deleted successfully" });
  } catch (error) {
    console.error("❌ Error deleting product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/* ==========================================================
   💧 OWNER ROUTES — Full CRUD control per station
========================================================== */

// ✅ Add Product
router.post("/owner", upload.single("photo"), async (req, res) => {
  try {
    const { name, type, size_category, price, station_id } = req.body;
    const photo = req.file ? req.file.filename : null;

    if (!name || !type || !size_category || !price || !station_id)
      return res.status(400).json({ error: "All fields are required" });

    // Check for duplicates
    const dup = await pool.query(
      `SELECT * FROM products 
       WHERE LOWER(name)=LOWER($1)
       AND LOWER(type)=LOWER($2)
       AND LOWER(size_category)=LOWER($3)
       AND station_id=$4`,
      [name, type, size_category, station_id]
    );
    if (dup.rows.length > 0)
      return res
        .status(409)
        .json({ error: "Product already exists in this station." });

    const result = await pool.query(
      `INSERT INTO products 
       (name, type, size_category, price, photo, station_id, created_at, is_archived)
       VALUES ($1,$2,$3,$4,$5,$6,NOW(),FALSE)
       RETURNING *`,
      [name, type, size_category, price, photo, station_id]
    );
    res.status(200).json({
      message: "✅ Product added successfully",
      product: result.rows[0],
    });
  } catch (error) {
    console.error("❌ Error adding owner product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Fetch products (Owner station only)
router.get("/owner/:station_id", async (req, res) => {
  try {
    const { station_id } = req.params;

    const result = await pool.query(
      `SELECT 
         p.*, s.station_name
       FROM products p
       LEFT JOIN water_refilling_stations s 
         ON p.station_id = s.station_id
       WHERE p.station_id = $1
       ORDER BY p.id DESC`,
      [station_id]
    );
    res.json(result.rows);
  } catch (error) {
    console.error("❌ Error fetching owner products:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Update Product
router.put("/owner/:id", upload.single("photo"), async (req, res) => {
  try {
    const { id } = req.params;
    const { name, type, size_category, price } = req.body;
    const photo = req.file ? req.file.filename : null;

    const current = await pool.query("SELECT * FROM products WHERE id=$1", [id]);
    if (current.rowCount === 0)
      return res.status(404).json({ error: "Product not found" });

    const station_id = current.rows[0].station_id;

    const dup = await pool.query(
      `SELECT * FROM products 
       WHERE LOWER(name)=LOWER($1)
       AND LOWER(type)=LOWER($2)
       AND LOWER(size_category)=LOWER($3)
       AND id != $4
       AND station_id = $5`,
      [name, type, size_category, id, station_id]
    );
    if (dup.rows.length > 0)
      return res.status(409).json({
        error: "Another product with same name/type/size exists.",
      });

    // Replace old photo if new uploaded
    const oldPhoto = current.rows[0].photo;
    if (photo && oldPhoto) {
      const oldPath = path.join(__dirname, "../uploads", oldPhoto);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    const result = await pool.query(
      `UPDATE products
       SET name=$1, type=$2, size_category=$3, price=$4,
           photo=COALESCE($5, photo), created_at=NOW()
       WHERE id=$6 RETURNING *`,
      [name, type, size_category, price, photo, id]
    );

    res.json({
      message: "✅ Product updated successfully",
      product: result.rows[0],
    });
  } catch (error) {
    console.error("❌ Error updating owner product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Archive / Unarchive Product
router.put("/owner/archive/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const check = await pool.query("SELECT is_archived FROM products WHERE id=$1", [id]);
    if (check.rowCount === 0)
      return res.status(404).json({ error: "Product not found" });

    const newStatus = !check.rows[0].is_archived;
    const result = await pool.query(
      "UPDATE products SET is_archived=$1 WHERE id=$2 RETURNING *",
      [newStatus, id]
    );

    const msg = newStatus
      ? "📦 Product archived successfully"
      : "✅ Product restored successfully";

    res.json({ message: msg, product: result.rows[0] });
  } catch (error) {
    console.error("❌ Error archiving owner product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

/* ==========================================================
   🧠 DEFAULT HANDLER
========================================================== */
router.use((req, res) => {
  res.status(404).json({ error: "Invalid products route" });
});

module.exports = router;
