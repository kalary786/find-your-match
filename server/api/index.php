<?php

declare(strict_types=1);

require dirname(__DIR__) . '/lib/bootstrap.php';

$action = (string) ($_GET['action'] ?? '');

try {
    match ($action) {
        'register' => register_user(),
        'login' => login_user(),
        'logout' => logout_user(),
        'me' => show_me(),
        'createProfile' => save_profile(true),
        'updateProfile' => save_profile(false),
        'setHidden' => set_hidden(),
        'setPrivacy' => set_privacy(),
        'deleteAccount' => delete_account(),
        'discover' => list_discover(),
        'search' => list_search(),
        'like' => swipe(true),
        'pass' => swipe(false),
        'matches' => list_matches(),
        'chats' => list_chats(),
        'messages' => list_messages(),
        'send' => send_message(),
        'block' => block_user(),
        'unblock' => unblock_user(),
        'blocked' => list_blocked(),
        'report' => report_user(),
        'ads' => list_ads(),
        default => fail(404, 'not-found', 'That action is not available.'),
    };
} catch (PDOException $error) {
    fail(500, 'unavailable', 'The database could not complete that request.');
} catch (RuntimeException $error) {
    fail(400, 'invalid-argument', $error->getMessage());
}

function register_user(): void
{
    $input = request_data();
    $email = normalize_email($input['email'] ?? '');
    $password = (string) ($input['password'] ?? '');
    if (strlen($password) < 8) {
        fail(400, 'invalid-argument', 'Use a password of at least 8 characters.');
    }
    $statement = db()->prepare('SELECT id, blocked FROM users WHERE email = ? LIMIT 1');
    $statement->execute([$email]);
    if ($statement->fetch()) {
        fail(409, 'already-exists', 'An account with that email already exists. Sign in instead.');
    }
    $insert = db()->prepare(
        'INSERT INTO users (email, password_hash, created_at) VALUES (?, ?, ?)'
    );
    $insert->execute([$email, password_hash($password, PASSWORD_DEFAULT), now()]);
    $userId = (int) db()->lastInsertId();
    json_out(auth_payload($userId, issue_token($userId)), 201);
}

function login_user(): void
{
    $input = request_data();
    $email = normalize_email($input['email'] ?? '');
    $password = (string) ($input['password'] ?? '');
    $statement = db()->prepare('SELECT id, password_hash, blocked FROM users WHERE email = ? LIMIT 1');
    $statement->execute([$email]);
    $user = $statement->fetch();
    if (!$user || !password_verify($password, (string) $user['password_hash'])) {
        fail(401, 'unauthenticated', 'Email or password is incorrect.');
    }
    if ((int) $user['blocked'] === 1) {
        fail(403, 'blocked', 'This account is blocked.');
    }
    $userId = (int) $user['id'];
    json_out(auth_payload($userId, issue_token($userId)));
}

function logout_user(): void
{
    $token = bearer_token();
    if ($token) {
        $statement = db()->prepare('UPDATE users SET token_hash = NULL WHERE token_hash = ?');
        $statement->execute([hash('sha256', $token)]);
    }
    json_out(['ok' => true]);
}

function show_me(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    touch_active($userId);
    $profile = load_profile($userId);
    json_out([
        'userId' => (string) $userId,
        'email' => $user['email'],
        'hasProfile' => $profile !== null,
        'profile' => $profile ? person_payload($profile, true) : null,
    ]);
}

