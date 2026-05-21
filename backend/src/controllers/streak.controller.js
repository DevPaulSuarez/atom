const db = require('../config/database');

const toDateStr = (d) => new Date(d).toISOString().slice(0, 10);
const todayStr  = () => toDateStr(Date.now());
const yesterdayStr = () => toDateStr(Date.now() - 86_400_000);

// GET /streak — devuelve racha actual (verifica si se rompió)
exports.get = async (req, res, next) => {
  try {
    const { rows: [user] } = await db.query(
      'SELECT current_streak, longest_streak, last_active_date FROM users WHERE id = ?',
      [req.user.id]
    );

    const lastDate = user.last_active_date ? toDateStr(user.last_active_date) : null;
    let currentStreak = user.current_streak;

    // Si no trabajó ayer ni hoy → racha rota
    if (lastDate && lastDate < yesterdayStr()) {
      currentStreak = 0;
      await db.query('UPDATE users SET current_streak = 0 WHERE id = ?', [req.user.id]);
    }

    res.json({ currentStreak, longestStreak: user.longest_streak });
  } catch (err) { next(err); }
};

// PATCH /streak/ping — llamado al completar un pomodoro
exports.ping = async (req, res, next) => {
  try {
    const { rows: [user] } = await db.query(
      'SELECT current_streak, longest_streak, last_active_date FROM users WHERE id = ?',
      [req.user.id]
    );

    const today     = todayStr();
    const yesterday = yesterdayStr();
    const lastDate  = user.last_active_date ? toDateStr(user.last_active_date) : null;

    let newStreak = user.current_streak;

    if (lastDate === today) {
      // Ya contó hoy, sin cambio
    } else if (lastDate === yesterday) {
      // Día consecutivo
      newStreak += 1;
    } else {
      // Primera vez o racha rota
      newStreak = 1;
    }

    const newLongest = Math.max(newStreak, user.longest_streak);

    await db.query(
      'UPDATE users SET current_streak = ?, longest_streak = ?, last_active_date = ? WHERE id = ?',
      [newStreak, newLongest, today, req.user.id]
    );

    res.json({ currentStreak: newStreak, longestStreak: newLongest });
  } catch (err) { next(err); }
};
