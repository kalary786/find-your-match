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
    $pdo = new PDO($dsn, (string) $config['db_user'], (string) $config['db_pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    return $pdo;
}

function fail(int $status, string $error, string $message): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => $error, 'message' => $message]);
    exit;
}

function json_out(array $payload, int $status = 200): never
{
    http_response_code($status);
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
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!is_string($header) || !preg_match('/^Bearer\s+(\S+)$/i', $header, $match)) {
        return null;
    }
    return $match[1];
}

function current_user(): array
{
    $token = bearer_token();
    if ($token === null || $token === '') {
        fail(401, 'unauthenticated', 'Sign in again.');
    }
    $hash = hash('sha256', $token);
    $statement = db()->prepare(
        'SELECT id, email, blocked FROM users WHERE token_hash = ? LIMIT 1'
    );
    $statement->execute([$hash]);
    $user = $statement->fetch();
    if (!$user) {
        fail(401, 'unauthenticated', 'Sign in again.');
    }
    if ((int) $user['blocked'] === 1) {
        fail(403, 'blocked', 'This account is blocked.');
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

function touch_active(int $userId): void
{
    $statement = db()->prepare('UPDATE profiles SET last_active_at = ? WHERE user_id = ?');
    $statement->execute([now(), $userId]);
}

function issue_token(int $userId): string
{
    $token = bin2hex(random_bytes(32));
    $statement = db()->prepare('UPDATE users SET token_hash = ? WHERE id = ?');
    $statement->execute([hash('sha256', $token), $userId]);
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

function require_visible_peer(int $me, int $peerId): array
{
    if ($peerId === $me) {
        fail(400, 'invalid-argument', 'That profile is not available.');
    }
    $statement = db()->prepare(
        'SELECT p.*, u.blocked AS admin_blocked FROM profiles p JOIN users u ON u.id = p.user_id WHERE p.user_id = ? LIMIT 1'
    );
    $statement->execute([$peerId]);
    $row = $statement->fetch();
    if (!$row || (int) $row['admin_blocked'] === 1 || (int) $row['hidden'] === 1 || blocked_either($me, $peerId)) {
        fail(404, 'not-found', 'That profile is not available.');
    }
    return $row;
}
