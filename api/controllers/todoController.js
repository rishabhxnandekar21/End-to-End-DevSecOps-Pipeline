const todoModel = require("../models/todoModel");

// Create Todo
const createTodo = async (req, res) => {
  try {
    const { title, description } = req.body;

    // Validation
    if (!title) {
      return res.status(400).json({
        success: false,
        message: "Title is required",
      });
    }

    const todo = await todoModel.createTodo(title, description);

    res.status(201).json({
      success: true,
      message: "Todo created successfully",
      data: todo,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};

module.exports = {
  createTodo,
};
