const { v4: uuidv4 } = require('uuid');
const { validationResult } = require('express-validator');
const db = require('../config/database');
const { generateMicroTasks } = require('../services/ollama.service');

exports.listProjects = async (req, res, next) => {
  try {
    const { rows: projects } = await db.query(
      'SELECT * FROM projects WHERE user_id = ? ORDER BY created_at DESC',
      [req.user.id]
    );

    if (!projects.length) return res.json([]);

    // Traer todas las tareas en una sola query y agrupar en JS
    const ids = projects.map((p) => p.id);
    const placeholders = ids.map(() => '?').join(',');
    const { rows: tasks } = await db.query(
      `SELECT * FROM micro_tasks WHERE project_id IN (${placeholders}) ORDER BY order_index`,
      ids
    );

    const tasksByProject = {};
    for (const t of tasks) {
      if (!tasksByProject[t.project_id]) tasksByProject[t.project_id] = [];
      tasksByProject[t.project_id].push(t);
    }

    res.json(projects.map((p) => ({ ...p, tasks: tasksByProject[p.id] || [] })));
  } catch (err) { next(err); }
};

exports.createProject = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { name, description = '', motivation = '' } = req.body;

    // Duración del enfoque elegida por el usuario (minutos). Default 25, rango 1–90.
    let focusMinutes = parseInt(req.body.focusMinutes, 10);
    if (!Number.isFinite(focusMinutes)) focusMinutes = 25;
    focusMinutes = Math.min(90, Math.max(1, focusMinutes));

    // 1. Crear proyecto
    const projectId = uuidv4();
    await db.query(
      'INSERT INTO projects (id, user_id, name, description, motivation, focus_minutes, ai_model) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [projectId, req.user.id, name, description, motivation, focusMinutes, process.env.GROQ_MODEL || 'llama-3.3-70b-versatile']
    );
    const { rows: [project] } = await db.query(
      'SELECT * FROM projects WHERE id = ?',
      [projectId]
    );

    // 2. Tareas: si el usuario las escribió a mano, se usan tal cual (sin IA);
    //    si no, las genera la IA. Cada tarea lleva su estimación de pomodoros.
    const clampPom = (n) => {
      const v = parseInt(n, 10);
      return Number.isFinite(v) ? Math.min(4, Math.max(1, v)) : 2;
    };
    const manualTasks = (Array.isArray(req.body.tasks) ? req.body.tasks : [])
      .map((t) => ({ title: String(t?.title ?? '').trim(), pomodoros: clampPom(t?.pomodoros) }))
      .filter((t) => t.title)
      .slice(0, 30);

    const generatedTasks = manualTasks.length
      ? manualTasks
      : await generateMicroTasks(name, description);

    // 3. Insertar tareas en una sola query
    const values = [];
    const placeholders = generatedTasks.map((t, i) => {
      values.push(uuidv4(), projectId, t.title, i, t.pomodoros);
      return '(?, ?, ?, ?, ?)';
    }).join(', ');

    await db.query(
      `INSERT INTO micro_tasks (id, project_id, title, order_index, estimated_pomodoros) VALUES ${placeholders}`,
      values
    );

    const { rows: tasks } = await db.query(
      'SELECT * FROM micro_tasks WHERE project_id = ? ORDER BY order_index',
      [projectId]
    );

    res.status(201).json({ ...project, tasks });
  } catch (err) { next(err); }
};

exports.getProject = async (req, res, next) => {
  try {
    const { rows: [project] } = await db.query(
      'SELECT * FROM projects WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (!project) return res.status(404).json({ error: 'Proyecto no encontrado' });

    const { rows: tasks } = await db.query(
      'SELECT * FROM micro_tasks WHERE project_id = ? ORDER BY order_index',
      [req.params.id]
    );

    res.json({ ...project, tasks });
  } catch (err) { next(err); }
};

exports.updateProject = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { rows } = await db.query(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Proyecto no encontrado' });

    if (req.body.focusMinutes === undefined) {
      return res.status(422).json({ error: 'Nada que actualizar' });
    }
    let focusMinutes = parseInt(req.body.focusMinutes, 10);
    if (!Number.isFinite(focusMinutes)) focusMinutes = 25;
    focusMinutes = Math.min(90, Math.max(1, focusMinutes));

    await db.query(
      'UPDATE projects SET focus_minutes = ? WHERE id = ?',
      [focusMinutes, req.params.id]
    );

    const { rows: [project] } = await db.query(
      'SELECT * FROM projects WHERE id = ?',
      [req.params.id]
    );
    res.json(project);
  } catch (err) { next(err); }
};

exports.deleteProject = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT id FROM projects WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Proyecto no encontrado' });

    await db.query('DELETE FROM projects WHERE id = ?', [req.params.id]);
    res.status(204).end();
  } catch (err) { next(err); }
};
