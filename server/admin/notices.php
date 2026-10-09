<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

$admin = require_admin();
$notice = null;
$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_ok()) {
        $error = 'The form expired. Try again.';
    } else {
        $action = (string) ($_POST['action'] ?? 'create');
        if ($action === 'delete') {
            $noticeId = (int) ($_POST['notice_id'] ?? 0);
            if ($noticeId <= 0) {
                $error = 'That notice is not available.';
            } else {
                $delete = db()->prepare('DELETE FROM notices WHERE id = ?');
                $delete->execute([$noticeId]);
                if ($delete->rowCount() < 1) {
                    $error = 'That notice is already gone.';
                } else {
                    log_moderation((int) $admin['id'], 'notice-delete', null, 'notice ' . $noticeId);
                    $notice = 'Notice removed.';
                }
            }
        } elseif ($action !== 'create') {
            $error = 'That action is not available.';
        } else {
            $title = trim((string) ($_POST['title'] ?? ''));
            $bodyText = trim((string) ($_POST['body'] ?? ''));
            $titleLength = function_exists('mb_strlen') ? mb_strlen($title) : strlen($title);
            $bodyLength = function_exists('mb_strlen') ? mb_strlen($bodyText) : strlen($bodyText);
            $target = (int) ($_POST['user_id'] ?? 0);
            try {
                $link = optional_link((string) ($_POST['link_url'] ?? ''));
                if ($title === '' || $titleLength > 80) {
                    $error = 'Enter a title up to 80 characters.';
                } elseif ($bodyText === '' || $bodyLength > 500) {
                    $error = 'Enter a message up to 500 characters.';
                } elseif ($target > 0) {
                    $exists = db()->prepare('SELECT id FROM users WHERE id = ? LIMIT 1');
                    $exists->execute([$target]);
                    if (!$exists->fetch()) {
                        $error = 'That user was not found.';
                    }
                }
                if ($error === null) {
                    $insert = db()->prepare(
                        'INSERT INTO notices (user_id, title, body, link_url, created_at) VALUES (?, ?, ?, ?, ?)'
                    );
                    $insert->execute([
                        $target > 0 ? $target : null,
                        $title,
                        $bodyText,
                        $link,
                        now(),
                    ]);
                    log_moderation(
                        (int) $admin['id'],
                        'notice-create',
                        $target > 0 ? $target : null,
                        'notice ' . (int) db()->lastInsertId()
                    );
                    $notice = $target > 0
                        ? 'Notice sent to that user.'
                        : 'Notice sent to everyone.';
                }
            } catch (RuntimeException $exception) {
                $error = $exception->getMessage();
            }
        }
    }
}

$users = db()->query(
    'SELECT u.id, u.email, p.username
     FROM users u
     LEFT JOIN profiles p ON p.user_id = u.id
     ORDER BY u.id DESC
     LIMIT 200'
)->fetchAll();
$rows = db()->query(
    'SELECT n.id, n.title, n.body, n.link_url, n.created_at, u.email, p.username
     FROM notices n
     LEFT JOIN users u ON u.id = n.user_id
     LEFT JOIN profiles p ON p.user_id = n.user_id
     ORDER BY n.id DESC
     LIMIT 100'
)->fetchAll();

$body = '<h1>Notices</h1><p>Send a message, and an optional link, to one person or to everyone. It shows inside the app. Chat between users stays separate, and each person can send at most 100 chat messages a day.</p>';
if ($notice) {
    $body .= '<p class="ok">' . h($notice) . '</p>';
}
if ($error) {
    $body .= '<p class="error">' . h($error) . '</p>';
}
$body .= '<form method="post" class="narrow">';
$body .= csrf_field();
$body .= '<label>Who <select name="user_id"><option value="0">Everyone</option>';
foreach ($users as $user) {
    $label = (string) $user['email'];
    if (!empty($user['username'])) {
        $label .= ' (' . $user['username'] . ')';
    }
    $body .= '<option value="' . (int) $user['id'] . '">' . h($label) . '</option>';
}
$body .= '</select></label>';
$body .= '<label>Title <input name="title" maxlength="80" required></label>';
$body .= '<label>Message <textarea name="body" maxlength="500" required></textarea></label>';
$body .= '<label>Link <input name="link_url" placeholder="https://example.com"></label>';
$body .= '<button type="submit">Send notice</button></form>';

$body .= '<table><thead><tr><th>When</th><th>Who</th><th>Title</th><th>Message</th><th>Link</th><th></th></tr></thead><tbody>';
foreach ($rows as $row) {
    $who = $row['email'] === null
        ? 'Everyone'
        : (string) $row['email'] . (!empty($row['username']) ? ' (' . $row['username'] . ')' : '');
    $body .= '<tr><td>' . h((string) $row['created_at']) . '</td><td>' . h($who) . '</td><td>'
        . h((string) $row['title']) . '</td><td>' . h((string) $row['body']) . '</td><td>'
        . h((string) $row['link_url']) . '</td><td>';
    $body .= '<form method="post" onsubmit="return confirm(\'Remove this notice?\')">' . csrf_field()
        . '<input type="hidden" name="action" value="delete">'
        . '<input type="hidden" name="notice_id" value="' . (int) $row['id'] . '">'
        . '<button class="danger" type="submit">Delete</button></form>';
    $body .= '</td></tr>';
}
$body .= '</tbody></table>';
layout('Notices', $body, $admin);
