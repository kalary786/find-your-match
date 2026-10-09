<?php

declare(strict_types=1);

const GENDERS = ['Woman', 'Man', 'Non-binary', 'Prefer not to say'];
const INTERESTS = [
    'Coffee', 'Hiking', 'Cooking', 'Music', 'Travel',
    'Reading', 'Fitness', 'Movies', 'Art', 'Photography',
];
const PREFERENCES = [
    'Friendship', 'Dating', 'Long-term relationship', 'Marriage',
];
const REPORT_REASONS = [
    'Harassment', 'Spam', 'Fake profile', 'Inappropriate photo',
    'Hate', 'Threat', 'Other',
];
const AD_PLACEMENTS = ['discover', 'search', 'matches'];

function config_path(): string
{
    return dirname(__DIR__) . '/config.php';
}

function app_config(): array
{
    $path = config_path();
    if (!is_file($path)) {
        fail(500, 'setup', 'Copy config.example.php to config.php and fill in the database.');
    }
    $config = require $path;
    if (!is_array($config)) {
        fail(500, 'setup', 'config.php must return an array.');
    }
    return $config;
}

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }
    $config = app_config();
    $dsn = sprintf(
        'mysql:host=%s;dbname=%s;charset=utf8mb4',
        $config['db_host'],
        $config['db_name']
    );
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ];
    if (defined('PDO::MYSQL_ATTR_CONNECT_TIMEOUT')) {
        $options[PDO::MYSQL_ATTR_CONNECT_TIMEOUT] = 8;
    }
    try {
        $pdo = new PDO($dsn, (string) $config['db_user'], (string) $config['db_pass'], $options);
    } catch (PDOException $error) {
        throw new RuntimeException(
            'Could not connect to the database. In config.php use host localhost and the database name, user, and password from hPanel.'
        );
    }
    try {
        ensure_runtime_tables($pdo);
    } catch (PDOException $error) {
        // The connection still works. Notice features report their own database error.
    }
    return $pdo;
}

