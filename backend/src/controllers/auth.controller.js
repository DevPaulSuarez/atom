const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
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

    const { rows } = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (rows.length) return res.status(409).json({ error: 'El email ya está registrado' });

    const passwordHash = await bcrypt.hash(password, 12);
    const id = uuidv4();
    await db.query(
      'INSERT INTO users (id, email, name, password_hash) VALUES (?, ?, ?, ?)',
      [id, email, name, passwordHash]
    );
    const { rows: newRows } = await db.query(
      'SELECT id, email, name, avatar_url, is_tester, created_at FROM users WHERE id = ?',
      [id]
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
    const { rows } = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    const user = rows[0];

    if (!user?.password_hash || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    const { password_hash, ...safeUser } = user;
    const tokens = await issueTokenPair(user.id, req);
    res.json({ user: safeUser, ...tokens });
  } catch (err) { next(err); }
};

exports.oauthCallback = async (req, res, next) => {
  try {
    const tokens = await issueTokenPair(req.user.id, req);
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
