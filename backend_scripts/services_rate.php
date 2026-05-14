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

function sk_db_has_index(mysqli $conn, string $table, string $indexName): bool {
  $stmt = $conn->prepare('SELECT COUNT(*) c FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = ? AND index_name = ?');
  $stmt->bind_param('ss', $table, $indexName);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
  return ((int)($row['c'] ?? 0)) > 0;
}

function sk_word_count(string $text): int {
  $t = trim($text);
  if ($t === '') return 0;
  $parts = preg_split('/\s+/', $t) ?: [];
  $n = 0;
  foreach ($parts as $p) {
    if (trim((string)$p) !== '') $n++;
  }
  return $n;
}

function sk_ensure_ratings_table(mysqli $conn): void {
  if (!sk_db_has_table($conn, 'service_ratings')) {
    $sql = "
      CREATE TABLE service_ratings (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        service_id BIGINT UNSIGNED NOT NULL,
        user_id BIGINT UNSIGNED NOT NULL,
        rating TINYINT UNSIGNED NOT NULL,
        username VARCHAR(120) NULL,
        review_text TEXT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (id),
        UNIQUE KEY uq_service_user (service_id, user_id),
        KEY idx_service (service_id),
        KEY idx_user (user_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ";
    $conn->query($sql);
    return;
  }

  if (!sk_db_has_column($conn, 'service_ratings', 'username')) {
    $conn->query('ALTER TABLE service_ratings ADD COLUMN username VARCHAR(120) NULL');
  }
  if (!sk_db_has_column($conn, 'service_ratings', 'review_text')) {
    $conn->query('ALTER TABLE service_ratings ADD COLUMN review_text TEXT NULL');
  }
  if (!sk_db_has_column($conn, 'service_ratings', 'created_at')) {
    $conn->query('ALTER TABLE service_ratings ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP');
  }
  if (!sk_db_has_column($conn, 'service_ratings', 'updated_at')) {
    $conn->query('ALTER TABLE service_ratings ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
  }
  if (!sk_db_has_index($conn, 'service_ratings', 'uq_service_user')) {
    $conn->query('ALTER TABLE service_ratings ADD UNIQUE KEY uq_service_user (service_id, user_id)');
  }
  if (!sk_db_has_index($conn, 'service_ratings', 'idx_service')) {
    $conn->query('ALTER TABLE service_ratings ADD KEY idx_service (service_id)');
  }
  if (!sk_db_has_index($conn, 'service_ratings', 'idx_user')) {
    $conn->query('ALTER TABLE service_ratings ADD KEY idx_user (user_id)');
  }
}

sk_ensure_ratings_table($conn);

$body = sk_read_json_body();
$serviceId = trim((string)($body['service_id'] ?? ($_POST['service_id'] ?? '')));
$userId = trim((string)($body['user_id'] ?? ($_POST['user_id'] ?? '')));
$ratingRaw = $body['rating'] ?? ($_POST['rating'] ?? null);
$username = trim((string)($body['username'] ?? ($_POST['username'] ?? '')));
$reviewText = trim((string)($body['review_text'] ?? ($_POST['review_text'] ?? '')));

if ($serviceId === '') sk_json(400, ['status' => 'error', 'message' => 'service_id_required']);
if ($userId === '') sk_json(400, ['status' => 'error', 'message' => 'user_id_required']);
if ($ratingRaw === null || (string)$ratingRaw === '') sk_json(400, ['status' => 'error', 'message' => 'rating_required']);

$sid = (int)$serviceId;
$uid = (int)$userId;
$rating = (int)$ratingRaw;
if ($sid <= 0) sk_json(400, ['status' => 'error', 'message' => 'invalid_service_id']);
if ($uid <= 0) sk_json(400, ['status' => 'error', 'message' => 'invalid_user_id']);
if ($rating < 1 || $rating > 5) sk_json(400, ['status' => 'error', 'message' => 'invalid_rating']);

if ($username !== '' && mb_strlen($username) > 120) {
  sk_json(400, ['status' => 'error', 'message' => 'username_too_long']);
}
if ($reviewText !== '' && sk_word_count($reviewText) > 100) {
  sk_json(400, ['status' => 'error', 'message' => 'review_too_long']);
}

$stmt = $conn->prepare('
  INSERT INTO service_ratings (service_id, user_id, rating, username, review_text, created_at, updated_at)
  VALUES (?, ?, ?, ?, ?, NOW(), NOW())
  ON DUPLICATE KEY UPDATE
    rating=VALUES(rating),
    username=VALUES(username),
    review_text=VALUES(review_text),
    updated_at=NOW()
');
$stmt->bind_param('iiiss', $sid, $uid, $rating, $username, $reviewText);
$stmt->execute();

$stmt = $conn->prepare('SELECT AVG(rating) avg_rating, COUNT(*) cnt FROM service_ratings WHERE service_id=?');
$stmt->bind_param('i', $sid);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc() ?: [];
$avg = (float)($row['avg_rating'] ?? 0);
$cnt = (int)($row['cnt'] ?? 0);

$my = null;
$stmt = $conn->prepare('SELECT rating FROM service_ratings WHERE service_id=? AND user_id=? LIMIT 1');
$stmt->bind_param('ii', $sid, $uid);
$stmt->execute();
$r = $stmt->get_result()->fetch_assoc();
if ($r) $my = (int)($r['rating'] ?? 0);

$reviews = [];
$stmt = $conn->prepare('
  SELECT user_id, rating, username, review_text, updated_at, created_at
  FROM service_ratings
  WHERE service_id=? AND COALESCE(review_text, "") <> ""
  ORDER BY updated_at DESC
  LIMIT 50
');
$stmt->bind_param('i', $sid);
$stmt->execute();
$res = $stmt->get_result();
while ($rev = $res->fetch_assoc()) {
  $reviews[] = $rev;
}

sk_json(200, [
  'status' => 'success',
  'data' => [
    'average' => $avg,
    'count' => $cnt,
    'my_rating' => $my,
  ],
  'reviews' => $reviews,
]);
