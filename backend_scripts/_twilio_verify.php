<?php
declare(strict_types=1);

function sk_load_env(): void {
  $candidates = [
    __DIR__ . '/.env',
    __DIR__ . '/../.env',
    __DIR__ . '/../../.env',
    __DIR__ . '/../../../.env',
  ];
  $path = null;
  foreach ($candidates as $p) {
    if (is_file($p)) {
      $path = $p;
      break;
    }
  }
  if ($path === null) return;
  $lines = file($path, FILE_IGNORE_NEW_LINES);
  if ($lines === false) return;
  foreach ($lines as $line) {
    $line = trim($line);
    if ($line === '') continue;
    if (str_starts_with($line, '#')) continue;
    $pos = strpos($line, '=');
    if ($pos === false) continue;
    $key = trim(substr($line, 0, $pos));
    $val = trim(substr($line, $pos + 1));
    if ($key === '') continue;
    $val = trim($val, "\"'");
    if (getenv($key) === false) {
      putenv($key . '=' . $val);
      $_ENV[$key] = $val;
    }
  }
}

function sk_json_response(int $code, array $payload): void {
  http_response_code($code);
  header('Content-Type: application/json; charset=utf-8');
  echo json_encode($payload);
  exit;
}

function sk_read_json_body(): array {
  $raw = file_get_contents('php://input');
  if ($raw === false || trim($raw) === '') return [];
  $decoded = json_decode($raw, true);
  return is_array($decoded) ? $decoded : [];
}

function sk_normalize_india_phone(string $input): ?string {
  $p = preg_replace('/[^\d\+]/', '', $input);
  if ($p === null) return null;
  $p = trim($p);
  if ($p === '') return null;
  if (str_starts_with($p, '+')) {
    if (preg_match('/^\+\d{10,15}$/', $p) === 1) return $p;
    return null;
  }
  if (preg_match('/^\d{10}$/', $p) === 1) return '+91' . $p;
  if (preg_match('/^91\d{10}$/', $p) === 1) return '+' . $p;
  if (preg_match('/^\d{11,15}$/', $p) === 1) return '+' . $p;
  return null;
}

function sk_twilio_verify_start(string $toE164, string $channel): array {
  sk_load_env();
  $accountSid = getenv('TWILIO_ACCOUNT_SID') ?: '';
  $authToken = getenv('TWILIO_AUTH_TOKEN') ?: '';
  $serviceSid = getenv('TWILIO_VERIFY_SERVICE_SID') ?: '';

  if ($accountSid === '' || $authToken === '' || $serviceSid === '') {
    return ['ok' => false, 'status' => 500, 'message' => 'Server not configured'];
  }

  $url = "https://verify.twilio.com/v2/Services/" . rawurlencode($serviceSid) . "/Verifications";
  $payload = http_build_query(['To' => $toE164, 'Channel' => $channel]);

  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
  curl_setopt($ch, CURLOPT_USERPWD, $accountSid . ':' . $authToken);
  curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);

  $body = curl_exec($ch);
  $httpCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
  $err = curl_error($ch);
  curl_close($ch);

  if ($body === false) {
    return ['ok' => false, 'status' => 502, 'message' => 'Twilio error: ' . $err];
  }

  $data = json_decode($body, true);
  if (!is_array($data)) {
    return ['ok' => false, 'status' => 502, 'message' => 'Invalid Twilio response'];
  }

  if ($httpCode >= 200 && $httpCode < 300) {
    return ['ok' => true, 'status' => 200, 'data' => $data];
  }

  $msg = $data['message'] ?? 'Twilio request failed';
  return ['ok' => false, 'status' => 400, 'message' => $msg, 'data' => $data];
}

function sk_twilio_verify_check(string $toE164, string $code): array {
  sk_load_env();
  $accountSid = getenv('TWILIO_ACCOUNT_SID') ?: '';
  $authToken = getenv('TWILIO_AUTH_TOKEN') ?: '';
  $serviceSid = getenv('TWILIO_VERIFY_SERVICE_SID') ?: '';

  if ($accountSid === '' || $authToken === '' || $serviceSid === '') {
    return ['ok' => false, 'status' => 500, 'message' => 'Server not configured'];
  }

  $url = "https://verify.twilio.com/v2/Services/" . rawurlencode($serviceSid) . "/VerificationCheck";
  $payload = http_build_query(['To' => $toE164, 'Code' => $code]);

  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
  curl_setopt($ch, CURLOPT_USERPWD, $accountSid . ':' . $authToken);
  curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);

  $body = curl_exec($ch);
  $httpCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
  $err = curl_error($ch);
  curl_close($ch);

  if ($body === false) {
    return ['ok' => false, 'status' => 502, 'message' => 'Twilio error: ' . $err];
  }

  $data = json_decode($body, true);
  if (!is_array($data)) {
    return ['ok' => false, 'status' => 502, 'message' => 'Invalid Twilio response'];
  }

  if ($httpCode >= 200 && $httpCode < 300) {
    return ['ok' => true, 'status' => 200, 'data' => $data];
  }

  $msg = $data['message'] ?? 'Twilio request failed';
  return ['ok' => false, 'status' => 400, 'message' => $msg, 'data' => $data];
}