function ensure_runtime_tables(PDO $pdo): void
{
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS notices (
          id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          user_id INT UNSIGNED NULL,
          title VARCHAR(80) NOT NULL,
          body VARCHAR(500) NOT NULL,
          link_url VARCHAR(500) NOT NULL DEFAULT \'\',
          created_at DATETIME NOT NULL,
          INDEX notices_user (user_id, id),
          CONSTRAINT fk_notices_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS notice_reads (
          notice_id INT UNSIGNED NOT NULL,
          user_id INT UNSIGNED NOT NULL,
          read_at DATETIME NOT NULL,
          PRIMARY KEY (notice_id, user_id),
          CONSTRAINT fk_notice_reads_notice FOREIGN KEY (notice_id) REFERENCES notices(id) ON DELETE CASCADE,
          CONSTRAINT fk_notice_reads_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS auth_attempts (
          id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          action VARCHAR(32) NOT NULL,
          subject_hash CHAR(64) NOT NULL,
          created_at DATETIME NOT NULL,
          INDEX auth_attempts_lookup (action, subject_hash, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS moderation_events (
          id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
          admin_id INT UNSIGNED NOT NULL,
          action VARCHAR(32) NOT NULL,
          target_user_id INT UNSIGNED NULL,
          note VARCHAR(120) NOT NULL DEFAULT \'\',
          created_at DATETIME NOT NULL,
          INDEX moderation_created (created_at),
          CONSTRAINT fk_moderation_admin FOREIGN KEY (admin_id) REFERENCES admins(id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
    );
    ensure_column($pdo, 'users', 'token_expires_at', 'DATETIME NULL');
    ensure_index($pdo, 'users', 'users_token_hash', 'ALTER TABLE users ADD INDEX users_token_hash (token_hash)');
    ensure_index($pdo, 'messages', 'messages_sender_day', 'ALTER TABLE messages ADD INDEX messages_sender_day (sender_id, created_at)');
    ensure_index($pdo, 'blocks', 'blocks_blocked', 'ALTER TABLE blocks ADD INDEX blocks_blocked (blocked_id)');
}

function ensure_column(PDO $pdo, string $table, string $column, string $definition): void
{
    $statement = $pdo->query('SHOW COLUMNS FROM `' . $table . '` LIKE ' . $pdo->quote($column));
    if ($statement && $statement->fetch()) {
        return;
    }
    $pdo->exec('ALTER TABLE `' . $table . '` ADD COLUMN `' . $column . '` ' . $definition);
}

function ensure_index(PDO $pdo, string $table, string $name, string $sql): void
{
    $statement = $pdo->query(
        'SHOW INDEX FROM `' . $table . '` WHERE Key_name = ' . $pdo->quote($name)
    );
    if ($statement && $statement->fetch()) {
        return;
    }
    $pdo->exec($sql);
}

function optional_link(string $value): string
{
    $link = trim($value);
    if ($link === '') {
        return '';
    }
    if (strlen($link) > 500 || !preg_match('#^https?://#i', $link)) {
        throw new RuntimeException('Use a full http or https link, or leave the link empty.');
    }
    return $link;
}

function client_ip(): string
{
    $ip = $_SERVER['REMOTE_ADDR'] ?? '';
    return is_string($ip) ? $ip : '';
}

function rate_limit_blocked(string $action, string $subject, int $max, int $windowSeconds): bool
{
    $since = date('Y-m-d H:i:s', time() - $windowSeconds);
    $count = db()->prepare(
        'SELECT COUNT(*) FROM auth_attempts WHERE action = ? AND subject_hash = ? AND created_at >= ?'
    );
    $count->execute([$action, hash('sha256', $subject), $since]);
    return (int) $count->fetchColumn() >= $max;
}

function rate_limit_record(string $action, string $subject): void
{
    $insert = db()->prepare(
        'INSERT INTO auth_attempts (action, subject_hash, created_at) VALUES (?, ?, ?)'
    );
    $insert->execute([$action, hash('sha256', $subject), now()]);
    if (random_int(1, 20) === 1) {
        $old = date('Y-m-d H:i:s', time() - 172800);
        $prune = db()->prepare('DELETE FROM auth_attempts WHERE created_at < ?');
        $prune->execute([$old]);
    }
}

function rate_limit_clear(string $action, string $subject): void
{
    $delete = db()->prepare('DELETE FROM auth_attempts WHERE action = ? AND subject_hash = ?');
    $delete->execute([$action, hash('sha256', $subject)]);
}

function log_moderation(int $adminId, string $action, ?int $targetUserId, string $note = ''): void
{
    $length = function_exists('mb_strlen') ? mb_strlen($note) : strlen($note);
    if ($length > 120) {
        $note = function_exists('mb_substr') ? mb_substr($note, 0, 120) : substr($note, 0, 120);
    }
    $insert = db()->prepare(
        'INSERT INTO moderation_events (admin_id, action, target_user_id, note, created_at) VALUES (?, ?, ?, ?, ?)'
    );
    $insert->execute([$adminId, $action, $targetUserId, $note, now()]);
}

function cors_headers(): void
{
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Auth-Token');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
}

function fail(int $status, string $error, string $message): never
{
    http_response_code($status);
    cors_headers();
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => $error, 'message' => $message]);
    exit;
}

function json_out(array $payload, int $status = 200): never
{
    http_response_code($status);
    cors_headers();
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload);
    exit;
}

function read_json_body(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function request_data(): array
{
    if (!empty($_POST)) {
        return $_POST;
    }
    return read_json_body();
}

function bearer_token(): ?string
{
    $header = authorization_header();
    if (preg_match('/^Bearer\s+(\S+)$/i', $header, $match)) {
        return $match[1];
    }
    $alt = $_SERVER['HTTP_X_AUTH_TOKEN'] ?? '';
    if (is_string($alt) && $alt !== '') {
        return $alt;
    }
    return null;
}

function authorization_header(): string
{
    foreach ([
        $_SERVER['HTTP_AUTHORIZATION'] ?? null,
        $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? null,
    ] as $value) {
        if (is_string($value) && $value !== '') {
            return $value;
        }
    }
    if (!function_exists('getallheaders')) {
        return '';
    }
    $headers = getallheaders();
    if (!is_array($headers)) {
        return '';
    }
    foreach ($headers as $name => $value) {
        if (!is_string($value) || $value === '') {
            continue;
        }
        if (strcasecmp((string) $name, 'Authorization') === 0) {
            return $value;
        }
        if (strcasecmp((string) $name, 'X-Auth-Token') === 0) {
            $_SERVER['HTTP_X_AUTH_TOKEN'] = $value;
        }
    }
    return '';
}

function current_user(): array
{
    $token = bearer_token();
    if ($token === null || $token === '') {
        fail(401, 'unauthenticated', 'Sign in again.');
    }
    $hash = hash('sha256', $token);
    $statement = db()->prepare(
        'SELECT id, email, blocked, token_expires_at FROM users WHERE token_hash = ? LIMIT 1'
    );
    $statement->execute([$hash]);
    $user = $statement->fetch();
    if (!$user) {
        fail(401, 'unauthenticated', 'Sign in again.');
    }
    if ((int) $user['blocked'] === 1) {
        fail(403, 'blocked', 'This account is blocked.');
    }
    $expires = $user['token_expires_at'] ?? null;
    if (!is_string($expires) || $expires === '') {
        $backfill = db()->prepare(
            'UPDATE users SET token_expires_at = ? WHERE id = ? AND token_hash = ?'
        );
        $backfill->execute([token_expiry(), (int) $user['id'], $hash]);
    } elseif (strtotime($expires) < time()) {
        $clear = db()->prepare(
            'UPDATE users SET token_hash = NULL, token_expires_at = NULL WHERE id = ? AND token_hash = ?'
        );
        $clear->execute([(int) $user['id'], $hash]);
        fail(401, 'unauthenticated', 'Sign in again.');
    }
    return $user;
}

function public_base(): string
{
    return rtrim((string) app_config()['base_url'], '/');
}

function media_url(?string $path): ?string
{
    if ($path === null || $path === '') {
        return null;
    }
    return public_base() . '/' . ltrim($path, '/');
}

function now(): string
{
    return (new DateTimeImmutable('now'))->format('Y-m-d H:i:s');
}

function server_day_bounds(): array
{
    // One calendar day on this server's clock, from midnight up to the next midnight.
    // Message rows use now(), so the daily cap and the stored time share that clock.
    $start = new DateTimeImmutable('today');
    return [
        $start->format('Y-m-d H:i:s'),
        $start->modify('+1 day')->format('Y-m-d H:i:s'),
    ];
}

function message_text(string $text): string
{
    $text = trim($text);
    $length = function_exists('mb_strlen') ? mb_strlen($text) : strlen($text);
    if ($text === '' || $length > 1000) {
        throw new RuntimeException('Write a message up to 1000 characters.');
    }
    return $text;
}

function validated_search_filters(array $input): array
{
    $minAge = filter_var($input['minAge'] ?? 18, FILTER_VALIDATE_INT);
    $maxAge = filter_var($input['maxAge'] ?? 99, FILTER_VALIDATE_INT);
    if ($minAge === false || $maxAge === false || $minAge < 18 || $maxAge > 99 || $maxAge < $minAge) {
        throw new RuntimeException('Use an age range from 18 to 99.');
    }
    $genderRaw = $input['gender'] ?? '';
    $gender = is_string($genderRaw) ? trim($genderRaw) : '';
    if ($gender !== '' && !in_array($gender, GENDERS, true)) {
        throw new RuntimeException('Choose a listed gender.');
    }
    $queryRaw = $input['query'] ?? '';
    $query = strtolower(trim(is_string($queryRaw) ? $queryRaw : ''));
    if (function_exists('mb_strlen') && mb_strlen($query) > 40) {
        $query = mb_substr($query, 0, 40);
    } elseif (strlen($query) > 40) {
        $query = substr($query, 0, 40);
    }
    return [
        'minAge' => $minAge,
        'maxAge' => $maxAge,
        'gender' => $gender,
        'query' => $query,
        'interests' => validated_choice_list(
            $input['interests'] ?? [],
            INTERESTS,
            'Choose interests from the list.'
        ),
        'preferences' => validated_choice_list(
            $input['preferences'] ?? [],
            PREFERENCES,
            'Choose preferences from the list.'
        ),
    ];
}

function validated_choice_list(mixed $value, array $allowed, string $message): array
{
    if ($value === null || $value === '' || $value === []) {
        return [];
    }
    if (is_string($value)) {
        $decoded = json_decode($value, true);
        if (!is_array($decoded)) {
            throw new RuntimeException($message);
        }
        $value = $decoded;
    }
    if (!is_array($value)) {
        throw new RuntimeException($message);
    }
    $clean = [];
    foreach ($value as $item) {
        if (!is_string($item) || !in_array($item, $allowed, true)) {
            throw new RuntimeException($message);
        }
        if (!in_array($item, $clean, true)) {
            $clean[] = $item;
        }
    }
    return $clean;
}

function like_contains(string $value): string
{
    return '%' . str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], $value) . '%';
}

function age_years(string $birthDate): int
{
    $born = DateTimeImmutable::createFromFormat('!Y-m-d', $birthDate);
    if (!$born || $born->format('Y-m-d') !== $birthDate) {
        fail(400, 'invalid-argument', 'Enter your date of birth.');
    }
    return $born->diff(new DateTimeImmutable('today'))->y;
}

function list_field(mixed $value, array $allowed): array
{
    if (is_string($value)) {
        $decoded = json_decode($value, true);
        $value = is_array($decoded) ? $decoded : [];
    }
    if (!is_array($value)) {
        return [];
    }
    $clean = [];
    foreach ($value as $item) {
        $text = trim((string) $item);
        if (in_array($text, $allowed, true) && !in_array($text, $clean, true)) {
            $clean[] = $text;
        }
    }
    return $clean;
}

function validate_profile_fields(array $input, bool $photoRequired, bool $hasExistingPhoto): array
{
    $username = strtolower(trim((string) ($input['username'] ?? '')));
    if (!preg_match('/^[a-z0-9_]{3,20}$/', $username)) {
        fail(400, 'invalid-argument', 'Username must be 3–20 characters: lowercase letters, numbers, or underscore.');
    }
    $birthDate = trim((string) ($input['birthDate'] ?? ''));
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $birthDate)) {
        fail(400, 'invalid-argument', 'Enter your date of birth.');
    }
    $age = age_years($birthDate);
    if ($age < 18) {
        fail(400, 'invalid-argument', 'You must be 18 or older. No profile was saved.');
    }
    $gender = (string) ($input['gender'] ?? '');
    if (!in_array($gender, GENDERS, true)) {
        fail(400, 'invalid-argument', 'Choose a gender.');
    }
    $city = trim((string) ($input['city'] ?? ''));
    if (!preg_match("/^[A-Za-z][A-Za-z .'-]{1,39}$/", $city)) {
        fail(400, 'invalid-argument', 'Enter a city using letters, up to 40 characters.');
    }
    $bio = trim((string) ($input['bio'] ?? ''));
    $length = function_exists('mb_strlen') ? mb_strlen($bio) : strlen($bio);
    if ($length < 8 || $length > 300) {
        fail(400, 'invalid-argument', 'Bio must be between 8 and 300 characters.');
    }
    $interests = list_field($input['interests'] ?? [], INTERESTS);
    $preferences = list_field($input['preferences'] ?? ($input['relationshipPreferences'] ?? []), PREFERENCES);
    if ($interests === []) {
        fail(400, 'invalid-argument', 'Choose at least one interest.');
    }
    if ($preferences === []) {
        fail(400, 'invalid-argument', 'Choose at least one relationship preference.');
    }
    if ($photoRequired && !$hasExistingPhoto && empty($_FILES['photo']['tmp_name'])) {
        fail(400, 'invalid-argument', 'Add a photo to continue.');
    }
    return [
        'username' => $username,
        'birthDate' => $birthDate,
        'age' => $age,
        'gender' => $gender,
        'city' => $city,
        'bio' => $bio,
        'interests' => $interests,
        'preferences' => $preferences,
    ];
}

