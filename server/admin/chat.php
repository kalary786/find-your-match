<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

$admin = require_admin();
$id = (int) ($_GET['id'] ?? 0);
$statement = db()->prepare(
    'SELECT c.id, low.username AS low_name, high.username AS high_name
     FROM conversations c
     JOIN profiles low ON low.user_id = c.user_low
     JOIN profiles high ON high.user_id = c.user_high
     WHERE c.id = ? LIMIT 1'
);
$statement->execute([$id]);
$conversation = $statement->fetch();
if (!$conversation) {
    layout('Chat', '<h1>Chat</h1><p>That chat is not available.</p>', $admin);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && csrf_ok()) {
    $delete = db()->prepare('DELETE FROM conversations WHERE id = ?');
    $delete->execute([$id]);
    log_moderation((int) $admin['id'], 'chat-delete', null, 'conversation ' . $id);
    header('Location: chats.php');
    exit;
}

$messages = db()->prepare(
    'SELECT m.body, m.created_at, p.username
     FROM messages m
     JOIN profiles p ON p.user_id = m.sender_id
     WHERE m.conversation_id = ?
     ORDER BY m.id ASC'
);
$messages->execute([$id]);

$body = '<h1>' . h((string) $conversation['low_name']) . ' and ' . h((string) $conversation['high_name']) . '</h1>';
$body .= '<p><a href="chats.php">Back to chats</a></p><div class="thread">';
foreach ($messages->fetchAll() as $message) {
    $body .= '<article><strong>' . h((string) $message['username']) . '</strong> <time>'
        . h((string) $message['created_at']) . '</time><p>' . h((string) $message['body']) . '</p></article>';
}
$body .= '</div><form method="post" onsubmit="return confirm(\'Delete this chat and its messages?\')">'
    . csrf_field() . '<button class="danger" type="submit">Delete chat</button></form>';
layout('Chat', $body, $admin);
