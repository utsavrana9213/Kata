<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap_json.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
require_once __DIR__ . '/db_connect.php';

const SK_ADMIN_LOGIN_VERSION = '2026-02-01a';

function sk_db_has_column_admin(mysqli $conn, string $column): bool {
  $table = 'admins';
  $stmt = $conn->prepare('SELECT COUNT(*) c FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?');
  $stmt->bind_param('ss', $table, $column);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return ((int)($row['c'] ?? 0)) > 0;
}

function sk_admin_password_matches(string $password, string $stored): bool {
  $stored = trim($stored);
  if ($password === '' || $stored === '') return false;
  if ($stored[0] !== '$') {
    if (str_starts_with($stored, '2y$') || str_starts_with($stored, '2a$') || str_starts_with($stored, '2b$') || str_starts_with($stored, 'argon2')) {
      $stored = '$' . $stored;
    }
  }
  if (str_starts_with($stored, '$2y$') || str_starts_with($stored, '$2a$') || str_starts_with($stored, '$2b$') || str_starts_with($stored, '$argon2')) {
    return password_verify($password, $stored);
  }
  return hash_equals($stored, $password);
}

$body = sk_read_json_body();
$email = strtolower(trim((string)($body['email'] ?? ($_POST['email'] ?? ''))));
$password = (string)($body['password'] ?? ($_POST['password'] ?? ''));

if ($email === '' || $password === '') {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_request', 'v' => SK_ADMIN_LOGIN_VERSION]);
}
if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_email', 'v' => SK_ADMIN_LOGIN_VERSION]);
}

$stmt = $conn->prepare('SELECT * FROM admins WHERE LOWER(email) = ? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$admin = $stmt->get_result()->fetch_assoc();

if (!$admin) {
  error_log('Admin login failed: no admin row found for email=' . $email);
  sk_json(401, ['status' => 'error', 'message' => 'admin_not_found', 'v' => SK_ADMIN_LOGIN_VERSION]);
}

if (sk_db_has_column_admin($conn, 'is_active')) {
  $active = (int)($admin['is_active'] ?? 0);
  if ($active <= 0) {
    error_log('Admin login failed: account_disabled email=' . $email . ' is_active=' . $active);
    sk_json(403, ['status' => 'error', 'message' => 'account_disabled', 'v' => SK_ADMIN_LOGIN_VERSION]);
  }
}

$hashCol = sk_db_has_column_admin($conn, 'password_hash') ? 'password_hash' : (sk_db_has_column_admin($conn, 'password') ? 'password' : null);
if ($hashCol === null) {
  sk_json(500, ['status' => 'error', 'message' => 'server_error', 'v' => SK_ADMIN_LOGIN_VERSION]);
}

$hash = (string)($admin[$hashCol] ?? '');
if (!sk_admin_password_matches($password, $hash)) {
  $hashLen = strlen(trim($hash));
  $prefix = substr(trim($hash), 0, 4);
  error_log('Admin login failed: password mismatch email=' . $email . ' hash_col=' . $hashCol . ' hash_len=' . $hashLen . ' hash_prefix=' . $prefix);
  if (($prefix === '$2y$' || $prefix === '$2a$' || $prefix === '$2b$') && $hashLen < 55) {
    sk_json(401, ['status' => 'error', 'message' => 'password_hash_truncated', 'v' => SK_ADMIN_LOGIN_VERSION]);
  }
  sk_json(401, ['status' => 'error', 'message' => 'password_mismatch', 'v' => SK_ADMIN_LOGIN_VERSION]);
}

$token = bin2hex(random_bytes(32));
try {
  if (sk_db_has_column_admin($conn, 'remember_token')) {
    $stmt = $conn->prepare('UPDATE admins SET remember_token = ? WHERE id = ?');
    $id = (int)($admin['id'] ?? 0);
    $stmt->bind_param('si', $token, $id);
    $stmt->execute();
  }
} catch (Throwable $e) {
}

sk_json(200, [
  'status' => 'success',
  'token' => $token,
  'v' => SK_ADMIN_LOGIN_VERSION,
  'user' => [
    'id' => (string)($admin['id'] ?? ''),
    'name' => (string)($admin['name'] ?? ''),
    'email' => (string)($admin['email'] ?? ''),
    'role' => 'admin',
  ],
]);
