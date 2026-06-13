/**
 * Runner de migraciones.
 * Aplica los .sql de /migrations que aún no se hayan aplicado, en orden.
 * Usa DATABASE_URL del .env del entorno (local o servidor), así que NO depende
 * de credenciales hardcodeadas.
 *
 * Uso (en la máquina donde vive la base, p. ej. el servidor):
 *   node scripts/migrate.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '../.env') });

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

// Errores que significan "esto ya estaba aplicado" → se tolera y se marca.
// 1060 = columna duplicada, 1050 = tabla ya existe, 1061 = índice duplicado.
const ALREADY_APPLIED = new Set([1050, 1060, 1061]);

async function main() {
  if (!process.env.DATABASE_URL) {
    console.error('Falta DATABASE_URL en el .env');
    process.exit(1);
  }

  const url = new URL(process.env.DATABASE_URL);
  const conn = await mysql.createConnection({
    host: url.hostname,
    port: parseInt(url.port) || 3306,
    user: decodeURIComponent(url.username),
    password: decodeURIComponent(url.password),
    database: url.pathname.slice(1),
    multipleStatements: true,
  });

  console.log(`Base: ${url.pathname.slice(1)} @ ${url.hostname}\n`);

  await conn.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      name       VARCHAR(255) PRIMARY KEY,
      applied_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  `);

  const [appliedRows] = await conn.query('SELECT name FROM _migrations');
  const done = new Set(appliedRows.map((r) => r.name));

  const dir = path.join(__dirname, '../migrations');
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();

  let applied = 0;
  for (const file of files) {
    if (done.has(file)) {
      console.log(`✓ ${file} (ya registrada)`);
      continue;
    }

    const sql = fs.readFileSync(path.join(dir, file), 'utf8');
    process.stdout.write(`→ ${file} ... `);
    try {
      await conn.query(sql);
      await conn.query('INSERT INTO _migrations (name) VALUES (?)', [file]);
      console.log('OK');
      applied++;
    } catch (err) {
      if (ALREADY_APPLIED.has(err.errno)) {
        // La columna/tabla ya existía (migración aplicada antes sin registro).
        await conn.query('INSERT IGNORE INTO _migrations (name) VALUES (?)', [file]);
        console.log('ya estaba aplicada (se registra)');
        continue;
      }
      console.log('ERROR');
      console.error(`  ${err.message}`);
      await conn.end();
      process.exit(1);
    }
  }

  console.log(`\nListo. ${applied} migración(es) nueva(s) aplicada(s).`);
  await conn.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
