<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap_json.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
require_once __DIR__ . '/db_connect.php';

const SK_ADMIN_SIGNUP_VERSION = '2026-02-01a';

function sk_db_has_column_admin_signup(mysqli $conn, string $column): bool {
  $table = 'admins';
  $stmt = $conn->prepare('SELECT COUNT(*) c FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?');
  $stmt->bind_param('ss', $table, $column);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return ((int)($row['c'] ?? 0)) > 0;
}

function sk_bind_params(mysqli_stmt $stmt, string $types, array $values): void {
  $refs = [];
  foreach ($values as $k => $v) {
    $refs[$k] = &$values[$k];
  }
  array_unshift($refs, $types);
  call_user_func_array([$stmt, 'bind_param'], $refs);
}

$body = sk_read_json_body();
$name = trim((string)($body['name'] ?? ($_POST['name'] ?? '')));
$email = strtolower(trim((string)($body['email'] ?? ($_POST['email'] ?? ''))));
$password = (string)($body['password'] ?? ($_POST['password'] ?? ''));

if ($name === '' || $email === '' || $password === '') {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_request', 'v' => SK_ADMIN_SIGNUP_VERSION]);
}
if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_email', 'v' => SK_ADMIN_SIGNUP_VERSION]);
}
if (strlen($password) < 6) {
  sk_json(400, ['status' => 'error', 'message' => 'weak_password', 'v' => SK_ADMIN_SIGNUP_VERSION]);
}

$stmt = $conn->prepare('SELECT id FROM admins WHERE LOWER(email) = ? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$existing = $stmt->get_result()->fetch_assoc();
if ($existing) {
  sk_json(409, ['status' => 'error', 'message' => 'email_exists', 'v' => SK_ADMIN_SIGNUP_VERSION]);
}

$cols = [];
$placeholders = [];
$types = '';
$values = [];

if (sk_db_has_column_admin_signup($conn, 'name')) {
  $cols[] = 'name';
  $placeholders[] = '?';
  $types .= 's';
  $values[] = $name;
}

$cols[] = 'email';
$placeholders[] = '?';
$types .= 's';
$values[] = $email;

$hashCol = sk_db_has_column_admin_signup($conn, 'password_hash') ? 'password_hash' : (sk_db_has_column_admin_signup($conn, 'password') ? 'password' : null);
if ($hashCol === null) {
  sk_json(500, ['status' => 'error', 'message' => 'server_error', 'v' => SK_ADMIN_SIGNUP_VERSION]);
}

$passwordValue = $hashCol === 'password_hash' ? password_hash($password, PASSWORD_DEFAULT) : $password;
$cols[] = $hashCol;
$placeholders[] = '?';
$types .= 's';
$values[] = $passwordValue;

if (sk_db_has_column_admin_signup($conn, 'is_active')) {
  $cols[] = 'is_active';
  $placeholders[] = '?';
  $types .= 'i';
  $values[] = 1;
}

if (sk_db_has_column_admin_signup($conn, 'created_at')) {
  $cols[] = 'created_at';
  $placeholders[] = '?';
  $types .= 's';
  $values[] = date('Y-m-d H:i:s');
}

$sql = 'INSERT INTO admins (' . implode(', ', $cols) . ') VALUES (' . implode(', ', $placeholders) . ')';
$stmt = $conn->prepare($sql);
sk_bind_params($stmt, $types, $values);
$stmt->execute();

$id = (int)$conn->insert_id;
$token = bin2hex(random_bytes(32));

try {
  if (sk_db_has_column_admin_signup($conn, 'remember_token')) {
    $stmt = $conn->prepare('UPDATE admins SET remember_token = ? WHERE id = ?');
    $stmt->bind_param('si', $token, $id);
    $stmt->execute();
  }
} catch (Throwable $e) {
}

sk_json(201, [
  'status' => 'success',
  'token' => $token,
  'v' => SK_ADMIN_SIGNUP_VERSION,
  'user' => [
    'id' => (string)$id,
    'name' => $name,
    'email' => $email,
    'role' => 'admin',
  ],
]);
