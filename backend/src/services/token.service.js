const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const { env } = require('../config/env');

const generateAccessToken = (userId) =>
  jwt.sign({ sub: userId }, env.JWT_SECRET, { expiresIn: env.JWT_EXPIRES_IN });

const generateRefreshToken = async (userId, deviceInfo = null) => {
  const token = uuidv4();
  const hash = crypto.createHash('sha256').update(token).digest('hex');
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  const id = uuidv4();

  await db.query(
    'INSERT INTO refresh_tokens (id, user_id, token_hash, device_info, expires_at) VALUES (?, ?, ?, ?, ?)',
    [id, userId, hash, deviceInfo, expiresAt]
  );
  return token;
};

const verifyRefreshToken = async (token) => {
  const hash = crypto.createHash('sha256').update(token).digest('hex');
  const { rows } = await db.query(
    'SELECT * FROM refresh_tokens WHERE token_hash = ? AND expires_at > NOW() AND revoked_at IS NULL',
    [hash]
  );
  return rows[0] || null;
};

const revokeRefreshToken = async (token) => {
  const hash = crypto.createHash('sha256').update(token).digest('hex');
  await db.query(
    'UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = ?',
    [hash]
  );
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  revokeRefreshToken,
};
