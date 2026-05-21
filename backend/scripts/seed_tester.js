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

function parseDbUrl(raw) {
  // encode # so URL constructor doesn't treat it as a fragment
  const safe = raw.replace(/#/g, '%23');
  const u = new URL(safe);
  return {
    host:     u.hostname,
    port:     parseInt(u.port) || 3306,
    user:     decodeURIComponent(u.username),
    password: decodeURIComponent(u.password),
    database: u.pathname.slice(1),
  };
}

async function main() {
  const conn = await mysql.createConnection(parseDbUrl(process.env.DATABASE_URL));

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
