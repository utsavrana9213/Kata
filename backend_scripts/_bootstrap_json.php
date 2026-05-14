<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

ini_set('display_errors', '0');
ini_set('display_startup_errors', '0');
error_reporting(E_ALL);

set_error_handler(static function (int $severity, string $message, string $file, int $line): bool {
  throw new ErrorException($message, 0, $severity, $file, $line);
});

set_exception_handler(static function (Throwable $e): void {
  error_log('OTP API exception: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
  http_response_code(500);
  echo json_encode(['status' => 'error', 'message' => 'server_error']);
  exit;
});

register_shutdown_function(static function (): void {
  $err = error_get_last();
  if (!$err) return;
  $fatalTypes = [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR];
  if (!in_array($err['type'] ?? 0, $fatalTypes, true)) return;
  error_log('OTP API fatal: ' . ($err['message'] ?? 'fatal') . ' in ' . ($err['file'] ?? '?') . ':' . ($err['line'] ?? 0));
  if (!headers_sent()) {
    header('Content-Type: application/json; charset=utf-8');
  }
  http_response_code(500);
  echo json_encode(['status' => 'error', 'message' => 'server_error']);
});

function sk_read_json_body(): array {
  $raw = file_get_contents('php://input');
  if ($raw === false || trim($raw) === '') return [];
  $decoded = json_decode($raw, true);
  return is_array($decoded) ? $decoded : [];
}

function sk_json(int $code, array $payload): void {
  http_response_code($code);
  echo json_encode($payload);
  exit;
}

function sk_normalize_india_phone(string $input): ?array {
  $digits = preg_replace('/\D+/', '', $input);
  if (!$digits) return null;

  if (strlen($digits) === 12 && str_starts_with($digits, '91')) {
    $digits = substr($digits, 2);
  }
  if (strlen($digits) !== 10) return null;

  return [
    'db' => $digits,
    'e164' => '+91' . $digits,
  ];
}

