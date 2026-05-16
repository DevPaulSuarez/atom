const { validationResult } = require('express-validator');
const db = require('../config/database');
const { generateMicroTasks } = require('../services/ollama.service');

exports.listProjects = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT p.*,
         COUNT(t.id)::int                                  AS total_tasks,
         COUNT(t.id) FILTER (WHERE t.is_completed)::int   AS completed_tasks
       FROM projects p
       LEFT JOIN micro_tasks t ON p.id = t.project_id
       WHERE p.user_id = $1
       GROUP BY p.id
       ORDER BY p.created_at DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (err) { next(err); }
};

exports.createProject = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { name, description = '' } = req.body;

    // 1. Crear proyecto
    const { rows: [project] } = await db.query(
      `INSERT INTO projects (user_id, name, description, ai_model)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.id, name, description, process.env.OLLAMA_MODEL || 'llama3.2']
    );

    // 2. Generar microtareas con Ollama (con fallback automático)
    const taskTitles = await generateMicroTasks(name, description);

    // 3. Insertar tareas con un único query parameterizado
    const values = [];
    const placeholders = taskTitles.map((title, i) => {
      const base = i * 3;
      values.push(project.id, title, i);
      return `($${base + 1}, $${base + 2}, $${base + 3})`;
    }).join(', ');

    const { rows: tasks } = await db.query(
      `INSERT INTO micro_tasks (project_id, title, order_index)
       VALUES ${placeholders} RETURNING *`,
      values
    );

    res.status(201).json({ ...project, tasks });
  } catch (err) { next(err); }
};

exports.getProject = async (req, res, next) => {
  try {
    const { rows: [project] } = await db.query(
      'SELECT * FROM projects WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (!project) return res.status(404).json({ error: 'Proyecto no encontrado' });

    const { rows: tasks } = await db.query(
      'SELECT * FROM micro_tasks WHERE project_id = $1 ORDER BY order_index',
      [req.params.id]
    );

    res.json({ ...project, tasks });
  } catch (err) { next(err); }
};

exports.deleteProject = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'DELETE FROM projects WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Proyecto no encontrado' });
    res.status(204).end();
  } catch (err) { next(err); }
};
