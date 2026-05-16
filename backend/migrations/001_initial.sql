-- ─────────────────────────────────────────────────────────────────────────────
-- Atom Pomodoro — Migración inicial
-- Ejecutar: psql $DATABASE_URL -f migrations/001_initial.sql
-- ─────────────────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── Usuarios ──────────────────────────────────────────────────────────────────
CREATE TABLE users (
  id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  email         VARCHAR(255) UNIQUE,
  name          VARCHAR(255) NOT NULL,
  avatar_url    TEXT,
  password_hash TEXT,                          -- null si solo usa OAuth
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Cuentas OAuth vinculadas ──────────────────────────────────────────────────
CREATE TABLE oauth_accounts (
  id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider         VARCHAR(20) NOT NULL CHECK (provider IN ('google', 'facebook')),
  provider_user_id VARCHAR(255) NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (provider, provider_user_id)
);

-- ── Refresh tokens (rotación, guardados como hash) ───────────────────────────
CREATE TABLE refresh_tokens (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  CHAR(64)    NOT NULL UNIQUE,       -- SHA-256 hex del token
  device_info VARCHAR(255),
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked_at  TIMESTAMPTZ,                       -- null = activo
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Proyectos ─────────────────────────────────────────────────────────────────
CREATE TABLE projects (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        VARCHAR(255) NOT NULL,
  description TEXT        NOT NULL DEFAULT '',
  status      VARCHAR(20) NOT NULL DEFAULT 'active'
              CHECK (status IN ('active', 'completed', 'archived')),
  ai_model    VARCHAR(100),                      -- modelo Ollama que generó las tareas
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Microtareas ───────────────────────────────────────────────────────────────
CREATE TABLE micro_tasks (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id   UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title        TEXT        NOT NULL,
  order_index  INTEGER     NOT NULL DEFAULT 0,
  is_completed BOOLEAN     NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Sesiones Pomodoro (historial) ─────────────────────────────────────────────
CREATE TABLE pomodoro_sessions (
  id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  micro_task_id  UUID        NOT NULL REFERENCES micro_tasks(id) ON DELETE CASCADE,
  type           VARCHAR(20) NOT NULL CHECK (type IN ('work', 'short_break', 'long_break')),
  started_at     TIMESTAMPTZ NOT NULL,
  ended_at       TIMESTAMPTZ,
  was_skipped    BOOLEAN     NOT NULL DEFAULT FALSE,
  task_completed BOOLEAN,                        -- respuesta al modal de confirmación
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Índices ───────────────────────────────────────────────────────────────────
CREATE INDEX idx_oauth_accounts_user        ON oauth_accounts(user_id);
CREATE INDEX idx_refresh_tokens_hash        ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_user        ON refresh_tokens(user_id);
CREATE INDEX idx_projects_user              ON projects(user_id);
CREATE INDEX idx_micro_tasks_project        ON micro_tasks(project_id);
CREATE INDEX idx_pomodoro_sessions_user     ON pomodoro_sessions(user_id);
CREATE INDEX idx_pomodoro_sessions_task     ON pomodoro_sessions(micro_task_id);

-- ── Trigger updated_at automático ────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER projects_updated_at
  BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION set_updated_at();
