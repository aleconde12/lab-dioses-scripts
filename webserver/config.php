<?php
session_start();

$host = "192.168.100.10";
$user = "webapp_user";
$pass = "WebAppPass123!";
$db   = "laboratorio_db";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Error de conexión a la DB: " . $conn->connect_error);
}

function require_login() {
    if (!isset($_SESSION["empleado_id"])) {
        header("Location: index.php");
        exit;
    }
}

function require_admin() {
    require_login();

    if ($_SESSION["rol"] !== "admin") {
        die("Acceso denegado. Solo admin.");
    }
}
?>
