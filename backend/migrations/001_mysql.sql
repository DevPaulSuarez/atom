-- ─────────────────────────────────────────────────────────────────────────────
-- Atom Pomodoro — Migración MySQL
-- Ejecutar: mysql -u root -p atom_db < migrations/001_mysql.sql
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
  id            VARCHAR(36)   PRIMARY KEY,
  email         VARCHAR(255)  UNIQUE,
  name          VARCHAR(255)  NOT NULL,
  avatar_url    TEXT,
  password_hash TEXT,
  created_at    DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at    DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS oauth_accounts (
  id               VARCHAR(36)   PRIMARY KEY,
  user_id          VARCHAR(36)   NOT NULL,
  provider         VARCHAR(20)   NOT NULL,
  provider_user_id VARCHAR(255)  NOT NULL,
  created_at       DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY uk_provider (provider, provider_user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          VARCHAR(36)   PRIMARY KEY,
  user_id     VARCHAR(36)   NOT NULL,
  token_hash  CHAR(64)      NOT NULL UNIQUE,
  device_info VARCHAR(255),
  expires_at  DATETIME(3)   NOT NULL,
  revoked_at  DATETIME(3),
  created_at  DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS projects (
  id          VARCHAR(36)   PRIMARY KEY,
  user_id     VARCHAR(36)   NOT NULL,
  name        VARCHAR(255)  NOT NULL,
  description VARCHAR(2000) NOT NULL DEFAULT '',
  status      VARCHAR(20)   NOT NULL DEFAULT 'active',
  ai_model    VARCHAR(100),
  created_at  DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at  DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS micro_tasks (
  id           VARCHAR(36)   PRIMARY KEY,
  project_id   VARCHAR(36)   NOT NULL,
  title        TEXT          NOT NULL,
  order_index  INT           NOT NULL DEFAULT 0,
  is_completed TINYINT(1)    NOT NULL DEFAULT 0,
  completed_at DATETIME(3),
  created_at   DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pomodoro_sessions (
  id             VARCHAR(36)   PRIMARY KEY,
  user_id        VARCHAR(36)   NOT NULL,
  micro_task_id  VARCHAR(36)   NOT NULL,
  type           VARCHAR(20)   NOT NULL,
  started_at     DATETIME(3)   NOT NULL,
  ended_at       DATETIME(3),
  was_skipped    TINYINT(1)    NOT NULL DEFAULT 0,
  task_completed TINYINT(1),
  created_at     DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_oauth_accounts_user     ON oauth_accounts(user_id);
CREATE INDEX idx_refresh_tokens_hash     ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_user     ON refresh_tokens(user_id);
CREATE INDEX idx_projects_user           ON projects(user_id);
CREATE INDEX idx_micro_tasks_project     ON micro_tasks(project_id);
CREATE INDEX idx_pomodoro_sessions_user  ON pomodoro_sessions(user_id);
CREATE INDEX idx_pomodoro_sessions_task  ON pomodoro_sessions(micro_task_id);