function store_image(array $file, string $folder): string
{
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        throw new RuntimeException('The photo could not be uploaded.');
    }
    if (($file['size'] ?? 0) > 5 * 1024 * 1024) {
        throw new RuntimeException('Photos must be smaller than 5 MB.');
    }
    $info = @getimagesize((string) $file['tmp_name']);
    $types = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png', IMAGETYPE_WEBP => 'webp'];
    $type = is_array($info) ? ($info[2] ?? 0) : 0;
    if (!isset($types[$type])) {
        throw new RuntimeException('Use a JPEG, PNG, or WebP photo.');
    }
    $relative = 'uploads/' . $folder;
    $directory = dirname(__DIR__) . '/' . $relative;
    if (!is_dir($directory) && !mkdir($directory, 0755, true) && !is_dir($directory)) {
        throw new RuntimeException('The upload folder is not writable.');
    }
    $name = bin2hex(random_bytes(16)) . '.' . $types[$type];
    $target = $directory . '/' . $name;
    if (!move_uploaded_file((string) $file['tmp_name'], $target)) {
        throw new RuntimeException('The photo could not be saved.');
    }
    return $relative . '/' . $name;
}

function unlink_public(?string $path): void
{
    if ($path === null || $path === '' || str_contains($path, '..')) {
        return;
    }
    $full = dirname(__DIR__) . '/' . ltrim($path, '/');
    if (is_file($full)) {
        unlink($full);
    }
}

