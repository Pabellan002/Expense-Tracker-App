<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

// Enable error reporting for debugging
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Create a log file for debugging
$log_file = 'upload_log.txt';
file_put_contents($log_file, "=== New Upload Request: " . date('Y-m-d H:i:s') . " ===\n", FILE_APPEND);
file_put_contents($log_file, "POST data: " . print_r($_POST, true) . "\n", FILE_APPEND);
file_put_contents($log_file, "FILES data: " . print_r($_FILES, true) . "\n", FILE_APPEND);

// Database connection
$servername = "localhost";
$username = "root";  // Default XAMPP username
$password = "";      // Default XAMPP password (empty)
$dbname = "expense_db";   // Your database name

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    file_put_contents($log_file, "Database connection failed: " . $conn->connect_error . "\n", FILE_APPEND);
    die(json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $conn->connect_error
    ]));
}

file_put_contents($log_file, "Database connected successfully\n", FILE_APPEND);

// Check if user_id is provided
if (!isset($_POST['user_id']) || empty($_POST['user_id'])) {
    file_put_contents($log_file, "User ID is missing\n", FILE_APPEND);
    die(json_encode([
        'success' => false,
        'message' => 'User ID is required'
    ]));
}

$user_id = $_POST['user_id'];
file_put_contents($log_file, "Processing upload for user ID: $user_id\n", FILE_APPEND);

// Check if file was uploaded
if (!isset($_FILES['profile_image']) || $_FILES['profile_image']['error'] != 0) {
    $error_code = isset($_FILES['profile_image']) ? $_FILES['profile_image']['error'] : 'No file uploaded';
    file_put_contents($log_file, "File upload error: $error_code\n", FILE_APPEND);
    die(json_encode([
        'success' => false,
        'message' => 'No file uploaded or upload error: ' . $error_code
    ]));
}

// Create uploads directory if it doesn't exist
$upload_dir = '../uploads/profile_images/';
if (!file_exists($upload_dir)) {
    if (!mkdir($upload_dir, 0777, true)) {
        file_put_contents($log_file, "Failed to create directory: $upload_dir\n", FILE_APPEND);
        die(json_encode([
            'success' => false,
            'message' => 'Failed to create upload directory'
        ]));
    }
    file_put_contents($log_file, "Created directory: $upload_dir\n", FILE_APPEND);
}

// Generate a unique filename
$file_extension = pathinfo($_FILES['profile_image']['name'], PATHINFO_EXTENSION);
$filename = 'profile_' . $user_id . '_' . time() . '.' . $file_extension;
$target_file = $upload_dir . $filename;
file_put_contents($log_file, "Target file: $target_file\n", FILE_APPEND);

// Move the uploaded file
if (move_uploaded_file($_FILES['profile_image']['tmp_name'], $target_file)) {
    file_put_contents($log_file, "File uploaded successfully to: $target_file\n", FILE_APPEND);
    
    // Get the server URL
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'];
    $image_url = "$protocol://$host/uploads/profile_images/$filename";
    file_put_contents($log_file, "Image URL: $image_url\n", FILE_APPEND);
    
    // Update the user's profile_image field in the database
    $stmt = $conn->prepare("UPDATE users SET profile_image = ? WHERE user_id = ?");
    $stmt->bind_param("si", $image_url, $user_id);
    
    if ($stmt->execute()) {
        file_put_contents($log_file, "Database updated successfully\n", FILE_APPEND);
        echo json_encode([
            'success' => true,
            'message' => 'Profile image updated successfully',
            'image_url' => $image_url
        ]);
    } else {
        file_put_contents($log_file, "Database update failed: " . $stmt->error . "\n", FILE_APPEND);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to update database: ' . $stmt->error
        ]);
    }
    
    $stmt->close();
} else {
    file_put_contents($log_file, "Failed to move uploaded file from: " . $_FILES['profile_image']['tmp_name'] . " to: $target_file\n", FILE_APPEND);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to move uploaded file'
    ]);
}

$conn->close();
file_put_contents($log_file, "=== End of request ===\n\n", FILE_APPEND);
?> 