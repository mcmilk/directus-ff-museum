# Directus Datenstruktur für Feuerwehrmuseum

Diese Dokumentation beschreibt die Datenbank-Struktur für die Verwaltung von Exponaten im Feuerwehrmuseum.

## Collections (Tabellen) definieren

### 1. Collection: "Exponat"

Hauptsammlung für alle Exponate (Fahrzeuge, Pumpen, Schläuche, etc.)

| Feldname | Typ | Eigenschaften | Beschreibung |
|----------|-----|--------------|----------|
| id | UUID | Primary Key, Auto | Eindeutige ID |
| inventarnummer | String | Unique, Required | z.B. "FW-2024-001" |
| name | String | Required | Exponat-Name |
| kategorie_id | Many-to-One | Link zu "Kategorie" | Fahrzeug, Pumpe, etc. |
| beschreibung | Text/Rich Text | Optional | Detaillierte Beschreibung |
| standort | String | Optional | z.B. "Halle A, Regal 3" |
| baujahr | Integer | Optional | z.B. 1985 |
| hersteller | String | Optional | z.B. "Ziegler" |
| gewicht_kg | Number | Optional | Gewicht in kg |
| bilder | Files | Array | Fotos des Exponats |
| audio_beschreibung | File | Optional | MP3/WAV Audiodatei |
| pdf_dokument | File | Optional | Betriebsanleitung, etc. |
| externe_links | JSON | Array of Objects | URLs zu Websites, Videos |
| gruppierungen | Many-to-Many | Link zu "Exponatgruppe" | Zugehörigkeit zu Gruppen |
| qr_code | String | Auto-generated | QR-Code URL |
| besonderheiten | Text | Optional | Erhaltungszustand, Funktionsfähigkeit |
| status | Dropdown | active/inactive | Ist das Exponat ausgestellt? |
| erstellt_am | Timestamp | Auto | Erstellungsdatum |
| aktualisiert_am | Timestamp | Auto | Letztes Änderungsdatum |

**Beispiel-Eintrag:**
```json
{
  "inventarnummer": "FW-2024-001",
  "name": "Tragkraftspritze TS 8/5",
  "kategorie_id": 2,
  "beschreibung": "Tragbare Spritze mit hoher Leistung, noch funktionsfähig",
  "standort": "Halle A, Regal 3",
  "baujahr": 1985,
  "hersteller": "Ziegler",
  "gewicht_kg": 450,
  "status": "active"
}
```

---

### 2. Collection: "Kategorie"

Kategorisierung der Exponate

