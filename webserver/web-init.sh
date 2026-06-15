#!/bin/bash

set -e

# Definir hostname y /etc/hosts

grep -q "# Laboratorio Ciber" /etc/hosts || cat >> /etc/hosts << 'EOF'

# Laboratorio Ciber
192.168.100.10 ciber-db
192.168.100.20 ciber-web
192.168.100.30 ciber-dhcp
192.168.100.40 ciber-files

EOF

NEW_HOSTNAME="ciber-web"

hostnamectl set-hostname "$NEW_HOSTNAME"

echo "Hostname configurado como: $NEW_HOSTNAME"

# Instalar paquetes

echo "Actualizando paquetes..."
apt update

echo "Instalando Apache2, PHP y dependencias..."
apt install -y apache2 php libapache2-mod-php php-mysql mariadb-client curl

echo "Habilitando Apache para iniciar con la VM..."
systemctl enable apache2
systemctl restart apache2

echo "Limpiando página default de Apache..."
rm -f "$APP_DIR/index.html"

echo "Copiando aplicación web..."
cp -r ./* "$APP_DIR"/

echo "Eliminando script de instalación del DocumentRoot..."
rm -f "$APP_DIR/web-init.sh"

echo "Asignando permisos..."
chown -R www-data:www-data "$APP_DIR"
find "$APP_DIR" -type d -exec chmod 755 {} \;
find "$APP_DIR" -type f -exec chmod 644 {} \;

echo "Verificando Apache..."
systemctl is-active apache2
systemctl is-enabled apache2

echo ""
echo "Webserver inicializado correctamente."
echo "IPs disponibles de esta VM:"
hostname -I
echo ""
echo "Probar desde esta VM con:"
echo "curl http://localhost"
echo ""
echo "Probar desde otra VM con:"
echo "curl http://IP_DE_CIBER_WEB"
