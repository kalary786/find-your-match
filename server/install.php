<?php

declare(strict_types=1);

$configFile = __DIR__ . '/config.php';
if (!is_file($configFile)) {
    exit('Copy config.example.php to config.php and fill in the database before opening install.php.');
}

require __DIR__ . '/lib/bootstrap.php';

function apply_schema(PDO $pdo): void
{
    $sql = file_get_contents(__DIR__ . '/schema.sql');
    if ($sql === false) {
        exit('schema.sql is missing.');
    }
    foreach (array_filter(array_map('trim', explode(';', $sql))) as $statement) {
        $pdo->exec($statement);
    }
}

$error = null;
$done = false;
try {
    apply_schema(db());
    $count = (int) db()->query('SELECT COUNT(*) FROM admins')->fetchColumn();
    if ($count > 0) {
        exit('An admin already exists. Delete install.php from the server.');
    }
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $email = strtolower(trim((string) ($_POST['email'] ?? '')));
        $password = (string) ($_POST['password'] ?? '');
        $confirm = (string) ($_POST['confirm'] ?? '');
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $error = 'Enter a valid admin email.';
        } elseif (strlen($password) < 8) {
            $error = 'Use a password of at least 8 characters.';
        } elseif (!hash_equals($password, $confirm)) {
            $error = 'The passwords do not match.';
        } else {
            $insert = db()->prepare(
                'INSERT INTO admins (email, password_hash, created_at) VALUES (?, ?, ?)'
            );
            $insert->execute([$email, password_hash($password, PASSWORD_DEFAULT), now()]);
            $done = true;
        }
    }
} catch (PDOException $exception) {
    $error = 'Could not prepare the database. Check config.php and that the MySQL database exists.';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Install Find Your Match</title>
  <link rel="stylesheet" href="admin/assets/admin.css">
</head>
<body>
  <main class="narrow">
    <h1>Install admin</h1>
    <?php if ($done): ?>
      <p class="ok">Admin created. Sign in from the admin panel, then delete <code>install.php</code> from the server.</p>
      <p><a href="admin/index.php">Open admin sign-in</a></p>
    <?php else: ?>
      <p>This creates the first admin. The Android app never stores this password.</p>
      <?php if ($error): ?><p class="error"><?= htmlspecialchars($error) ?></p><?php endif; ?>
      <form method="post">
        <label>Email <input type="email" name="email" required></label>
        <label>Password <input type="password" name="password" minlength="8" required></label>
        <label>Confirm password <input type="password" name="confirm" minlength="8" required></label>
        <button type="submit">Create admin</button>
      </form>
    <?php endif; ?>
  </main>
</body>
</html>
