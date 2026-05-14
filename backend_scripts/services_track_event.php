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

$body = sk_read_json_body();
$serviceId = trim((string)($body['service_id'] ?? ($_POST['service_id'] ?? ($_GET['service_id'] ?? ''))));
$eventType = trim((string)($body['event_type'] ?? ($_POST['event_type'] ?? ($_GET['event_type'] ?? ''))));

if ($serviceId === '') sk_json(400, ['status' => 'error', 'message' => 'service_id_required']);
if ($eventType === '') sk_json(400, ['status' => 'error', 'message' => 'event_type_required']);

$serviceIdInt = (int)$serviceId;
if ($serviceIdInt <= 0) sk_json(400, ['status' => 'error', 'message' => 'invalid_service_id']);

$allowed = [
  'view_details',
  'tap_phone',
  'tap_email',
  'tap_website',
  'tap_map',
  'tap_whatsapp',
];
if (!in_array($eventType, $allowed, true)) {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_event_type']);
}

if (!sk_db_has_table($conn, 'services')) {
  sk_json(500, ['status' => 'error', 'message' => 'services_table_missing']);
}

$stmt = $conn->prepare('SELECT id FROM services WHERE id=? LIMIT 1');
$stmt->bind_param('i', $serviceIdInt);
$stmt->execute();
$ok = $stmt->get_result()->fetch_assoc();
if (!$ok) sk_json(404, ['status' => 'error', 'message' => 'service_not_found']);

$create = <<<SQL
CREATE TABLE IF NOT EXISTS service_event_counts (
  service_id INT NOT NULL,
  event_type VARCHAR(32) NOT NULL,
  cnt BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (service_id, event_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
SQL;
$conn->query($create);

$stmt = $conn->prepare('INSERT INTO service_event_counts (service_id, event_type, cnt) VALUES (?, ?, 1) ON DUPLICATE KEY UPDATE cnt = cnt + 1');
$stmt->bind_param('is', $serviceIdInt, $eventType);
$stmt->execute();

sk_json(200, ['status' => 'success']);

