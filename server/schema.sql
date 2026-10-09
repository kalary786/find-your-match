CREATE TABLE IF NOT EXISTS admins (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  token_hash CHAR(64) NULL,
  token_expires_at DATETIME NULL,
  blocked TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL,
  INDEX users_token_hash (token_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS profiles (
  user_id INT UNSIGNED PRIMARY KEY,
  username VARCHAR(20) NOT NULL UNIQUE,
  birth_date DATE NOT NULL,
  age TINYINT UNSIGNED NOT NULL,
  gender VARCHAR(32) NOT NULL,
  city VARCHAR(40) NOT NULL,
  bio VARCHAR(300) NOT NULL,
  interests JSON NOT NULL,
  preferences JSON NOT NULL,
  photo_path VARCHAR(255) NULL,
  hidden TINYINT(1) NOT NULL DEFAULT 0,
  show_online TINYINT(1) NOT NULL DEFAULT 0,
  show_last_active TINYINT(1) NOT NULL DEFAULT 0,
  last_active_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  CONSTRAINT fk_profiles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS swipes (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  from_user_id INT UNSIGNED NOT NULL,
  to_user_id INT UNSIGNED NOT NULL,
  liked TINYINT(1) NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY swipe_pair (from_user_id, to_user_id),
  CONSTRAINT fk_swipes_from FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_swipes_to FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS matches (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_low INT UNSIGNED NOT NULL,
  user_high INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY match_pair (user_low, user_high),
  CONSTRAINT fk_matches_low FOREIGN KEY (user_low) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_matches_high FOREIGN KEY (user_high) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS conversations (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  match_id INT UNSIGNED NOT NULL UNIQUE,
  user_low INT UNSIGNED NOT NULL,
  user_high INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  CONSTRAINT fk_conversations_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE,
  CONSTRAINT fk_conversations_low FOREIGN KEY (user_low) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_conversations_high FOREIGN KEY (user_high) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS messages (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id INT UNSIGNED NOT NULL,
  sender_id INT UNSIGNED NOT NULL,
  body VARCHAR(1000) NOT NULL,
  created_at DATETIME NOT NULL,
  INDEX messages_conversation (conversation_id, id),
  INDEX messages_sender_day (sender_id, created_at),
  CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS blocks (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  blocker_id INT UNSIGNED NOT NULL,
  blocked_id INT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY block_pair (blocker_id, blocked_id),
  INDEX blocks_blocked (blocked_id),
  CONSTRAINT fk_blocks_blocker FOREIGN KEY (blocker_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_blocks_blocked FOREIGN KEY (blocked_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS reports (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reporter_id INT UNSIGNED NOT NULL,
  reported_id INT UNSIGNED NOT NULL,
  reason VARCHAR(64) NOT NULL,
  details VARCHAR(500) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  resolved TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_reports_reported FOREIGN KEY (reported_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notices (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  title VARCHAR(80) NOT NULL,
  body VARCHAR(500) NOT NULL,
  link_url VARCHAR(500) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  INDEX notices_user (user_id, id),
  CONSTRAINT fk_notices_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS notice_reads (
  notice_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  read_at DATETIME NOT NULL,
  PRIMARY KEY (notice_id, user_id),
  CONSTRAINT fk_notice_reads_notice FOREIGN KEY (notice_id) REFERENCES notices(id) ON DELETE CASCADE,
  CONSTRAINT fk_notice_reads_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ads (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(80) NOT NULL,
  image_path VARCHAR(255) NOT NULL,
  link_url VARCHAR(500) NOT NULL,
  placement ENUM('discover', 'search', 'matches') NOT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
