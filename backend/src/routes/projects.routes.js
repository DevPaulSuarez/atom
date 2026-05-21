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
  ],
  projectsController.createProject
);

router.get('/:id', projectsController.getProject);
router.delete('/:id', projectsController.deleteProject);

module.exports = router;
