<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

include "connection-pdo.php";

if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $operation = $_GET['operation'];
    $json = $_GET['json'];
    
    switch($operation) {
        case "getCategories":
            echo getCategories($json);
            break;
        case "getSubcategories":
            echo getSubcategories($json);
            break;
        case "getPaymentMethods":
            echo getPaymentMethods();
            break;
        case "getTransactions":
            echo getTransactions($json);
            break;
        case "getCategoryBreakdown":
            echo getCategoryBreakdown($json);
            break;
        case "getMonthlyTrends":
            echo getMonthlyTrends($json);
            break;
        case "getReports":
            echo getReports($json);
            break;
        case "getCategoryStats": 
            echo getCategoryStats($json);
            break;
        case "deleteTransaction":
            echo deleteTransaction($json);
            break;
        case 'deleteWalletBalance':
            echo deleteWalletBalance($_GET['json']);
            break;
    }

} else if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $operation = $_POST['operation'];
    $json = $_POST['json'];
    
    switch($operation) {
        case "addTransaction":
            echo addTransaction($json);
            break;
        case "updateTransaction":
            echo updateTransaction($json);
            break;
    }
}
function getPaymentMethods() {
    global $conn;
    
    try {
        $sql = "SELECT * FROM tbl_payment_methods ORDER BY method_id";
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        
        return json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch(PDOException $e) {
        return json_encode([
            "success" => false,
            "error" => $e->getMessage()
        ]);
    }
}
function deleteWalletBalance($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $conn->beginTransaction();

        $sql = "DELETE FROM tbl_wallet_balances 
                WHERE user_id = :user_id 
                AND payment_method_id = :payment_method_id";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id'], PDO::PARAM_INT);
        $stmt->bindParam(":payment_method_id", $data['payment_method_id'], PDO::PARAM_INT);
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to delete wallet balance");
        }
        
        $conn->commit();
        return json_encode([
            "success" => true,
            "message" => "Wallet balance deleted successfully"
        ]);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        return json_encode([
            "success" => false,
            "message" => $e->getMessage()
        ]);
    }
}
function getCategoryStats($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $dateCondition = "";
        switch ($data['period']) {
            case 'month':
                $dateCondition = "AND DATE_FORMAT(t.transaction_date, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')";
                break;
            case 'year':
                $dateCondition = "AND YEAR(t.transaction_date) = YEAR(CURDATE())";
                break;
            case 'all':
                $dateCondition = "";
                break;
        }

        $sql = "SELECT 
                c.category_id,
                c.name as category_name,
                COUNT(t.transaction_id) as transaction_count,
                SUM(t.amount) as total
            FROM tbl_transactions t
            JOIN tbl_categories c ON t.category_id = c.category_id
            WHERE t.user_id = :user_id 
            AND t.type = :type
            $dateCondition
            GROUP BY c.category_id, c.name
            ORDER BY total DESC";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":type", $data['type']);
        $stmt->execute();
        
        return json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}
function getReports($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $dateCondition = "";
        $startDate = "";
        $endDate = "";
        
        switch($data['period']) {
            case 'day':
                $startDate = date('Y-m-d');
                $endDate = date('Y-m-d');
                $dateCondition = "AND DATE(transaction_date) = CURRENT_DATE()";
                break;
            case 'week':
                $startDate = date('Y-m-d', strtotime('monday this week'));
                $endDate = date('Y-m-d', strtotime('sunday this week'));
                $dateCondition = "AND DATE(transaction_date) BETWEEN '$startDate' AND '$endDate'";
                break;
            case 'month':
                $startDate = date('Y-m-01');
                $endDate = date('Y-m-t');
                $dateCondition = "AND DATE(transaction_date) BETWEEN '$startDate' AND '$endDate'";
                break;
        }
        $sql = "SELECT 
                COUNT(*) as count,
                COALESCE(SUM(amount), 0) as total,
                COALESCE(MAX(amount), 0) as highest,
                COALESCE(AVG(amount), 0) as daily_average,
                '$startDate' as start_date,
                '$endDate' as end_date
            FROM tbl_transactions 
            WHERE user_id = :user_id 
            AND type = :type 
            $dateCondition";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":type", $data['type']);
        $stmt->execute();
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);
        $sql = "SELECT 
                c.name,
                COUNT(*) as count,
                COALESCE(SUM(t.amount), 0) as total,
                ROUND((SUM(t.amount) / (SELECT SUM(amount) FROM tbl_transactions 
                    WHERE user_id = :user_id AND type = :type $dateCondition)) * 100, 1) as percentage
            FROM tbl_transactions t
            JOIN tbl_categories c ON t.category_id = c.category_id
            WHERE t.user_id = :user_id 
            AND t.type = :type 
            $dateCondition
            GROUP BY c.category_id, c.name
            ORDER BY total DESC";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":type", $data['type']);
        $stmt->execute();
        $categories = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $sql = "SELECT 
                DATE(transaction_date) as date,
                COUNT(*) as count,
                COALESCE(SUM(amount), 0) as total
            FROM tbl_transactions 
            WHERE user_id = :user_id 
            AND type = :type 
            $dateCondition
            GROUP BY DATE(transaction_date)
            ORDER BY date DESC";
            
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":type", $data['type']);
        $stmt->execute();
        $daily = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $result = [
            'summary' => $summary,
            'category_breakdown' => $categories,
            'daily_breakdown' => $daily,
            'period' => [
                'type' => $data['period'],
                'start_date' => $startDate,
                'end_date' => $endDate
            ]
        ];

        return json_encode($result);
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
} 

