const pool = require("../config/database");

// Create Todo
const createTodo = async (title, description) => {
  const query = `
    INSERT INTO todos (title, description)
    VALUES ($1, $2)
    RETURNING *;
  `;

  const values = [title, description];

  const result = await pool.query(query, values);

  return result.rows[0];
};

module.exports = {
  createTodo,
};