function person_payload(array $row, bool $includeBirth): array
{
    $interests = json_decode((string) $row['interests'], true);
    $preferences = json_decode((string) $row['preferences'], true);
    $showOnline = (int) $row['show_online'] === 1;
    $showActive = (int) $row['show_last_active'] === 1;
    $last = $row['last_active_at'] ?? null;
    $online = false;
    $lastLabel = '';
    if (is_string($last) && $last !== '') {
        $seen = new DateTimeImmutable($last);
        $minutes = (int) floor(((new DateTimeImmutable('now'))->getTimestamp() - $seen->getTimestamp()) / 60);
        $online = $showOnline && $minutes <= 5;
        if ($showActive) {
            $lastLabel = $minutes < 2 ? 'Active now' : ($minutes < 60 ? 'Active recently' : 'Active earlier');
        }
    }
    $payload = [
        'id' => (string) $row['user_id'],
        'username' => $row['username'],
        'displayName' => $row['username'],
        'age' => (int) $row['age'],
        'gender' => $row['gender'],
        'city' => $row['city'],
        'bio' => $row['bio'],
        'interests' => is_array($interests) ? array_values($interests) : [],
        'preferences' => is_array($preferences) ? array_values($preferences) : [],
        'photoUrl' => media_url($row['photo_path'] ?? null),
        'hidden' => (int) $row['hidden'] === 1,
        'hue' => abs(crc32((string) $row['username'])) % 360,
        'online' => $online,
        'lastActive' => $lastLabel,
    ];
    if ($includeBirth) {
        $payload['birthDate'] = $row['birth_date'];
        $payload['showOnline'] = (int) $row['show_online'] === 1;
        $payload['showLastActive'] = (int) $row['show_last_active'] === 1;
    }
    return $payload;
}

