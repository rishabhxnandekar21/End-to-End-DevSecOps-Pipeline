const { Pool } = require("pg");

console.log({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

pool
  .connect()
  .then((client) => {
    console.log("✅ PostgreSQL Connected");
    client.release();
  })
  .catch((err) => {
    console.error("❌ PostgreSQL Connection Failed");
    console.error(err.message);
  });

module.exports = pool;
