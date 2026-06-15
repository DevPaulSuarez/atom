const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Eliminar cuenta — Atom</title>
  <style>
    body { font-family: sans-serif; max-width: 700px; margin: 40px auto; padding: 0 20px; color: #333; line-height: 1.6; }
    h1 { color: #111; }
  </style>
</head>
<body>
  <h1>Eliminar tu cuenta de Atom</h1>
  <p>Para solicitar la eliminación de tu cuenta y todos tus datos, envía un correo a:</p>
  <p><strong>paulsuarez018@gmail.com</strong></p>
  <p>Asunto: <strong>Eliminar cuenta Atom</strong></p>
  <p>Incluye el correo electrónico asociado a tu cuenta. Procesaremos tu solicitud en un plazo de 7 días hábiles.</p>
  <h2>Datos que se eliminan</h2>
  <ul>
    <li>Tu cuenta y datos de perfil</li>
    <li>Todos tus proyectos y tareas</li>
    <li>Tu historial de pomodoros</li>
  </ul>
</body>
</html>`);
});

module.exports = router;
