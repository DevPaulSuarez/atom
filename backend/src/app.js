require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

require('./config/passport'); // registra estrategias OAuth
const { env } = require('./config/env');
const authRouter = require('./routes/auth.routes');
const projectsRouter = require('./routes/projects.routes');
const tasksRouter = require('./routes/tasks.routes');
const sessionsRouter = require('./routes/sessions.routes');
const streakRouter   = require('./routes/streak.routes');
const privacyRouter       = require('./routes/privacy');
const deleteAccountRouter = require('./routes/delete-account');
const versionRouter       = require('./routes/version.routes');
const { errorMiddleware } = require('./middleware/error.middleware');

const app = express();

app.use(helmet());
app.use(cors({
  origin: env.ALLOWED_ORIGINS.split(','),
  credentials: true,
}));
app.use(morgan('dev'));
app.use(express.json());

// Health check (no requiere auth)
app.get('/health', (_req, res) =>
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
);

app.use('/auth',     authRouter);
app.use('/projects', projectsRouter);
app.use('/tasks',    tasksRouter);
app.use('/sessions', sessionsRouter);
app.use('/streak',   streakRouter);
app.use('/version',  versionRouter);
app.use('/privacidad',      privacyRouter);
app.use('/eliminar-cuenta', deleteAccountRouter);

// 404 genérico
app.use((_req, res) => res.status(404).json({ error: 'Ruta no encontrada' }));

app.use(errorMiddleware);

module.exports = app;
