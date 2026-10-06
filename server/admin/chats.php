<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

$admin = require_admin();
$notice = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_ok()) {
        $notice = 'The form expired. Try again.';
    } else {
        $conversationId = (int) ($_POST['conversation_id'] ?? 0);
        $statement = db()->prepare('DELETE FROM conversations WHERE id = ?');
        $statement->execute([$conversationId]);
        $notice = 'Chat deleted. The messages are gone.';
    }
}

$rows = db()->query(
    'SELECT c.id, c.created_at,
        low.username AS low_name, high.username AS high_name,
        (SELECT COUNT(*) FROM messages m WHERE m.conversation_id = c.id) AS message_count
     FROM conversations c
     JOIN profiles low ON low.user_id = c.user_low
     JOIN profiles high ON high.user_id = c.user_high
     ORDER BY c.id DESC
     LIMIT 200'
)->fetchAll();

$body = '<h1>Chats</h1>';
if ($notice) {
    $body .= '<p class="ok">' . h($notice) . '</p>';
}
$body .= '<table><thead><tr><th>People</th><th>Messages</th><th>Started</th><th></th></tr></thead><tbody>';
foreach ($rows as $row) {
    $id = (int) $row['id'];
    $body .= '<tr><td>' . h((string) $row['low_name']) . ' and ' . h((string) $row['high_name'])
        . '</td><td>' . (int) $row['message_count'] . '</td><td>' . h((string) $row['created_at'])
        . '</td><td class="actions"><a href="chat.php?id=' . $id . '">Open</a>
        <form method="post" onsubmit="return confirm(\'Delete this chat and its messages?\')">'
        . csrf_field()
        . '<input type="hidden" name="conversation_id" value="' . $id . '">
        <button class="danger" type="submit">Delete</button></form></td></tr>';
}
$body .= '</tbody></table>';
layout('Chats', $body, $admin);
