const { v4: uuidv4 } = require('uuid');
const passport = require('passport');
const { Strategy: GoogleStrategy } = require('passport-google-oauth20');
const { Strategy: FacebookStrategy } = require('passport-facebook');
const db = require('./database');
const { env } = require('./env');

const findOrCreateOAuthUser = async (provider, profile) => {
  const email = profile.emails?.[0]?.value || null;
  const name = profile.displayName || profile.username || 'Usuario';
  const avatarUrl = profile.photos?.[0]?.value || null;
  const providerId = profile.id;

  // 1. ¿Ya existe la cuenta OAuth?
  const { rows: oauthRows } = await db.query(
    `SELECT u.* FROM users u
     JOIN oauth_accounts o ON u.id = o.user_id
     WHERE o.provider = ? AND o.provider_user_id = ?`,
    [provider, providerId]
  );
  if (oauthRows.length > 0) return oauthRows[0];

  // 2. ¿Existe usuario con el mismo email?
  let userId = null;
  if (email) {
    const { rows: emailRows } = await db.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );
    if (emailRows.length > 0) userId = emailRows[0].id;
  }

  // 3. Si no existe, crear usuario
  if (!userId) {
    userId = uuidv4();
    await db.query(
      'INSERT INTO users (id, email, name, avatar_url) VALUES (?, ?, ?, ?)',
      [userId, email, name, avatarUrl]
    );
  }

  // 4. Registrar oauth_account
  await db.query(
    'INSERT INTO oauth_accounts (id, user_id, provider, provider_user_id) VALUES (?, ?, ?, ?)',
    [uuidv4(), userId, provider, providerId]
  );

  const { rows: [userRow] } = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
  return userRow;
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