function save_profile(bool $creating): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $existing = load_profile($userId);
    if ($creating && $existing) {
        json_out([
            'alreadyExisted' => true,
            'profile' => person_payload($existing, true),
        ]);
    }
    if (!$creating && !$existing) {
        fail(400, 'failed-precondition', 'Create a profile before changing it.');
    }
    if ($existing && strtotime((string) $existing['updated_at']) > time() - 3) {
        fail(429, 'resource-exhausted', 'Please wait a few seconds before saving again.');
    }
    $fields = validate_profile_fields(
        request_data(),
        $creating,
        $existing !== null && !empty($existing['photo_path'])
    );
    $owner = db()->prepare('SELECT user_id FROM profiles WHERE username = ? AND user_id <> ? LIMIT 1');
    $owner->execute([$fields['username'], $userId]);
    if ($owner->fetch()) {
        fail(409, 'already-exists', 'That username is already taken.');
    }
    $photoPath = $existing['photo_path'] ?? null;
    if (!empty($_FILES['photo']['tmp_name'])) {
        $uploaded = store_image($_FILES['photo'], 'photos');
        unlink_public(is_string($photoPath) ? $photoPath : null);
        $photoPath = $uploaded;
    }
    if ($creating && ($photoPath === null || $photoPath === '')) {
        fail(400, 'invalid-argument', 'Add a photo to continue.');
    }
    $stamp = now();
    if ($creating) {
        $insert = db()->prepare(
            'INSERT INTO profiles
            (user_id, username, birth_date, age, gender, city, bio, interests, preferences, photo_path, hidden, last_active_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)'
        );
        $insert->execute([
            $userId,
            $fields['username'],
            $fields['birthDate'],
            $fields['age'],
            $fields['gender'],
            $fields['city'],
            $fields['bio'],
            json_encode($fields['interests']),
            json_encode($fields['preferences']),
            $photoPath,
            $stamp,
            $stamp,
            $stamp,
        ]);
    } else {
        $update = db()->prepare(
            'UPDATE profiles SET username = ?, birth_date = ?, age = ?, gender = ?, city = ?, bio = ?,
            interests = ?, preferences = ?, photo_path = ?, updated_at = ?, last_active_at = ? WHERE user_id = ?'
        );
        $update->execute([
            $fields['username'],
            $fields['birthDate'],
            $fields['age'],
            $fields['gender'],
            $fields['city'],
            $fields['bio'],
            json_encode($fields['interests']),
            json_encode($fields['preferences']),
            $photoPath,
            $stamp,
            $stamp,
            $userId,
        ]);
    }
    $saved = load_profile($userId);
    json_out([
        'alreadyExisted' => false,
        'profile' => person_payload($saved ?: [], true),
    ]);
}

