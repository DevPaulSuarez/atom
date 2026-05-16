const { Router } = require('express');
const { body } = require('express-validator');
const passport = require('passport');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');

const router = Router();

router.post('/register',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }).withMessage('Mínimo 6 caracteres'),
    body('name').trim().notEmpty().withMessage('Nombre requerido'),
  ],
  authController.register
);

router.post('/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty(),
  ],
  authController.login
);

router.post('/refresh', authController.refresh);
router.post('/logout', authenticate, authController.logout);

// ── Google OAuth ──────────────────────────────────────────────────────────────
router.get('/google',
  passport.authenticate('google', { scope: ['profile', 'email'], session: false })
);
router.get('/google/callback',
  passport.authenticate('google', { session: false, failureRedirect: '/auth/failed' }),
  authController.oauthCallback
);

// ── Facebook OAuth ────────────────────────────────────────────────────────────
router.get('/facebook',
  passport.authenticate('facebook', { scope: ['email'], session: false })
);
router.get('/facebook/callback',
  passport.authenticate('facebook', { session: false, failureRedirect: '/auth/failed' }),
  authController.oauthCallback
);

router.get('/failed', (_req, res) =>
  res.status(401).json({ error: 'Autenticación fallida' })
);

module.exports = router;
