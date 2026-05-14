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
$vendorId = trim((string)($body['vendor_id'] ?? $body['id'] ?? ($_POST['vendor_id'] ?? ($_POST['id'] ?? ''))));
$action = strtolower(trim((string)($body['action'] ?? ($_POST['action'] ?? ''))));

if ($adminId === '') sk_json(400, ['status' => 'error', 'message' => 'admin_id_required']);
if ($vendorId === '') sk_json(400, ['status' => 'error', 'message' => 'vendor_id_required']);
if ($action !== 'approve' && $action !== 'reject') sk_json(400, ['status' => 'error', 'message' => 'invalid_action']);

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

$vid = (int)$vendorId;
$stmt = $conn->prepare('SELECT * FROM vendor WHERE id=? LIMIT 1');
$stmt->bind_param('i', $vid);
$stmt->execute();
$vendor = $stmt->get_result()->fetch_assoc();
if (!$vendor) sk_json(404, ['status' => 'error', 'message' => 'vendor_not_found']);

$hasStatus = sk_db_has_column($conn, 'vendor', 'status');
$hasActive = sk_db_has_column($conn, 'vendor', 'is_active');

$setParts = [];

if ($action === 'approve') {
  if ($hasStatus) $setParts[] = "status='approved'";
  if ($hasActive) $setParts[] = 'is_active=1';
  if (sk_db_has_column($conn, 'vendor', 'approved_at')) $setParts[] = 'approved_at=NOW()';
} else {
  if ($hasStatus) $setParts[] = "status='rejected'";
  if ($hasActive) $setParts[] = 'is_active=0';
  if (sk_db_has_column($conn, 'vendor', 'rejected_at')) $setParts[] = 'rejected_at=NOW()';
}

if (sk_db_has_column($conn, 'vendor', 'updated_at')) $setParts[] = 'updated_at=NOW()';

if ($setParts) {
  $sql = 'UPDATE vendor SET ' . implode(', ', $setParts) . ' WHERE id=?';
  $stmt = $conn->prepare($sql);
  $stmt->bind_param('i', $vid);
  $stmt->execute();
} else {
  if ($action === 'reject') {
    $stmt = $conn->prepare('DELETE FROM vendor WHERE id=?');
    $stmt->bind_param('i', $vid);
    $stmt->execute();
  }
}

sk_json(200, ['status' => 'success']);