| Feldname | Typ | Eigenschaften |
|----------|-----|---------------|
| id | Integer | Primary Key, Auto |
| name | String | Required, Unique |
| beschreibung | Text | Optional |
| icon | File | Optional (SVG/PNG) |
| farbe | String | Optional (Hex: #FF6B6B) |
| sortierung | Integer | Reihenfolge in UI |

**Vordefinierte Kategorien:**
- 🚒 Fahrzeuge
- 💧 Pumpen & Spritzen
- 🔗 Schläuche & Anschlüsse
- 🛡️ Schutzausrüstung
- 🔧 Werkzeug & Zubehör
- 👔 Uniformen & Abzeichen
- 📚 Dokumentation & Archive
- ❓ Sonstiges

---

### 3. Collection: "Exponatgruppe"

Gruppierung von verwandten Exponaten

| Feldname | Typ | Eigenschaften |
|----------|-----|---------------|
| id | Integer | Primary Key, Auto |
| name | String | Required, Unique |
| beschreibung | Text | Optional |
| exponate | Many-to-Many | Link zu "Exponat" |
| gruppenfoto | File | Optional |
| sortierung | Integer | Reihenfolge |

**Beispiel-Gruppen:**
- "Tragkraftspritzen der 1980er"
- "Rotes Fahrzeug #42 - Komponenten"
- "Historische Schutzausrüstung"
- "Löschfahrzeuge der Gemeinde"

---

## Setup in Directus Admin Interface

### Schritt 1: Login
```
http://localhost:8055
Benutzer: admin@museum.local
Password: (aus .env)
```

### Schritt 2: Collections erstellen
1. Klick auf "Settings" (⚙️ oben rechts)
2. Navigation → "Data Model"
3. "Create Collection" klicken
4. Felder wie oben beschrieben hinzufügen

### Schritt 3: Relations konfigurieren
1. Bei "kategorie_id" → Feld-Editor → "Relationship"
2. "Related Collection" = "Kategorie"
3. Speichern

### Schritt 4: Many-to-Many für Gruppierungen
1. Bei "gruppierungen" → "Relationship"
2. Type: "Many-to-Many"
3. Related Collection: "Exponatgruppe"
4. Speichern

---

## JSON Konfiguration (API Export)

Diese Struktur können Sie auch per API importieren:

```json
{
  "collections": [
    {
      "collection": "exponat",
      "meta": {
        "icon": "folder_special",
        "display_template": "{{inventarnummer}} - {{name}}",
        "color": "#FF6B6B"
      },
      "fields": [
        {
          "field": "id",
          "type": "uuid",
          "meta": { "hidden": true }
        },
        {
          "field": "inventarnummer",
          "type": "string",
          "meta": { 
            "interface": "input",
            "required": true,
            "unique": true
          }
        },
        {
          "field": "name",
          "type": "string",
          "meta": { 
            "interface": "input",
            "required": true
          }
        },
        {
          "field": "kategorie_id",
          "type": "integer",
          "meta": {
            "interface": "select-dropdown-m2o",
            "relationships": [
              {
                "collection": "kategorie",
                "field": "id",
                "meta": { "one_allowed": false }
              }
            ]
          }
        },
        {
          "field": "beschreibung",
          "type": "text",
          "meta": { "interface": "input-rich-text-html" }
        },
        {
          "field": "standort",
          "type": "string",
          "meta": { "interface": "input" }
        },
        {
          "field": "baujahr",
          "type": "integer",
          "meta": { "interface": "input-number" }
        },
        {
          "field": "hersteller",
          "type": "string",
          "meta": { "interface": "input" }
        },
        {
          "field": "gewicht_kg",
          "type": "decimal",
          "meta": { "interface": "input-number" }
        },
        {
          "field": "bilder",
          "type": "json",
          "meta": { "interface": "file-image" }
        },
        {
          "field": "audio_beschreibung",
          "type": "string",
          "meta": { "interface": "file-audio" }
        },
        {
          "field": "pdf_dokument",
          "type": "string",
          "meta": { "interface": "file-pdf" }
        },
        {
          "field": "externe_links",
          "type": "json",
          "meta": { "interface": "input-code", "note": "[{typ, url, label}]" }
        },
        {
          "field": "status",
          "type": "string",
          "meta": {
            "interface": "select-dropdown",
            "options": [
              { "text": "Aktiv", "value": "active" },
              { "text": "Inaktiv", "value": "inactive" },
              { "text": "In Reparatur", "value": "repair" }
            ]
          }
        },
        {
          "field": "erstellt_am",
          "type": "timestamp",
          "meta": { "hidden": true, "readonly": true }
        },
        {
          "field": "aktualisiert_am",
          "type": "timestamp",
          "meta": { "hidden": true, "readonly": true }
        }
      ]
    },
    {
      "collection": "kategorie",
      "meta": {
        "icon": "category",
        "color": "#4ECDC4",
        "display_template": "{{name}}"
      }
    },
    {
      "collection": "exponatgruppe",
      "meta": {
        "icon": "collections",
        "color": "#95E1D3",
        "display_template": "{{name}}"
      }
    }
  ]
}
```

---

## API Queries (Beispiele)

### Alle Exponate abrufen
```bash
curl "http://localhost:8055/items/exponat?fields=*.*"
```

### Exponat mit ID abrufen
```bash
curl "http://localhost:8055/items/exponat/f47ac10b-58cc-4372-a567-0e02b2c3d479?fields=*.*"
```

### Exponate einer Kategorie
```bash
curl "http://localhost:8055/items/exponat?filter[kategorie_id][_eq]=2&fields=*.*"
```

### Neues Exponat erstellen
```bash
curl -X POST "http://localhost:8055/items/exponat" \
  -H "Content-Type: application/json" \
  -d '{
    "inventarnummer": "FW-2024-001",
    "name": "Tragkraftspritze",
    "kategorie_id": 2,
    "baujahr": 1985
  }'
```

---

## Tipps & Best Practices

✅ **Zu beachten:**
- Inventarnummern sollten eindeutig (UNIQUE) sein
- QR-Code URL: automatisch generiert aus `{ID}`
- Array-Felder für mehrere Bilder nutzen
- JSON-Felder für komplexe Strukturen
- Relations für Flexible Groupierungen

⚠️ **Besonderheiten:**
- Timestamps werden automatisch gesetzt
- Dateien landen im `/uploads/` Verzeichnis
- Standard Dateigröße: 50MB (in docker-compose.yml anpassbar)
- File-Metadaten (EXIF) werden auto-extrahiert

---

Weitere Infos: [Directus Official Docs](https://docs.directus.io/)
