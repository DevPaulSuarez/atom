const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const streakController = require('../controllers/streak.controller');

const router = Router();
router.use(authenticate);

router.get('/',        streakController.get);
router.patch('/ping',  streakController.ping);

module.exports = router;
