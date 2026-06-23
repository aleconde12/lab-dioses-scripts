#!/bin/bash
set -e

LOG_FILE="/var/log/init-dhcp.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== INICIO INIT DHCP ====="
date

if [ "$EUID" -ne 0 ]; then
  echo "ERROR: ejecutar con sudo"
  exit 1
fi

HOSTNAME_VM="ciber-dhcp"
INTERNAL_IFACE="enp0s8"
INTERNAL_IP="192.168.100.30"

echo "[1/6] Configurando hostname..."
hostnamectl set-hostname "$HOSTNAME_VM"

# actualizar /etc/hosts para no dejar changeme
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
fi

echo "[2/6] Configurando IP privada en $INTERNAL_IFACE..."
cat > /etc/network/interfaces.d/internal.conf <<EOF
auto $INTERNAL_IFACE
iface $INTERNAL_IFACE inet static
    address $INTERNAL_IP
    netmask 255.255.255.0
EOF

ifdown "$INTERNAL_IFACE" 2>/dev/null || true
ifup "$INTERNAL_IFACE"

echo "[3/6] Configurando /etc/hosts..."
cat > /etc/hosts <<EOF
127.0.0.1 localhost
127.0.1.1 $HOSTNAME_VM

192.168.100.10 ciber-db
192.168.100.20 ciber-web
192.168.100.30 ciber-dhcp
192.168.100.40 ciber-files
EOF

echo "[4/6] Instalando servidor DHCP..."
apt update
apt install -y isc-dhcp-server

echo "[5/6] Configurando DHCP sobre $INTERNAL_IFACE..."
cat > /etc/default/isc-dhcp-server <<EOF
INTERFACESv4="$INTERNAL_IFACE"
INTERFACESv6=""
EOF

cat > /etc/dhcp/dhcpd.conf <<EOF
default-lease-time 600;
max-lease-time 7200;

authoritative;

subnet 192.168.100.0 netmask 255.255.255.0 {
  range 192.168.100.100 192.168.100.200;
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.100.255;
  option domain-name "ciber.local";
  option domain-name-servers 192.168.100.30;
}
EOF

echo "[6/6] Habilitando servicio DHCP..."
systemctl reset-failed isc-dhcp-server || true
systemctl enable isc-dhcp-server
systemctl restart isc-dhcp-server

echo "===== ESTADO DHCP ====="
systemctl status isc-dhcp-server --no-pager || true

echo "===== IP EN $INTERNAL_IFACE ====="
ip a show "$INTERNAL_IFACE"

# Configurar firewall
echo "[+] Configurando firewall UFW para ciber-dhcp..."

ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# SSH administrativo
ufw allow from 192.168.100.0/24 to any port 22035 proto tcp

# DHCP
ufw allow 67/udp
ufw allow 68/udp

ufw --force enable

echo "[+] Estado UFW:"
ufw status verbose

echo "===== FIN INIT DHCP ====="
date