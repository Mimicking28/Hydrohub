const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const pool = require("../db");
const router = express.Router();

// ⚙️ Multer storage for product images
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, path.join(__dirname, "../uploads")),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

/* ==========================================================
   PRODUCT ROUTES — ADMIN (read/delete) + OWNER (full control)
   ========================================================== */

// ✅ Add Product (Owner only)
router.post("/", upload.single("photo"), async (req, res) => {
  try {
    const { name, type, size_category, price, station_id } = req.body;
    const photo = req.file ? req.file.filename : null;

    if (!name || !type || !size_category || !price || !station_id)
      return res.status(400).json({ error: "All fields are required" });

    // 🔍 Check duplicates per station
    const existing = await pool.query(
      `SELECT * FROM products 
       WHERE LOWER(name) = LOWER($1)
       AND LOWER(type) = LOWER($2)
       AND LOWER(size_category) = LOWER($3)
       AND station_id = $4`,
      [name, type, size_category, station_id]
    );

    if (existing.rows.length > 0)
      return res.status(409).json({
        error: "A product with the same name, type, and size already exists in this station.",
      });

    // ✅ Insert new product
    const result = await pool.query(
      `INSERT INTO products 
       (name, type, size_category, price, photo, station_id, created_at, is_archived)
       VALUES ($1, $2, $3, $4, $5, $6, NOW(), FALSE)
       RETURNING *`,
      [name, type, size_category, price, photo, station_id]
    );

    res.status(200).json({
      message: "✅ Product added successfully",
      product: result.rows[0],
    });
  } catch (error) {
    console.error("❌ Error adding product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Fetch Products
// ?role=admin  → all stations
// ?station_id=3 → owner station only
router.get("/", async (req, res) => {
  try {
    const { role, station_id, type } = req.query;
    let query = "SELECT * FROM products";
    const params = [];

    // 🧠 Admin → see all products
    if (role === "admin") {
      if (type) {
        params.push(type);
        query += ` WHERE LOWER(type) = LOWER($${params.length})`;
      }
    }
    // 🧠 Owner → only their station
    else if (station_id) {
      params.push(station_id);
      query += ` WHERE station_id = $${params.length}`;
      if (type) {
        params.push(type);
        query += ` AND LOWER(type) = LOWER($${params.length})`;
      }
    } else {
      return res.status(400).json({ error: "Missing role or station_id" });
    }

    query += " ORDER BY id DESC";
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error("❌ Error fetching products:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Update Product (Owner only)
router.put("/:id", upload.single("photo"), async (req, res) => {
  try {
    const { id } = req.params;
    const { name, type, size_category, price } = req.body;
    const photo = req.file ? req.file.filename : null;

    if (!name || !type || !size_category || !price)
      return res.status(400).json({ error: "All fields are required" });

    const existingProduct = await pool.query("SELECT * FROM products WHERE id = $1", [id]);
    if (existingProduct.rows.length === 0)
      return res.status(404).json({ error: "Product not found" });

    const duplicateCheck = await pool.query(
      `SELECT * FROM products 
       WHERE LOWER(name) = LOWER($1)
       AND LOWER(type) = LOWER($2)
       AND LOWER(size_category) = LOWER($3)
       AND id != $4
       AND station_id = $5`,
      [name, type, size_category, id, existingProduct.rows[0].station_id]
    );

    if (duplicateCheck.rows.length > 0)
      return res.status(409).json({
        error:
          "Another product with the same name, type, and size already exists in this station.",
      });

    // 🧹 Replace old photo if new uploaded
    const currentPhoto = existingProduct.rows[0].photo;
    if (photo && currentPhoto) {
      const oldPath = path.join(__dirname, "../uploads", currentPhoto);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    const result = await pool.query(
      `UPDATE products
       SET name = $1, type = $2, size_category = $3, price = $4,
           photo = COALESCE($5, photo), created_at = NOW()
       WHERE id = $6 RETURNING *`,
      [name, type, size_category, price, photo, id]
    );

    res.json({ message: "✅ Product updated successfully", product: result.rows[0] });
  } catch (error) {
    console.error("❌ Error updating product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Archive / Unarchive Product (Owner only)
router.put("/archive/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.query;

    if (role === "admin")
      return res.status(403).json({ error: "Admins cannot archive products" });

    const check = await pool.query("SELECT is_archived FROM products WHERE id = $1", [id]);
    if (check.rowCount === 0) return res.status(404).json({ error: "Product not found" });

    const newStatus = !check.rows[0].is_archived;
    const result = await pool.query(
      "UPDATE products SET is_archived = $1 WHERE id = $2 RETURNING *",
      [newStatus, id]
    );

    const message = newStatus
      ? "📦 Product archived successfully"
      : "✅ Product restored successfully";

    res.json({ message, product: result.rows[0] });
  } catch (error) {
    console.error("❌ Error updating archive status:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ Delete Product (Admin only)
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.query;

    if (role !== "admin")
      return res.status(403).json({ error: "Only admins can delete products" });

    const result = await pool.query("DELETE FROM products WHERE id = $1 RETURNING *", [id]);

    if (result.rowCount === 0)
      return res.status(404).json({ error: "Product not found" });

    res.json({ message: "🗑️ Product deleted successfully" });
  } catch (error) {
    console.error("❌ Error deleting product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
