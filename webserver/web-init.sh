#!/bin/bash

set -e

HOSTNAME_WEB="ciber-web"
APP_DIR="/var/www/html"

echo "Configurando hostname..."
hostnamectl set-hostname "$HOSTNAME_WEB"

if grep -q "^127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1\t$HOSTNAME_WEB/" /etc/hosts
else
    echo "127.0.1.1 $HOSTNAME_WEB" >> /etc/hosts
fi

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
