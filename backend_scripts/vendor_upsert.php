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

function sk_is_nonempty(?string $s): bool {
  return $s !== null && trim($s) !== '';
}

$table = 'vendor';
if (!sk_db_has_table($conn, $table)) {
  sk_json(500, ['status' => 'error', 'message' => 'vendor_table_missing']);
}

$body = sk_read_json_body();

$email = strtolower(trim((string)($body['email'] ?? ($_POST['email'] ?? ''))));
if ($email === '' || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_email']);
}

$stmt = $conn->prepare('SELECT * FROM vendor WHERE LOWER(email)=? LIMIT 1');
$stmt->bind_param('s', $email);
$stmt->execute();
$existing = $stmt->get_result()->fetch_assoc();

$hasActiveCol = sk_db_has_column($conn, $table, 'is_active');
$hasStatusCol = sk_db_has_column($conn, $table, 'status');
$hasTokenCol = sk_db_has_column($conn, $table, 'remember_token');

$token = trim((string)($body['token'] ?? ($_POST['token'] ?? '')));
$userId = trim((string)($body['user_id'] ?? ($_POST['user_id'] ?? '')));

if (is_array($existing)) {
  $existingId = (int)($existing['id'] ?? 0);
  $existingActive = $hasActiveCol ? (int)($existing['is_active'] ?? 0) : 0;
  $existingStatus = $hasStatusCol ? strtolower(trim((string)($existing['status'] ?? ''))) : '';

  $approved = false;
  if ($hasStatusCol) {
    $approved = $existingStatus === 'approved';
  } elseif ($hasActiveCol) {
    $approved = $existingActive > 0;
  }

  if ($approved && $hasTokenCol) {
    $tokenOk = ($userId !== '' && (int)$userId === $existingId && $token !== '' && hash_equals((string)($existing['remember_token'] ?? ''), $token));
    if (!$tokenOk) {
      sk_json(401, ['status' => 'error', 'message' => 'unauthorized']);
    }
  }
}

$allowed = [
  'name',
  'businessname',
  'business_name',
  'email',
  'mobile',
  'number',
  'phone',
  'bwebsite',
  'businesswebsite',
  'address',
  'city',
  'state',
  'pincode',
  'is_active',
  'status',
];

$data = [];
foreach ($allowed as $k) {
  $v = sk_read_field($body, $k);
  if (!sk_is_nonempty($v)) continue;
  $data[$k] = trim((string)$v);
}
$data['email'] = $email;

$password = (string)($body['password'] ?? ($_POST['password'] ?? ''));
if ($password !== '') {
  if (strlen($password) < 6) sk_json(400, ['status' => 'error', 'message' => 'weak_password']);
  $data['password'] = password_hash($password, PASSWORD_DEFAULT);
}

if (!is_array($existing) && $password === '') {
  sk_json(400, ['status' => 'error', 'message' => 'password_required']);
}

if ($hasStatusCol && !isset($data['status']) && !is_array($existing)) {
  $data['status'] = 'pending';
}

if ($hasActiveCol && !isset($data['is_active']) && !is_array($existing)) {
  $data['is_active'] = '0';
}

if (is_array($existing)) {
  $id = (int)($existing['id'] ?? 0);
  if ($id <= 0) sk_json(500, ['status' => 'error', 'message' => 'server_error']);

  $setParts = [];
  $types = '';
  $params = [];

  foreach ($data as $k => $v) {
    $col = $k;
    if ($k === 'business_name' && sk_db_has_column($conn, $table, 'businessname')) $col = 'businessname';
    if ($k === 'businesswebsite' && sk_db_has_column($conn, $table, 'bwebsite')) $col = 'bwebsite';
    if ($k === 'number' && sk_db_has_column($conn, $table, 'mobile')) $col = 'mobile';
    if ($k === 'phone' && sk_db_has_column($conn, $table, 'mobile')) $col = 'mobile';

    if (!sk_db_has_column($conn, $table, $col)) continue;
    if ($col === 'email') continue;
    $setParts[] = $col . '=?';
    $types .= 's';
    $params[] = $v;
  }

  if (sk_db_has_column($conn, $table, 'updated_at')) {
    $setParts[] = 'updated_at=NOW()';
  }

  if (!$setParts) {
    sk_json(200, ['status' => 'success', 'vendor' => ['id' => (string)$id]]);
  }

  $sql = 'UPDATE vendor SET ' . implode(', ', $setParts) . ' WHERE id=?';
  $types .= 'i';
  $params[] = $id;
  $stmt = $conn->prepare($sql);
  if ($types !== '') {
    $stmt->bind_param($types, ...$params);
  }
  $stmt->execute();

  $stmt = $conn->prepare('SELECT * FROM vendor WHERE id=? LIMIT 1');
  $stmt->bind_param('i', $id);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  sk_json(200, ['status' => 'success', 'vendor' => $row ?: ['id' => (string)$id]]);
}

$cols = [];
$vals = [];
$types = '';
$params = [];

foreach ($data as $k => $v) {
  $col = $k;
  if ($k === 'business_name' && sk_db_has_column($conn, $table, 'businessname')) $col = 'businessname';
  if ($k === 'businesswebsite' && sk_db_has_column($conn, $table, 'bwebsite')) $col = 'bwebsite';
  if ($k === 'number' && sk_db_has_column($conn, $table, 'mobile')) $col = 'mobile';
  if ($k === 'phone' && sk_db_has_column($conn, $table, 'mobile')) $col = 'mobile';

  if (!sk_db_has_column($conn, $table, $col)) continue;
  $cols[] = $col;
  $vals[] = '?';
  $types .= 's';
  $params[] = $v;
}

if (sk_db_has_column($conn, $table, 'created_at')) {
  $cols[] = 'created_at';
  $vals[] = 'NOW()';
}
if (sk_db_has_column($conn, $table, 'updated_at')) {
  $cols[] = 'updated_at';
  $vals[] = 'NOW()';
}

if (!$cols) {
  sk_json(400, ['status' => 'error', 'message' => 'no_valid_fields']);
}

$sql = 'INSERT INTO vendor (' . implode(', ', $cols) . ') VALUES (' . implode(', ', $vals) . ')';
$stmt = $conn->prepare($sql);
if ($types !== '') {
  $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$id = (int)$conn->insert_id;

$stmt = $conn->prepare('SELECT * FROM vendor WHERE id=? LIMIT 1');
$stmt->bind_param('i', $id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();

sk_json(201, ['status' => 'success', 'vendor' => $row ?: ['id' => (string)$id]]);
