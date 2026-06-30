const { Router } = require('express');
const { env } = require('../config/env');

const router = Router();

// Público (no requiere auth): la app lo consulta al arrancar para saber si
// debe forzar una actualización. Los valores se controlan por variables de
// entorno (APP_LATEST_VERSION, APP_MIN_SUPPORTED) sin necesidad de redeploy
// de la app.
router.get('/', (_req, res) => {
  res.json({
    latest: env.APP_LATEST_VERSION,
    minSupported: env.APP_MIN_SUPPORTED,
    storeUrlIos: env.STORE_URL_IOS,
    storeUrlAndroid: env.STORE_URL_ANDROID,
  });
});

module.exports = router;
