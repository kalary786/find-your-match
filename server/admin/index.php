<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

if (admin_user()) {
    header('Location: users.php');
    exit;
}

$error = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = strtolower(trim((string) ($_POST['email'] ?? '')));
    $password = (string) ($_POST['password'] ?? '');
    $emailKey = 'admin-email:' . $email;
    $ipKey = 'admin-ip:' . client_ip();
    if (rate_limit_blocked('admin-login', $emailKey, 8, 900) || rate_limit_blocked('admin-login', $ipKey, 30, 900)) {
        $error = 'Too many sign-in attempts. Try again later.';
    } else {
        $statement = db()->prepare('SELECT id, password_hash FROM admins WHERE email = ? LIMIT 1');
        $statement->execute([$email]);
        $admin = $statement->fetch();
        if (!$admin || !password_verify($password, (string) $admin['password_hash'])) {
            rate_limit_record('admin-login', $emailKey);
            rate_limit_record('admin-login', $ipKey);
            $error = 'Email or password is incorrect.';
        } else {
            rate_limit_clear('admin-login', $emailKey);
            session_regenerate_id(true);
            $_SESSION['admin_id'] = (int) $admin['id'];
            csrf_token();
            header('Location: users.php');
            exit;
        }
    }
}

$body = '<h1>Admin sign-in</h1>';
if ($error) {
    $body .= '<p class="error">' . h($error) . '</p>';
}
$body .= '<form method="post" class="narrow">
  <label>Email <input type="email" name="email" required></label>
  <label>Password <input type="password" name="password" required></label>
  <button type="submit">Sign in</button>
</form>';
layout('Admin sign-in', $body, null);
