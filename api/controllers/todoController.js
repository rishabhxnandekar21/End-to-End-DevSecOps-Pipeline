const todoModel = require("../models/todoModel");

// Get All Todos
const getTodos = async (req, res) => {
  try {
    const todos = await todoModel.getAllTodos();

    res.json({
      success: true,
      data: todos,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      message: "Internal Server Error",
    });
  }
};

// Create Todo
const createTodo = async (req, res) => {
  try {
    const { title, description } = req.body;

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

// Update Todo
const updateTodo = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, status } = req.body;

    const todo = await todoModel.updateTodo(id, title, description, status);

    if (!todo) {
      return res.status(404).json({
        success: false,
        message: "Todo not found",
      });
    }

    res.json({
      success: true,
      message: "Todo updated successfully",
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

// Delete Todo
const deleteTodo = async (req, res) => {
  try {
    const { id } = req.params;

    const todo = await todoModel.deleteTodo(id);

    if (!todo) {
      return res.status(404).json({
        success: false,
        message: "Todo not found",
      });
    }

    res.json({
      success: true,
      message: "Todo deleted successfully",
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
  getTodos,
  createTodo,
  updateTodo,
  deleteTodo,
};
