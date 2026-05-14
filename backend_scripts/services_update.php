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

function sk_read_field(array $body, string $key): ?string {
  if (array_key_exists($key, $body)) {
    $v = $body[$key];
    if ($v === null) return null;
    if (is_bool($v)) return $v ? '1' : '0';
    if (is_int($v) || is_float($v)) return (string)$v;
    if (is_string($v)) return $v;
    return json_encode($v);
  }
  if (isset($_POST[$key])) return (string)$_POST[$key];
  return null;
}

$body = sk_read_json_body();
$token = trim((string)($body['token'] ?? ($_POST['token'] ?? '')));
$userId = trim((string)($body['user_id'] ?? ($_POST['user_id'] ?? '')));
$serviceId = trim((string)($body['service_id'] ?? $body['id'] ?? ($_POST['service_id'] ?? ($_POST['id'] ?? ''))));

if ($userId === '') sk_json(400, ['status' => 'error', 'message' => 'user_id_required']);
if ($serviceId === '') sk_json(400, ['status' => 'error', 'message' => 'service_id_required']);

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

$allowed = [
  'companyname',
  'servicename',
  'locations',
  'category_id',
  'categorys',
  'categories',
  'category',
  'subcategory',
  'price',
  'perprice',
  'allhour',
  'ofprice',
  'percen',
  'workingdays',
  'opentime',
  'closetime',
  'spworkingday',
  'spopentime',
  'spclosetime',
  'number',
  'imgfold',
  'dimgfold',
  'address',
  'description',
  'shortdescription',
  'gmap',
  'lati',
  'lngi',
  'plist',
  'is_active',
  'avr_rat',
  'viewscont',
  'email',
  'website',
  'facebook',
  'twitter',
  'instagram',
  'linkedin',
  'slug',
  'pagetitle',
  'metadescription',
];

$data = [];
foreach ($allowed as $k) {
  $v = sk_read_field($body, $k);
  if ($v === null) continue;
  $v = trim((string)$v);
  if ($v === '') continue;
  $data[$k] = $v;
}

$catVal = null;
if (isset($data['category_id'])) {
  $catVal = $data['category_id'];
} else {
  foreach (['categorys', 'category', 'categories'] as $alt) {
    if (isset($data[$alt])) {
      $catVal = $data[$alt];
      break;
    }
  }
}
if ($catVal !== null && trim((string)$catVal) !== '') {
  if (sk_db_has_column($conn, 'services', 'category_id')) {
    $data['category_id'] = $catVal;
  } else {
    unset($data['category_id']);
  }
  if (sk_db_has_column($conn, 'services', 'categorys')) {
    $data['categorys'] = $catVal;
  }
  if (sk_db_has_column($conn, 'services', 'category')) {
    $data['category'] = $catVal;
  }
  if (sk_db_has_column($conn, 'services', 'categories')) {
    $data['categories'] = $catVal;
  }
} else {
  unset($data['category_id']);
}

$setParts = [];
$types = '';
$params = [];
foreach ($data as $k => $v) {
  if (!sk_db_has_column($conn, 'services', $k)) continue;
  $setParts[] = $k . '=?';
  $types .= 's';
  $params[] = $v;
}

if (sk_db_has_column($conn, 'services', 'updated_at')) {
  $setParts[] = 'updated_at=NOW()';
}

if (!$setParts) sk_json(400, ['status' => 'error', 'message' => 'no_valid_fields']);

$sql = 'UPDATE services SET ' . implode(', ', $setParts) . ' WHERE id=? AND user_id=?';
$types .= 'ii';
$params[] = (int)$serviceId;
$params[] = (int)$userId;

$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$params);
$stmt->execute();

$stmt = $conn->prepare('SELECT * FROM services WHERE id=? AND user_id=? LIMIT 1');
$sid = (int)$serviceId;
$uid = (int)$userId;
$stmt->bind_param('ii', $sid, $uid);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();

sk_json(200, ['status' => 'success', 'service' => $row ?: ['id' => (string)$serviceId]]);
