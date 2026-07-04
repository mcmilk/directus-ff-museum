# Troubleshooting für Directus Feuerwehrmuseum

## 🔴 Häufige Probleme & Lösungen

---

## Port-Konflikte

### Problem: "Port 8055 already in use"

```bash
# Welcher Prozess nutzt Port 8055?
sudo lsof -i :8055

# Prozess beenden
kill -9 <PID>

# ODER: Anderen Port in docker-compose.yml verwenden
# Ändere: ports: - "8055:8055" zu "8056:8055"

# Dann neu starten
docker compose up -d
```

### Problem: Port 5432 (PostgreSQL) belegt

```bash
# Port 5433 stattdessen nutzen
# In docker-compose.yml:
ports:
  - "5433:5432"

# Von außen: postgresql://localhost:5433
```

---

## Datenbank-Probleme

### Problem: "Verbindung zur Datenbank fehlgeschlagen"

```bash
# 1. PostgreSQL Container prüfen
docker compose logs postgres

# 2. Ist Container am Leben?
docker ps | grep postgres

# 3. Health-Check prüfen
docker inspect directus-postgres | grep -A 5 State

# 4. DB_PASSWORD in .env prüfen (Sonderzeichen?)
# Besser: nur alphanumerisch + -_

# 5. Container neu starten
docker compose restart postgres
```

### Problem: "FATAL: password authentication failed"

```bash
# .env überprüfen:
# - DB_USER: directus_user
# - DB_PASSWORD: (keine Leerzeichen, keine Sonderzeichen)
# - DB_NAME: feuerwehrmuseum

# Neu starten mit reset
docker compose down
rm -rf postgres/  # ⚠️ LÖSCHT DATENBANK!
docker compose up -d
```

### Problem: "Database already exists"

```bash
# PostgreSQL Volume ist noch vorhanden
docker compose down
docker volume ls | grep postgres
docker volume rm feuerwehrmuseum_postgres  # ODER: directus-ff-museum_postgres

docker compose up -d
```

---

## Directus-spezifische Probleme

### Problem: Directus Admin-Panel laden nicht

```bash
# Logs ansehen
docker compose logs directus

# Fehlermeldungen nach "Error" suchen:
docker compose logs directus | grep -i error

# Key/Secret überprüfen
grep DIRECTUS_KEY .env
grep DIRECTUS_SECRET .env

# Muss mindestens 32 Zeichen lang sein!
# Neu generieren:
openssl rand -base64 32

# .env aktualisieren und neu starten
vim .env
docker compose restart directus
```

### Problem: "Uploads funktionieren nicht"

```bash
# Berechtigungen prüfen
ls -la uploads/

# Sollte so aussehen:
drwxr-xr-x 2 1000 1000 uploads/

# Falls nicht, Berechtigungen setzen:
chmod 755 uploads/
sudo chown $USER:$USER uploads/

# Docker-Berechtigungen
chmod 777 uploads/  # Notfalls (unsicherer)
```

### Problem: "File size exceeded"

```bash
# In docker-compose.yml erhöhen:
environment:
  ...
  FILE_UPLOAD_SIZE_LIMIT: 104857600  # 100MB (in Bytes)
  FILE_SIZE_LIMIT: 52428800          # 50MB

# Dann neu starten
docker compose up -d
```

### Problem: "Collection nicht sichtbar nach erstellen"

```bash
# Cache leeren
# Im Directus Admin:
# Settings → Cache (oben rechts) → Clear All

# ODER per API:
curl -X DELETE http://localhost:8055/api/cache

# ODER Docker neu starten
docker compose restart directus
```

---

## API-Probleme

### Problem: "CORS Error" im Browser

```bash
# .env prüfen:
CORS_ENABLED=true
CORS_ORIGIN=*  # oder spezifische Domain: http://example.com

# Dann neu starten
docker compose restart directus
```

### Problem: "401 Unauthorized" bei API-Calls

```bash
# Authentication Token erforderlich
# 1. Token abrufen
curl -X POST http://localhost:8055/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@museum.local",
    "password": "AdminPassword123!"
  }'

# 2. Token verwenden in API-Calls
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8055/items/exponat
```

### Problem: "404 Not Found" für Items

```bash
# Collection existiert nicht
# Prüfe in Directus Admin: Settings → Data Model

# Oder per API:
curl http://localhost:8055/api/collections

# Richtige Collection-Namen verwenden!
# Z.B. /items/exponat (nicht /items/exponats)
```

---

## Performance-Probleme

### Problem: "Directus lädt langsam"

```bash
# 1. RAM/CPU prüfen
docker stats directus

# 2. Logs auf Fehler prüfen
docker compose logs directus | tail -50

# 3. Datenbank-Performance
# In pgAdmin: Tools → Maintenance → VACUUM

# 4. Redis Cache aktivieren (optional)
# In docker-compose.yml:
#   CACHE_ENABLED: 'true'
#   CACHE_STORE: 'redis'

# 5. Directus neu starten
docker compose restart directus
```