function getCategories($json) {
    global $conn;
    $data = json_decode($json, true);
    
    $sql = "SELECT * FROM tbl_categories WHERE type = :type";
    try {
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":type", $data['type']);
        $stmt->execute();
        return json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}

function getSubcategories($json) {
    global $conn;
    $data = json_decode($json, true);
    
    $sql = "SELECT * FROM tbl_subcategories WHERE category_id = :category_id";
    try {
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":category_id", $data['category_id']);
        $stmt->execute();
        return json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}
function getTransactions($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $sql = "SELECT 
                t.*,
                c.name as category_name,
                COALESCE(s.name, '') as subcategory_name,
                p.name as payment_method_name
            FROM tbl_transactions t
            LEFT JOIN tbl_categories c ON t.category_id = c.category_id
            LEFT JOIN tbl_subcategories s ON t.subcategory_id = s.subcategory_id
            LEFT JOIN tbl_payment_methods p ON t.payment_method_id = p.method_id
            WHERE t.user_id = :user_id 
            AND t.type = :type
            AND DATE_FORMAT(t.transaction_date, '%Y-%m') = DATE_FORMAT(:date, '%Y-%m')
            ORDER BY t.transaction_date DESC, t.transaction_id DESC";
            
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":type", $data['type']);
        $stmt->bindParam(":date", $data['date']);
        $stmt->execute();
        
        return json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}


function getWalletBalances($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $sql = "SELECT 
                wb.payment_method_id as method_id,
                pm.name as method_name,
                COALESCE(wb.balance, 0) as balance
            FROM tbl_payment_methods pm
            LEFT JOIN tbl_wallet_balances wb ON pm.method_id = wb.payment_method_id 
                AND wb.user_id = :user_id
            ORDER BY pm.method_id";
            
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->execute();
        
        return json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}

function getCategoryBreakdown($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $sql = "SELECT 
                c.name as category,
                c.category_id,
                SUM(t.amount) as total,
                COUNT(*) as transaction_count
            FROM tbl_transactions t
            JOIN tbl_categories c ON t.category_id = c.category_id
            WHERE t.user_id = :user_id 
            AND t.type = 'expense'
            AND DATE_FORMAT(t.transaction_date, '%Y-%m') = DATE_FORMAT(:date, '%Y-%m')
            GROUP BY c.category_id, c.name
            ORDER BY total DESC";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":date", $data['date']);
        $stmt->execute();
        
        header('Content-Type: application/json');
        return json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch(PDOException $e) {
        return json_encode(["error" => $e->getMessage()]);
    }
}
function updateTransaction($json) {
    global $conn;
    
    try {
        $data = json_decode($json, true);
        if ($data === null) {
            throw new Exception("Invalid JSON data");
        }
        $conn->beginTransaction();
        $check_sql = "SELECT type FROM tbl_transactions WHERE transaction_id = :transaction_id";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bindParam(":transaction_id", $data['transaction_id']);
        $check_stmt->execute();
        $current = $check_stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$current) {
            throw new Exception("Transaction not found");
        }
        $sql = "UPDATE tbl_transactions SET 
                amount = :amount,
                note = :note,
                updated_at = CURRENT_TIMESTAMP
                WHERE transaction_id = :transaction_id";
                
        $stmt = $conn->prepare($sql);
        $amount = abs($data['amount']);
        if ($current['type'] === 'expense') {
            $amount = -$amount;
        }
        
        $stmt->bindParam(":amount", $amount);
        $stmt->bindParam(":note", $data['note']);
        $stmt->bindParam(":transaction_id", $data['transaction_id']);
        $stmt->execute();
        $conn->commit();
        
        return json_encode([
            "success" => true,
            "message" => "Transaction updated successfully"
        ]);
    } catch(Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        return json_encode([
            "success" => false,
            "message" => $e->getMessage()
        ]);
    }
}

