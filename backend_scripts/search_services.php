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
$query = trim((string)($body['query'] ?? ($_POST['query'] ?? ($_GET['query'] ?? ''))));
$limit = (int)($body['limit'] ?? ($_POST['limit'] ?? ($_GET['limit'] ?? 20)));
$offset = (int)($body['offset'] ?? ($_POST['offset'] ?? ($_GET['offset'] ?? 0)));

if ($query === '') {
  sk_json(400, ['status' => 'error', 'message' => 'query_required']);
}

if (!sk_db_has_table($conn, 'services')) {
  sk_json(500, ['status' => 'error', 'message' => 'services_table_missing']);
}

$searchableColumns = [];
$searchFields = ['servicename', 'companyname', 'description', 'shortdescription', 'locations', 'address', 'category', 'subcategory', 'categorys', 'categories'];

foreach ($searchFields as $field) {
  if (sk_db_has_column($conn, 'services', $field)) {
    $searchableColumns[] = $field;
  }
}

if (empty($searchableColumns)) {
  sk_json(500, ['status' => 'error', 'message' => 'no_searchable_columns_found']);
}

$where = [];
$types = '';
$params = [];

$searchTerm = '%' . $query . '%';
$searchConditions = [];

foreach ($searchableColumns as $column) {
  $searchConditions[] = "$column LIKE ?";
  $types .= 's';
  $params[] = $searchTerm;
}

if (sk_db_has_table($conn, 'categorys')) {
  $categoryNameColumn = sk_db_has_column($conn, 'categorys', 'category_name') ? 'category_name' : (sk_db_has_column($conn, 'categorys', 'name') ? 'name' : '');
  if ($categoryNameColumn !== '') {
    foreach (['category_id', 'categorys', 'category'] as $serviceCategoryColumn) {
      if (sk_db_has_column($conn, 'services', $serviceCategoryColumn)) {
        $searchConditions[] = "EXISTS (SELECT 1 FROM categorys c WHERE c.id = services.$serviceCategoryColumn AND c.$categoryNameColumn LIKE ?)";
        $types .= 's';
        $params[] = $searchTerm;
      }
    }
  }
}

if (sk_db_has_table($conn, 'subcategorys')) {
  $subcategoryNameColumn = sk_db_has_column($conn, 'subcategorys', 'subname') ? 'subname' : (sk_db_has_column($conn, 'subcategorys', 'subcategory_name') ? 'subcategory_name' : (sk_db_has_column($conn, 'subcategorys', 'name') ? 'name' : ''));
  if ($subcategoryNameColumn !== '' && sk_db_has_column($conn, 'services', 'subcategory')) {
    $searchConditions[] = "EXISTS (SELECT 1 FROM subcategorys sc WHERE FIND_IN_SET(sc.id, REPLACE(services.subcategory, ' ', '')) > 0 AND sc.$subcategoryNameColumn LIKE ?)";
    $types .= 's';
    $params[] = $searchTerm;
  }
}

$where[] = '(' . implode(' OR ', $searchConditions) . ')';

if (sk_db_has_column($conn, 'services', 'is_active')) {
  $where[] = "is_active='1'";
}

$sql = 'SELECT * FROM services';
if ($where) {
  $sql .= ' WHERE ' . implode(' AND ', $where);
}

$orderBy = '';
if (sk_db_has_column($conn, 'services', 'avr_rat')) {
  $orderBy = 'avr_rat DESC, ';
}
if (sk_db_has_column($conn, 'services', 'viewscont')) {
  $orderBy .= 'viewscont DESC, ';
}
if (sk_db_has_column($conn, 'services', 'id')) {
  $orderBy .= 'id DESC';
}
if ($orderBy) {
  $sql .= ' ORDER BY ' . rtrim($orderBy, ', ');
}

if ($limit > 0) {
  $sql .= ' LIMIT ? OFFSET ?';
  $types .= 'ii';
  $params[] = $limit;
  $params[] = $offset;
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

$countSql = 'SELECT COUNT(*) as total FROM services';
if ($where) {
  $countWhere = $where;
  $countSql .= ' WHERE ' . implode(' AND ', $countWhere);
  
  $countStmt = $conn->prepare($countSql);
  if ($types !== '') {
    $countTypes = $types;
    $countParams = $params;
    if ($limit > 0) {
      $countTypes = substr($countTypes, 0, -2);
      array_pop($countParams);
      array_pop($countParams);
    }
    $countStmt->bind_param($countTypes, ...$countParams);
  }
  $countStmt->execute();
  $countRes = $countStmt->get_result();
  $totalRow = $countRes->fetch_assoc();
  $total = (int)($totalRow['total'] ?? 0);
} else {
  $total = count($services);
}

sk_json(200, [
  'status' => 'success',
  'query' => $query,
  'total' => $total,
  'count' => count($services),
  'limit' => $limit,
  'offset' => $offset,
  'services' => $services
]);
