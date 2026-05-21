const { v4: uuidv4 } = require('uuid');
const { validationResult } = require('express-validator');
const db = require('../config/database');

exports.createSession = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { microTaskId, type, startedAt, endedAt, wasSkipped, taskCompleted } = req.body;

    // Verificar que la tarea pertenece al usuario
    const { rows: check } = await db.query(
      `SELECT t.id FROM micro_tasks t
       JOIN projects p ON t.project_id = p.id
       WHERE t.id = ? AND p.user_id = ?`,
      [microTaskId, req.user.id]
    );
    if (!check.length) return res.status(404).json({ error: 'Tarea no encontrada' });

    const id = uuidv4();
    await db.query(
      `INSERT INTO pomodoro_sessions
         (id, user_id, micro_task_id, type, started_at, ended_at, was_skipped, task_completed)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, req.user.id, microTaskId, type, startedAt, endedAt ?? null, wasSkipped ?? false, taskCompleted ?? null]
    );

    const { rows: [session] } = await db.query(
      'SELECT * FROM pomodoro_sessions WHERE id = ?',
      [id]
    );

    res.status(201).json(session);
  } catch (err) { next(err); }
};