### Problem: "Datenbank wächst zu schnell"

```bash
# Logs prüfen
docker compose logs postgres | tail -100

# Größe prüfen
docker exec directus-postgres du -sh /var/lib/postgresql/data

# Alte Revisionen löschen (in pgAdmin):
DELETE FROM directus_revisions 
  WHERE created_at < now() - interval '6 months';

VACUUM FULL directus_revisions;
```

---

## Docker-Probleme

### Problem: "Docker Compose nicht gefunden"

```bash
# Prüfe Installation
docker compose --version

# Falls nicht vorhanden:
sudo apt install docker-compose-plugin

# ODER alte Version:
sudo apt install docker-compose
```

### Problem: "Permission denied" Docker-Befehl

```bash
# Docker Gruppe hinzufügen
sudo usermod -aG docker $USER
newgrp docker

# Test
docker ps
```

### Problem: "Out of disk space"

```bash
# Verfügbaren Speicher prüfen
df -h

# Docker-Speicher bereinigen
docker system prune -a

# Alte Logs rotieren
sudo journalctl --vacuum=100M

# Backup-Speicher prüfen
du -sh /backup/directus/*
find /backup/directus -mtime +30 -delete
```

---

## SSL/HTTPS-Probleme

### Problem: "Selbstsigniertes Zertifikat"

```bash
# Let's Encrypt Zertifikat mit certbot
sudo apt install certbot python3-certbot-nginx

# Zertifikat generieren
sudo certbot certonly --standalone -d museum.example.com

# In docker-compose.yml (nginx):
volumes:
  - /etc/letsencrypt:/etc/nginx/ssl:ro

# nginx.conf anpassen für SSL
```

---

## Backup/Restore-Probleme

### Problem: "Backup fehlgeschlagen"

```bash
# Speicher prüfen
df -h /backup/

# PostgreSQL Backup manuell testen
docker exec directus-postgres pg_dump -U directus_user feuerwehrmuseum | head

# Falls Fehler: Größe limitieren
docker exec directus-postgres pg_dump -U directus_user feuerwehrmuseum | \
  gzip -9 > dump.sql.gz  # -9 = max Kompression
```

### Problem: "Restore funktioniert nicht"

```bash
# 1. Alte Datenbank löschen
docker exec directus-postgres dropdb -U directus_user feuerwehrmuseum

# 2. Neue Datenbank erstellen
docker exec directus-postgres createdb -U directus_user feuerwehrmuseum

# 3. Dump einspielen
gunzip -c dump.sql.gz | \
  docker exec -i directus-postgres psql -U directus_user feuerwehrmuseum

# 4. Prüfen
docker exec directus-postgres psql -U directus_user feuerwehrmuseum -c "\dt"
```

---

## Netzwerk-Probleme

### Problem: "Localhost funktioniert, externe IP nicht"

```bash
# 1. Firewall prüfen
sudo ufw status

# 2. Port freigeben
sudo ufw allow 8055/tcp
sudo ufw allow 5432/tcp

# 3. Docker-Netzwerk prüfen
docker network ls
docker network inspect feuerwehrmuseum_directus-network

# 4. IP-Adressen prüfen
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' directus-app
```

---

## Debug-Tipps

### Ausführliche Logs anschauen

```bash
# Live-Logs mit viel Detail
docker compose logs -f --timestamps directus postgres pgadmin

# Nur Fehler
docker compose logs | grep -i error

# Spezifische Container
docker logs -f directus-app
```

### Container untersuchen

```bash
# In Container gehen
docker exec -it directus-app /bin/sh

# Dateisystem prüfen
ls -la /directus/
ls -la /directus/uploads/

# Prozesse prüfen
ps aux

# Netzwerk testen
nslookup postgres
ping postgres
```

### Configuration prüfen

```bash
# .env validieren
cat .env

# docker-compose.yml prüfen
docker compose config

# Auf Syntax-Fehler prüfen
yaml-lint docker-compose.yml
```

---

## Kontakt & Weitere Hilfe

- 📖 [Directus Dokumentation](https://docs.directus.io/)
- 🐛 [Directus Issues](https://github.com/directus/directus/issues)
- 💬 [PostgreSQL Docs](https://www.postgresql.org/docs/)
- 🐳 [Docker Docs](https://docs.docker.com/)

---

## Schnelle Notfall-Befehle

```bash
# Alles stoppen
docker compose down

# Alles neu starten
docker compose up -d

# Logs in Echtzeit
docker compose logs -f

# Status prüfen
docker compose ps

# Datenbank zurücksetzen (⚠️ LÖSCHT ALLES)
docker compose down
rm -rf postgres/ uploads/ data/
docker compose up -d
```

---

**Noch ein Problem? Öffnen Sie bitte ein Issue mit:**
- `docker compose version`
- `docker --version`
- Fehlermeldung aus `docker compose logs`
- Betriebssystem (Linux, Mac, Windows)
