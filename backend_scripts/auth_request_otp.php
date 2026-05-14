<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap_json.php';
require_once __DIR__ . '/_twilio_messaging.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
require_once __DIR__ . '/db_connect.php';

$body = sk_read_json_body();
$channel = strtolower(trim((string)($body['channel'] ?? ($_POST['channel'] ?? ''))));
$phoneRaw = trim((string)($body['phone'] ?? ($_POST['phone'] ?? '')));

if (!in_array($channel, ['sms', 'whatsapp'], true) || $phoneRaw === '') {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_request']);
}

$norm = sk_normalize_india_phone($phoneRaw);
if ($norm === null) sk_json(400, ['status' => 'error', 'message' => 'invalid_phone']);
$phoneDb = $norm['db'];
$phoneE164 = $norm['e164'];

$stmt = $conn->prepare('SELECT COUNT(*) c FROM otp_codes WHERE destination=? AND created_at >= (NOW() - INTERVAL 15 MINUTE)');
$stmt->bind_param('s', $phoneDb);
$stmt->execute();
$c = (int)$stmt->get_result()->fetch_assoc()['c'];
if ($c >= 5) sk_json(429, ['status' => 'error', 'message' => 'rate_limited']);

$otp = (string)random_int(100000, 999999);
$codeHash = hash('sha256', $otp);
$expiresAt = date('Y-m-d H:i:s', time() + 300);

$stmt = $conn->prepare('INSERT INTO otp_codes (channel, destination, code_hash, expires_at, attempts, created_at) VALUES (?, ?, ?, ?, 0, NOW())');
$stmt->bind_param('ssss', $channel, $phoneDb, $codeHash, $expiresAt);
$stmt->execute();

$msg = 'Your ServeKeen OTP is: ' . $otp;
$send = sk_twilio_send_message($phoneE164, $msg, $channel);
if (!$send['ok']) sk_json(500, ['status' => 'error', 'message' => $send['message'] ?? 'send_failed']);

sk_json(200, ['status' => 'success', 'message' => 'otp_sent']);
