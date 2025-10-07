const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const pool = require("../db"); // ✅ PostgreSQL connection
const router = express.Router();

// ⚙️ Multer storage config for photo uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "../uploads"));
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({ storage });

// ✅ POST /api/products — Add new product with improved duplicate validation
router.post("/", upload.single("photo"), async (req, res) => {
  try {
    const { name, type, size_category, price } = req.body;
    const photo = req.file ? req.file.filename : null;

    if (!name || !type || !size_category || !price) {
      return res.status(400).json({ error: "All fields are required" });
    }

    // 🔍 Check for duplicates based on (name, type, size_category)
    const existing = await pool.query(
      `SELECT * FROM products 
       WHERE LOWER(name) = LOWER($1) 
       AND LOWER(type) = LOWER($2) 
       AND LOWER(size_category) = LOWER($3)`,
      [name, type, size_category]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        error:
          "A product with the same name, type, and size already exists.",
      });
    }

    // ✅ Insert product
    const result = await pool.query(
      `INSERT INTO products (name, type, size_category, price, photo, created_at, is_archived)
       VALUES ($1, $2, $3, $4, $5, NOW(), FALSE) RETURNING *`,
      [name, type, size_category, price, photo]
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

// ✅ GET /api/products — Fetch ALL products (archived + non-archived)
router.get("/", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM products ORDER BY is_archived ASC, id DESC"
    );
    res.json(result.rows);
  } catch (error) {
    console.error("❌ Error fetching products:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ PUT /api/products/:id — Update existing product
router.put("/:id", upload.single("photo"), async (req, res) => {
  try {
    const { id } = req.params;
    const { name, type, size_category, price } = req.body;
    const photo = req.file ? req.file.filename : null;

    if (!name || !type || !size_category || !price) {
      return res.status(400).json({ error: "All fields are required" });
    }

    // 🔍 Check if product exists
    const existingProduct = await pool.query(
      "SELECT * FROM products WHERE id = $1",
      [id]
    );

    if (existingProduct.rows.length === 0) {
      return res.status(404).json({ error: "Product not found" });
    }

    // ✅ Prevent duplicates (exclude the current product itself)
    const duplicateCheck = await pool.query(
      `SELECT * FROM products 
       WHERE LOWER(name) = LOWER($1) 
       AND LOWER(type) = LOWER($2) 
       AND LOWER(size_category) = LOWER($3)
       AND id != $4`,
      [name, type, size_category, id]
    );

    if (duplicateCheck.rows.length > 0) {
      return res.status(409).json({
        error:
          "Another product with the same name, type, and size already exists.",
      });
    }

    const currentPhoto = existingProduct.rows[0].photo;

    // 🧹 Delete old photo if new one uploaded
    if (photo && currentPhoto) {
      const oldPath = path.join(__dirname, "../uploads", currentPhoto);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    // ✅ Update product info
    const result = await pool.query(
      `UPDATE products
       SET name = $1, type = $2, size_category = $3, price = $4, 
           photo = COALESCE($5, photo), created_at = NOW()
       WHERE id = $6 RETURNING *`,
      [name, type, size_category, price, photo, id]
    );

    res.json({
      message: "✅ Product updated successfully",
      product: result.rows[0],
    });
  } catch (error) {
    console.error("❌ Error updating product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// ✅ ARCHIVE /api/products/archive/:id — Toggle archive/unarchive
router.put("/archive/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // 🔍 Check current archive status
    const check = await pool.query("SELECT is_archived FROM products WHERE id = $1", [id]);
    if (check.rowCount === 0) {
      return res.status(404).json({ error: "Product not found" });
    }

    const newStatus = !check.rows[0].is_archived; // toggle true/false

    // 🔄 Update archive status
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

// ✅ DELETE /api/products/:id — Optional delete route
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query("DELETE FROM products WHERE id = $1 RETURNING *", [id]);

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Product not found" });
    }

    res.json({ message: "🗑️ Product deleted successfully" });
  } catch (error) {
    console.error("❌ Error deleting product:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
