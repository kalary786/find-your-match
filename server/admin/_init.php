<?php

declare(strict_types=1);

require dirname(__DIR__) . '/lib/bootstrap.php';

session_set_cookie_params([
    'httponly' => true,
    'samesite' => 'Lax',
    'path' => '/',
]);
session_start();

function admin_user(): ?array
{
    $id = $_SESSION['admin_id'] ?? null;
    if (!is_int($id) && !ctype_digit((string) $id)) {
        return null;
    }
    $statement = db()->prepare('SELECT id, email FROM admins WHERE id = ? LIMIT 1');
    $statement->execute([(int) $id]);
    $admin = $statement->fetch();
    return $admin ?: null;
}

function require_admin(): array
{
    $admin = admin_user();
    if (!$admin) {
        header('Location: index.php');
        exit;
    }
    return $admin;
}

function csrf_token(): string
{
    if (empty($_SESSION['csrf']) || !is_string($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(16));
    }
    return $_SESSION['csrf'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="csrf" value="' . htmlspecialchars(csrf_token()) . '">';
}

function csrf_ok(): bool
{
    $sent = (string) ($_POST['csrf'] ?? '');
    $known = (string) ($_SESSION['csrf'] ?? '');
    return $known !== '' && hash_equals($known, $sent);
}

function h(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
}

function layout(string $title, string $body, ?array $admin): void
{
    $nav = '';
    if ($admin) {
        $nav = '<nav>
          <a href="users.php">Users</a>
          <a href="chats.php">Chats</a>
          <a href="reports.php">Reports</a>
          <a href="ads.php">Ads</a>
          <a href="logout.php">Sign out</a>
        </nav>';
    }
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>' . h($title) . '</title>
      <link rel="stylesheet" href="assets/admin.css"></head><body>
      <header><strong>Find Your Match</strong>' . $nav . '</header>
      <main>' . $body . '</main></body></html>';
}
