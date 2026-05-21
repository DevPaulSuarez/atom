const { Router } = require('express');
const { body } = require('express-validator');
const tasksController = require('../controllers/tasks.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = Router();
router.use(authenticate);

router.patch('/:id',
  [
    body('isCompleted').optional().isBoolean(),
    body('pomodorosCount').optional().isInt({ min: 0 }),
  ],
  tasksController.updateTask
);

router.post('/:id/split', tasksController.splitTask);

module.exports = router;
