#!/bin/bash

set -euo pipefail

# Setear IP privada

cat > /etc/network/interfaces.d/internal.conf <<EOF
auto enp0s8
iface enp0s8 inet static
    address 192.168.100.20
    netmask 255.255.255.0
EOF

ifup enp0s8

# ================================
# Inicialización Webserver - Ciber
# ================================

LOG_FILE="/var/log/web-init.log"
APP_DIR="/var/www/html"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_HOSTNAME="ciber-web"

# Validar root
if [[ "${EUID}" -ne 0 ]]; then
  echo "[ERROR] Este script debe ejecutarse con sudo o como root."
  echo "Ejemplo: sudo ./web-init.sh"
  exit 1
fi

# Redirigir stdout y stderr al log y a pantalla
exec > >(tee -a "$LOG_FILE") 2>&1

trap 'echo "[ERROR] Falló en la línea $LINENO. Revisar $LOG_FILE"' ERR

echo "========================================"
echo "Inicio de inicialización WEB $(date)"
echo "========================================"
echo "Repo detectado en: $REPO_DIR"
echo "DocumentRoot: $APP_DIR"
echo "Log: $LOG_FILE"
echo ""

# 1. Hostname y hosts

echo "[1/9] Configurando hostname y /etc/hosts..."

if ! grep -q "# Laboratorio Ciber" /etc/hosts; then
  cat >> /etc/hosts << 'HOSTS_EOF'

# Laboratorio Ciber
192.168.100.10 ciber-db
192.168.100.20 ciber-web
192.168.100.30 ciber-dhcp
192.168.100.40 ciber-files
HOSTS_EOF
else
  echo "Entradas de Laboratorio Ciber ya existen en /etc/hosts."
fi

hostnamectl set-hostname "$NEW_HOSTNAME"
echo "Hostname configurado como: $NEW_HOSTNAME"
echo ""

# actualizar /etc/hosts para no dejar changeme
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
fi

# 2. Paquetes

echo "[2/9] Actualizando paquetes..."
apt update

echo "[3/9] Instalando Apache2, PHP y dependencias..."
apt install -y apache2 php libapache2-mod-php php-mysql mariadb-client curl rsync netcat-openbsd

echo ""

# 3. Apache básico

echo "[4/9] Configurando Apache..."
mkdir -p "$APP_DIR"

# Evita warning típico: Could not reliably determine the server's fully qualified domain name
if [[ ! -f /etc/apache2/conf-available/servername.conf ]]; then
  echo "ServerName ciber-web" > /etc/apache2/conf-available/servername.conf
fi
a2enconf servername >/dev/null

systemctl enable apache2
systemctl restart apache2

echo "Apache habilitado y reiniciado."
echo ""

# 4. Copia de aplicación

echo "[5/9] Limpiando DocumentRoot..."
rm -rf "${APP_DIR:?}"/*

echo "[6/9] Copiando aplicación web desde el repo..."
rsync -av \
  --exclude='.git' \
  --exclude='.gitignore' \
  --exclude='web-init.sh' \
  --exclude='web-init-fixed.sh' \
  --exclude='README.md' \
  "$REPO_DIR"/ "$APP_DIR"/

echo "Aplicación copiada a $APP_DIR"
echo ""

# 5. Permisos

echo "[7/9] Asignando permisos..."
chown -R www-data:www-data "$APP_DIR"
find "$APP_DIR" -type d -exec chmod 755 {} \;
find "$APP_DIR" -type f -exec chmod 644 {} \;
echo "Permisos aplicados."
echo ""

# 6. Validaciones

echo "[8/9] Verificando servicios..."
systemctl is-active --quiet apache2 && echo "Apache: activo"
systemctl is-enabled --quiet apache2 && echo "Apache: habilitado al inicio"

echo "Puertos escuchando:"
ss -tlnp | grep -E ':(80|443)\s' || echo "[WARN] No se detectó Apache escuchando en 80/443."
echo ""

# 7. Pruebas rápidas

echo "[9/9] Probando respuesta HTTP local..."
HTTP_CODE="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1 || true)"
echo "HTTP local: $HTTP_CODE"

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "302" ]]; then
  echo "[WARN] Apache respondió con código $HTTP_CODE. Revisar /var/log/apache2/error.log si la app falla."
fi

echo ""
echo "Probando conectividad básica hacia DB ciber-db:3306..."
if nc -zvw3 ciber-db 3306; then
  echo "DB: puerto 3306 accesible desde ciber-web."
else
  echo "[WARN] No se pudo conectar a ciber-db:3306. Verificar que la VM DB esté encendida, IP 192.168.100.10, MariaDB y bind-address/permisos."
fi

# Administrar puertos con UFW

ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# SSH administrativo
ufw allow from 192.168.100.0/24 to any port 22035 proto tcp

# Acceso web
ufw allow from 192.168.100.0/24 to any port 80 proto tcp

ufw --force enable

echo "[+] Estado UFW:"
ufw status verbose

echo ""
echo "========================================"
echo "Inicialización WEB finalizada $(date)"
echo "========================================"
echo "IPs disponibles de esta VM:"
hostname -I || true
echo ""
echo "Pruebas útiles:"
echo "  curl http://127.0.0.1"
echo "  curl http://192.168.100.20"
echo "  sudo tail -50 $LOG_FILE"
echo "  sudo tail -50 /var/log/apache2/error.log"
echo ""
