<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap_json.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
require_once __DIR__ . '/db_connect.php';

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
$channel = strtolower(trim((string)($body['channel'] ?? ($_POST['channel'] ?? ''))));
$phoneRaw = trim((string)($body['phone'] ?? ($_POST['phone'] ?? '')));
$otp = trim((string)($body['otp'] ?? ($_POST['otp'] ?? '')));

if (!in_array($channel, ['sms', 'whatsapp'], true) || $phoneRaw === '' || $otp === '') {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_request']);
}

$norm = sk_normalize_india_phone($phoneRaw);
if ($norm === null) sk_json(400, ['status' => 'error', 'message' => 'invalid_phone']);
$phoneDb = $norm['db'];

if (preg_match('/^\d{4,10}$/', $otp) !== 1) {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_otp']);
}

try {
  $otpHasUsedAt = sk_db_has_column($conn, 'otp_codes', 'used_at');
  $otpHasAttempts = sk_db_has_column($conn, 'otp_codes', 'attempts');

  $sql = 'SELECT id, code_hash, expires_at' . ($otpHasAttempts ? ', attempts' : '') .
    ' FROM otp_codes WHERE channel=? AND destination=?' . ($otpHasUsedAt ? ' AND used_at IS NULL' : '') .
    ' ORDER BY id DESC LIMIT 1';
  $stmt = $conn->prepare($sql);
  $stmt->bind_param('ss', $channel, $phoneDb);
  $stmt->execute();
  $row = $stmt->get_result()->fetch_assoc();
} catch (Throwable $e) {
  sk_json(500, ['status' => 'error', 'message' => 'server_error']);
}

if (!$row) sk_json(401, ['status' => 'error', 'message' => 'otp_not_found']);
if (strtotime($row['expires_at']) < time()) sk_json(401, ['status' => 'error', 'message' => 'otp_expired']);
$attempts = isset($row['attempts']) ? (int)$row['attempts'] : 0;
if ($attempts >= 5) sk_json(429, ['status' => 'error', 'message' => 'too_many_attempts']);

if (!hash_equals((string)$row['code_hash'], hash('sha256', $otp))) {
  try {
    if (sk_db_has_column($conn, 'otp_codes', 'attempts')) {
      $stmt = $conn->prepare('UPDATE otp_codes SET attempts = attempts + 1 WHERE id=?');
      $id = (int)$row['id'];
      $stmt->bind_param('i', $id);
      $stmt->execute();
    }
  } catch (Throwable $e) {
  }
  sk_json(401, ['status' => 'error', 'message' => 'otp_invalid']);
}

try {
  if (sk_db_has_column($conn, 'otp_codes', 'used_at')) {
    $stmt = $conn->prepare('UPDATE otp_codes SET used_at = NOW() WHERE id=?');
    $id = (int)$row['id'];
    $stmt->bind_param('i', $id);
    $stmt->execute();
  } else {
    $stmt = $conn->prepare('DELETE FROM otp_codes WHERE id=?');
    $id = (int)$row['id'];
    $stmt->bind_param('i', $id);
    $stmt->execute();
  }
} catch (Throwable $e) {
}

$user = null;
$userIdCol = null;
$userNameCol = null;
$userEmailCol = null;
$userPhoneCol = null;
$userRoleCol = null;
$userCreatedAtCol = null;

