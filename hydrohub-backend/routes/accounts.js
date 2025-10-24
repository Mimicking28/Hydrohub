const express = require("express");
const router = express.Router();
const pool = require("../db");
const bcrypt = require("bcryptjs");

/* ================================================================
 🧑‍💼 ADMINISTRATOR SECTION
================================================================ */

// ✅ CREATE ADMIN ACCOUNT
router.post("/admin", async (req, res) => {
  try {
    const { first_name, last_name, gender, phone_number, password } = req.body;

    if (!first_name || !last_name || !gender || !phone_number || !password)
      return res.status(400).json({ success: false, error: "Missing required fields" });

    // ✅ Check if phone number already exists
    const existing = await pool.query(
      "SELECT * FROM administrator WHERE phone_number = $1 LIMIT 1",
      [phone_number]
    );
    if (existing.rows.length > 0)
      return res.status(400).json({ success: false, error: "Phone number already exists." });

    // ✅ Find the latest numeric suffix used (always increment safely)
    const latest = await pool.query(`
      SELECT username
      FROM administrator
      WHERE username ~ '^[a-zA-Z]+[0-9]+$'
      ORDER BY CAST(REGEXP_REPLACE(username, '\\D', '', 'g') AS INTEGER) DESC
      LIMIT 1
    `);

    let nextNumber = 1;
    if (latest.rows.length > 0) {
      const match = latest.rows[0].username.match(/(\d+)$/);
      if (match) nextNumber = parseInt(match[1]) + 1;
    }

    const formatted = nextNumber.toString().padStart(6, "0");
    const username = `admin${formatted}`;
    const hashed = await bcrypt.hash(password, 10);

    // ✅ Insert new admin
    await pool.query(
      `INSERT INTO administrator (first_name, last_name, gender, phone_number, username, password)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [first_name, last_name, gender, phone_number, username, hashed]
    );

    res.status(201).json({ success: true, message: "✅ Admin created", username });
  } catch (err) {
    console.error("❌ Error creating admin:", err);
    res.status(500).json({ success: false, error: "Server error while creating admin" });
  }
});

// ✅ GET ADMIN PROFILE
router.get("/admin/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "SELECT admin_id, first_name, last_name, gender, phone_number, username FROM administrator WHERE admin_id = $1",
      [id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: "Admin not found" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error("❌ Error fetching admin:", err);
    res.status(500).json({ error: "Server error fetching admin" });
  }
});

// ✅ UPDATE ADMIN PROFILE
router.put("/admin/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { first_name, last_name, phone_number, password } = req.body;

    const admin = await pool.query("SELECT * FROM administrator WHERE admin_id = $1", [id]);
    if (admin.rows.length === 0)
      return res.status(404).json({ success: false, error: "Admin not found" });

    const fields = [];
    const values = [];
    let count = 1;

    if (first_name) {
      fields.push(`first_name = $${count++}`);
      values.push(first_name);
    }
    if (last_name) {
      fields.push(`last_name = $${count++}`);
      values.push(last_name);
    }
    if (phone_number) {
      fields.push(`phone_number = $${count++}`);
      values.push(phone_number);
    }
    if (password) {
      const hashed = await bcrypt.hash(password, 10);
      fields.push(`password = $${count++}`);
      values.push(hashed);
    }

    if (!fields.length) return res.status(400).json({ error: "No fields to update" });

    values.push(id);
    const result = await pool.query(
      `UPDATE administrator SET ${fields.join(", ")} WHERE admin_id = $${count} RETURNING *`,
      values
    );

    res.json({ success: true, message: "✅ Admin updated", admin: result.rows[0] });
  } catch (err) {
    console.error("❌ Error updating admin:", err);
    res.status(500).json({ error: "Server error updating admin" });
  }
});
/* ================================================================
 💧 STATIONS SECTION
================================================================ */
/* ================================================================
 🏢 STATION SECTION
================================================================ */

// ✅ GET ALL STATIONS
router.get("/stations", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        s.station_id,
        s.station_name,
        s.status,
        COUNT(o.owner_id) AS total_owners,
        COUNT(st.staff_id) AS total_staff
      FROM water_refilling_stations s
      LEFT JOIN owners o ON s.station_id = o.station_id
      LEFT JOIN staff st ON s.station_id = st.station_id
      GROUP BY s.station_id
      ORDER BY s.station_name ASC
    `);

    res.status(200).json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching stations:", err);
    res.status(500).json({ error: "Server error fetching stations" });
  }
});

