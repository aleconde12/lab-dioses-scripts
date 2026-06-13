<?php
require_once "config.php";

$usuario = $_POST["usuario"] ?? "";
$password = $_POST["password"] ?? "";

$stmt = $conn->prepare("SELECT id, usuario, password, nombre, rol FROM empleados WHERE usuario = ? AND activo = TRUE");
$stmt->bind_param("s", $usuario);
$stmt->execute();

$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $empleado = $result->fetch_assoc();

    if ($password === $empleado["password"]) {
        $_SESSION["empleado_id"] = $empleado["id"];
        $_SESSION["usuario"] = $empleado["usuario"];
        $_SESSION["nombre"] = $empleado["nombre"];
        $_SESSION["rol"] = $empleado["rol"];

        header("Location: dashboard.php");
        exit;
    }
}

echo "Usuario o password incorrecto.";
echo "<br><a href='index.php'>Volver</a>";
?>