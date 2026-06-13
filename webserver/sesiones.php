<?php
require_once "config.php";
require_login();

$mensaje = "";
$precio_por_minuto = 20;

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $accion = $_POST["accion"];

    if ($accion === "iniciar") {
        $cliente_id = $_POST["cliente_id"];
        $maquina_id = $_POST["maquina_id"];
        $empleado_id = $_SESSION["empleado_id"];

        $stmt = $conn->prepare("INSERT INTO sesiones (cliente_id, maquina_id, empleado_id, inicio) VALUES (?, ?, ?, NOW())");
        $stmt->bind_param("iii", $cliente_id, $maquina_id, $empleado_id);

        if ($stmt->execute()) {
            $conn->query("UPDATE maquinas SET estado = 'ocupada' WHERE id = $maquina_id");
            $mensaje = "Sesión iniciada correctamente.";
        } else {
            $mensaje = "Error: " . $stmt->error;
        }
    }

    if ($accion === "finalizar") {
        $sesion_id = $_POST["sesion_id"];

        $stmt = $conn->prepare("
            UPDATE sesiones
            SET 
                fin = NOW(),
                duracion_minutos = TIMESTAMPDIFF(MINUTE, inicio, NOW()),
                costo = TIMESTAMPDIFF(MINUTE, inicio, NOW()) * ?
            WHERE id = ?
        ");

        $stmt->bind_param("di", $precio_por_minuto, $sesion_id);

        if ($stmt->execute()) {
            $conn->query("
                UPDATE maquinas 
                SET estado = 'libre' 
                WHERE id = (
                    SELECT maquina_id FROM sesiones WHERE id = $sesion_id
                )
            ");

            $mensaje = "Sesión finalizada correctamente.";
        } else {
            $mensaje = "Error: " . $stmt->error;
        }
    }
}

$clientes = $conn->query("SELECT id, nombre FROM clientes ORDER BY nombre");
$maquinas_libres = $conn->query("SELECT id, nombre FROM maquinas WHERE estado = 'libre' ORDER BY nombre");

$sesiones_activas = $conn->query("
    SELECT 
        s.id,
        c.nombre AS cliente,
        m.nombre AS maquina,
        e.nombre AS empleado,
        s.inicio
    FROM sesiones s
    JOIN clientes c ON s.cliente_id = c.id
    JOIN maquinas m ON s.maquina_id = m.id
    JOIN empleados e ON s.empleado_id = e.id
    WHERE s.fin IS NULL
    ORDER BY s.inicio DESC
");

$historial = $conn->query("
    SELECT 
        s.id,
        c.nombre AS cliente,
        m.nombre AS maquina,
        e.nombre AS empleado,
        s.inicio,
        s.fin,
        s.duracion_minutos,
        s.costo
    FROM sesiones s
    JOIN clientes c ON s.cliente_id = c.id
    JOIN maquinas m ON s.maquina_id = m.id
    JOIN empleados e ON s.empleado_id = e.id
    ORDER BY s.id DESC
");
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Sesiones</title>
    <style>
        body { font-family: Arial; background: #dcdcdc; margin: 40px; color: #111; }
        form, table { background: #f3f3f3; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        select, button { padding: 8px; margin: 5px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #aaa; padding: 8px; }
        th { background: #ccc; }
    </style>
</head>
<body>

<h1>Sesiones de uso</h1>

<p><a href="dashboard.php">Volver al panel</a></p>

<?php if ($mensaje): ?>
    <p><b><?php echo $mensaje; ?></b></p>
<?php endif; ?>

<form method="POST">
    <h2>Iniciar sesión</h2>

    <input type="hidden" name="accion" value="iniciar">

    <label>Cliente:</label>
    <select name="cliente_id" required>
        <?php while ($c = $clientes->fetch_assoc()): ?>
            <option value="<?php echo $c["id"]; ?>">
                <?php echo $c["nombre"]; ?>
            </option>
        <?php endwhile; ?>
    </select>

    <label>Máquina:</label>
    <select name="maquina_id" required>
        <?php while ($m = $maquinas_libres->fetch_assoc()): ?>
            <option value="<?php echo $m["id"]; ?>">
                <?php echo $m["nombre"]; ?>
            </option>
        <?php endwhile; ?>
    </select>

    <button type="submit">Iniciar</button>
</form>

<h2>Sesiones activas</h2>

<table>
    <tr>
        <th>ID</th>
        <th>Cliente</th>
        <th>Máquina</th>
        <th>Empleado</th>
        <th>Inicio</th>
        <th>Acción</th>
    </tr>

    <?php while ($s = $sesiones_activas->fetch_assoc()): ?>
        <tr>
            <td><?php echo $s["id"]; ?></td>
            <td><?php echo $s["cliente"]; ?></td>
            <td><?php echo $s["maquina"]; ?></td>
            <td><?php echo $s["empleado"]; ?></td>
            <td><?php echo $s["inicio"]; ?></td>
            <td>
                <form method="POST">
                    <input type="hidden" name="accion" value="finalizar">
                    <input type="hidden" name="sesion_id" value="<?php echo $s["id"]; ?>">
                    <button type="submit">Finalizar</button>
                </form>
            </td>
        </tr>
    <?php endwhile; ?>
</table>

<h2>Historial</h2>

<table>
    <tr>
        <th>ID</th>
        <th>Cliente</th>
        <th>Máquina</th>
        <th>Empleado</th>
        <th>Inicio</th>
        <th>Fin</th>
        <th>Minutos</th>
        <th>Costo</th>
    </tr>

    <?php while ($h = $historial->fetch_assoc()): ?>
        <tr>
            <td><?php echo $h["id"]; ?></td>
            <td><?php echo $h["cliente"]; ?></td>
            <td><?php echo $h["maquina"]; ?></td>
            <td><?php echo $h["empleado"]; ?></td>
            <td><?php echo $h["inicio"]; ?></td>
            <td><?php echo $h["fin"] ?? "-"; ?></td>
            <td><?php echo $h["duracion_minutos"] ?? "-"; ?></td>
            <td><?php echo $h["costo"] ?? "-"; ?></td>
        </tr>
    <?php endwhile; ?>
</table>

</body>
</html>