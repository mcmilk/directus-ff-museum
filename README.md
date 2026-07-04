# Directus Feuerwehrmuseum - Komplettes Setup

Inventarverwaltungssystem für Feuerwehrmuseum mit QR-Codes, Datenbank und Druckfunktion.

## 📋 Voraussetzungen

- Debian 11/12 VM (vorbereitet ✅)
- Docker + Docker Compose
- 2-4 GB RAM minimum (Sie haben 128GB 🎉)
- 50GB Disk minimum (Sie haben 5TB 🎉)

## 🚀 Installation in 5 Minuten

### 1. Docker & Docker Compose installieren

```bash
# System aktualisieren
sudo apt update && sudo apt upgrade -y

# Docker installieren
sudo apt install -y docker.io docker-compose-plugin

# Benutzer zu docker Gruppe hinzufügen
sudo usermod -aG docker $USER
newgrp docker

# Test
docker --version
docker compose version
```

### 2. Projekt-Verzeichnis erstellen

```bash
mkdir -p ~/feuerwehrmuseum
cd ~/feuerwehrmuseum
```

### 3. Repository klonen

```bash
git clone https://github.com/mcmilk/directus-ff-museum.git
cd directus-ff-museum
```

### 4. Umgebungsvariablen konfigurieren

```bash
# .env Datei kopieren und anpassen
cp .env.example .env

# Sichere Keys generieren
openssl rand -base64 32  # -> DIRECTUS_KEY
openssl rand -base64 32  # -> DIRECTUS_SECRET

# .env mit Editoren anpassen
nano .env
```

### 5. Starten

```bash
# Verzeichnisse für Persistenz erstellen
mkdir -p data postgres uploads

# Docker Compose starten
docker compose up -d

# Status prüfen
docker compose logs -f directus
```

### 6. Zugriff

```
Admin Panel: http://localhost:8055
Standard Benutzer: admin@museum.local / AdminPassword123!

Datenbank (pgAdmin):
http://localhost:5050
Benutzer: admin@museum.local / AdminPassword123!
```

## 📁 Dateistruktur

```
directus-ff-museum/
├── docker-compose.yml      # Docker-Konfiguration
├── .env.example             # Template für Umgebungsvariablen
├── .env                     # Ihre Konfiguration (NICHT in Git!)
├── SCHEMA.md               # Datenstruktur Setup
├── FRONTEND.md             # QR-Code & Web-App
├── BACKUP.md               # Backup & Wartung
├── TROUBLESHOOTING.md      # Häufige Probleme
├── uploads/                # Exponat-Bilder, Audio, PDFs
├── data/                   # Directus-Konfiguration
├── postgres/               # Datenbank-Persistenz
├── nginx.conf              # Nginx Konfiguration (optional)
├── docker-compose.prod.yml # Production Setup (optional)
└── README.md              # Diese Datei
```

## 🔧 Konfiguration

Siehe `docker-compose.yml` und `.env` für:
- Admin-Passwort ändern
- Datenbank-Credentials
- Backup-Einstellungen
- Datei-Größenlimits

## 📚 Weitere Dokumentation

- [Directus Datenstruktur Setup](./SCHEMA.md)
- [QR-Code & Web-Frontend](./FRONTEND.md)
- [Backup & Wartung](./BACKUP.md)
- [Troubleshooting](./TROUBLESHOOTING.md)

## 🐛 Häufige Probleme

**Port 8055 bereits in Verwendung:**
```bash
sudo lsof -i :8055
# Oder anderen Port in docker-compose.yml verwenden
```

**Datenbank-Verbindung fehlgeschlagen:**
```bash
docker compose logs postgres
# Prüfen Sie DB_PASSWORD in .env
```

**Uploads funktionieren nicht:**
```bash
sudo chmod 755 uploads/
sudo chown $USER:$USER uploads/
```

---

**Fragen? Siehe [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) oder öffnen Sie ein Issue.**
