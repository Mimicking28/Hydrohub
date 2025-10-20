const express = require("express");
const router = express.Router();
const pool = require("../db");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

router.post("/", async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, error: "Missing username or password" });
    }

    let user = null;
    let role = null;

    // ✅ 1. Administrator
    const adminResult = await pool.query(
      "SELECT * FROM administrator WHERE username = $1 LIMIT 1",
      [username]
    );
    if (adminResult.rows.length > 0) {
      user = adminResult.rows[0];
      role = "admin";
    }

    // ✅ 2. Owner
    if (!user) {
      const ownerResult = await pool.query(
        "SELECT * FROM owners WHERE username = $1 LIMIT 1",
        [username]
      );
      if (ownerResult.rows.length > 0) {
        user = ownerResult.rows[0];
        role = "owner";
      }
    }

    // ✅ 3. Staff (Onsite / Delivery)
    if (!user) {
      const staffResult = await pool.query(
        "SELECT * FROM staff WHERE username = $1 AND LOWER(status) = 'active' LIMIT 1",
        [username]
      );
      if (staffResult.rows.length > 0) {
        user = staffResult.rows[0];
        role = user.type ? user.type.toLowerCase() : "staff";
      }
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        error: "Invalid credentials or inactive account",
      });
    }

    // ✅ Password verification
    let validPassword = false;
    try {
      validPassword = await bcrypt.compare(password, user.password);
    } catch {
      validPassword = false;
    }
    if (!validPassword && password === user.password) validPassword = true;

    if (!validPassword) {
      return res.status(401).json({ success: false, error: "Incorrect password" });
    }

    // ✅ Generate JWT
    const token = jwt.sign(
      {
        id: user.admin_id || user.owner_id || user.staff_id,
        username: user.username,
        role,
      },
      "hydrohub_secret",
      { expiresIn: "7d" }
    );

    // ✅ Build structured response
    const response = { success: true, message: "✅ Login successful", token };

    if (role === "admin") {
      response.admin = {
        admin_id: user.admin_id,
        first_name: user.first_name,
        last_name: user.last_name,
        gender: user.gender,
        phone_number: user.phone_number,
        username: user.username,
      };
    } else if (role === "owner") {
      response.owner = {
        owner_id: user.owner_id,
        station_id: user.station_id,
        first_name: user.first_name,
        last_name: user.last_name,
        gender: user.gender,
        phone_number: user.phone_number,
        username: user.username,
      };
    } else {
      response.staff = {
        staff_id: user.staff_id,
        station_id: user.station_id,
        first_name: user.first_name,
        last_name: user.last_name,
        gender: user.gender,
        phone_number: user.phone_number,
        type: user.type ? user.type.toLowerCase() : "staff",
        username: user.username,
        status: user.status,
      };
    }

    console.log("✅ User logged in:", response.staff || response.owner || response.admin);
    res.json(response);
  } catch (err) {
    console.error("❌ Login error:", err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});

module.exports = router;
