const express = require("express");
const router = express.Router();
const pool = require("../db");

/* =========================================================
   🔧 HELPER: Get station_id of a given staff_id
========================================================= */
async function getStationIdByStaff(staff_id) {
  const result = await pool.query(
    "SELECT station_id FROM staff WHERE staff_id = $1",
    [staff_id]
  );
  return result.rows.length > 0 ? result.rows[0].station_id : null;
}

/* =========================================================
   🧾 UNIVERSAL: Add Stock (auto-secured by staff_id)
========================================================= */
router.post("/", async (req, res) => {
  try {
    const { product_id, amount, stock_type, date, reason, staff_id } = req.body;

    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(400).json({ error: "Invalid or missing staff_id" });

    const result = await pool.query(
      `INSERT INTO stocks (product_id, amount, stock_type, date, reason, staff_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [product_id, amount, stock_type, date, reason || null, staff_id]
    );

    console.log(`✅ Stock added by staff ${staff_id} in station ${station_id}`);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("❌ Error adding stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   👑 ADMIN ROUTES — view all stations
========================================================= */
router.get("/admin", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT st.*, 
             p.name AS product_name, p.size_category, p.type AS product_type,
             sf.first_name, sf.last_name, ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      ORDER BY st.date DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Admin fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   🧑‍💼 OWNER ROUTES — view only their own station
========================================================= */
router.get("/owner/:station_id", async (req, res) => {
  try {
    const { station_id } = req.params;

    const result = await pool.query(
      `
      SELECT st.*, 
             p.name AS product_name, p.size_category, p.type AS product_type,
             sf.first_name, sf.last_name, ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      WHERE ws.station_id = $1
      ORDER BY st.date DESC
    `,
      [station_id]
    );

    console.log(`✅ Owner station ${station_id} fetched ${result.rows.length} stocks`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Owner fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   🧍‍♂️ ONSITE STAFF — add/view stocks in their station
========================================================= */
router.get("/onsite/:staff_id", async (req, res) => {
  try {
    const { staff_id } = req.params;
    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(400).json({ error: "Invalid staff_id" });

    const result = await pool.query(
      `
      SELECT st.*, 
             p.name AS product_name, p.size_category, p.type AS product_type,
             sf.first_name, sf.last_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      WHERE sf.station_id = $1
      ORDER BY st.date DESC
    `,
      [station_id]
    );

    console.log(`✅ Onsite staff ${staff_id} fetched ${result.rows.length} stocks`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Onsite fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   ✏️ UPDATE STOCK RECORD (used by UpdateRefilled)
========================================================= */
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { product_id, amount, stock_type, date, staff_id } = req.body;

    if (!product_id || !amount || !stock_type || !date || !staff_id) {
      return res.status(400).json({ error: "⚠️ All fields are required" });
    }

    const check = await pool.query("SELECT * FROM stocks WHERE id = $1", [id]);
    if (check.rowCount === 0) {
      return res.status(404).json({ error: "❌ Stock record not found" });
    }

    const result = await pool.query(
      `UPDATE stocks
       SET product_id = $1, amount = $2, stock_type = $3, date = $4, staff_id = $5
       WHERE id = $6
       RETURNING *`,
      [product_id, amount, stock_type, date, staff_id, id]
    );

    console.log(`✏️ Stock ID ${id} updated by staff ${staff_id}`);
    res.json(result.rows[0]);
  } catch (err) {
    console.error("❌ Error updating stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   🚚 DELIVERY STAFF — view delivered & returned stocks
========================================================= */
router.get("/delivery/:staff_id", async (req, res) => {
  try {
    const { staff_id } = req.params;
    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(400).json({ error: "Invalid staff_id" });

    const result = await pool.query(
      `
      SELECT st.*, 
             p.name AS product_name, p.size_category, p.type AS product_type,
             sf.first_name, sf.last_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      WHERE sf.station_id = $1
        AND st.stock_type IN ('delivered', 'returned')
      ORDER BY st.date DESC
    `,
      [station_id]
    );

    console.log(`✅ Delivery staff ${staff_id} fetched ${result.rows.length} records`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Delivery fetch error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   📊 AVAILABLE STOCKS (user-specific filtering)
========================================================= */
router.post("/available", async (req, res) => {
  try {
    const { staff_id, product_id } = req.body;
    const station_id = await getStationIdByStaff(staff_id);
    if (!station_id)
      return res.status(400).json({ error: "Invalid staff_id" });

    const result = await pool.query(
      `
      SELECT
        COALESCE(SUM(CASE WHEN st.stock_type IN ('refilled','returned') THEN amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN st.stock_type IN ('discarded','delivered') THEN amount ELSE 0 END), 0)
        AS available
      FROM stocks st
      JOIN staff sf ON st.staff_id = sf.staff_id
      WHERE st.product_id = $1 AND sf.station_id = $2
    `,
      [product_id, station_id]
    );

    const available = parseInt(result.rows[0].available) || 0;
    console.log(`📦 Station ${station_id} available stock:`, available);
    res.json({ available: available < 0 ? 0 : available });
  } catch (err) {
    console.error("❌ Error fetching available stock:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   💧 GET STOCKS BY TYPE (refilled, discarded, returned, delivered)
========================================================= */
router.get("/type/:station_id/:stock_type", async (req, res) => {
  try {
    const { station_id, stock_type } = req.params;

    const allowedTypes = ["refilled", "discarded", "returned", "delivered"];
    if (!allowedTypes.includes(stock_type.toLowerCase())) {
      return res.status(400).json({ error: "❌ Invalid stock type" });
    }

    const result = await pool.query(
      `
      SELECT st.*, 
             p.name AS product_name, 
             p.size_category, 
             p.type AS product_type,
             sf.first_name, sf.last_name,
             ws.station_name
      FROM stocks st
      JOIN products p ON st.product_id = p.id
      JOIN staff sf ON st.staff_id = sf.staff_id
      JOIN water_refilling_stations ws ON sf.station_id = ws.station_id
      WHERE sf.station_id = $1
        AND st.stock_type = $2
      ORDER BY st.date DESC
      `,
      [station_id, stock_type]
    );

    console.log(
      `📦 ${stock_type.toUpperCase()} stocks fetched for station ${station_id}: ${result.rows.length}`
    );
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching stocks by type:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

/* =========================================================
   🧮 STOCK SUMMARY PER STATION (Owner & Admin)
========================================================= */
router.get("/summary/:station_id", async (req, res) => {
  try {
    const { station_id } = req.params;

    const result = await pool.query(
      `
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
      WHERE sf.station_id = $1
      GROUP BY p.id, p.name, p.type, p.size_category
      ORDER BY p.name ASC
    `,
      [station_id]
    );

    console.log(`📊 Station ${station_id} summary: ${result.rows.length} products`);
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Stock summary error:", err.message);
    res.status(500).json({ error: "Server error" });
  }
});

module.exports = router;
