console.log("🔥 todoRoutes.js loaded");
const express = require("express");
const router = express.Router();

console.log("✅ Todo Routes Loaded");

router.get("/test", (req, res) => {
  res.json({
    success: true,
    message: "Todo route is working",
  });
});

router.post("/", (req, res) => {
  console.log("POST /api/todos hit");

  res.json({
    success: true,
    message: "POST route is working",
    body: req.body,
  });
});

module.exports = router;
