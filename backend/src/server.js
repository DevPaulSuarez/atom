const app = require('./app');
const { env } = require('./config/env');
const db = require('./config/database');

const start = async () => {
  try {
    await db.query('SELECT 1'); // verifica conexión a PostgreSQL
    console.log('✅ Base de datos conectada');

    app.listen(env.PORT, () => {
      console.log(`🚀 Servidor corriendo en http://localhost:${env.PORT}`);
      console.log(`📋 Entorno:  ${env.NODE_ENV}`);
      console.log(`🤖 Ollama:   ${env.OLLAMA_URL}  (modelo: ${env.OLLAMA_MODEL})`);
    });
  } catch (err) {
    console.error('❌ Error al iniciar el servidor:', err.message);
    process.exit(1);
  }
};

start();
