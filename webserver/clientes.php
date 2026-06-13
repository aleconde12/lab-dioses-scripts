<?php
require_once "config.php";
require_login();

$mensaje = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $nombre = $_POST["nombre"];
    $documento = $_POST["documento"];

    $stmt = $conn->prepare("INSERT INTO clientes (nombre, documento) VALUES (?, ?)");
    $stmt->bind_param("ss", $nombre, $documento);

    if ($stmt->execute()) {
        $mensaje = "Cliente creado correctamente.";
    } else {
        $mensaje = "Error: " . $stmt->error;
    }
}

$clientes = $conn->query("SELECT * FROM clientes ORDER BY id DESC");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Clientes</title>
    <style>
        body { font-family: Arial; background: #dcdcdc; margin: 40px; color: #111; }
        form, table { background: #f3f3f3; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        input, button { padding: 8px; margin: 5px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #aaa; padding: 8px; }
        th { background: #ccc; }
    </style>
</head>
<body>

<h1>Clientes</h1>

<p><a href="dashboard.php">Volver al panel</a></p>

<?php if ($mensaje): ?>
    <p><b><?php echo $mensaje; ?></b></p>
<?php endif; ?>

<form method="POST">
    <h2>Crear cliente</h2>

    <input type="text" name="nombre" placeholder="Nombre" required>
    <input type="text" name="documento" placeholder="Documento">
    <button type="submit">Crear</button>
</form>

<table>
    <tr>
        <th>ID</th>
        <th>Nombre</th>
        <th>Documento</th>
        <th>Creado</th>
    </tr>

    <?php while ($c = $clientes->fetch_assoc()): ?>
        <tr>
            <td><?php echo $c["id"]; ?></td>
            <td><?php echo $c["nombre"]; ?></td>
            <td><?php echo $c["documento"]; ?></td>
            <td><?php echo $c["creado_en"]; ?></td>
        </tr>
    <?php endwhile; ?>
</table>

</body>
</html>