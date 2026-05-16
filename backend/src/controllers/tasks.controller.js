const { validationResult } = require('express-validator');
const db = require('../config/database');

exports.updateTask = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { isCompleted } = req.body;

    // Verificar que la tarea pertenece a un proyecto del usuario autenticado
    const { rows } = await db.query(
      `UPDATE micro_tasks t
       SET
         is_completed = $1,
         completed_at = CASE WHEN $1 THEN NOW() ELSE NULL END
       FROM projects p
       WHERE t.id = $2
         AND t.project_id = p.id
         AND p.user_id = $3
       RETURNING t.*`,
      [isCompleted, req.params.id, req.user.id]
    );

    if (!rows.length) return res.status(404).json({ error: 'Tarea no encontrada' });

    // Actualizar status del proyecto si todas las tareas están completas
    await db.query(
      `UPDATE projects
       SET status = CASE
         WHEN (SELECT COUNT(*) FROM micro_tasks WHERE project_id = $1 AND NOT is_completed) = 0
         THEN 'completed'
         ELSE 'active'
       END
       WHERE id = $1`,
      [rows[0].project_id]
    );

    res.json(rows[0]);
  } catch (err) { next(err); }
};
