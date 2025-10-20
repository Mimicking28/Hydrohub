const express = require("express");
const router = express.Router();
const pool = require("../db");

// ========================
// ✅ Add new stock record
// ========================
router.post("/", async (req, res) => {
  try {
    const { product_id, amount, stock_type, date, reason, staff_id } = req.body;

    const staffResult = await pool.query(
      "SELECT station_id FROM staff WHERE staff_id = $1",
      [staff_id]
    );

    if (staffResult.rows.length === 0)
      return res.status(400).json({ error: "Invalid staff_id" });

    const result = await pool.query(
      `INSERT INTO stocks (product_id, amount, stock_type, date, reason, staff_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [product_id, amount, stock_type, date, reason || null, staff_id]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("❌ Error inserting stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get all stocks (20L only, filtered by station_id if provided)
// ========================
router.get("/", async (req, res) => {
  try {
    const { station_id, type } = req.query;
    const params = [];

    let query = `
      SELECT 
        st.id, st.amount, st.stock_type, st.reason, st.date,
        p.id AS product_id, p.name AS product_name, p.size_category, p.price, p.type AS product_type,
        sf.staff_id, sf.first_name, sf.last_name, sf.station_id,
        ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      WHERE p.size_category ILIKE '%20%'
    `;

    // ✅ Optional station filter
    if (station_id) {
      query += ` AND sf.station_id = $${params.length + 1}`;
      params.push(station_id);
    }

    // ✅ Optional stock type filter
    if (type) {
      query += ` AND st.stock_type = ANY($${params.length + 1})`;
      params.push(type.split(","));
    }

    query += " ORDER BY st.date DESC";

    const result = await pool.query(query, params);
    console.log("✅ Stocks fetched:", result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching stocks:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get only refilled stocks (20L only)
// ========================
router.get("/refilled", async (req, res) => {
  try {
    const { station_id } = req.query;

    let query = `
      SELECT st.*, 
             p.id AS product_id, p.type AS product_type, 
             p.size_category, p.name AS product_name,
             sf.first_name, sf.last_name, ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      WHERE st.stock_type = 'refilled'
        AND p.size_category ILIKE '%20%'
    `;
    const params = [];

    if (station_id) {
      query += " AND sf.station_id = $1";
      params.push(station_id);
    }

    query += " ORDER BY st.date DESC";
    const result = await pool.query(query, params);

    console.log("✅ Refilled stocks found:", result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching refilled stocks:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get only discarded stocks (20L only)
// ========================
router.get("/discarded", async (req, res) => {
  try {
    const { station_id } = req.query;

    let query = `
      SELECT st.*, 
             p.id AS product_id, p.type AS product_type, 
             p.size_category, p.name AS product_name,
             sf.first_name, sf.last_name, ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      WHERE st.stock_type = 'discarded'
        AND p.size_category ILIKE '%20%'
    `;
    const params = [];

    if (station_id) {
      query += " AND sf.station_id = $1";
      params.push(station_id);
    }

    query += " ORDER BY st.date DESC";
    const result = await pool.query(query, params);

    console.log("✅ Discarded stocks found:", result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching discarded stocks:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get only delivered stocks (20L only)
// ========================
router.get("/delivered", async (req, res) => {
  try {
    const { station_id } = req.query;

    let query = `
      SELECT st.*, 
             p.id AS product_id, p.type AS product_type, 
             p.size_category, p.name AS product_name,
             sf.first_name, sf.last_name, ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      WHERE st.stock_type = 'delivered'
        AND p.size_category ILIKE '%20%'
    `;
    const params = [];

    if (station_id) {
      query += " AND sf.station_id = $1";
      params.push(station_id);
    }

    query += " ORDER BY st.date DESC";
    const result = await pool.query(query, params);

    console.log("✅ Delivered stocks found:", result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching delivered stocks:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get only returned stocks (20L only)
// ========================
router.get("/returned", async (req, res) => {
  try {
    const { station_id } = req.query;

    let query = `
      SELECT st.*, 
             p.id AS product_id, p.type AS product_type, 
             p.size_category, p.name AS product_name,
             sf.first_name, sf.last_name, ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      WHERE st.stock_type = 'returned'
        AND p.size_category ILIKE '%20%'
    `;
    const params = [];

    if (station_id) {
      query += " AND sf.station_id = $1";
      params.push(station_id);
    }

    query += " ORDER BY st.date DESC";
    const result = await pool.query(query, params);

    console.log("✅ Returned stocks found:", result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching returned stocks:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Update stock record by ID
// ========================
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { product_id, amount, stock_type, date, reason } = req.body;

    const result = await pool.query(
      `UPDATE stocks
       SET product_id=$1, amount=$2, stock_type=$3, date=$4, reason=$5
       WHERE id=$6
       RETURNING *`,
      [product_id, amount, stock_type, date, reason || null, id]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ error: "Stock not found" });

    console.log(`✅ Stock ${id} updated successfully`);
    res.json(result.rows[0]);
  } catch (err) {
    console.error("❌ Error updating stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Get available stock for specific product
// ========================
router.post("/available", async (req, res) => {
  try {
    const { product_id } = req.body;

    const result = await pool.query(
      `SELECT
         COALESCE(SUM(CASE WHEN stock_type IN ('refilled','returned') THEN amount ELSE 0 END), 0)
         - COALESCE(SUM(CASE WHEN stock_type IN ('discarded','delivered') THEN amount ELSE 0 END), 0)
         AS available
       FROM stocks
       WHERE product_id = $1`,
      [product_id]
    );

    const available = parseInt(result.rows[0].available);
    console.log(`ℹ️ Product ${product_id} available:`, available);
    res.json({ available: available < 0 ? 0 : available });
  } catch (err) {
    console.error("❌ Error fetching available stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

// ========================
// ✅ Stock summary by product (20L only, grouped per station)
// ========================
router.get("/stock_summary", async (req, res) => {
  try {
    const { station_id } = req.query;

    let query = `
      SELECT 
        p.id AS product_id,
        p.name AS product_name,
        p.type AS product_type,
        p.size_category,
        COALESCE(SUM(CASE WHEN st.stock_type IN ('refilled','returned') THEN st.amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN st.stock_type IN ('discarded','delivered') THEN st.amount ELSE 0 END), 0)
        AS available
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      WHERE p.size_category ILIKE '%20%'
    `;

    const params = [];
    if (station_id) {
      query += " AND sf.station_id = $1";
      params.push(station_id);
    }

    query += `
      GROUP BY p.id, p.name, p.type, p.size_category
      ORDER BY p.name ASC
    `;

    const result = await pool.query(query, params);

    const formatted = result.rows.map((r) => ({
      product_id: r.product_id,
      name: `${r.product_name} ${r.size_category}`,
      available: parseInt(r.available),
      type: r.product_type,
    }));

    console.log("📊 Stock summary products returned:", formatted.length);
    res.json(formatted);
  } catch (err) {
    console.error("❌ Error fetching product-level stock summary:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

module.exports = router;
