console.log("🔥 todoRoutes.js loaded");

const express = require("express");
const router = express.Router();

const {
  getTodos,
  createTodo,
  updateTodo,
  deleteTodo,
} = require("../controllers/todoController");

console.log("✅ Todo Routes Loaded");

// Test Route
router.get("/test", (req, res) => {
  res.json({
    success: true,
    message: "Todo route is working",
  });
});

// Get All Todos
router.get("/", getTodos);

// Create Todo
router.post("/", createTodo);

// Update Todo
router.put("/:id", updateTodo);

// Delete Todo
router.delete("/:id", deleteTodo);

module.exports = router;
