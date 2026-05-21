const mysql = require('mysql2/promise');
const { env } = require('./env');

const url = new URL(env.DATABASE_URL);

const pool = mysql.createPool({
  host: url.hostname,
  port: parseInt(url.port) || 3306,
  user: decodeURIComponent(url.username),
  password: decodeURIComponent(url.password),
  database: url.pathname.slice(1),
  waitForConnections: true,
  connectionLimit: 10,
  timezone: '+00:00',
  typeCast(field, next) {
    // Convierte TINYINT(1) a boolean igual que PostgreSQL
    if (field.type === 'TINY' && field.length === 1) {
      return field.string() === '1';
    }
    return next();
  },
});

// Wrapper que devuelve { rows } en todas las queries
module.exports = {
  async query(sql, params = []) {
    const [rows] = await pool.query(sql, params);
    return { rows: Array.isArray(rows) ? rows : [] };
  },
};
