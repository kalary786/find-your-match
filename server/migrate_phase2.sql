-- Additive migration for existing databases.
-- The API also applies these changes on the next connection (see ensure_runtime_tables).
-- Do not drop or truncate users, profiles, messages, or any existing table.
--
-- Backup before uploading the new server files:
--   mysqldump --single-transaction -h HOST -u USER -p DATABASE users messages blocks > phase2_backup.sql
--
-- Rollback removes only the new column, indexes, and new tables.
-- It does not restore session tokens that were already replaced.
--   ALTER TABLE users DROP INDEX users_token_hash;
--   ALTER TABLE users DROP COLUMN token_expires_at;
--   ALTER TABLE messages DROP INDEX messages_sender_day;
--   ALTER TABLE blocks DROP INDEX blocks_blocked;
--   DROP TABLE auth_attempts;
--   DROP TABLE moderation_events;

CREATE TABLE IF NOT EXISTS auth_attempts (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(32) NOT NULL,
  subject_hash CHAR(64) NOT NULL,
  created_at DATETIME NOT NULL,
  INDEX auth_attempts_lookup (action, subject_hash, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS moderation_events (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  admin_id INT UNSIGNED NOT NULL,
  action VARCHAR(32) NOT NULL,
  target_user_id INT UNSIGNED NULL,
  note VARCHAR(120) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  INDEX moderation_created (created_at),
  CONSTRAINT fk_moderation_admin FOREIGN KEY (admin_id) REFERENCES admins(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
