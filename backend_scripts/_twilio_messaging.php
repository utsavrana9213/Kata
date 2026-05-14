<?php
declare(strict_types=1);

require_once __DIR__ . '/_bootstrap_json.php';

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
    if ($line === '' || str_starts_with($line, '#')) continue;
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

function sk_twilio_send_message(string $to, string $body, string $channel): array {
  sk_load_env();

  $sid = getenv('TWILIO_ACCOUNT_SID') ?: '';
  $token = getenv('TWILIO_AUTH_TOKEN') ?: '';
  $smsFrom = getenv('TWILIO_SMS_FROM') ?: '';
  $waFrom = getenv('TWILIO_WHATSAPP_FROM') ?: '';

  if ($sid === '' || $token === '') {
    return ['ok' => false, 'message' => 'twilio_not_configured'];
  }

  if (!function_exists('curl_init')) {
    return ['ok' => false, 'message' => 'php_curl_missing'];
  }

  if ($channel === 'sms') {
    if ($smsFrom === '') return ['ok' => false, 'message' => 'twilio_sms_from_missing'];
    $from = $smsFrom;
    $toFinal = $to;
  } else {
    if ($waFrom === '') return ['ok' => false, 'message' => 'twilio_whatsapp_from_missing'];
    $from = $waFrom;
    if (!str_starts_with($from, 'whatsapp:')) $from = 'whatsapp:' . $from;
    $toFinal = $to;
    if (!str_starts_with($toFinal, 'whatsapp:')) $toFinal = 'whatsapp:' . $toFinal;
  }

  $url = 'https://api.twilio.com/2010-04-01/Accounts/' . rawurlencode($sid) . '/Messages.json';
  $post = http_build_query(['To' => $toFinal, 'From' => $from, 'Body' => $body]);

  $ch = curl_init($url);
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
  curl_setopt($ch, CURLOPT_USERPWD, $sid . ':' . $token);
  curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);

  $resp = curl_exec($ch);
  $httpCode = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
  $err = curl_error($ch);
  curl_close($ch);

  if ($resp === false) return ['ok' => false, 'message' => 'twilio_error', 'detail' => $err];

  $data = json_decode((string)$resp, true);
  if ($httpCode >= 200 && $httpCode < 300) return ['ok' => true, 'data' => $data];

  $msg = is_array($data) ? ($data['message'] ?? 'twilio_error') : 'twilio_error';
  return ['ok' => false, 'message' => $msg];
}
