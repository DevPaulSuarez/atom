/**
 * Crea el usuario tester si no existe.
 * Uso: node scripts/seed_tester.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const mysql = require('mysql2/promise');

const TESTER_EMAIL    = 'tester@atom.app';
const TESTER_PASSWORD = 'Atom#Tester2026';
const TESTER_NAME     = 'Tester';

async function main() {
  const url = new URL(process.env.DATABASE_URL);
  const conn = await mysql.createConnection({
    host:     url.hostname,
    port:     parseInt(url.port) || 3306,
    user:     decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    database: url.pathname.slice(1),
  });

  try {
    const [rows] = await conn.execute(
      'SELECT id, is_tester FROM users WHERE email = ?',
      [TESTER_EMAIL]
    );

    if (rows.length) {
      if (!rows[0].is_tester) {
        await conn.execute(
          'UPDATE users SET is_tester = 1 WHERE id = ?',
          [rows[0].id]
        );
        console.log('✓ Usuario tester ya existía — is_tester activado.');
      } else {
        console.log('✓ Usuario tester ya existe y está configurado correctamente.');
      }
      return;
    }

    const hash = await bcrypt.hash(TESTER_PASSWORD, 12);
    const id   = uuidv4();
    await conn.execute(
      'INSERT INTO users (id, email, name, password_hash, is_tester) VALUES (?, ?, ?, ?, 1)',
      [id, TESTER_EMAIL, TESTER_NAME, hash]
    );

    console.log('✓ Usuario tester creado.');
    console.log(`  Email:    ${TESTER_EMAIL}`);
    console.log(`  Password: ${TESTER_PASSWORD}`);
  } finally {
    await conn.end();
  }
}

main().catch((err) => { console.error(err); process.exit(1); });
