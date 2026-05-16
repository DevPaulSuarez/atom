require('dotenv').config();

const required = (key) => {
  const val = process.env[key];
  if (!val) throw new Error(`Variable de entorno requerida no definida: ${key}`);
  return val;
};

const env = {
  NODE_ENV:             process.env.NODE_ENV || 'development',
  PORT:                 parseInt(process.env.PORT || '3000', 10),
  DATABASE_URL:         required('DATABASE_URL'),
  JWT_SECRET:           required('JWT_SECRET'),
  JWT_EXPIRES_IN:       process.env.JWT_EXPIRES_IN || '15m',
  GOOGLE_CLIENT_ID:     process.env.GOOGLE_CLIENT_ID || '',
  GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET || '',
  FACEBOOK_APP_ID:      process.env.FACEBOOK_APP_ID || '',
  FACEBOOK_APP_SECRET:  process.env.FACEBOOK_APP_SECRET || '',
  OLLAMA_URL:           process.env.OLLAMA_URL || 'http://localhost:11434',
  OLLAMA_MODEL:         process.env.OLLAMA_MODEL || 'llama3.2',
  API_URL:              process.env.API_URL || 'http://localhost:3000',
  APP_SCHEME:           process.env.APP_SCHEME || 'atom',
  ALLOWED_ORIGINS:      process.env.ALLOWED_ORIGINS || 'http://localhost:3000',
};

module.exports = { env };
