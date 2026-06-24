#!/bin/bash

set -e

# Setear IP privada

cat > /etc/network/interfaces.d/internal.conf <<EOF
auto enp0s8
iface enp0s8 inet static
    address 192.168.100.10
    netmask 255.255.255.0
EOF

ifup enp0s8

# Definir hostname y /etc/hosts

HOSTNAME="ciber-db"

echo "[INFO] Seteando hostname..."
hostnamectl set-hostname "$HOSTNAME"
echo "$HOSTNAME" > /etc/hostname

echo "[INFO] Normalizando /etc/hosts..."
cat > /etc/hosts <<'HOSTS_EOF'
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

# Laboratorio Ciber
192.168.100.10 ciber-db
192.168.100.20 ciber-web
192.168.100.30 ciber-dhcp
192.168.100.40 ciber-files
HOSTS_EOF



# Iniciar DB

LOG_FILE="/var/log/db-init.log"

# Redirigir stdout y stderr al log y a pantalla
exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================="
echo "Inicio de inicialización DB $(date)"
echo "======================================="

# Manejo de errores
trap 'echo "[ERROR] Falló en la línea $LINENO"' ERR

DB_NAME="laboratorio_db"
DB_USER="webapp_user"
DB_PASS="WebAppPass123!"

echo "[INFO] Actualizando paquetes..."
apt update

echo "[INFO] Instalando MariaDB/MySQL..."
apt install -y mariadb-server mariadb-client

echo "[INFO] Habilitando escucha en todas las interfaces..."
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf || true

echo "[INFO] Iniciando MariaDB..."
service mariadb start

echo "[INFO] Esperando inicio del servicio..."
sleep 5

echo "[INFO] Inicializando base de datos..."

mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';

USE ${DB_NAME};

CREATE TABLE IF NOT EXISTS empleados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    rol ENUM('admin', 'empleado') NOT NULL DEFAULT 'empleado',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    documento VARCHAR(30),
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS maquinas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    estado ENUM('libre', 'ocupada') DEFAULT 'libre'
);

CREATE TABLE IF NOT EXISTS sesiones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    maquina_id INT NOT NULL,
    empleado_id INT NOT NULL,
    inicio DATETIME NOT NULL,
    fin DATETIME,
    duracion_minutos INT,
    costo DECIMAL(10,2),
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (maquina_id) REFERENCES maquinas(id),
    FOREIGN KEY (empleado_id) REFERENCES empleados(id)
);

INSERT IGNORE INTO maquinas (nombre) VALUES
('PC-01'), ('PC-02'), ('PC-03');

INSERT INTO empleados (usuario, password, nombre, rol)
SELECT 'admin', 'admin123', 'Administrador', 'admin'
WHERE NOT EXISTS (SELECT 1 FROM empleados WHERE usuario = 'admin');

INSERT INTO empleados (usuario, password, nombre, rol)
SELECT 'empleado', 'empleado123', 'Empleado Demo', 'empleado'
WHERE NOT EXISTS (SELECT 1 FROM empleados WHERE usuario = 'empleado');

FLUSH PRIVILEGES;
EOF

echo "[OK] MariaDB inicializado correctamente"

# restart para que tome la config de bind 0.0.0.0 

systemctl restart mariadb
systemctl enable mariadb

echo "servicio mariadb reiniciado"

# Configurar firewall
echo "[+] Configurando firewall UFW para ciber-db..."
ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# SSH administrativo
ufw allow from 192.168.100.0/24 to any port 22035 proto tcp

# MariaDB solo desde el webserver
ufw allow from 192.168.100.20 to any port 3306 proto tcp

ufw --force enable

echo "[+] Estado UFW:"
ufw status verbose

echo "Fin del script $(date)"
