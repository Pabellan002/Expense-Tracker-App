<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

include "connection-pdo.php";

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $operation = $_GET['operation'];
    $json = $_GET['json'];
    
    switch($operation) {
        case "login":
            echo login($json);
            break;
        case "register":
            echo register($json);
            break;
        case "getUserData":
            echo getUserData($json);
            break;
        case "getWalletBalances":
            echo getWalletBalances($json);
            break;
        case "updateWalletBalance":
            echo updateWalletBalance($json);
            break;
    }
} else if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $operation = $_POST['operation'];
    $json = $_POST['json'];
    
    switch($operation) {
        case "updateProfile":
            echo updateProfile($json);
            break;
        case "changePassword":
            echo changePassword($json);
            break;
    }
}

function login($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $sql = "SELECT user_id, username, password, first_name, middle_name, last_name, 
                gender, profile_image FROM tbl_users WHERE username = :username";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":username", $data['username']);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user && password_verify($data['password'], $user['password'])) {
            unset($user['password']);
            return json_encode([$user]);
        } else {
            return json_encode([
                "error" => "Invalid username or password"
            ]);
        }
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}

function register($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $check_sql = "SELECT user_id FROM tbl_users WHERE username = :username";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bindParam(":username", $data['username']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            return json_encode([
                "success" => false,
                "message" => "Username already exists"
            ]);
        }
        
        $hashed_password = password_hash($data['password'], PASSWORD_DEFAULT);
        
        $sql = "INSERT INTO tbl_users(username, password, first_name, middle_name, last_name, gender) 
                VALUES (:username, :password, :first_name, :middle_name, :last_name, :gender)";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":username", $data['username']);
        $stmt->bindParam(":password", $hashed_password);
        $stmt->bindParam(":first_name", $data['first_name']);
        $stmt->bindParam(":middle_name", $data['middle_name']);
        $stmt->bindParam(":last_name", $data['last_name']);
        $stmt->bindParam(":gender", $data['gender']);
        $stmt->execute();

        if ($stmt->rowCount() > 0) {
            return json_encode([
                "success" => true,
                "message" => "Registration successful"
            ]);
        } else {
            return json_encode([
                "success" => false,
                "message" => "Registration failed"
            ]);
        }
    } catch(PDOException $e) {
        return json_encode([
            "success" => false,
            "message" => $e->getMessage()
        ]);
    }
}

function getUserData($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $sql = "SELECT user_id, username, first_name, middle_name, last_name, gender, profile_image 
                FROM tbl_users WHERE user_id = :user_id";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id'], PDO::PARAM_INT);
        $stmt->execute();
        
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        return json_encode($user);
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}

function getWalletBalances($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $sql = "SELECT 
                pm.method_id,
                pm.name,
                COALESCE(wb.balance, 0) as balance
                FROM tbl_payment_methods pm
                LEFT JOIN tbl_wallet_balances wb 
                    ON wb.payment_method_id = pm.method_id 
                    AND wb.user_id = :user_id
                ORDER BY pm.name";
                
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id'], PDO::PARAM_INT);
        $stmt->execute();
        
        $balances = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return json_encode($balances);
    } catch (PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}

function updateWalletBalance($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $conn->beginTransaction();
        $sql = "SELECT balance FROM tbl_wallet_balances 
                WHERE user_id = :user_id AND payment_method_id = :payment_method_id";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id'], PDO::PARAM_INT);
        $stmt->bindParam(":payment_method_id", $data['payment_method_id'], PDO::PARAM_INT);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            $sql = "UPDATE tbl_wallet_balances 
                   SET balance = balance + :amount,
                       updated_at = CURRENT_TIMESTAMP 
                   WHERE user_id = :user_id AND payment_method_id = :payment_method_id";
            $stmt = $conn->prepare($sql);
            $stmt->bindParam(":amount", $data['amount'], PDO::PARAM_STR);
            $stmt->bindParam(":user_id", $data['user_id'], PDO::PARAM_INT);
            $stmt->bindParam(":payment_method_id", $data['payment_method_id'], PDO::PARAM_INT);
        } else {
            $sql = "INSERT INTO tbl_wallet_balances (user_id, payment_method_id, balance) 
                   VALUES (:user_id, :payment_method_id, :amount)";
            $stmt = $conn->prepare($sql);
            $stmt->bindParam(":user_id", $data['user_id'], PDO::PARAM_INT);
            $stmt->bindParam(":payment_method_id", $data['payment_method_id'], PDO::PARAM_INT);
            $stmt->bindParam(":amount", $data['amount'], PDO::PARAM_STR);
        }
        
        $stmt->execute();
        $conn->commit();
        
        return json_encode([
            "success" => true,
            "message" => "Wallet balance updated successfully"
        ]);
    } catch (PDOException $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        return json_encode([
            "success" => false,
            "message" => $e->getMessage()
        ]);
    }
}

