const errorMiddleware = (err, req, res, next) => { // eslint-disable-line no-unused-vars
  console.error('[Error]', err.message);

  // Errores de PostgreSQL conocidos
  if (err.code === '23505') return res.status(409).json({ error: 'El recurso ya existe' });
  if (err.code === '23503') return res.status(404).json({ error: 'Recurso relacionado no encontrado' });
  if (err.code === '22P02') return res.status(400).json({ error: 'Formato de ID inválido' });

  const status = err.status || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'Error interno del servidor'
    : err.message;

  res.status(status).json({ error: message });
};

module.exports = { errorMiddleware };
