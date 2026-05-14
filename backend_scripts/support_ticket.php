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

sk_load_env();

$body = sk_read_json_body();
$subject = trim((string)($body['subject'] ?? ($_POST['subject'] ?? '')));
$message = trim((string)($body['message'] ?? ($_POST['message'] ?? '')));
$userId = trim((string)($body['user_id'] ?? ($_POST['user_id'] ?? '')));
$userEmail = trim((string)($body['user_email'] ?? ($_POST['user_email'] ?? '')));
$userMobile = trim((string)($body['user_mobile'] ?? ($_POST['user_mobile'] ?? '')));

if ($subject === '' || $message === '') {
  sk_json(400, ['status' => 'error', 'message' => 'invalid_request']);
}

$to = getenv('SUPPORT_TICKET_TO') ?: 'utsavrana572@gmail.com';
$from = getenv('SUPPORT_TICKET_FROM') ?: 'no-reply@servekeen.com';

$lines = [];
$lines[] = "New ServeKeen Support Ticket";
$lines[] = "";
$lines[] = "Subject: " . $subject;
if ($userId !== '') $lines[] = "User ID: " . $userId;
if ($userEmail !== '') $lines[] = "User Email: " . $userEmail;
if ($userMobile !== '') $lines[] = "User Mobile: " . $userMobile;
$lines[] = "";
$lines[] = "Message:";
$lines[] = $message;
$bodyText = implode("\n", $lines);

$headers = [];
$headers[] = "MIME-Version: 1.0";
$headers[] = "Content-Type: text/plain; charset=UTF-8";
$headers[] = "From: " . $from;
if ($userEmail !== '' && filter_var($userEmail, FILTER_VALIDATE_EMAIL) !== false) {
  $headers[] = "Reply-To: " . $userEmail;
}

$ok = @mail($to, $subject, $bodyText, implode("\r\n", $headers));
if (!$ok) {
  sk_json(500, ['status' => 'error', 'message' => 'mail_failed']);
}

sk_json(200, ['status' => 'success', 'message' => 'ticket_sent']);

