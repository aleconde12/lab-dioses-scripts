#!/bin/bash
set -euo pipefail

BACKUP_DIR="/opt/ciber-backups"
STATE_DIR="/var/lib/ciber-backup"
COUNTER_FILE="$STATE_DIR/counter"

mkdir -p "$BACKUP_DIR"
mkdir -p "$STATE_DIR"

WEB_DIR="/var/www/html"

DB_HOST="ciber-db"
DB_NAME="laboratorio_db"
DB_USER="webapp_user"
DB_PASS="WebAppPass123!"

FTP_HOST="ciber-files"
FTP_USER="ciberfiles"
FTP_PASS="Ciber1234"
FTP_DIR="backups"

# Contador persistente de ejecuciones
if [ ! -f "$COUNTER_FILE" ]; then
    echo 0 > "$COUNTER_FILE"
fi

COUNTER=$(cat "$COUNTER_FILE")

if ! [[ "$COUNTER" =~ ^[0-9]+$ ]]; then
    COUNTER=0
fi

COUNTER=$((COUNTER + 1))
echo "$COUNTER" > "$COUNTER_FILE"

# Rotación circular de 5 slots
SLOT=$(( ((COUNTER - 1) % 5) + 1 ))

FECHA=$(date +%F_%H%M%S)

WEB_BACKUP="$BACKUP_DIR/web_${FECHA}_run${COUNTER}_slot${SLOT}.tar.gz"
DB_BACKUP="$BACKUP_DIR/db_${FECHA}_run${COUNTER}_slot${SLOT}.sql.gz"
FULL_BACKUP="$BACKUP_DIR/backup_${FECHA}_run${COUNTER}_slot${SLOT}.tar.gz"
FULL_BACKUP_NAME="$(basename "$FULL_BACKUP")"

echo "[+] Ejecución número: $COUNTER"
echo "[+] Slot seleccionado: $SLOT"
echo "[+] Archivo final: $FULL_BACKUP_NAME"

echo "[+] Eliminando backup local anterior del slot $SLOT..."
rm -f "$BACKUP_DIR"/backup_*_slot${SLOT}.tar.gz
rm -f "$BACKUP_DIR"/web_*_slot${SLOT}.tar.gz
rm -f "$BACKUP_DIR"/db_*_slot${SLOT}.sql.gz

echo "[+] Generando backup de la web..."
tar -czf "$WEB_BACKUP" "$WEB_DIR"

echo "[+] Generando backup de la base de datos..."
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$DB_BACKUP"

echo "[+] Generando backup completo..."
tar -czf "$FULL_BACKUP" "$WEB_BACKUP" "$DB_BACKUP"

echo "[+] Eliminando archivos intermedios locales..."
rm -f "$WEB_BACKUP" "$DB_BACKUP"

echo "[+] Subiendo backup al FTP..."
ftp -inv "$FTP_HOST" <<EOF
user $FTP_USER $FTP_PASS
binary
cd $FTP_DIR
prompt off
mdelete backup_*_slot${SLOT}.tar.gz
put $FULL_BACKUP $FULL_BACKUP_NAME
bye
EOF

echo "[+] Backup finalizado correctamente."