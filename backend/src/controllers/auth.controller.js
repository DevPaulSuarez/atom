const bcrypt = require('bcryptjs');
const { validationResult } = require('express-validator');
const db = require('../config/database');
const {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  revokeRefreshToken,
} = require('../services/token.service');
const { env } = require('../config/env');

const issueTokenPair = async (userId, req) => ({
  accessToken: generateAccessToken(userId),
  refreshToken: await generateRefreshToken(userId, req.headers['user-agent']),
});

exports.register = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { email, password, name } = req.body;

    const { rows } = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (rows.length) return res.status(409).json({ error: 'El email ya está registrado' });

    const passwordHash = await bcrypt.hash(password, 12);
    const { rows: newRows } = await db.query(
      `INSERT INTO users (email, name, password_hash)
       VALUES ($1, $2, $3)
       RETURNING id, email, name, avatar_url, created_at`,
      [email, name, passwordHash]
    );

    const user = newRows[0];
    const tokens = await issueTokenPair(user.id, req);
    res.status(201).json({ user, ...tokens });
  } catch (err) { next(err); }
};

exports.login = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });

    const { email, password } = req.body;
    const { rows } = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = rows[0];

    if (!user?.password_hash || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    const { password_hash, ...safeUser } = user;
    const tokens = await issueTokenPair(user.id, req);
    res.json({ user: safeUser, ...tokens });
  } catch (err) { next(err); }
};

// Llamado tras OAuth exitoso (Google / Facebook)
exports.oauthCallback = async (req, res, next) => {
  try {
    const tokens = await issueTokenPair(req.user.id, req);
    // Redirige al deep link de Flutter con los tokens
    const url = new URL(`${env.APP_SCHEME}://auth`);
    url.searchParams.set('access_token', tokens.accessToken);
    url.searchParams.set('refresh_token', tokens.refreshToken);
    res.redirect(url.toString());
  } catch (err) { next(err); }
};

exports.refresh = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(401).json({ error: 'Refresh token requerido' });

    const stored = await verifyRefreshToken(refreshToken);
    if (!stored) return res.status(401).json({ error: 'Refresh token inválido o expirado' });

    // Rotación: revocar el viejo y emitir uno nuevo
    await revokeRefreshToken(refreshToken);
    const newAccessToken = generateAccessToken(stored.user_id);
    const newRefreshToken = await generateRefreshToken(stored.user_id, req.headers['user-agent']);

    res.json({ accessToken: newAccessToken, refreshToken: newRefreshToken });
  } catch (err) { next(err); }
};

exports.logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) await revokeRefreshToken(refreshToken);
    res.status(204).end();
  } catch (err) { next(err); }
};
