const express = require("express");
const router = express.Router();
const pool = require("../db");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// 📸 Image upload setup
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) =>
    cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// ✅ GET: Station profile by ID
router.get("/:station_id", async (req, res) => {
  try {
    const { station_id } = req.params;
    const result = await pool.query(
      "SELECT * FROM water_refilling_stations WHERE station_id = $1",
      [station_id]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ message: "Station not found" });

    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch station details" });
  }
});

// ✅ POST: Update station profile
router.post("/update-profile", upload.single("profile_picture"), async (req, res) => {
  try {
    const {
      station_id,
      station_name,
      address,
      contact_number,
      description,
      latitude,
      longitude,
      working_days,
      opening_time,
      closing_time,
    } = req.body;

    const profilePic = req.file ? req.file.filename : null;

    const existing = await pool.query(
      "SELECT * FROM water_refilling_stations WHERE station_id = $1",
      [station_id]
    );

    if (existing.rows.length === 0)
      return res.status(404).json({ error: "Station not found" });

    // Update station info
    await pool.query(
      `UPDATE water_refilling_stations
       SET station_name = $1,
           address = $2,
           contact_number = $3,
           description = $4,
           latitude = $5,
           longitude = $6,
           working_days = $7,
           opening_time = $8,
           closing_time = $9,
           profile_picture = COALESCE($10, profile_picture)
       WHERE station_id = $11`,
      [
        station_name,
        address,
        contact_number,
        description,
        latitude || null,
        longitude || null,
        working_days ? JSON.parse(working_days) : null,
        opening_time,
        closing_time,
        profilePic,
        station_id,
      ]
    );

    res.json({ success: true, message: "Station profile updated" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to update station profile" });
  }
});

module.exports = router;
