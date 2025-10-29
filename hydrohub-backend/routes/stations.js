const express = require("express");
const router = express.Router();
const pool = require("../db");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// =======================================================
// 📸 FILE UPLOAD CONFIGURATION
// =======================================================
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, "uploads/"),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// =======================================================
// 🔹 GET STATION DETAILS BY ID
// =======================================================
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "SELECT * FROM water_refilling_stations WHERE station_id = $1",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Station not found" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error("❌ Error fetching station details:", err);
    res.status(500).json({ error: err.message });
  }
});

// =======================================================
// 🔹 UPDATE STATION PROFILE
// =======================================================
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

    // ✅ Convert working_days (Flutter sends JSON array)
    let formattedWorkingDays = working_days;
    try {
      if (typeof working_days === "string") {
        const parsed = JSON.parse(working_days);
        if (Array.isArray(parsed)) {
          formattedWorkingDays = `{${parsed.join(",")}}`;
        } else {
          formattedWorkingDays = `{${working_days}}`;
        }
      } else if (Array.isArray(working_days)) {
        formattedWorkingDays = `{${working_days.join(",")}}`;
      }
    } catch (err) {
      formattedWorkingDays = "{Mon,Tue,Wed,Thu,Fri}";
    }

    // ✅ Handle profile picture
    let profilePicture = null;
    if (req.file) {
      profilePicture = req.file.filename;

      // Remove old image if exists
      const oldPic = await pool.query(
        "SELECT profile_picture FROM water_refilling_stations WHERE station_id = $1",
        [station_id]
      );
      if (oldPic.rows.length > 0 && oldPic.rows[0].profile_picture) {
        const oldPath = path.join("uploads", oldPic.rows[0].profile_picture);
        if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
      }
    }

    // ✅ Update record
    const updateQuery = `
      UPDATE water_refilling_stations
      SET 
        station_name = $1,
        address = $2,
        contact_number = $3,
        description = $4,
        latitude = $5,
        longitude = $6,
        working_days = $7,
        opening_time = $8,
        closing_time = $9,
        profile_picture = COALESCE($10, profile_picture)
      WHERE station_id = $11
      RETURNING *;
    `;

    const result = await pool.query(updateQuery, [
      station_name,
      address,
      contact_number,
      description,
      latitude || null,
      longitude || null,
      formattedWorkingDays,
      opening_time || null,
      closing_time || null,
      profilePicture,
      station_id,
    ]);

    res.status(200).json({
      message: "✅ Station profile updated successfully!",
      data: result.rows[0],
    });
  } catch (err) {
    console.error("❌ Update failed:", err);
    res.status(500).json({ error: err.message });
  }
});


// =======================================================
// 🔹 GET ALL ACTIVE STATIONS (for Customer Homepage)
// =======================================================
router.get("/", async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT 
        station_id,
        station_name,
        address,
        contact_number,
        description,
        profile_picture
      FROM water_refilling_stations
      WHERE status = 'Active'
      ORDER BY station_name ASC;
    `);

    // ✅ Add default rating for frontend compatibility
    const formatted = result.rows.map((station) => ({
      ...station,
      rating: 0.0, // Default rating placeholder
    }));

    res.json(formatted);
  } catch (err) {
    console.error("❌ Error fetching active stations:", err);
    res.status(500).json({ error: "Server error while fetching active stations." });
  }
});module.exports = router;