try {
  if (sk_db_has_table($conn, 'users')) {
    foreach (['id', 'user_id'] as $c) {
      if (sk_db_has_column($conn, 'users', $c)) {
        $userIdCol = $c;
        break;
      }
    }
    foreach (['name', 'full_name', 'username'] as $c) {
      if (sk_db_has_column($conn, 'users', $c)) {
        $userNameCol = $c;
        break;
      }
    }
    if (sk_db_has_column($conn, 'users', 'email')) $userEmailCol = 'email';
    foreach (['phone', 'mobile', 'number'] as $c) {
      if (sk_db_has_column($conn, 'users', $c)) {
        $userPhoneCol = $c;
        break;
      }
    }
    foreach (['role', 'user_type', 'type'] as $c) {
      if (sk_db_has_column($conn, 'users', $c)) {
        $userRoleCol = $c;
        break;
      }
    }
    foreach (['created_at', 'createdAt', 'created_on'] as $c) {
      if (sk_db_has_column($conn, 'users', $c)) {
        $userCreatedAtCol = $c;
        break;
      }
    }

    if ($userPhoneCol !== null) {
      $cols = [];
      if ($userIdCol !== null) $cols[] = $userIdCol;
      if ($userNameCol !== null) $cols[] = $userNameCol;
      if ($userEmailCol !== null) $cols[] = $userEmailCol;
      $cols[] = $userPhoneCol;
      if ($userRoleCol !== null) $cols[] = $userRoleCol;
      $cols = array_values(array_unique($cols));

      $stmt = $conn->prepare('SELECT ' . implode(', ', $cols) . ' FROM users WHERE ' . $userPhoneCol . '=? LIMIT 1');
      $stmt->bind_param('s', $phoneDb);
      $stmt->execute();
      $user = $stmt->get_result()->fetch_assoc();

      if (!$user) {
        $now = date('Y-m-d H:i:s');
        $insCols = [$userPhoneCol];
        $insVals = ['?'];
        $types = 's';
        $params = [$phoneDb];

        if ($userNameCol !== null) {
          $insCols[] = $userNameCol;
          $insVals[] = '?';
          $types .= 's';
          $params[] = '';
        }
        if ($userEmailCol !== null) {
          $insCols[] = $userEmailCol;
          $insVals[] = '?';
          $types .= 's';
          $params[] = '';
        }
        if (sk_db_has_column($conn, 'users', 'password_hash')) {
          $insCols[] = 'password_hash';
          $insVals[] = '?';
          $types .= 's';
          $params[] = '';
        } elseif (sk_db_has_column($conn, 'users', 'password')) {
          $insCols[] = 'password';
          $insVals[] = '?';
          $types .= 's';
          $params[] = '';
        }
        if ($userRoleCol !== null) {
          $insCols[] = $userRoleCol;
          $insVals[] = '?';
          $types .= 's';
          $params[] = 'user';
        }
        if ($userCreatedAtCol !== null) {
          $insCols[] = $userCreatedAtCol;
          $insVals[] = '?';
          $types .= 's';
          $params[] = $now;
        }

        $stmt = $conn->prepare('INSERT INTO users (' . implode(', ', $insCols) . ') VALUES (' . implode(', ', $insVals) . ')');
        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $newId = $conn->insert_id;

        $user = [$userPhoneCol => $phoneDb];
        if ($userIdCol !== null) $user[$userIdCol] = (string)$newId;
        if ($userNameCol !== null) $user[$userNameCol] = '';
        if ($userEmailCol !== null) $user[$userEmailCol] = '';
        if ($userRoleCol !== null) $user[$userRoleCol] = 'user';
      }
    }
  }
} catch (Throwable $e) {
  $user = null;
}

if (!is_array($user)) {
  $user = ['id' => '0', 'name' => '', 'email' => '', 'phone' => $phoneDb, 'role' => 'user'];
  $userIdCol = 'id';
  $userNameCol = 'name';
  $userEmailCol = 'email';
  $userPhoneCol = 'phone';
  $userRoleCol = 'role';
}

$token = bin2hex(random_bytes(32));
$tokenHash = hash('sha256', $token);
$expiresAt = date('Y-m-d H:i:s', time() + 60 * 60 * 24 * 30);

try {
  if (sk_db_has_table($conn, 'user_sessions')
    && sk_db_has_column($conn, 'user_sessions', 'user_id')
    && sk_db_has_column($conn, 'user_sessions', 'token_hash')
    && sk_db_has_column($conn, 'user_sessions', 'expires_at')
  ) {
    $uidRaw = $userIdCol !== null ? ($user[$userIdCol] ?? null) : ($user['id'] ?? null);
    $userId = (int)($uidRaw ?? 0);
    $createdAtNow = date('Y-m-d H:i:s');
    $stmt = $conn->prepare('INSERT INTO user_sessions (user_id, token_hash, expires_at, created_at) VALUES (?, ?, ?, ?)');
    $stmt->bind_param('isss', $userId, $tokenHash, $expiresAt, $createdAtNow);
    $stmt->execute();
  }
} catch (Throwable $e) {
}

$respId = (string)($userIdCol !== null ? ($user[$userIdCol] ?? '') : ($user['id'] ?? ''));
$respName = $userNameCol !== null ? (string)($user[$userNameCol] ?? '') : (string)($user['name'] ?? '');
$respEmail = $userEmailCol !== null ? (string)($user[$userEmailCol] ?? '') : (string)($user['email'] ?? '');
$respMobile = $userPhoneCol !== null ? (string)($user[$userPhoneCol] ?? '') : (string)($user['phone'] ?? '');
$respRole = $userRoleCol !== null ? (string)($user[$userRoleCol] ?? 'user') : (string)($user['role'] ?? 'user');

sk_json(200, [
  'status' => 'success',
  'token' => $token,
  'user' => [
    'id' => $respId,
    'name' => $respName,
    'email' => $respEmail,
    'mobile' => $respMobile,
    'role' => $respRole === '' ? 'user' : $respRole,
  ],
]);
