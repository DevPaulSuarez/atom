const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Política de Privacidad — Atom</title>
  <style>
    body { font-family: sans-serif; max-width: 700px; margin: 40px auto; padding: 0 20px; color: #333; line-height: 1.6; }
    h1 { color: #111; }
    h2 { color: #444; margin-top: 30px; }
  </style>
</head>
<body>
  <h1>Política de Privacidad — Atom</h1>
  <p>Última actualización: 22 de mayo de 2026</p>
  <p>Atom es desarrollada por DevPess. Esta política describe cómo recopilamos y usamos tu información.</p>
  <h2>Información que recopilamos</h2>
  <ul>
    <li>Nombre y correo electrónico al registrarte</li>
    <li>Proyectos y tareas que creas dentro de la app</li>
    <li>Número de pomodoros completados</li>
  </ul>
  <h2>Cómo usamos tu información</h2>
  <ul>
    <li>Para crear y gestionar tu cuenta</li>
    <li>Para sincronizar tus proyectos y tareas en la nube</li>
    <li>Para generar tareas automáticamente con inteligencia artificial</li>
  </ul>
  <h2>Compartir información</h2>
  <p>No compartimos tu información con terceros.</p>
  <h2>Seguridad</h2>
  <p>Los datos se almacenan en servidores seguros.</p>
  <h2>Eliminación de cuenta</h2>
  <p>Puedes solicitar la eliminación de tu cuenta escribiendo a paulsuarez018@gmail.com.</p>
  <h2>Contacto</h2>
  <p>paulsuarez018@gmail.com</p>
</body>
</html>`);
});

module.exports = router;
