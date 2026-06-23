#!/bin/bash
set -e

# Setear IP privada

cat > /etc/network/interfaces.d/internal.conf <<EOF
auto enp0s8
iface enp0s8 inet static
    address 192.168.100.40
    netmask 255.255.255.0
EOF

ifup enp0s8

# Log file e inicio

LOGFILE="/var/log/ciber-files-init.log"

exec > >(tee -a "$LOGFILE") 2>&1

echo "========================================="
echo "Inicio: $(date)"
echo "========================================="

HOSTNAME="ciber-files"
USER_FILE="ciberfiles"
PASS_FILE="Ciber1234"

FTP_DIR="/srv/ftp/backups"
SAMBA_DIR="/srv/samba/compartido"

echo "[INFO] Seteando hostname..."
hostnamectl set-hostname "$HOSTNAME"

# actualizar /etc/hosts para no dejar changeme
if grep -q "^127\.0\.1\.1" /etc/hosts; then
    sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts
else
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
fi

echo "[INFO] Instalando paquetes..."
apt update
apt install -y vsftpd samba smbclient

echo "[INFO] Creando usuario..."
if ! id "$USER_FILE" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$USER_FILE"
    echo "${USER_FILE}:${PASS_FILE}" | chpasswd
fi

echo "[INFO] Creando carpetas..."
mkdir -p "$FTP_DIR"
mkdir -p "$SAMBA_DIR"

chown -R "$USER_FILE:$USER_FILE" /srv/ftp
chown -R "$USER_FILE:$USER_FILE" /srv/samba

chmod -R 755 /srv/ftp
chmod -R 775 /srv/samba

echo "[INFO] Configurando vsftpd..."
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak.$(date +%F-%H%M%S)

cat > /etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=NO
allow_writeable_chroot=YES
user_sub_token=\$USER
local_root=/srv/ftp
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30100
EOF

echo "[INFO] Configurando Samba..."
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak.$(date +%F-%H%M%S)

cat > /etc/samba/smb.conf <<EOF
[global]
   workgroup = WORKGROUP
   server string = Ciber File Server
   security = user
   map to guest = Bad User
   dns proxy = no

[compartido]
   path = /srv/samba/compartido
   browsable = yes
   writable = yes
   valid users = $USER_FILE
   create mask = 0664
   directory mask = 0775
EOF

echo "[INFO] Configurando password Samba..."
echo -e "${PASS_FILE}\n${PASS_FILE}" | smbpasswd -a "$USER_FILE"
smbpasswd -e "$USER_FILE"

echo "[INFO] Reiniciando servicios..."
systemctl restart vsftpd
systemctl restart smbd
systemctl restart nmbd

systemctl enable vsftpd
systemctl enable smbd
systemctl enable nmbd

echo "[OK] ciber-files configurado correctamente."
echo "FTP: ftp://192.168.100.40"
echo "Samba: \\\\192.168.100.40\\compartido"
echo "Usuario: $USER_FILE"
echo "Password: $PASS_FILE"

# Configurar firewall
ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# SSH administrativo
ufw allow from 192.168.100.0/24 to any port 22035 proto tcp

# FTP para backups desde web y db
ufw allow from 192.168.100.20 to any port 21 proto tcp
ufw allow from 192.168.100.10 to any port 21 proto tcp

# Samba para acceso desde Windows/red interna
ufw allow from 192.168.100.0/24 to any port 445 proto tcp
ufw allow from 192.168.100.0/24 to any port 139 proto tcp
ufw allow from 192.168.100.0/24 to any port 137 proto udp
ufw allow from 192.168.100.0/24 to any port 138 proto udp

# Rango para permitir ftp pasivo
sudo ufw allow from 192.168.100.20 to any port 40000:40100 proto tcp
sudo ufw allow from 192.168.100.10 to any port 40000:40100 proto tcp

ufw --force enable

echo "[+] Estado UFW:"
ufw status verbose

echo "========================================="
echo "Fin: $(date)"
echo "========================================="