const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

const connectWithRetry = async (retries = 10) => {
  while (retries > 0) {
    try {
      await pool.query("SELECT NOW()");
      console.log("✅ Connected to PostgreSQL");
      return;
    } catch (error) {
      console.log(
        `⏳ PostgreSQL not ready... Retrying in 5 seconds (${retries} attempts left)`,
      );

      retries--;

      await new Promise((resolve) => setTimeout(resolve, 5000));
    }
  }

  console.error("❌ Could not connect to PostgreSQL");
  process.exit(1);
};

connectWithRetry();

module.exports = pool;
