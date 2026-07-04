#!/bin/bash

# =============================================================================
# Directus Feuerwehrmuseum - Setup Script
# Generiert sichere Passwörter und konfiguriert das System
# =============================================================================

set -e  # Beende bei Fehlern

echo "=========================================================================="
echo "Directus Feuerwehrmuseum - Setup Script"
echo "Generiert sichere Passwörter und konfiguriert das System"
echo "=========================================================================="

# Check ob bereits konfiguriert
if [ -f ".env" ] && [ -f "init-db.sql" ]; then
    echo ""
    echo "System bereits konfiguriert (.env und init-db.sql existieren)"
    read -p "Neu konfigurieren? (ja/nein): " response
    if [[ ! "$response" =~ ^[jJ]$ ]]; then
        echo "Setup abgebrochen."
        exit 0
    fi
    echo "Alte Dateien werden überschrieben..."
fi

# =============================================================================
# 1. Sichere Passwörter generieren
# =============================================================================
echo ""
echo "[1/5] Generiere sichere Passwörter..."

DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-20)
DIRECTUS_KEY=$(openssl rand -base64 32)
DIRECTUS_SECRET=$(openssl rand -base64 32)

echo "OK - Passwörter generiert"

# =============================================================================
# 2. .env Datei erstellen
# =============================================================================
echo ""
echo "[2/5] Erstelle .env Datei..."

cat > .env << EOF
# ========== DATABASE ==========
DB_NAME=feuerwehrmuseum
DB_USER=directus_user
DB_PASSWORD=${DB_PASSWORD}

# ========== DIRECTUS ADMIN ==========
ADMIN_EMAIL=admin@museum.local
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# ========== DIRECTUS KEYS ==========
DIRECTUS_KEY=${DIRECTUS_KEY}
DIRECTUS_SECRET=${DIRECTUS_SECRET}

# ========== EMAIL (Optional) ==========
MAIL_FROM=museum@feuerwehrmuseum.local

# ========== DOCKER COMPOSE ==========
COMPOSE_PROJECT_NAME=feuerwehrmuseum

# ========== DIRECTUS EXTRA ==========
NODE_ENV=production
LOG_LEVEL=info
EOF

chmod 600 .env  # Nur Eigentümer darf lesen
echo "OK - .env Datei erstellt (Berechtigungen: 600)"

# =============================================================================
# 3. init-db.sql mit echten Passwörtern generieren
# =============================================================================
echo ""
echo "[3/5] Erstelle init-db.sql mit Passwörtern..."

cat > init-db.sql << EOF
-- Init script für PostgreSQL
-- Erstellt den Directus-Datenbankbenutzer automatisch beim Start
-- Generiert am: $(date)

-- Benutzer erstellen (falls nicht vorhanden)
CREATE ROLE directus_user WITH LOGIN PASSWORD '${DB_PASSWORD}';

-- Berechtigungen für die Datenbank
ALTER DATABASE feuerwehrmuseum OWNER TO directus_user;
GRANT ALL PRIVILEGES ON DATABASE feuerwehrmuseum TO directus_user;

-- Berechtigungen für alle zukünftigen Tabellen/Schemas
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO directus_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO directus_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO directus_user;

-- Schema-Berechtigungen
GRANT USAGE ON SCHEMA public TO directus_user;
GRANT CREATE ON SCHEMA public TO directus_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO directus_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO directus_user;
EOF

echo "OK - init-db.sql erstellt"

# =============================================================================
# 4. Verzeichnisse erstellen
# =============================================================================
echo ""
echo "[4/5] Erstelle erforderliche Verzeichnisse..."

mkdir -p data postgres pgadmin uploads
chmod 755 data postgres pgadmin uploads

echo "OK - Verzeichnisse erstellt"

# =============================================================================
# 5. Zusammenfassung und nächste Schritte
# =============================================================================
echo ""
echo "[5/5] Setup abgeschlossen!"
echo ""
echo "=========================================================================="
echo "KONFIGURATION ERFOLGREICH"
echo "=========================================================================="
echo ""

echo "Login-Daten:"
echo ""
echo "Directus Admin Panel:"
echo "  URL:      http://localhost:8055"
echo "  Email:    admin@museum.local"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""

echo "pgAdmin (Datenbank):"
echo "  URL:      http://localhost:5050"
echo "  Email:    admin@museum.local"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""

echo "PostgreSQL Datenbank:"
echo "  Host:     localhost:5432"
echo "  Database: feuerwehrmuseum"
echo "  User:     directus_user"
echo "  Password: ${DB_PASSWORD}"
echo ""

echo "Nächste Schritte:"
echo ""
echo "1. Überprüfe .env Datei:"
echo "   cat .env"
echo ""
echo "2. Starte Docker Compose:"
echo "   docker compose up -d"
echo ""
echo "3. Prüfe Logs:"
echo "   docker compose logs -f"
echo ""
echo "4. Öffne Browser:"
echo "   http://localhost:8055"
echo ""

echo "WICHTIG:"
echo "  - Die .env Datei enthält Passwörter - NICHT committen!"
echo "  - .gitignore verhindert versehentliches Committen"
echo "  - init-db.sql wird beim ersten DB-Start ausgeführt"
echo ""
