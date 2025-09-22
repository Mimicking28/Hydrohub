const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const { Pool } = require("pg");
const multer = require("multer");
const path = require("path");

const app = express();
const port = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use("/uploads", express.static("uploads"));

// PostgreSQL connection
const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "hydrohub",
  password: "12345",
  port: 5432,
});

// Multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage: storage });

// ✅ Add Sale with optional proof upload
app.post("/sales", upload.single("proof"), async (req, res) => {
  try {
    const { water_type, size, quantity, total, payment_method, sale_type } =
      req.body;

    const proof = req.file ? req.file.filename : null;
    const date = new Date(); // auto-generate current date

    const result = await pool.query(
      "INSERT INTO sales (water_type, size, quantity, total, payment_method, sale_type, proof, date) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *",
      [water_type, size, quantity, total, payment_method, sale_type, proof, date]
    );

    // Return proof_url for Flutter
    const sale = result.rows[0];
    res.json({
      ...sale,
      proof_url: proof ? `http://localhost:5000/uploads/${proof}` : null,
    });
  } catch (err) {
    console.error("Error adding sale:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Fetch Sales (onsite + delivery)
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

    // Add full proof_url
    const sales = result.rows.map((sale) => ({
      ...sale,
      proof_url: sale.proof
        ? `http://localhost:5000/uploads/${sale.proof}`
        : null,
    }));

    res.json(sales);
  } catch (err) {
    console.error("Error fetching sales:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Fetch Logs (alias for sales with full proof_url)
app.get("/logs", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM sales ORDER BY date DESC");

    const logs = result.rows.map((sale) => ({
      ...sale,
      proof_url: sale.proof
        ? `http://localhost:5000/uploads/${sale.proof}`
        : null,
    }));

    res.json(logs);
  } catch (err) {
    console.error("Error fetching logs:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Start server
app.listen(port, () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});
