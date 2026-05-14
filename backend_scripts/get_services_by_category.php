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
$categoryId = trim((string)($body['category_id'] ?? ($_POST['category_id'] ?? ($_GET['category_id'] ?? ''))));
$subcategoryId = trim((string)($body['subcategory_id'] ?? ($_POST['subcategory_id'] ?? ($_GET['subcategory_id'] ?? ''))));

if ($categoryId === '') sk_json(400, ['status' => 'error', 'message' => 'category_id_required']);

if (!sk_db_has_table($conn, 'services')) {
  sk_json(500, ['status' => 'error', 'message' => 'services_table_missing']);
}

$where = [];
$types = '';
$params = [];

$catCols = [];
foreach (['category_id', 'categorys', 'categories', 'category'] as $c) {
  if (sk_db_has_column($conn, 'services', $c)) $catCols[] = $c;
}
if (!$catCols) {
  sk_json(500, ['status' => 'error', 'message' => 'category_columns_missing']);
}

$catParts = [];
foreach ($catCols as $c) {
  $catParts[] = $c . '=?';
  $types .= 's';
  $params[] = $categoryId;
}
$where[] = '(' . implode(' OR ', $catParts) . ')';

if ($subcategoryId !== '' && sk_db_has_column($conn, 'services', 'subcategory')) {
  $where[] = '(subcategory=? OR FIND_IN_SET(?, REPLACE(subcategory, " ", "")) > 0)';
  $types .= 'ss';
  $params[] = $subcategoryId;
  $params[] = $subcategoryId;
}

if (sk_db_has_column($conn, 'services', 'is_active')) {
  $where[] = "is_active='1'";
}

$sql = 'SELECT * FROM services';
if ($where) {
  $sql .= ' WHERE ' . implode(' AND ', $where);
}
if (sk_db_has_column($conn, 'services', 'id')) {
  $sql .= ' ORDER BY id DESC';
}

$stmt = $conn->prepare($sql);
if ($types !== '') {
  $stmt->bind_param($types, ...$params);
}
$stmt->execute();
$res = $stmt->get_result();

$services = [];
while ($row = $res->fetch_assoc()) {
  $services[] = $row;
}

sk_json(200, ['status' => 'success', 'services' => $services]);