function updateProfile($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $check_sql = "SELECT user_id FROM tbl_users 
                     WHERE username = :username AND user_id != :user_id";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bindParam(":username", $data['username']);
        $check_stmt->bindParam(":user_id", $data['user_id']);
        $check_stmt->execute();
        
        if ($check_stmt->rowCount() > 0) {
            return json_encode([
                "success" => false,
                "message" => "Username is already taken"
            ]);
        }

        $profile_image = null;
        if (isset($data['image_base64']) && !empty($data['image_base64'])) {
            $image_data = base64_decode($data['image_base64']);
            $file_name = uniqid() . '.jpg';
            $upload_path = 'uploads/' . $file_name;
            
            if (!is_dir('uploads')) {
                mkdir('uploads', 0777, true);
            }
            
            if (file_put_contents($upload_path, $image_data)) {
                $profile_image = $upload_path;
            }
        }
        
        $sql = "UPDATE tbl_users SET 
                username = :username,
                first_name = :first_name,
                middle_name = :middle_name,
                last_name = :last_name,
                gender = :gender";
        
        if ($profile_image !== null) {
            $old_image_sql = "SELECT profile_image FROM tbl_users WHERE user_id = :user_id";
            $old_image_stmt = $conn->prepare($old_image_sql);
            $old_image_stmt->bindParam(":user_id", $data['user_id']);
            $old_image_stmt->execute();
            $old_image = $old_image_stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($old_image && $old_image['profile_image'] && file_exists($old_image['profile_image'])) {
                unlink($old_image['profile_image']);
            }
            
            $sql .= ", profile_image = :profile_image";
        }
        
        $sql .= " WHERE user_id = :user_id";
                
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":username", $data['username']);
        $stmt->bindParam(":first_name", $data['first_name']);
        $stmt->bindParam(":middle_name", $data['middle_name']);
        $stmt->bindParam(":last_name", $data['last_name']);
        $stmt->bindParam(":gender", $data['gender']);
        $stmt->bindParam(":user_id", $data['user_id']);
        
        if ($profile_image !== null) {
            $stmt->bindParam(":profile_image", $profile_image);
        }
        
        $stmt->execute();
        
        $select_sql = "SELECT user_id, username, first_name, middle_name, last_name, 
                             gender, profile_image 
                      FROM tbl_users WHERE user_id = :user_id";
        $select_stmt = $conn->prepare($select_sql);
        $select_stmt->bindParam(":user_id", $data['user_id']);
        $select_stmt->execute();
        $user = $select_stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user) {
            return json_encode([
                "success" => true,
                "message" => "Profile updated successfully",
                "user" => $user
            ]);
        } else {
            return json_encode([
                "success" => false,
                "message" => "User not found"
            ]);
        }
    } catch(PDOException $e) {
        return json_encode([
            "success" => false,
            "message" => $e->getMessage()
        ]);
    }
}

function changePassword($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $check_sql = "SELECT password FROM tbl_users WHERE user_id = :user_id";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bindParam(":user_id", $data['user_id']);
        $check_stmt->execute();
        $user = $check_stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user || !password_verify($data['current_password'], $user['password'])) {
            return json_encode([
                "success" => false,
                "message" => "Current password is incorrect"
            ]);
        }
        
        $hashed_password = password_hash($data['new_password'], PASSWORD_DEFAULT);
        $sql = "UPDATE tbl_users SET password = :password 
                WHERE user_id = :user_id";
                
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":password", $hashed_password);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->execute();
        
        return json_encode([
            "success" => true,
            "message" => "Password updated successfully"
        ]);
    } catch(PDOException $e) {
        return json_encode([
            "success" => false,
            "message" => $e->getMessage()
        ]);
    }
}

function updateExistingPasswords() {
    global $conn;
    try {
        $sql = "SELECT user_id, password FROM tbl_users";
        $stmt = $conn->query($sql);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        foreach ($users as $user) {
            if (!password_get_info($user['password'])['algo']) {
                $hashed_password = password_hash($user['password'], PASSWORD_DEFAULT);
                $update_sql = "UPDATE tbl_users SET password = :password WHERE user_id = :user_id";
                $update_stmt = $conn->prepare($update_sql);
                $update_stmt->bindParam(":password", $hashed_password);
                $update_stmt->bindParam(":user_id", $user['user_id']);
                $update_stmt->execute();
            }
        }
        return true;
    } catch(PDOException $e) {
        return false;
    }
} 