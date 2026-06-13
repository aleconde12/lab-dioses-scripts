<?php
require_once "config.php";

if (isset($_SESSION["empleado_id"])) {
    header("Location: dashboard.php");
    exit;
}
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Login Ciber</title>
    <style>
        body {
            font-family: Arial;
            background: #dcdcdc;
            color: #111;
            margin: 40px;
        }

        form {
            background: #f3f3f3;
            padding: 20px;
            border-radius: 8px;
            width: 300px;
        }

        input, button {
            display: block;
            margin: 10px 0;
            padding: 8px;
            width: 95%;
        }
    </style>
</head>
<body>

<h1>Cyber Dioses</h1>
<h2>Ingreso al sistema</h2>

<form method="POST" action="login.php">
    <label>Usuario</label>
    <input type="text" name="usuario" required>

    <label>Password</label>
    <input type="password" name="password" required>

    <button type="submit">Ingresar</button>
</form>

<p>Admin: <b>admin / admin123</b></p>
<p>Empleado: <b>empleado / empleado123</b></p>

</body>
</html>