const passport = require('passport');
const { Strategy: GoogleStrategy } = require('passport-google-oauth20');
const { Strategy: FacebookStrategy } = require('passport-facebook');
const db = require('./database');
const { env } = require('./env');

// Busca la cuenta OAuth, o crea usuario y la vincula.
// Si el mismo email ya existe (registro manual), los une al mismo user_id.
const findOrCreateOAuthUser = async (provider, profile) => {
  const email = profile.emails?.[0]?.value || null;
  const name = profile.displayName || profile.username || 'Usuario';
  const avatarUrl = profile.photos?.[0]?.value || null;
  const providerId = profile.id;

  // 1. ¿Ya existe la cuenta OAuth?
  const { rows: oauthRows } = await db.query(
    `SELECT u.* FROM users u
     JOIN oauth_accounts o ON u.id = o.user_id
     WHERE o.provider = $1 AND o.provider_user_id = $2`,
    [provider, providerId]
  );
  if (oauthRows.length > 0) return oauthRows[0];

  // 2. ¿Existe usuario con el mismo email? (vincular cuentas)
  let userId = null;
  if (email) {
    const { rows: emailRows } = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    if (emailRows.length > 0) userId = emailRows[0].id;
  }

  // 3. Si no existe, crear usuario
  if (!userId) {
    const { rows } = await db.query(
      'INSERT INTO users (email, name, avatar_url) VALUES ($1, $2, $3) RETURNING id',
      [email, name, avatarUrl]
    );
    userId = rows[0].id;
  }

  // 4. Registrar oauth_account
  await db.query(
    'INSERT INTO oauth_accounts (user_id, provider, provider_user_id) VALUES ($1, $2, $3)',
    [userId, provider, providerId]
  );

  const { rows: userRows } = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
  return userRows[0];
};

if (env.GOOGLE_CLIENT_ID) {
  passport.use(new GoogleStrategy(
    {
      clientID: env.GOOGLE_CLIENT_ID,
      clientSecret: env.GOOGLE_CLIENT_SECRET,
      callbackURL: `${env.API_URL}/auth/google/callback`,
    },
    async (_access, _refresh, profile, done) => {
      try { done(null, await findOrCreateOAuthUser('google', profile)); }
      catch (err) { done(err); }
    }
  ));
}

if (env.FACEBOOK_APP_ID) {
  passport.use(new FacebookStrategy(
    {
      clientID: env.FACEBOOK_APP_ID,
      clientSecret: env.FACEBOOK_APP_SECRET,
      callbackURL: `${env.API_URL}/auth/facebook/callback`,
      profileFields: ['id', 'emails', 'displayName', 'photos'],
    },
    async (_access, _refresh, profile, done) => {
      try { done(null, await findOrCreateOAuthUser('facebook', profile)); }
      catch (err) { done(err); }
    }
  ));
}

module.exports = passport;