function load_profile(int $userId): ?array
{
    $statement = db()->prepare('SELECT * FROM profiles WHERE user_id = ? LIMIT 1');
    $statement->execute([$userId]);
    $row = $statement->fetch();
    return $row ?: null;
}

function delete_user_account(int $userId): void
{
    $profile = load_profile($userId);
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $statement = $pdo->prepare('DELETE FROM users WHERE id = ?');
        $statement->execute([$userId]);
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $error;
    }
    if ($profile) {
        unlink_public($profile['photo_path'] ?? null);
    }
}

function touch_active(int $userId): void
{
    $statement = db()->prepare('UPDATE profiles SET last_active_at = ? WHERE user_id = ?');
    $statement->execute([now(), $userId]);
}

function token_expiry(): string
{
    return (new DateTimeImmutable('now'))->modify('+30 days')->format('Y-m-d H:i:s');
}

function issue_token(int $userId): string
{
    $token = bin2hex(random_bytes(32));
    $statement = db()->prepare(
        'UPDATE users SET token_hash = ?, token_expires_at = ? WHERE id = ?'
    );
    $statement->execute([hash('sha256', $token), token_expiry(), $userId]);
    return $token;
}

function auth_payload(int $userId, string $token): array
{
    $profile = load_profile($userId);
    return [
        'token' => $token,
        'userId' => (string) $userId,
        'hasProfile' => $profile !== null,
        'profile' => $profile ? person_payload($profile, true) : null,
    ];
}

function blocked_either(int $a, int $b): bool
{
    $statement = db()->prepare(
        'SELECT 1 FROM blocks WHERE (blocker_id = ? AND blocked_id = ?) OR (blocker_id = ? AND blocked_id = ?) LIMIT 1'
    );
    $statement->execute([$a, $b, $b, $a]);
    return (bool) $statement->fetchColumn();
}

function require_visible_peer(int $me, int $peerId, bool $allowHidden = false): array
{
    if ($peerId === $me) {
        fail(400, 'invalid-argument', 'That profile is not available.');
    }
    $statement = db()->prepare(
        'SELECT p.*, u.blocked AS admin_blocked FROM profiles p JOIN users u ON u.id = p.user_id WHERE p.user_id = ? LIMIT 1'
    );
    $statement->execute([$peerId]);
    $row = $statement->fetch();
    $hidden = $row && (int) $row['hidden'] === 1;
    if (!$row || (int) $row['admin_blocked'] === 1 || (!$allowHidden && $hidden) || blocked_either($me, $peerId)) {
        fail(404, 'not-found', 'That profile is not available.');
    }
    return $row;
}
