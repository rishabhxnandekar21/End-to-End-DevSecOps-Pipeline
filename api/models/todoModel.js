const pool = require("../config/database");

// Get all todos
const getAllTodos = async () => {
  const result = await pool.query("SELECT * FROM todos ORDER BY id DESC");

  return result.rows;
};

// Create todo
const createTodo = async (title, description) => {
  const result = await pool.query(
    `INSERT INTO todos (title, description, status)
     VALUES ($1, $2, 'Pending')
     RETURNING *`,
    [title, description],
  );

  return result.rows[0];
};

// Update todo
const updateTodo = async (id, title, description, status) => {
  const result = await pool.query(
    `UPDATE todos
     SET title = $1,
         description = $2,
         status = $3,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = $4
     RETURNING *`,
    [title, description, status, id],
  );

  return result.rows[0];
};

const deleteTodo = async (id) => {
  const result = await pool.query(
    `DELETE FROM todos
     WHERE id = $1
     RETURNING *`,
    [id],
  );

  return result.rows[0];
};

module.exports = {
  getAllTodos,
  createTodo,
  updateTodo,
  deleteTodo,
};
