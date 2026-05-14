<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap_json.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$db1 = __DIR__ . '/db_connect.php';
$db2 = __DIR__ . '/db_connection.php';
if (is_file($db1)) {
  require_once $db1;
} elseif (is_file($db2)) {
  require_once $db2;
} else {
  sk_json(500, ['status' => 'error', 'message' => 'db_not_configured']);
}

function sk_db_has_table(mysqli $conn, string $table): bool {
  $stmt = $conn->prepare('SELECT COUNT(*) c FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?');
  $stmt->bind_param('s', $table);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return ((int)($row['c'] ?? 0)) > 0;
}

function sk_db_has_column(mysqli $conn, string $table, string $column): bool {
  $stmt = $conn->prepare('SELECT COUNT(*) c FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?');
  $stmt->bind_param('ss', $table, $column);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return ((int)($row['c'] ?? 0)) > 0;
}

$body = sk_read_json_body();
$token = trim((string)($body['token'] ?? ($_POST['token'] ?? '')));
$adminId = trim((string)($body['admin_id'] ?? $body['user_id'] ?? ($_POST['admin_id'] ?? ($_POST['user_id'] ?? ''))));

if ($adminId === '') sk_json(400, ['status' => 'error', 'message' => 'admin_id_required']);

if (sk_db_has_table($conn, 'admins') && sk_db_has_column($conn, 'admins', 'remember_token')) {
  $stmt = $conn->prepare('SELECT id FROM admins WHERE id=? AND remember_token=? LIMIT 1');
  $aid = (int)$adminId;
  $stmt->bind_param('is', $aid, $token);
  $stmt->execute();
  $ok = $stmt->get_result()->fetch_assoc();
  if (!$ok) sk_json(401, ['status' => 'error', 'message' => 'unauthorized']);
}

if (!sk_db_has_table($conn, 'vendor')) {
  sk_json(500, ['status' => 'error', 'message' => 'vendor_table_missing']);
}

$hasStatus = sk_db_has_column($conn, 'vendor', 'status');
$hasActive = sk_db_has_column($conn, 'vendor', 'is_active');

if (!$hasStatus && !$hasActive) {
  sk_json(500, ['status' => 'error', 'message' => 'vendor_approval_fields_missing']);
}

$cols = ['id'];

foreach (['name', 'ownername', 'full_name'] as $c) {
  if (sk_db_has_column($conn, 'vendor', $c)) {
    $cols[] = $c . ' AS name';
    break;
  }
}

foreach (['businessname', 'business_name', 'companyname'] as $c) {
  if (sk_db_has_column($conn, 'vendor', $c)) {
    $cols[] = $c . ' AS businessname';
    break;
  }
}

if (sk_db_has_column($conn, 'vendor', 'email')) $cols[] = 'email';

foreach (['created_at', 'createdAt', 'registration_date'] as $c) {
  if (sk_db_has_column($conn, 'vendor', $c)) {
    $cols[] = $c . ' AS created_at';
    break;
  }
}

$where = '';
$types = '';
$params = [];

if ($hasStatus) {
  $where = 'WHERE LOWER(status)=?';
  $types = 's';
  $params = ['pending'];
} else {
  $where = 'WHERE is_active=?';
  $types = 'i';
  $params = [0];
}

$sql = 'SELECT ' . implode(', ', $cols) . ' FROM vendor ' . $where . ' ORDER BY id DESC';
$stmt = $conn->prepare($sql);
if ($types !== '') {
  $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$res = $stmt->get_result();

$vendors = [];
while ($row = $res->fetch_assoc()) {
  $vendors[] = $row;
}

sk_json(200, ['status' => 'success', 'vendors' => $vendors]);
