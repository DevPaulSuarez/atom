const { Router } = require('express');
const { body } = require('express-validator');
const sessionsController = require('../controllers/sessions.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = Router();
router.use(authenticate);

router.get('/stats', sessionsController.getStats);

router.post('/',
  [
    body('microTaskId').isUUID(),
    body('type').isIn(['work', 'short_break', 'long_break']),
    body('startedAt').isISO8601(),
    body('endedAt').optional({ nullable: true }).isISO8601(),
    body('wasSkipped').optional().isBoolean(),
    body('taskCompleted').optional({ nullable: true }).isBoolean(),
  ],
  sessionsController.createSession
);

module.exports = router;
