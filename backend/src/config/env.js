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
  GROQ_API_KEY:         process.env.GROQ_API_KEY || '',
  GROQ_MODEL:           process.env.GROQ_MODEL || 'llama-3.3-70b-versatile',
  API_URL:              process.env.API_URL || 'http://localhost:3000',
  APP_SCHEME:           process.env.APP_SCHEME || 'atom',
  ALLOWED_ORIGINS:      process.env.ALLOWED_ORIGINS || 'http://localhost:3000',

  // Control de versiones de la app móvil (endpoint /version).
  // APP_LATEST_VERSION: última versión publicada en las tiendas.
  // APP_MIN_SUPPORTED:  versión mínima que puede seguir usando la app; por
  //                     debajo de ésta se fuerza la actualización.
  APP_LATEST_VERSION:   process.env.APP_LATEST_VERSION || '1.0.3',
  APP_MIN_SUPPORTED:    process.env.APP_MIN_SUPPORTED  || '1.0.0',
  STORE_URL_IOS:        process.env.STORE_URL_IOS ||
                        'https://apps.apple.com/app/atom/id000000000',
  STORE_URL_ANDROID:    process.env.STORE_URL_ANDROID ||
                        'https://play.google.com/store/apps/details?id=com.devpess.atom',
};

module.exports = { env };
