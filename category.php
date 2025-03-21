<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

class Category {
    function getCategories($json){
        include "connection-pdo.php";

        $sql = "SELECT * FROM tbl_categories ORDER BY category_name";
        $stmt = $conn->prepare($sql);
        $stmt->execute();
        $returnValue = $stmt->fetchAll(PDO::FETCH_ASSOC);
        unset($conn); 
        unset($stmt);
        return json_encode($returnValue);
    }
    function addCategory($json){
        include "connection-pdo.php";

        $json = json_decode($json, true);
    
        $sql = "INSERT INTO tbl_categories(category_name, category_icon) ";
        $sql .= "VALUES (:category_name, :category_icon)";
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(":category_name", $json['category_name']);
        $stmt->bindParam(":category_icon", $json['category_icon']);
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

$category = new Category();
switch($operation){
    case "getCategories":
        echo $category->getCategories($json);
        break;
    case "addCategory":
        echo $category->addCategory($json);
        break;
}
?>