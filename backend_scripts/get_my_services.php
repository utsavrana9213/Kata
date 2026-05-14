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
$userId = trim((string)($body['user_id'] ?? ($_POST['user_id'] ?? '')));
if ($userId === '') sk_json(400, ['status' => 'error', 'message' => 'user_id_required']);

if (sk_db_has_table($conn, 'vendor') && sk_db_has_column($conn, 'vendor', 'remember_token')) {
  $stmt = $conn->prepare('SELECT id FROM vendor WHERE id=? AND remember_token=? LIMIT 1');
  $idInt = (int)$userId;
  $stmt->bind_param('is', $idInt, $token);
  $stmt->execute();
  $ok = $stmt->get_result()->fetch_assoc();
  if (!$ok) sk_json(401, ['status' => 'error', 'message' => 'unauthorized']);
}

if (!sk_db_has_table($conn, 'services')) {
  sk_json(500, ['status' => 'error', 'message' => 'services_table_missing']);
}

$stmt = $conn->prepare('SELECT * FROM services WHERE user_id=? ORDER BY id DESC');
$idInt = (int)$userId;
$stmt->bind_param('i', $idInt);
$stmt->execute();
$res = $stmt->get_result();
$services = [];
while ($row = $res->fetch_assoc()) {
  $services[] = $row;
}

sk_json(200, ['status' => 'success', 'services' => $services]);

