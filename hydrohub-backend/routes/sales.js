const express = require("express");
const router = express.Router();
const pool = require("../db");
const multer = require("multer");
const path = require("path");

// 📸 Configure file upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// ✅ POST sale (with optional proof)
router.post("/", upload.single("proof"), async (req, res) => {
  try {
    const { water_type, size, quantity, total, date, payment_method, sale_type } = req.body;
    const proof = req.file ? req.file.filename : null;

    await pool.query(
      `INSERT INTO sales (water_type, size, quantity, total, date, payment_method, proof, sale_type)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [water_type, size, quantity, total, date, payment_method, proof, sale_type]
    );

    res.status(201).json({ message: "✅ Sale added successfully" });
  } catch (err) {
    console.error("❌ Error saving sale:", err);
    res.status(500).json({ error: "Server error while saving sale" });
  }
});

// ✅ GET all sales or filter by type (?type=delivery)
router.get("/", async (req, res) => {
  try {
    const { type } = req.query;
    let query = "SELECT * FROM sales";
    let params = [];

    if (type) {
      query += " WHERE sale_type = $1";
      params.push(type);
    }

    query += " ORDER BY date DESC";
    const result = await pool.query(query, params);

    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching sales:", err);
    res.status(500).json({ error: "Server error while fetching sales" });
  }
});

module.exports = router;
