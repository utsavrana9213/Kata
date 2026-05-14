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

function sk_public_base_url(): string {
  $override = getenv('PUBLIC_BASE_URL');
  if ($override && trim($override) !== '') return rtrim(trim($override), '/');
  return 'https://servekeen.com';
}

$token = trim((string)($_POST['token'] ?? ''));
$userId = trim((string)($_POST['user_id'] ?? ''));
$serviceId = trim((string)($_POST['service_id'] ?? $_POST['id'] ?? ''));

if ($userId === '' || $serviceId === '') {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_request']);
}

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

$sid = (int)$serviceId;
$uid = (int)$userId;
$stmt = $conn->prepare('SELECT id, imgfold FROM services WHERE id=? AND user_id=? LIMIT 1');
$stmt->bind_param('ii', $sid, $uid);
$stmt->execute();
$service = $stmt->get_result()->fetch_assoc();
if (!$service) {
  sk_json(404, ['status' => 'error', 'message' => 'service_not_found']);
}

if (!isset($_FILES['images'])) {
  sk_json(400, ['status' => 'error', 'message' => 'images_required']);
}

$images = $_FILES['images'];
$names = $images['name'] ?? [];
$tmpNames = $images['tmp_name'] ?? [];
$errors = $images['error'] ?? [];

if (!is_array($names)) {
  $names = [$names];
  $tmpNames = [$tmpNames];
  $errors = [$errors];
}

$uploadRoot = realpath(__DIR__ . '/..');
if ($uploadRoot === false) $uploadRoot = __DIR__ . '/..';
$dir = rtrim($uploadRoot, '/\\') . '/uploads/services/' . $serviceId;
if (!is_dir($dir)) {
  if (!mkdir($dir, 0775, true) && !is_dir($dir)) {
    sk_json(500, ['status' => 'error', 'message' => 'upload_dir_failed']);
  }
}

$baseUrl = sk_public_base_url();
$savedUrls = [];

for ($i = 0; $i < count($names); $i++) {
  $err = (int)($errors[$i] ?? UPLOAD_ERR_NO_FILE);
  if ($err !== UPLOAD_ERR_OK) continue;
  $tmp = (string)($tmpNames[$i] ?? '');
  if ($tmp === '' || !is_uploaded_file($tmp)) continue;

  $orig = (string)($names[$i] ?? 'image');
  $ext = strtolower(pathinfo($orig, PATHINFO_EXTENSION));
  if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp'], true)) {
    $ext = 'jpg';
  }
  $file = bin2hex(random_bytes(8)) . '.' . $ext;
  $dest = $dir . '/' . $file;

  if (!move_uploaded_file($tmp, $dest)) continue;
  $rel = '/uploads/services/' . $serviceId . '/' . $file;
  $savedUrls[] = $baseUrl . $rel;
}

if (!$savedUrls) {
  sk_json(400, ['status' => 'error', 'message' => 'no_images_uploaded']);
}

$existing = (string)($service['imgfold'] ?? '');
$existingList = [];
if (trim($existing) !== '') {
  $existingList = array_values(array_filter(array_map('trim', explode(',', $existing)), static fn($v) => $v !== ''));
}
$merged = array_values(array_unique(array_merge($existingList, $savedUrls)));
$imgfoldValue = implode(', ', $merged);

if (sk_db_has_column($conn, 'services', 'imgfold')) {
  $stmt = $conn->prepare('UPDATE services SET imgfold=? WHERE id=? AND user_id=?');
  $stmt->bind_param('sii', $imgfoldValue, $sid, $uid);
  $stmt->execute();
}

$stmt = $conn->prepare('SELECT * FROM services WHERE id=? AND user_id=? LIMIT 1');
$stmt->bind_param('ii', $sid, $uid);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();

sk_json(200, ['status' => 'success', 'uploaded' => $savedUrls, 'service' => $row]);