// ✅ TOGGLE STATION STATUS (cascade owners + staff)
router.put("/stations/status/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Check current station status
    const stationCheck = await pool.query(
      "SELECT status FROM water_refilling_stations WHERE station_id = $1",
      [id]
    );
    if (stationCheck.rows.length === 0)
      return res.status(404).json({ error: "Station not found" });

    const currentStatus = stationCheck.rows[0].status;
    const newStatus = currentStatus === "Active" ? "Inactive" : "Active";

    // Update station
    await pool.query(
      "UPDATE water_refilling_stations SET status = $1 WHERE station_id = $2",
      [newStatus, id]
    );

    // ✅ Cascade status to linked accounts
    await pool.query("UPDATE owners SET status = $1 WHERE station_id = $2", [newStatus, id]);
    await pool.query("UPDATE staff SET status = $1 WHERE station_id = $2", [newStatus, id]);

    res.status(200).json({
      success: true,
      message:
        newStatus === "Active"
          ? "✅ Station reactivated along with linked accounts."
          : "🚫 Station deactivated along with linked accounts.",
    });
  } catch (err) {
    console.error("❌ Error toggling station status:", err);
    res.status(500).json({ error: "Server error updating station status" });
  }
});
/* ================================================================
 📋 ALL ACCOUNTS (ADMIN DASHBOARD) — includes password
================================================================ */

// ✅ Fetch all account types (Administrator, Owners, Staff)
router.get("/all", async (req, res) => {
  try {
    // 🧩 Fetch Administrators
    const admins = await pool.query(`
      SELECT 
        admin_id AS id,
        first_name,
        last_name,
        gender,
        phone_number,
        username,
        password,
        'Administrator' AS role,
        NULL AS type,
        NULL AS station_name,
        NULL AS status
      FROM administrator
    `);

    // 🧩 Fetch Owners (joined with station)
    const owners = await pool.query(`
      SELECT 
        owner_id AS id,
        first_name,
        last_name,
        gender,
        phone_number,
        username,
        password,
        'Owner' AS role,
        NULL AS type,
        s.station_name,
        o.status
      FROM owners o
      LEFT JOIN water_refilling_stations s ON o.station_id = s.station_id
    `);

    // 🧩 Fetch Staff (joined with station)
    const staff = await pool.query(`
      SELECT 
        staff_id AS id,
        first_name,
        last_name,
        gender,
        phone_number,
        username,
        password,
        'Staff' AS role,
        type,
        s.station_name,
        st.status
      FROM staff st
      LEFT JOIN water_refilling_stations s ON st.station_id = s.station_id
    `);

    // 🧩 Combine all results
    const combined = [
      ...admins.rows,
      ...owners.rows,
      ...staff.rows
    ];

    res.status(200).json(combined);
  } catch (err) {
    console.error("❌ Error fetching all accounts:", err);
    res.status(500).json({ error: "Server error fetching all accounts" });
  }
});
/* ================================================================
 💧 OWNER SECTION
================================================================ */

// ✅ CREATE OWNER + STATION
router.post("/owner", async (req, res) => {
  try {
    const { station_name, first_name, last_name, gender, phone_number, password } = req.body;
    if (!station_name || !first_name || !last_name || !gender || !phone_number || !password)
      return res.status(400).json({ error: "Missing required fields" });

    const check = await pool.query("SELECT * FROM owners WHERE phone_number = $1", [phone_number]);
    if (check.rows.length > 0)
      return res.status(400).json({ error: "Phone number already exists" });

    // Create or find station
    const station = await pool.query(
      `INSERT INTO water_refilling_stations (station_name, status)
       VALUES ($1, 'Active')
       ON CONFLICT (station_name) DO NOTHING RETURNING station_id`,
      [station_name]
    );

    let stationId = station.rows.length
      ? station.rows[0].station_id
      : (await pool.query("SELECT station_id FROM water_refilling_stations WHERE station_name = $1", [station_name]))
          .rows[0].station_id;

    const latest = await pool.query("SELECT username FROM owners ORDER BY owner_id DESC LIMIT 1");
    let next = 1;
    if (latest.rows.length > 0) {
      const match = latest.rows[0].username.match(/(\\d+)$/);
      if (match) next = parseInt(match[1]) + 1;
    }
    const formatted = next.toString().padStart(6, "0");
    const username = `${last_name.toLowerCase()}${formatted}`;
    const hashed = await bcrypt.hash(password, 10);

    await pool.query(
      `INSERT INTO owners (first_name, last_name, gender, phone_number, username, password, station_id, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,'Active')`,
      [first_name, last_name, gender, phone_number, username, hashed, stationId]
    );

    res.status(201).json({ success: true, message: "✅ Owner created", username });
  } catch (err) {
    console.error("❌ Error creating owner:", err);
    res.status(500).json({ error: "Server error creating owner" });
  }
});

