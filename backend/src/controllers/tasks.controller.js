const { v4: uuidv4 } = require('uuid');
const { validationResult } = require('express-validator');
const db = require('../config/database');
const { splitBlockedTask, generateCoachMessage } = require('../services/ollama.service');

exports.updateTask = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { isCompleted, pomodorosCount } = req.body;

    if (isCompleted === undefined && pomodorosCount === undefined) {
      return res.status(422).json({ error: 'Se requiere isCompleted o pomodorosCount' });
    }

    // Verificar que la tarea pertenece a un proyecto del usuario
    const { rows: check } = await db.query(
      `SELECT t.id, t.project_id, t.parent_id FROM micro_tasks t
       JOIN projects p ON t.project_id = p.id
       WHERE t.id = ? AND p.user_id = ?`,
      [req.params.id, req.user.id]
    );
    if (!check.length) return res.status(404).json({ error: 'Tarea no encontrada' });

    const { project_id: projectId, parent_id: parentId } = check[0];

    // Construir el UPDATE según los campos recibidos
    const sets = [];
    const params = [];

    if (isCompleted !== undefined) {
      sets.push('is_completed = ?', 'completed_at = CASE WHEN ? THEN NOW() ELSE NULL END');
      params.push(isCompleted, isCompleted);
    }
    if (pomodorosCount !== undefined) {
      sets.push('pomodoros_count = ?');
      params.push(pomodorosCount);
    }
    params.push(req.params.id);

    await db.query(
      `UPDATE micro_tasks SET ${sets.join(', ')} WHERE id = ?`,
      params
    );

    // Si es una subtarea completada, verificar si el padre debe completarse también
    if (isCompleted && parentId) {
      const { rows: [{ total, done }] } = await db.query(
        'SELECT COUNT(*) AS total, SUM(is_completed) AS done FROM micro_tasks WHERE parent_id = ?',
        [parentId]
      );
      if (parseInt(total) > 0 && parseInt(total) === parseInt(done)) {
        await db.query(
          'UPDATE micro_tasks SET is_completed = 1, completed_at = NOW() WHERE id = ?',
          [parentId]
        );
      }
    }

    // Actualizar status del proyecto (solo tareas top-level sin parent)
    if (isCompleted !== undefined) {
      await db.query(
        `UPDATE projects
         SET status = CASE
               WHEN (SELECT COUNT(*) FROM micro_tasks WHERE project_id = ? AND is_completed = 0 AND parent_id IS NULL) = 0
               THEN 'completed'
               ELSE 'active'
             END,
             completed_at = CASE
               WHEN (SELECT COUNT(*) FROM micro_tasks WHERE project_id = ? AND is_completed = 0 AND parent_id IS NULL) = 0
               THEN NOW()
               ELSE NULL
             END
         WHERE id = ?`,
        [projectId, projectId, projectId]
      );
    }

    const { rows: [task] } = await db.query(
      'SELECT * FROM micro_tasks WHERE id = ?',
      [req.params.id]
    );

    res.json(task);
  } catch (err) { next(err); }
};

exports.splitTask = async (req, res, next) => {
  try {
    const { rows: check } = await db.query(
      `SELECT t.id, t.title, t.parent_id, t.project_id,
              p.name AS project_name, p.description AS project_desc, p.motivation
       FROM micro_tasks t
       JOIN projects p ON t.project_id = p.id
       WHERE t.id = ? AND p.user_id = ? AND t.is_completed = 0`,
      [req.params.id, req.user.id]
    );
    if (!check.length) return res.status(404).json({ error: 'Tarea no encontrada o ya completada' });

    const task = check[0];

    // Solo se dividen tareas top-level (máximo 2 niveles)
    if (task.parent_id) {
      return res.status(400).json({ error: 'No se puede dividir una subtarea' });
    }

    // Si ya tiene subtareas, devolver las tareas actuales sin modificar
    const { rows: [{ count }] } = await db.query(
      'SELECT COUNT(*) AS count FROM micro_tasks WHERE parent_id = ?',
      [task.id]
    );
    if (parseInt(count) > 0) {
      const { rows: tasks } = await db.query(
        'SELECT * FROM micro_tasks WHERE project_id = ? ORDER BY parent_id IS NULL DESC, order_index',
        [task.project_id]
      );
      return res.json({ tasks, splitCount: 0 });
    }

    // Generar subtareas y mensaje de coach en paralelo
    const [subtasks, coachMessage] = await Promise.all([
      splitBlockedTask(task.title, task.project_name, task.project_desc),
      generateCoachMessage(task.title, task.motivation || ''),
    ]);

    // Insertar subtareas como hijos de la tarea bloqueada (con su estimación)
    const values = [];
    const placeholders = subtasks.map((sub, i) => {
      values.push(uuidv4(), task.project_id, task.id, sub.title, i, sub.pomodoros);
      return '(?, ?, ?, ?, ?, ?)';
    }).join(', ');

    await db.query(
      `INSERT INTO micro_tasks (id, project_id, parent_id, title, order_index, estimated_pomodoros) VALUES ${placeholders}`,
      values
    );

    const { rows: tasks } = await db.query(
      'SELECT * FROM micro_tasks WHERE project_id = ? ORDER BY parent_id IS NULL DESC, order_index',
      [task.project_id]
    );

    res.json({ tasks, splitCount: subtasks.length, coachMessage });
  } catch (err) { next(err); }
};
