# Backup & Wartung für Feuerwehrmuseum Directus Setup

## 🔄 Automatische Backups

### Backup-Script (täglich)

Erstellen Sie `backup.sh`:

```bash
#!/bin/bash

# Konfiguration
BACKUP_DIR="/backup/directus"
DB_CONTAINER="directus-postgres"
DB_NAME="feuerwehrmuseum"
DB_USER="directus_user"
RETENTION_DAYS=30
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Backup-Verzeichnis erstellen
mkdir -p "$BACKUP_DIR"

echo "🔄 Starte Backup um $(date)"

# Datenbank sichern
echo "💾 Sicherungs-Datenbank..."
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | \
  gzip > "$BACKUP_DIR/db_$TIMESTAMP.sql.gz"

if [ $? -eq 0 ]; then
    echo "✅ Datenbank-Backup erfolgreich"
else
    echo "❌ Datenbank-Backup fehlgeschlagen!"
    exit 1
fi

# Uploads sichern
echo "📁 Sicherungs-Dateien..."
tar -czf "$BACKUP_DIR/uploads_$TIMESTAMP.tar.gz" ./uploads/ \
    --exclude='*.tmp'

if [ $? -eq 0 ]; then
    echo "✅ Datei-Backup erfolgreich"
else
    echo "❌ Datei-Backup fehlgeschlagen!"
    exit 1
fi

# Alte Backups löschen (älter als 30 Tage)
echo "🧹 Aufräumen alte Backups..."
find "$BACKUP_DIR" -name "*.gz" -type f -mtime +"$RETENTION_DAYS" -delete

echo "✅ Backup abgeschlossen um $(date)"
echo "📊 Backup-Größe: $(du -sh $BACKUP_DIR | cut -f1)"
```

**Ausführbar machen:**
```bash
chmod +x backup.sh
```

**Cron Job (täglich um 2 Uhr morgens):**
```bash
crontab -e

# Eintrag:
0 2 * * * /home/user/feuerwehrmuseum/backup.sh >> /var/log/directus_backup.log 2>&1
```

---

## 📊 Datenbank-Dump per Hand

### Einzelnen Dump erstellen

```bash
# Datenbank exportieren
docker exec directus-postgres pg_dump -U directus_user feuerwehrmuseum > dump.sql

# Mit Kompression
docker exec directus-postgres pg_dump -U directus_user feuerwehrmuseum | \
  gzip > dump_$(date +%Y%m%d).sql.gz
```

### Datenbank importieren

```bash
# Aus Dump wiederherstellen
gunzip -c dump_20240704.sql.gz | \
  docker exec -i directus-postgres psql -U directus_user feuerwehrmuseum
```

---

## 📤 Upload-Dateien sichern

```bash
# Alle Uploads sichern
tar -czf uploads_backup_$(date +%Y%m%d).tar.gz uploads/

# Zurückstellen
tar -xzf uploads_backup_20240704.tar.gz
```

---

## 🔍 Monitoring & Logs

### Docker Logs ansehen

```bash
# Directus Logs (live)
docker compose logs -f directus

# PostgreSQL Logs
docker compose logs -f postgres

# Alle Logs
docker compose logs -f

# Letzte 100 Zeilen
docker compose logs --tail 100
```

### Disk-Speicher prüfen

```bash
# Gesamtspeicher
df -h

# Backup-Größe
du -sh /backup/directus/*

# Docker-Volumes
docker system df

# Alte Backups finden
find /backup/directus -name "*.gz" -type f -mtime +30
```

---

## 🔧 Wartung & Updates

### Directus aktualisieren

```bash
# Verfügbare Versionen prüfen
docker pull directus/directus:latest

# Update in docker-compose.yml:
# image: directus/directus:latest -> directus/directus:12.3.0

# Stoppen, updaten, starten
docker compose stop
docker compose up -d

# Logs prüfen
docker compose logs -f directus
```

### PostgreSQL aktualisieren

⚠️ **Vorsicht!** Major-Versionen benötigen Migration.

```bash
# Minor-Update (z.B. 15.2 -> 15.3):
docker compose stop postgres
docker pull postgres:15-alpine
docker compose up -d postgres

# Prüfen
docker compose logs postgres
```

---

## 🗑️ Bereinigung

### Alte Docker Images löschen

```bash
# Nicht verwendete Images
docker image prune -a

# Nicht verwendete Volumes
docker volume prune

# Komplettes System bereinigen
docker system prune -a
```

### Datenbank-Vacuum (Optimierung)

```bash
# PostgreSQL optimieren
docker exec directus-postgres vacuumdb -U directus_user feuerwehrmuseum
```

---

## 📋 Checkliste: Monatliche Wartung

- [ ] Backups prüfen (Größe, Datum)
- [ ] Disk-Speicher prüfen (`df -h`)
- [ ] Docker-Logs auf Fehler prüfen
- [ ] Updates verfügbar? (`docker pull`)
- [ ] Alte Backups löschen (>90 Tage)
- [ ] Test-Restore durchführen
- [ ] Benutzer-Passwörter aktualisieren

---

## 🆘 Notfall: Datenbank beschädigt

```bash
# 1. Container stoppen
docker compose down

# 2. Volume löschen (WARNUNG: Daten weg!)
docker volume rm feuerwehrmuseum_postgres

# 3. Backup wiederherstellen
tar -xzf postgres_backup.tar.gz -C ./

# 4. Neu starten
docker compose up -d

# 5. Datenbank importieren
gunzip -c dump.sql.gz | \
  docker exec -i directus-postgres psql -U directus_user feuerwehrmuseum
```

---

## 📡 Remote Backups (Optional)

### Mit rsync zu Remote-Server

```bash
#!/bin/bash

REMOTE_USER="backup"
REMOTE_HOST="backup.example.com"
REMOTE_PATH="/mnt/backups/feuerwehrmuseum"
BACKUP_DIR="/backup/directus"

# Zu Remote-Server kopieren
rsync -avz --delete \
  -e "ssh -i /home/user/.ssh/backup_key" \
  "$BACKUP_DIR/" \
  "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

echo "✅ Remote Backup erfolgreich"
```

---

## ☁️ Cloud-Backup Alternativen

- **Backblaze B2** - Günstig, S3-kompatibel
- **AWS S3** - Skalierbar, zuverlässig
- **Nextcloud** - Selbst-gehostet
- **Duplicati** - Verschlüsselte Cloud-Backups

```bash
# Beispiel: S3 Upload
aws s3 cp dump_$(date +%Y%m%d).sql.gz \
  s3://my-backups/directus/
```

---

## 📞 Support & Dokumentation

- [Directus Docs](https://docs.directus.io/)
- [PostgreSQL Backup](https://www.postgresql.org/docs/current/backup.html)
- [Docker Backup Best Practices](https://docs.docker.com/storage/volumes/)