// ✅ GET OWNER PROFILE
router.get("/owner/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT o.*, s.station_name 
       FROM owners o 
       LEFT JOIN water_refilling_stations s ON o.station_id = s.station_id 
       WHERE o.owner_id = $1`,
      [id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: "Owner not found" });
    res.json(result.rows[0]);
  } catch (err) {
    console.error("❌ Error fetching owner profile:", err);
    res.status(500).json({ error: "Server error fetching owner profile" });
  }
});

// ✅ UPDATE OWNER PROFILE
router.put("/owner/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { first_name, last_name, phone_number, password } = req.body;

    const owner = await pool.query("SELECT * FROM owners WHERE owner_id = $1", [id]);
    if (owner.rows.length === 0)
      return res.status(404).json({ error: "Owner not found" });

    const updates = [];
    const vals = [];
    let i = 1;

    if (first_name) {
      updates.push(`first_name = $${i++}`);
      vals.push(first_name);
    }
    if (last_name) {
      updates.push(`last_name = $${i++}`);
      vals.push(last_name);
    }
    if (phone_number) {
      updates.push(`phone_number = $${i++}`);
      vals.push(phone_number);
    }
    if (password) {
      const hashed = await bcrypt.hash(password, 10);
      updates.push(`password = $${i++}`);
      vals.push(hashed);
    }

    if (!updates.length) return res.status(400).json({ error: "No fields to update" });
    vals.push(id);

    const result = await pool.query(
      `UPDATE owners SET ${updates.join(", ")} WHERE owner_id = $${i} RETURNING *`,
      vals
    );

    res.json({ success: true, message: "✅ Owner updated", owner: result.rows[0] });
  } catch (err) {
    console.error("❌ Error updating owner:", err);
    res.status(500).json({ error: "Server error updating owner" });
  }
});

/* ================================================================
 👷‍♂️ STAFF SECTION
================================================================ */

// ✅ CREATE STAFF ACCOUNT (with lastname-based username + phone validation)
router.post("/staff", async (req, res) => {
  try {
    const {
      station_id,
      first_name,
      last_name,
      gender,
      phone_number,
      type,
      password,
    } = req.body;

    // 🧠 Validate required fields
    if (
      !station_id ||
      !first_name ||
      !last_name ||
      !gender ||
      !phone_number ||
      !type ||
      !password
    )
      return res.status(400).json({ error: "Missing required fields" });

    // 📱 Validate phone number format (must start with 09 and be 11 digits)
    const phoneRegex = /^09\d{9}$/;
    if (!phoneRegex.test(phone_number))
      return res
        .status(400)
        .json({ error: "Invalid phone number. Must start with 09 and be 11 digits." });

    // ⚙️ Validate staff type
    if (!["Onsite", "Delivery"].includes(type))
      return res.status(400).json({ error: "Invalid staff type" });

    // 🔍 Check for duplicate phone number
    const existingPhone = await pool.query(
      "SELECT * FROM staff WHERE phone_number = $1",
      [phone_number]
    );
    if (existingPhone.rows.length > 0)
      return res.status(400).json({ error: "Phone number already exists." });

    // 🔢 Generate next username suffix
    const latest = await pool.query(`
      SELECT username FROM staff
      WHERE username ~ '[0-9]+$'
      ORDER BY CAST(REGEXP_REPLACE(username, '\\D', '', 'g') AS INTEGER) DESC
      LIMIT 1
    `);

    let nextNumber = 1;
    if (latest.rows.length > 0) {
      const match = latest.rows[0].username.match(/(\d+)$/);
      if (match) nextNumber = parseInt(match[1]) + 1;
    }

    const formatted = nextNumber.toString().padStart(6, "0");

    // 🧑‍💼 Use last name prefix in lowercase for username
    const username = `${last_name.toLowerCase()}${formatted}`;
    const hashed = await bcrypt.hash(password, 10);

    // 🗄️ Insert new staff record
    const result = await pool.query(
      `INSERT INTO staff 
        (station_id, first_name, last_name, gender, phone_number, type, username, password, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'Active')
       RETURNING staff_id, first_name, last_name, username, type, status`,
      [station_id, first_name, last_name, gender, phone_number, type, username, hashed]
    );

    // 📄 Return generated credentials
    res.status(201).json({
      success: true,
      message: "✅ Staff account created successfully.",
      username: username,
      password: password, // Return plain for display (only once)
      staff: result.rows[0],
    });
  } catch (err) {
    console.error("❌ Error creating staff:", err);
    if (err.code === "23505") {
      res.status(400).json({ error: "Duplicate username or phone number detected." });
    } else {
      res.status(500).json({ error: "Server error creating staff" });
    }
  }
});

// ✅ GET STAFF PROFILE (Onsite / Delivery)
router.get("/staff/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // 🧩 Properly join with the station table for full info
    const result = await pool.query(
      `
      SELECT 
        st.staff_id,
        st.first_name,
        st.last_name,
        st.gender,
        st.phone_number,
        st.username,
        st.type,
        st.status,
        st.station_id,
        s.station_name
      FROM staff st
      LEFT JOIN water_refilling_stations s 
        ON st.station_id = s.station_id
      WHERE st.staff_id = $1
      LIMIT 1
      `,
      [id]
    );

    // 🧠 Handle not found
    if (result.rows.length === 0)
      return res.status(404).json({ error: "Staff not found" });

    // ✅ Return a clean structured profile
    res.status(200).json({
      staff_id: result.rows[0].staff_id,
      first_name: result.rows[0].first_name,
      last_name: result.rows[0].last_name,
      gender: result.rows[0].gender,
      phone_number: result.rows[0].phone_number,
      username: result.rows[0].username,
      type: result.rows[0].type,
      status: result.rows[0].status,
      station_id: result.rows[0].station_id,
      station_name: result.rows[0].station_name || "Unknown Station",
    });
  } catch (err) {
    console.error("❌ Error fetching staff profile:", err);
    res
      .status(500)
      .json({ error: "Server error while fetching staff profile" });
  }
});

// ✅ UPDATE STAFF PROFILE
router.put("/staff/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { first_name, last_name, phone_number, password } = req.body;

    const staff = await pool.query("SELECT * FROM staff WHERE staff_id = $1", [id]);
    if (staff.rows.length === 0)
      return res.status(404).json({ error: "Staff not found" });

    const updates = [];
    const vals = [];
    let i = 1;

    if (first_name) {
      updates.push(`first_name = $${i++}`);
      vals.push(first_name);
    }
    if (last_name) {
      updates.push(`last_name = $${i++}`);
      vals.push(last_name);
    }
    if (phone_number) {
      updates.push(`phone_number = $${i++}`);
      vals.push(phone_number);
    }
    if (password) {
      const hashed = await bcrypt.hash(password, 10);
      updates.push(`password = $${i++}`);
      vals.push(hashed);
    }

    if (!updates.length) return res.status(400).json({ error: "No fields to update" });
    vals.push(id);

    const result = await pool.query(
      `UPDATE staff SET ${updates.join(", ")} WHERE staff_id = $${i} RETURNING *`,
      vals
    );

    res.json({ success: true, message: "✅ Staff updated", staff: result.rows[0] });
  } catch (err) {
    console.error("❌ Error updating staff:", err);
    res.status(500).json({ error: "Server error updating staff" });
  }
});
// ✅ GET ALL STAFF (Optionally filter by station_id)
router.get("/staff", async (req, res) => {
  try {
    const { station_id } = req.query;

    let query = `
      SELECT 
        st.staff_id, st.first_name, st.last_name, st.gender, st.phone_number, 
        st.username, st.type, st.status, s.station_name
      FROM staff st
      LEFT JOIN water_refilling_stations s ON st.station_id = s.station_id
    `;
    const params = [];

    if (station_id) {
      query += ` WHERE st.station_id = $1`;
      params.push(station_id);
    }

    query += " ORDER BY st.staff_id ASC";

    const result = await pool.query(query, params);
    res.status(200).json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching staff list:", err);
    res.status(500).json({ error: "Server error fetching staff list" });
  }
});
// ✅ TOGGLE STAFF STATUS (Active / Inactive)
router.put("/staff/status/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Check if staff exists
    const check = await pool.query("SELECT status FROM staff WHERE staff_id = $1", [id]);   
    if (check.rows.length === 0)
      return res.status(404).json({ success: false, error: "Staff not found" });

    const currentStatus = check.rows[0].status;
    const newStatus = currentStatus === "Active" ? "Inactive" : "Active";

    const updated = await pool.query(
      `UPDATE staff SET status = $1 WHERE staff_id = $2 RETURNING *`,
      [newStatus, id]
    );

    res.status(200).json({
      success: true,
      message:
        newStatus === "Active"
          ? "✅ Staff account activated."
          : "🚫 Staff account deactivated.",
      staff: updated.rows[0],
    });
  } catch (err) {
    console.error("❌ Error toggling staff status:", err);
    res.status(500).json({ success: false, error: "Server error updating staff status" });
  }
});

module.exports = router;
