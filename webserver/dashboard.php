<?php
require_once "config.php";
require_login();
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Panel Ciber</title>
    <style>
        body {
            font-family: Arial;
            background: #dcdcdc;
            color: #111;
            margin: 40px;
        }

        a {
            display: block;
            margin: 12px 0;
            color: #000;
            font-weight: bold;
        }

        .box {
            background: #f3f3f3;
            padding: 20px;
            border-radius: 8px;
            width: 400px;
        }
    </style>
</head>
<body>

<div class="box">
    <h1>Panel del Ciber</h1>

    <p>Usuario: <b><?php echo $_SESSION["nombre"]; ?></b></p>
    <p>Rol: <b><?php echo $_SESSION["rol"]; ?></b></p>

    <a href="clientes.php">Gestionar clientes</a>
    <a href="sesiones.php">Cargar / finalizar horas</a>

    <?php if ($_SESSION["rol"] === "admin"): ?>
        <p><b>Opciones admin disponibles próximamente.</b></p>
    <?php endif; ?>

    <a href="logout.php">Cerrar sesión</a>
</div>

</body>
</html>