#!/bin/bash

FECHA=$(date +%F)
SLOT=$(( ($(date +%s) / 86400 % 5) + 1 ))

BACKUP_DIR="/opt/ciber-backups"
WEB_DIR="/var/www/html"

DB_HOST="ciber-db"
DB_NAME="laboratorio_db"
DB_USER="webapp_user"
DB_PASS="WebAppPass123!"

FTP_HOST="ciber-files"
FTP_USER="ciberfiles"
FTP_PASS="Ciber1234"
FTP_DIR="backups"

WEB_BACKUP="$BACKUP_DIR/web_${FECHA}_slot${SLOT}.tar.gz"
DB_BACKUP="$BACKUP_DIR/db_${FECHA}_slot${SLOT}.sql.gz"
FULL_BACKUP="$BACKUP_DIR/backup_${FECHA}_slot${SLOT}.tar.gz"

rm -f "$BACKUP_DIR"/*_slot${SLOT}.*

tar -czf "$WEB_BACKUP" "$WEB_DIR"

mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$DB_BACKUP"

tar -czf "$FULL_BACKUP" "$WEB_BACKUP" "$DB_BACKUP"

ftp -inv "$FTP_HOST" <<EOF
user $FTP_USER $FTP_PASS
mkdir $FTP_DIR
cd $FTP_DIR
put $FULL_BACKUP
bye
EOF