function set_hidden(): void
{
    $user = current_user();
    $profile = load_profile((int) $user['id']);
    if (!$profile) {
        fail(400, 'failed-precondition', 'Create a profile before changing it.');
    }
    $hidden = request_data()['hidden'] ?? false;
    $flag = filter_var($hidden, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    $statement = db()->prepare('UPDATE profiles SET hidden = ?, updated_at = ? WHERE user_id = ?');
    $statement->execute([$flag, now(), (int) $user['id']]);
    $saved = load_profile((int) $user['id']);
    json_out(['profile' => person_payload($saved ?: [], true)]);
}

function set_privacy(): void
{
    $user = current_user();
    $profile = load_profile((int) $user['id']);
    if (!$profile) {
        fail(400, 'failed-precondition', 'Create a profile before changing it.');
    }
    $input = request_data();
    $online = filter_var($input['showOnline'] ?? false, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    $active = filter_var($input['showLastActive'] ?? false, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    $statement = db()->prepare(
        'UPDATE profiles SET show_online = ?, show_last_active = ? WHERE user_id = ?'
    );
    $statement->execute([$online, $active, (int) $user['id']]);
    json_out(['ok' => true, 'showOnline' => $online === 1, 'showLastActive' => $active === 1]);
}

function delete_account(): void
{
    $user = current_user();
    delete_user_account((int) $user['id']);
    json_out(['ok' => true]);
}

function list_discover(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    touch_active($userId);
    $statement = db()->prepare(
        'SELECT p.* FROM profiles p
         JOIN users u ON u.id = p.user_id
         WHERE p.user_id <> ?
           AND p.hidden = 0
           AND u.blocked = 0
           AND NOT EXISTS (
             SELECT 1 FROM swipes s WHERE s.from_user_id = ? AND s.to_user_id = p.user_id
           )
           AND NOT EXISTS (
             SELECT 1 FROM blocks b
             WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
           )
         ORDER BY p.created_at DESC
         LIMIT 30'
    );
    $statement->execute([$userId, $userId, $userId, $userId]);
    json_out(['people' => array_map(fn ($row) => person_payload($row, false), $statement->fetchAll())]);
}

function list_search(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $input = request_data();
    $minAge = max(18, (int) ($input['minAge'] ?? 18));
    $maxAge = min(99, (int) ($input['maxAge'] ?? 99));
    if ($maxAge < $minAge) {
        $maxAge = $minAge;
    }
    $gender = (string) ($input['gender'] ?? '');
    $query = strtolower(trim((string) ($input['query'] ?? '')));
    $sql = 'SELECT p.* FROM profiles p
            JOIN users u ON u.id = p.user_id
            WHERE p.user_id <> ? AND p.hidden = 0 AND u.blocked = 0
              AND p.age BETWEEN ? AND ?
              AND NOT EXISTS (
                SELECT 1 FROM blocks b
                WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                   OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
              )';
    $params = [$userId, $minAge, $maxAge, $userId, $userId];
    if (in_array($gender, GENDERS, true)) {
        $sql .= ' AND p.gender = ?';
        $params[] = $gender;
    }
    if ($query !== '') {
        $sql .= ' AND (LOWER(p.username) LIKE ? OR LOWER(p.city) LIKE ?)';
        $like = '%' . $query . '%';
        $params[] = $like;
        $params[] = $like;
    }
    $sql .= ' ORDER BY p.created_at DESC LIMIT 50';
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $interests = list_field($input['interests'] ?? [], INTERESTS);
    $preferences = list_field($input['preferences'] ?? [], PREFERENCES);
    $people = [];
    foreach ($statement->fetchAll() as $row) {
        $rowInterests = json_decode((string) $row['interests'], true) ?: [];
        $rowPreferences = json_decode((string) $row['preferences'], true) ?: [];
        if ($interests !== [] && array_intersect($interests, $rowInterests) === []) {
            continue;
        }
        if ($preferences !== [] && array_intersect($preferences, $rowPreferences) === []) {
            continue;
        }
        $people[] = person_payload($row, false);
    }
    json_out(['people' => $people]);
}

function swipe(bool $liked): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $peerId = (int) (request_data()['userId'] ?? 0);
    require_visible_peer($userId, $peerId);
    $statement = db()->prepare(
        'INSERT INTO swipes (from_user_id, to_user_id, liked, created_at)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE liked = VALUES(liked)'
    );
    $statement->execute([$userId, $peerId, $liked ? 1 : 0, now()]);
    $matched = false;
    if ($liked) {
        $back = db()->prepare(
            'SELECT 1 FROM swipes WHERE from_user_id = ? AND to_user_id = ? AND liked = 1 LIMIT 1'
        );
        $back->execute([$peerId, $userId]);
        if ($back->fetchColumn()) {
            $low = min($userId, $peerId);
            $high = max($userId, $peerId);
            $match = db()->prepare(
                'INSERT IGNORE INTO matches (user_low, user_high, created_at) VALUES (?, ?, ?)'
            );
            $match->execute([$low, $high, now()]);
            $found = db()->prepare('SELECT id FROM matches WHERE user_low = ? AND user_high = ? LIMIT 1');
            $found->execute([$low, $high]);
            $matchId = (int) $found->fetchColumn();
            if ($matchId > 0) {
                $conversation = db()->prepare(
                    'INSERT IGNORE INTO conversations (match_id, user_low, user_high, created_at) VALUES (?, ?, ?, ?)'
                );
                $conversation->execute([$matchId, $low, $high, now()]);
            }
            $matched = true;
        }
    }
    json_out(['matched' => $matched]);
}

function list_matches(): void
{
    $user = current_user();
    json_out(['people' => matched_rows((int) $user['id'])]);
}

function list_chats(): void
{
    $userId = (int) current_user()['id'];
    $statement = db()->prepare(
        'SELECT c.id AS conversation_id, p.*,
            (SELECT body FROM messages m WHERE m.conversation_id = c.id ORDER BY m.id DESC LIMIT 1) AS last_body
         FROM conversations c
         JOIN profiles p ON p.user_id = IF(c.user_low = ?, c.user_high, c.user_low)
         JOIN users u ON u.id = p.user_id
         WHERE (c.user_low = ? OR c.user_high = ?)
           AND u.blocked = 0
           AND NOT EXISTS (
             SELECT 1 FROM blocks b
             WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
           )
         ORDER BY (
           SELECT MAX(m.id) FROM messages m WHERE m.conversation_id = c.id
         ) DESC, c.id DESC'
    );
    $statement->execute([$userId, $userId, $userId, $userId, $userId]);
    $chats = [];
    foreach ($statement->fetchAll() as $row) {
        $person = person_payload($row, false);
        $person['lastMessage'] = (string) ($row['last_body'] ?? '');
        $chats[] = $person;
    }
    json_out(['chats' => $chats]);
}

function conversation_with(int $me, int $peerId): ?array
{
    $low = min($me, $peerId);
    $high = max($me, $peerId);
    $statement = db()->prepare(
        'SELECT * FROM conversations WHERE user_low = ? AND user_high = ? LIMIT 1'
    );
    $statement->execute([$low, $high]);
    $row = $statement->fetch();
    return $row ?: null;
}

function list_messages(): void
{
    $userId = (int) current_user()['id'];
    $peerId = (int) ($_GET['userId'] ?? request_data()['userId'] ?? 0);
    require_visible_peer($userId, $peerId, true);
    $conversation = conversation_with($userId, $peerId);
    if (!$conversation) {
        fail(404, 'not-found', 'Chat opens after a match.');
    }
    $statement = db()->prepare(
        'SELECT id, sender_id, body, created_at FROM messages
         WHERE conversation_id = ?
         ORDER BY id DESC
         LIMIT 200'
    );
    $statement->execute([(int) $conversation['id']]);
    $messages = [];
    foreach (array_reverse($statement->fetchAll()) as $row) {
        $messages[] = message_payload($row, $userId);
    }
    json_out(['messages' => $messages]);
}

function send_message(): void
{
    $userId = (int) current_user()['id'];
    $input = request_data();
    $peerId = (int) ($input['userId'] ?? 0);
    $text = trim((string) ($input['text'] ?? ''));
    $length = function_exists('mb_strlen') ? mb_strlen($text) : strlen($text);
    if ($text === '' || $length > 1000) {
        fail(400, 'invalid-argument', 'Write a message up to 1000 characters.');
    }
    require_visible_peer($userId, $peerId, true);
    $conversation = conversation_with($userId, $peerId);
    if (!$conversation) {
        fail(404, 'not-found', 'Chat opens after a match.');
    }
    $stamp = now();
    $insert = db()->prepare(
        'INSERT INTO messages (conversation_id, sender_id, body, created_at) VALUES (?, ?, ?, ?)'
    );
    $insert->execute([(int) $conversation['id'], $userId, $text, $stamp]);
    touch_active($userId);
    json_out([
        'message' => [
            'id' => (string) db()->lastInsertId(),
            'fromMe' => true,
            'text' => $text,
            'timeLabel' => (new DateTimeImmutable($stamp))->format('g:i a'),
        ],
    ]);
}

function block_user(): void
{
    $userId = (int) current_user()['id'];
    $peerId = (int) (request_data()['userId'] ?? 0);
    if ($peerId <= 0 || $peerId === $userId) {
        fail(400, 'invalid-argument', 'That person cannot be blocked.');
    }
    $statement = db()->prepare(
        'INSERT IGNORE INTO blocks (blocker_id, blocked_id, created_at) VALUES (?, ?, ?)'
    );
    $statement->execute([$userId, $peerId, now()]);
    json_out(['ok' => true]);
}

function unblock_user(): void
{
    $userId = (int) current_user()['id'];
    $peerId = (int) (request_data()['userId'] ?? 0);
    $statement = db()->prepare('DELETE FROM blocks WHERE blocker_id = ? AND blocked_id = ?');
    $statement->execute([$userId, $peerId]);
    json_out(['ok' => true]);
}

function list_blocked(): void
{
    $userId = (int) current_user()['id'];
    $statement = db()->prepare(
        'SELECT p.* FROM blocks b
         JOIN profiles p ON p.user_id = b.blocked_id
         WHERE b.blocker_id = ?
         ORDER BY b.id DESC'
    );
    $statement->execute([$userId]);
    json_out(['people' => array_map(fn ($row) => person_payload($row, false), $statement->fetchAll())]);
}

function report_user(): void
{
    $userId = (int) current_user()['id'];
    $input = request_data();
    $peerId = (int) ($input['userId'] ?? 0);
    $reason = (string) ($input['reason'] ?? '');
    if (!in_array($reason, REPORT_REASONS, true)) {
        fail(400, 'invalid-argument', 'Choose a report reason.');
    }
    if ($peerId <= 0 || $peerId === $userId) {
        fail(400, 'invalid-argument', 'That profile cannot be reported.');
    }
    $details = trim((string) ($input['details'] ?? ''));
    if ((function_exists('mb_strlen') ? mb_strlen($details) : strlen($details)) > 500) {
        $details = function_exists('mb_substr') ? mb_substr($details, 0, 500) : substr($details, 0, 500);
    }
    $statement = db()->prepare(
        'INSERT INTO reports (reporter_id, reported_id, reason, details, created_at) VALUES (?, ?, ?, ?, ?)'
    );
    $statement->execute([$userId, $peerId, $reason, $details, now()]);
    json_out(['ok' => true]);
}

function list_ads(): void
{
    current_user();
    $placement = (string) ($_GET['placement'] ?? '');
    if (!in_array($placement, AD_PLACEMENTS, true)) {
        fail(400, 'invalid-argument', 'That ad placement is not available.');
    }
    $statement = db()->prepare(
        'SELECT id, title, image_path, link_url, placement FROM ads
         WHERE active = 1 AND placement = ? ORDER BY id DESC LIMIT 1'
    );
    $statement->execute([$placement]);
    $row = $statement->fetch();
    json_out([
        'ad' => $row ? [
            'id' => (string) $row['id'],
            'title' => $row['title'],
            'imageUrl' => media_url($row['image_path']),
            'linkUrl' => $row['link_url'],
            'placement' => $row['placement'],
        ] : null,
    ]);
}

function matched_rows(int $userId): array
{
    $statement = db()->prepare(
        'SELECT p.* FROM matches m
         JOIN profiles p ON p.user_id = IF(m.user_low = ?, m.user_high, m.user_low)
         JOIN users u ON u.id = p.user_id
         WHERE (m.user_low = ? OR m.user_high = ?)
           AND u.blocked = 0
           AND NOT EXISTS (
             SELECT 1 FROM blocks b
             WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
           )
         ORDER BY m.id DESC'
    );
    $statement->execute([$userId, $userId, $userId, $userId, $userId]);
    return array_map(fn ($row) => person_payload($row, false), $statement->fetchAll());
}

function message_payload(array $row, int $userId): array
{
    return [
        'id' => (string) $row['id'],
        'fromMe' => (int) $row['sender_id'] === $userId,
        'text' => $row['body'],
        'timeLabel' => (new DateTimeImmutable((string) $row['created_at']))->format('g:i a'),
    ];
}

function normalize_email(mixed $value): string
{
    $email = strtolower(trim((string) $value));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail(400, 'invalid-argument', 'Enter a valid email address.');
    }
    return $email;
}
