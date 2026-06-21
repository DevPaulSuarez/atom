const { Router } = require('express');
const { body } = require('express-validator');
const projectsController = require('../controllers/projects.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = Router();
router.use(authenticate);

router.get('/', projectsController.listProjects);

router.post('/',
  [
    body('name').trim().notEmpty().isLength({ max: 255 }),
    body('description').optional().trim().isLength({ max: 2000 }),
    body('motivation').optional().trim().isLength({ max: 500 }),
    body('focusMinutes').optional().isInt({ min: 1, max: 90 }),
    body('tasks').optional().isArray({ max: 30 }),
  ],
  projectsController.createProject
);

router.get('/:id', projectsController.getProject);

router.patch('/:id',
  [body('focusMinutes').optional().isInt({ min: 1, max: 90 })],
  projectsController.updateProject
);

router.delete('/:id', projectsController.deleteProject);

module.exports = router;
