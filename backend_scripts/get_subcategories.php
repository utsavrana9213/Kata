<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

include 'db_connection.php';

$input = json_decode(file_get_contents('php://input'), true);
$category_id = '';
if (is_array($input) && isset($input['category_id'])) {
    $category_id = trim((string)$input['category_id']);
} elseif (isset($_POST['category_id'])) {
    $category_id = trim((string)$_POST['category_id']);
}

if ($category_id === '') {
    echo json_encode(['status' => 'error', 'message' => 'Category ID is required']);
    exit();
}

$category_id = $conn->real_escape_string($category_id);

$sql = "SELECT id, cat_id, subname FROM subcategorys WHERE cat_id = '$category_id' ORDER BY subname ASC";
$result = $conn->query($sql);

$subcategories = [];
if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $subcategories[] = $row;
    }
}

echo json_encode(['status' => 'success', 'subcategories' => $subcategories]);

$conn->close();