function deleteTransaction($json) {
    global $conn;
    error_log("Received JSON: " . $json);
    $data = json_decode($json, true); 
    error_log("Decoded data: " . print_r($data, true));
    
    try {
        $conn->beginTransaction();
        
        $sql = "DELETE FROM tbl_wallet_balances 
                WHERE user_id = :user_id 
                AND payment_method_id = :payment_method_id";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindValue(':user_id', $data['user_id']);
        $stmt->bindValue(':payment_method_id', $data['payment_method_id']);
        $stmt->execute();
        
        $sql = "DELETE FROM tbl_transactions 
                WHERE transaction_id = :transaction_id 
                AND user_id = :user_id";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindValue(':transaction_id', $data['transaction_id']);
        $stmt->bindValue(':user_id', $data['user_id']);
        $stmt->execute();
        $conn->commit();
        return json_encode([
            'success' => true,
            'message' => 'Transaction and wallet balance deleted successfully',
            'debug' => [
                'user_id' => $data['user_id'],
                'transaction_id' => $data['transaction_id'],
                'payment_method_id' => $data['payment_method_id']
            ]
        ]);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        error_log("Delete Transaction Error: " . $e->getMessage());
        return json_encode([
            'success' => false,
            'message' => $e->getMessage(),
            'debug' => [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]
        ]);
    }
}
function addTransaction($json) {
    global $conn;
    $data = json_decode($json, true);
    
    try {
        $conn->beginTransaction();
        if ($data['type'] == 'expense') {
            $balanceQuery = "SELECT balance FROM tbl_wallet_balances 
                           WHERE user_id = :user_id AND payment_method_id = :payment_method_id";
            $stmt = $conn->prepare($balanceQuery);
            $stmt->bindParam(":user_id", $data['user_id']);
            $stmt->bindParam(":payment_method_id", $data['payment_method_id']);
            $stmt->execute();
            
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($result) {
                $currentBalance = $result['balance'];
                if ($currentBalance < $data['amount']) {
                    throw new Exception("Insufficient balance");
                }
            } else {
                if ($data['type'] == 'expense') {
                    throw new Exception("No balance found for this payment method");
                }
            }
        }
        $transactionSql = "INSERT INTO tbl_transactions (
            user_id, 
            type, 
            amount, 
            note, 
            category_id, 
            subcategory_id, 
            payment_method_id, 
            transaction_date
        ) VALUES (:user_id, :type, :amount, :note, :category_id, :subcategory_id, :payment_method_id, :transaction_date)";
        
        $stmt = $conn->prepare($transactionSql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":type", $data['type']);
        $stmt->bindParam(":amount", $data['amount']);
        $stmt->bindParam(":note", $data['note']);
        $stmt->bindParam(":category_id", $data['category_id']);
        $stmt->bindParam(":subcategory_id", $data['subcategory_id']);
        $stmt->bindParam(":payment_method_id", $data['payment_method_id']);
        $stmt->bindParam(":transaction_date", $data['transaction_date']);
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to insert transaction");
        }
        
        $amount = $data['type'] == 'expense' ? -$data['amount'] : $data['amount'];
        
        $updateBalanceSql = "INSERT INTO tbl_wallet_balances 
                            (user_id, payment_method_id, balance, updated_at) 
                            VALUES (:user_id, :payment_method_id, :balance, CURRENT_TIMESTAMP) 
                            ON DUPLICATE KEY UPDATE 
                            balance = balance + :amount,
                            updated_at = CURRENT_TIMESTAMP";
        
        $stmt = $conn->prepare($updateBalanceSql);
        $stmt->bindParam(":user_id", $data['user_id']);
        $stmt->bindParam(":payment_method_id", $data['payment_method_id']);
        $stmt->bindParam(":balance", $amount);
        $stmt->bindParam(":amount", $amount);
        
        if (!$stmt->execute()) {
            throw new Exception("Failed to update balance");
        }
        
        $conn->commit();
        
        return json_encode([
            "success" => true,
            "message" => "Transaction added successfully"
        ]);
        
    } catch (Exception $e) {
        if ($conn->inTransaction()) {
            $conn->rollBack();
        }
        return json_encode([
            "success" => false,
            "message" => $e->getMessage()
        ]);
    }
}
?>