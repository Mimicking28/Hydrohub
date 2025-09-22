const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const { Pool } = require("pg");
const multer = require("multer");
const path = require("path");

const app = express();
const port = 5000;

// ========================
// Middleware
// ========================
app.use(cors());
app.use(bodyParser.json());
app.use("/uploads", express.static("uploads")); // serve proof images

// ========================
// PostgreSQL Connection
// ========================
const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "hydrohub",
  password: "12345",
  port: 5432,
});

// ========================
// Multer Setup for Proof Uploads
// ========================
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });

// ========================
// STOCK ROUTES
// ========================

// ✅ Add stock
app.post("/stocks", async (req, res) => {
  try {
    const { water_type, size, amount, stock_type, date, reason } = req.body;

    const result = await pool.query(
      `INSERT INTO stocks (water_type, size, amount, stock_type, date, reason)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [water_type, size, amount, stock_type, date, reason || null]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Error inserting stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Fetch stocks
app.get("/stocks", async (req, res) => {
  try {
    const { type } = req.query;
    let query = "SELECT * FROM stocks";
    let params = [];

    if (type) {
      const types = type.split(",");
      query += " WHERE stock_type = ANY($1)";
      params.push(types);
    }

    query += " ORDER BY date DESC";

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error("Error fetching stocks:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Update stock
app.put("/stocks/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { water_type, size, amount, stock_type, date, reason } = req.body;

    const result = await pool.query(
      `UPDATE stocks
       SET water_type=$1, size=$2, amount=$3, stock_type=$4, date=$5, reason=$6
       WHERE id=$7
       RETURNING *`,
      [water_type, size, amount, stock_type, date, reason || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Stock not found" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("Error updating stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Get available stock
app.post("/available_stock", async (req, res) => {
  try {
    const { water_type, size } = req.body;

    const result = await pool.query(
      `SELECT
         COALESCE(SUM(CASE WHEN stock_type IN ('refilled','returned') THEN amount ELSE 0 END), 0)
         - COALESCE(SUM(CASE WHEN stock_type IN ('discarded','delivered') THEN amount ELSE 0 END), 0)
         AS available
       FROM stocks
       WHERE water_type = $1 AND size = $2`,
      [water_type, size]
    );

    const available = parseInt(result.rows[0].available);
    res.json({ available: available < 0 ? 0 : available });
  } catch (err) {
    console.error("Error fetching available stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Stock summary
app.get("/stock_summary", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT LOWER(water_type) AS water_type,
         COALESCE(SUM(CASE WHEN stock_type IN ('refilled','returned') THEN amount ELSE 0 END), 0)
         - COALESCE(SUM(CASE WHEN stock_type IN ('discarded','delivered') THEN amount ELSE 0 END), 0)
         AS available
       FROM stocks
       GROUP BY LOWER(water_type)`
    );

    const summary = { Alkaline: 0, Mineral: 0, Purified: 0 };
    result.rows.forEach((row) => {
      const key = row.water_type.charAt(0).toUpperCase() + row.water_type.slice(1);
      summary[key] = parseInt(row.available);
    });

    res.json(summary);
  } catch (err) {
    console.error("Error fetching stock summary:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// SALES ROUTES
// ========================

// ✅ Add Sale
app.post("/sales", upload.single("proof"), async (req, res) => {
  try {
    const {
      water_type,
      size,
      quantity,
      total,
      payment_method,
      sale_type,
    } = req.body;

    const proof = req.file ? req.file.filename : null;
    const date = new Date();

    const result = await pool.query(
      `INSERT INTO sales
        (water_type, size, quantity, total, date, payment_method, sale_type, proof)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING *`,
      [water_type, size, quantity, total, date, payment_method, sale_type, proof]
    );

    const sale = result.rows[0];
    res.status(201).json({
      ...sale,
      proof_url: proof ? `http://localhost:5000/uploads/${proof}` : null,
    });
  } catch (err) {
    console.error("Error adding sale:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Fetch Sales
app.get("/sales", async (req, res) => {
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

    const sales = result.rows.map((sale) => ({
      ...sale,
      proof_url: sale.proof ? `http://localhost:5000/uploads/${sale.proof}` : null,
    }));

    res.json(sales);
  } catch (err) {
    console.error("Error fetching sales:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Update Sale
app.put("/sales/:id", upload.single("proof"), async (req, res) => {
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
    } = req.body;

    const proofPath = req.file ? req.file.filename : null;

    const existingSale = await pool.query("SELECT * FROM sales WHERE id = $1", [id]);
    if (existingSale.rows.length === 0) {
      return res.status(404).json({ error: "Sale not found" });
    }

    const result = await pool.query(
      `UPDATE sales
       SET water_type=$1, size=$2, quantity=$3, total=$4, date=$5,
           payment_method=$6, sale_type=$7, proof=COALESCE($8, proof)
       WHERE id=$9
       RETURNING *`,
      [water_type, size, quantity, total, date, payment_method, sale_type, proofPath, id]
    );

    const sale = result.rows[0];
    res.json({
      ...sale,
      proof_url: sale.proof ? `http://localhost:5000/uploads/${sale.proof}` : null,
    });
  } catch (err) {
    console.error("Error updating sale:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Logs (alias for sales with proof_url)
app.get("/logs", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM sales ORDER BY date DESC");

    const logs = result.rows.map((sale) => ({
      ...sale,
      proof_url: sale.proof ? `http://localhost:5000/uploads/${sale.proof}` : null,
    }));

    res.json(logs);
  } catch (err) {
    console.error("Error fetching logs:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// START SERVER
// ========================
app.listen(port, () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});
