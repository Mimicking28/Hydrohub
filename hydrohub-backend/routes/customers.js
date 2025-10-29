const express = require("express");
const router = express.Router();
const pool = require("../db");

// ✅ Safe bcrypt import with fallback
let bcrypt;
try {
  bcrypt = require("bcrypt");
  console.log("Using native bcrypt");
} catch {
  bcrypt = require("bcryptjs");
  console.log("Using bcryptjs (fallback)");
}

// =======================================================
// 🧾 REGISTER CUSTOMER ACCOUNT
// =======================================================
router.post("/register", async (req, res) => {
  try {
    const { first_name, last_name, email, phone_number, password } = req.body;

    if (!first_name || !last_name || !email || !phone_number || !password) {
      return res
        .status(400)
        .json({ success: false, error: "All fields are required." });
    }

    const existing = await pool.query(
      "SELECT * FROM customers WHERE email = $1",
      [email]
    );
    if (existing.rows.length > 0) {
      return res
        .status(400)
        .json({ success: false, error: "Email already registered." });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await pool.query(
      `INSERT INTO customers (first_name, last_name, email, phone_number, password)
       VALUES ($1, $2, $3, $4, $5)`,
      [first_name, last_name, email, phone_number, hashedPassword]
    );

    res.status(200).json({
      success: true,
      message: "✅ Customer registered successfully.",
    });
  } catch (err) {
    console.error("❌ Error registering customer:", err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error. Please try again later." });
  }
});

// =======================================================
// 🔐 CUSTOMER LOGIN
// =======================================================
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password)
      return res
        .status(400)
        .json({ success: false, error: "Email and password are required." });

    const result = await pool.query("SELECT * FROM customers WHERE email = $1", [email]);

    if (result.rows.length === 0)
      return res
        .status(401)
        .json({ success: false, error: "Invalid email or password." });

    const customer = result.rows[0];
    const isMatch = await bcrypt.compare(password, customer.password);

    if (!isMatch)
      return res
        .status(401)
        .json({ success: false, error: "Invalid email or password." });

    res.status(200).json({
      success: true,
      message: "✅ Login successful.",
      customer: {
        customer_id: customer.customer_id,
        first_name: customer.first_name,
        last_name: customer.last_name,
        email: customer.email,
        phone_number: customer.phone_number,
      },
    });
  } catch (err) {
    console.error("❌ Error logging in customer:", err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error while logging in." });
  }
});

// =======================================================
// 👤 GET SINGLE CUSTOMER PROFILE BY ID
// =======================================================
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const customerResult = await pool.query(
      `SELECT customer_id, first_name, last_name, email, phone_number, address, latitude, longitude
       FROM customers
       WHERE customer_id = $1`,
      [id]
    );

    if (customerResult.rows.length === 0)
      return res.status(404).json({ success: false, error: "Customer not found." });

    const addressResult = await pool.query(
      "SELECT * FROM customer_addresses WHERE customer_id = $1 AND is_default = TRUE LIMIT 1",
      [id]
    );

    res.status(200).json({
      ...customerResult.rows[0],
      default_address: addressResult.rows[0] || null,
    });
  } catch (err) {
    console.error("❌ Error fetching customer profile:", err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error fetching profile." });
  }
});

// =======================================================
//✏️ UPDATE CUSTOMER INFORMATION (Now includes email + hash password)
// =======================================================
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  let { first_name, last_name, email, phone_number, password, status } = req.body;

  try {
    // If password is provided, hash it
    if (password) {
      password = await bcrypt.hash(password, 10);
    }

    const result = await pool.query(
      `UPDATE customers 
       SET first_name = COALESCE($1, first_name),
           last_name = COALESCE($2, last_name),
           email = COALESCE($3, email),
           phone_number = COALESCE($4, phone_number),
           password = COALESCE($5, password),
           status = COALESCE($6, status)
       WHERE customer_id = $7
       RETURNING customer_id, first_name, last_name, email, phone_number`,
      [first_name, last_name, email, phone_number, password, status, id]
    );

    if (result.rows.length === 0)
      return res.status(404).json({ success: false, error: "Customer not found." });

    res.json({
      success: true,
      message: "✅ Customer updated successfully.",
      customer: result.rows[0],
    });
  } catch (err) {
    console.error("❌ Error updating customer:", err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error updating customer information." });
  }
});

// =======================================================
// 📍 UPDATE SINGLE CUSTOMER ADDRESS
// =======================================================
router.put("/update-address", async (req, res) => {
  try {
    const { customer_id, address, latitude, longitude } = req.body;

    if (!customer_id || !address || !latitude || !longitude) {
      return res.status(400).json({ success: false, error: "Missing fields." });
    }

    await pool.query(
      `UPDATE customers 
       SET address = $1, latitude = $2, longitude = $3
       WHERE customer_id = $4`,
      [address, latitude, longitude, customer_id]
    );

    res.status(200).json({
      success: true,
      message: "✅ Address updated successfully.",
    });
  } catch (err) {
    console.error("❌ Error updating address:", err.message);
    res
      .status(500)
      .json({ success: false, error: "Server error updating address." });
  }
});

// =======================================================
// 📦 MULTIPLE ADDRESS MANAGEMENT
// =======================================================
router.get("/:id/addresses", async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      "SELECT * FROM customer_addresses WHERE customer_id = $1 ORDER BY is_default DESC, created_at DESC",
      [id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error("❌ Error fetching addresses:", err.message);
    res.status(500).json({ error: "Server error fetching addresses." });
  }
});

router.post("/:id/addresses", async (req, res) => {
  const { id } = req.params;
  const { label, address, note, latitude, longitude } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO customer_addresses 
      (customer_id, label, address, note, latitude, longitude)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *`,
      [id, label || null, address, note || null, latitude, longitude]
    );
    res.json({ success: true, address: result.rows[0] });
  } catch (err) {
    console.error("❌ Error adding address:", err.message);
    res.status(500).json({ error: "Server error adding address." });
  }
});

router.put("/:id/addresses/:address_id", async (req, res) => {
  const { id, address_id } = req.params;
  const { label, address, note, latitude, longitude } = req.body;

  try {
    await pool.query(
      `UPDATE customer_addresses
       SET label = $1, address = $2, note = $3, latitude = $4, longitude = $5
       WHERE address_id = $6 AND customer_id = $7`,
      [label, address, note, latitude, longitude, address_id, id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("❌ Error updating address:", err.message);
    res.status(500).json({ error: "Server error updating address." });
  }
});

router.delete("/:id/addresses/:address_id", async (req, res) => {
  const { id, address_id } = req.params;
  try {
    await pool.query(
      "DELETE FROM customer_addresses WHERE address_id = $1 AND customer_id = $2",
      [address_id, id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("❌ Error deleting address:", err.message);
    res.status(500).json({ error: "Server error deleting address." });
  }
});

router.put("/:id/addresses/:address_id/default", async (req, res) => {
  const { id, address_id } = req.params;
  try {
    await pool.query(
      "UPDATE customer_addresses SET is_default = FALSE WHERE customer_id = $1",
      [id]
    );
    await pool.query(
      "UPDATE customer_addresses SET is_default = TRUE WHERE address_id = $1",
      [address_id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("❌ Error setting default address:", err.message);
    res.status(500).json({ error: "Server error setting default address." });
  }
});

module.exports = router;
