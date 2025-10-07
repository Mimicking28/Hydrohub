const express = require("express");
const router = express.Router();
const pool = require("../db"); // Make sure db.js exports PostgreSQL Pool

// ========================
// ✅ Add new stock record
// ========================
router.post("/", async (req, res) => {
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
    console.error("❌ Error inserting stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get all or filtered stocks
// ========================
router.get("/", async (req, res) => {
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
    console.error("❌ Error fetching stocks:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Update stock record by ID
// ========================
router.put("/:id", async (req, res) => {
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
    console.error("❌ Error updating stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get available stock for water type + size
// ========================
router.post("/available", async (req, res) => {
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
    console.error("❌ Error fetching available stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Stock summary by water type
// ========================
router.get("/summary", async (req, res) => {
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
      const key =
        row.water_type.charAt(0).toUpperCase() + row.water_type.slice(1);
      summary[key] = parseInt(row.available);
    });

    res.json(summary);
  } catch (err) {
    console.error("❌ Error fetching stock summary:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Flutter Compatibility (alias for /summary)
// ========================
// Flutter calls this: http://10.0.2.2:3000/api/stocks/stock_summary
router.get("/stock_summary", async (req, res) => {
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
      const key =
        row.water_type.charAt(0).toUpperCase() + row.water_type.slice(1);
      summary[key] = parseInt(row.available);
    });

    res.json(summary);
  } catch (err) {
    console.error("❌ Error fetching stock summary:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

module.exports = router;
