const { v4: uuidv4 } = require('uuid');
const { validationResult } = require('express-validator');
const db = require('../config/database');

// MySQL DATETIME no acepta ISO8601 con 'T'/'Z' (ej. 2026-06-21T10:00:00.000Z).
// Convierte a 'YYYY-MM-DD HH:MM:SS' en UTC. Devuelve null si la fecha es inválida.
const toMysqlDateTime = (iso) => {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(0, 19).replace('T', ' ');
};

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
      [id, req.user.id, microTaskId, type, toMysqlDateTime(startedAt), toMysqlDateTime(endedAt), wasSkipped ?? false, taskCompleted ?? null]
    );

    const { rows: [session] } = await db.query(
      'SELECT * FROM pomodoro_sessions WHERE id = ?',
      [id]
    );

    res.status(201).json(session);
  } catch (err) { next(err); }
};

// GET /sessions/stats — resumen de productividad del usuario
exports.getStats = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Para usuarios tester, las sesiones saltadas también cuentan (probar rápido).
    const { rows: [u] } = await db.query(
      'SELECT is_tester FROM users WHERE id = ?',
      [userId]
    );
    const isTester = !!(u && (u.is_tester === 1 || u.is_tester === true));
    const WORK = isTester
      ? `type = 'work' AND ended_at IS NOT NULL`
      : `type = 'work' AND was_skipped = 0 AND ended_at IS NOT NULL`;

    const { rows: [totals] } = await db.query(
      `SELECT
         COUNT(*)                                                          AS totalPomodoros,
         COALESCE(SUM(TIMESTAMPDIFF(MINUTE, started_at, ended_at)), 0)     AS totalMinutes,
         COALESCE(SUM(started_at >= CURDATE()), 0)                         AS todayPomodoros,
         COALESCE(SUM(YEARWEEK(started_at, 1) = YEARWEEK(CURDATE(), 1)), 0) AS weekPomodoros
       FROM pomodoro_sessions
       WHERE user_id = ? AND ${WORK}`,
      [userId]
    );

    const { rows: daily } = await db.query(
      `SELECT DATE(started_at) AS date,
              COUNT(*)                                                     AS pomodoros,
              COALESCE(SUM(TIMESTAMPDIFF(MINUTE, started_at, ended_at)), 0) AS minutes
       FROM pomodoro_sessions
       WHERE user_id = ? AND ${WORK}
         AND started_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE(started_at)
       ORDER BY date`,
      [userId]
    );

    const { rows: [{ tasksCompleted }] } = await db.query(
      `SELECT COUNT(*) AS tasksCompleted
       FROM micro_tasks t JOIN projects p ON t.project_id = p.id
       WHERE p.user_id = ? AND t.is_completed = 1`,
      [userId]
    );

    const toDateStr = (d) => new Date(d).toISOString().slice(0, 10);

    res.json({
      totalPomodoros: Number(totals.totalPomodoros),
      totalMinutes:   Number(totals.totalMinutes),
      todayPomodoros: Number(totals.todayPomodoros),
      weekPomodoros:  Number(totals.weekPomodoros),
      tasksCompleted: Number(tasksCompleted),
      daily: daily.map((d) => ({
        date: toDateStr(d.date),
        pomodoros: Number(d.pomodoros),
        minutes: Number(d.minutes),
      })),
    });
  } catch (err) { next(err); }
};
