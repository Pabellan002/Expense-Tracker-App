<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

class Expense {
    function addExpense($json){
        include "connection-pdo.php";

        $json = json_decode($json, true);
    
        $sql = "INSERT INTO tbl_expenses(user_id, category_id, amount, description, expense_date) ";
        $sql .= "VALUES (:user_id, :category_id, :amount, :description, :expense_date)";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $json['user_id']);
        $stmt->bindParam(":category_id", $json['category_id']);
        $stmt->bindParam(":amount", $json['amount']);
        $stmt->bindParam(":description", $json['description']);
        $stmt->bindParam(":expense_date", $json['expense_date']);
        $stmt->execute();
        $returnValue = $stmt->rowCount() > 0 ? 1 : 0;
        unset($conn); 
        unset($stmt);
        return json_encode($returnValue);
    }

    function getUserExpenses($json){
        include "connection-pdo.php";

        $json = json_decode($json, true);

        $sql = "SELECT e.*, c.category_name, c.category_icon FROM tbl_expenses e ";
        $sql .= "JOIN tbl_categories c ON e.category_id = c.category_id ";
        $sql .= "WHERE e.user_id = :user_id ORDER BY e.expense_date DESC";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":user_id", $json['user_id']);
        $stmt->execute();
        $returnValue = $stmt->fetchAll(PDO::FETCH_ASSOC);
        unset($conn); 
        unset($stmt);
        return json_encode($returnValue);
    }

    function updateExpense($json){
        include "connection-pdo.php";

        $json = json_decode($json, true);
    
        $sql = "UPDATE tbl_expenses SET category_id = :category_id, ";
        $sql .= "amount = :amount, description = :description, ";
        $sql .= "expense_date = :expense_date WHERE expense_id = :expense_id AND user_id = :user_id";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":category_id", $json['category_id']);
        $stmt->bindParam(":amount", $json['amount']);
        $stmt->bindParam(":description", $json['description']);
        $stmt->bindParam(":expense_date", $json['expense_date']);
        $stmt->bindParam(":expense_id", $json['expense_id']);
        $stmt->bindParam(":user_id", $json['user_id']);
        $stmt->execute();
        $returnValue = $stmt->rowCount() > 0 ? 1 : 0;
        unset($conn); 
        unset($stmt);
        return json_encode($returnValue);
    }

    function deleteExpense($json){
        include "connection-pdo.php";

        $json = json_decode($json, true);
    
        $sql = "DELETE FROM tbl_expenses WHERE expense_id = :expense_id AND user_id = :user_id";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":expense_id", $json['expense_id']);
        $stmt->bindParam(":user_id", $json['user_id']);
        $stmt->execute();
        $returnValue = $stmt->rowCount() > 0 ? 1 : 0;
        unset($conn); 
        unset($stmt);
        return json_encode($returnValue);
    }
}

if ($_SERVER['REQUEST_METHOD'] == 'GET'){
    $operation = $_GET['operation'];
    $json = $_GET['json'];
} else if($_SERVER['REQUEST_METHOD'] == 'POST'){
    $operation = $_POST['operation'];
    $json = $_POST['json'];
}

$expense = new Expense();
switch($operation){
    case "addExpense":
        echo $expense->addExpense($json);
        break;
    case "getUserExpenses":
        echo $expense->getUserExpenses($json);
        break;
    case "updateExpense":
        echo $expense->updateExpense($json);
        break;
    case "deleteExpense":
        echo $expense->deleteExpense($json);
        break;
}
?>