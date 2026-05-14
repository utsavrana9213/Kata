<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap_json.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
require_once __DIR__ . '/db_connect.php';

function sk_db_has_column_vendor(mysqli $conn, string $column): bool {
  $table = 'vendor';
  $stmt = $conn->prepare('SELECT COUNT(*) c FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?');
  $stmt->bind_param('ss', $table, $column);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return ((int)($row['c'] ?? 0)) > 0;
}

$body = sk_read_json_body();
$email = trim((string)($body['email'] ?? ($_POST['email'] ?? '')));
$password = (string)($body['password'] ?? ($_POST['password'] ?? ''));

if ($email === '' || $password === '') {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_request']);
}
if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_email']);
}

$stmt = $conn->prepare('SELECT * FROM vendor WHERE email = ? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$vendor = $stmt->get_result()->fetch_assoc();

if (!$vendor) {
  sk_json(401, ['status' => 'error', 'message' => 'invalid_credentials']);
}

$hash = (string)($vendor['password'] ?? '');
if ($hash === '' || !password_verify($password, $hash)) {
  sk_json(401, ['status' => 'error', 'message' => 'invalid_credentials']);
}

$hasStatus = sk_db_has_column_vendor($conn, 'status');
if ($hasStatus) {
  $status = strtolower(trim((string)($vendor['status'] ?? '')));
  if ($status !== '' && $status !== 'approved') {
    if ($status === 'rejected') {
      sk_json(403, ['status' => 'error', 'message' => 'vendor_rejected']);
    }
    sk_json(403, ['status' => 'error', 'message' => 'vendor_pending_approval']);
  }
}

if (sk_db_has_column_vendor($conn, 'is_active')) {
  $active = (int)($vendor['is_active'] ?? 0);
  if ($active <= 0) {
    sk_json(403, ['status' => 'error', 'message' => 'vendor_pending_approval']);
  }
}

$token = bin2hex(random_bytes(32));
try {
  if (sk_db_has_column_vendor($conn, 'remember_token')) {
    $stmt = $conn->prepare('UPDATE vendor SET remember_token = ? WHERE id = ?');
    $id = (int)($vendor['id'] ?? 0);
    $stmt->bind_param('si', $token, $id);
    $stmt->execute();
  }
} catch (Throwable $e) {
}

sk_json(200, [
  'status' => 'success',
  'token' => $token,
  'user' => [
    'id' => (string)($vendor['id'] ?? ''),
    'name' => (string)($vendor['businessname'] ?? ''),
    'email' => (string)($vendor['email'] ?? ''),
    'mobile' => (string)($vendor['mobile'] ?? ''),
    'address' => (string)($vendor['address'] ?? ''),
    'city' => (string)($vendor['city'] ?? ''),
    'state' => (string)($vendor['state'] ?? ''),
    'pincode' => (string)($vendor['pincode'] ?? ''),
    'role' => 'seller',
    'vendor' => [
      'id' => (string)($vendor['id'] ?? ''),
      'businessname' => (string)($vendor['businessname'] ?? ''),
      'mobile' => (string)($vendor['mobile'] ?? ''),
      'bwebsite' => (string)($vendor['bwebsite'] ?? ''),
      'address' => (string)($vendor['address'] ?? ''),
      'city' => (string)($vendor['city'] ?? ''),
      'state' => (string)($vendor['state'] ?? ''),
      'pincode' => (string)($vendor['pincode'] ?? ''),
    ],
  ],
]);
