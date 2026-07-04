# Frontend für Feuerwehrmuseum - QR-Codes & Web-App

## 📱 Übersicht

Die Web-App zeigt:
1. QR-Codes zum Scannen mit Smartphone
2. Exponat-Details (Name, Beschreibung, Bilder)
3. Audio-Player für Beschreibungen
4. PDF-Viewer für Dokumentation
5. Links zu externen Ressourcen

---

## 🔲 QR-Code Generierung

### Option 1: QR-Code URL (einfach)

Jedes Exponat bekommt automatisch eine URL mit seiner ID:

```
https://museum.local/expo/{id}

Beispiel:
https://museum.local/expo/f47ac10b-58cc-4372-a567-0e02b2c3d479
```

Scanner dieser URL öffnet die Detail-Seite im Smartphone.

---

### Option 2: QR-Code mit Python generieren

Falls Sie QR-Codes als PNG-Dateien speichern möchten:

```python
import qrcode
import json
import os

def generate_qr_code(expo_id, expo_name, output_dir="qr_codes"):
    """Generiert QR-Code PNG für Exponat"""
    
    # Verzeichnis erstellen
    os.makedirs(output_dir, exist_ok=True)
    
    # URL mit Exponat-ID
    url = f"https://museum.local/expo/{expo_id}"
    
    # QR-Code erstellen
    qr = qrcode.QRCode(
        version=1,  # Größe
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)
    
    # Als Bild speichern
    img = qr.make_image(fill_color="black", back_color="white")
    filepath = os.path.join(output_dir, f"{expo_id}.png")
    img.save(filepath)
    
    print(f"✅ QR-Code erstellt: {filepath}")
    return url

# Verwendung
generate_qr_code(
    "f47ac10b-58cc-4372-a567-0e02b2c3d479", 
    "Tragkraftspritze"
)
```

**Installation:**
```bash
pip install qrcode[pil]
```

---

### Option 3: Batch-QR-Codes in PDF drucken (Etiketten)

```python
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
import qrcode
import requests
import json

def generate_label_sheet(api_url, output_file="feuerwehrmuseum_qr_labels.pdf"):
    """Erstellt PDF mit QR-Code-Etiketten (50x25mm pro Etikett)"""
    
    # Alle Exponate von Directus API abrufen
    response = requests.get(f"{api_url}/items/exponat?limit=1000")
    exponate = response.json()["data"]
    
    c = canvas.Canvas(output_file, pagesize=A4)
    c.setTitle("Feuerwehrmuseum QR-Code Etiketten")
    
    x, y = 10, 280  # Position (mm)
    etikett_breite = 50
    etikett_hoehe = 25
    
    for idx, expo in enumerate(exponate):
        print(f"Generiere QR-Code {idx+1}/{len(exponate)}: {expo['name']}")
        
        # QR-Code generieren
        qr = qrcode.QRCode(version=1, box_size=3, border=1)
        qr.add_data(f"https://museum.local/expo/{expo['id']}")
        qr.make()
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Temporär speichern
        img.save("temp_qr.png")
        
        # Etikett-Rahmen zeichnen
        c.rect(x*mm, (y-etikett_hoehe)*mm, 
               etikett_breite*mm, etikett_hoehe*mm, stroke=1, fill=0)
        
        # QR-Code zeichnen
        c.drawImage("temp_qr.png", 
                   x*mm + 1*mm, (y-20)*mm, 
                   width=15*mm, height=15*mm)
        
        # Text darunter
        c.setFont("Helvetica-Bold", 7)
        c.drawString(x*mm + 17*mm, (y-5)*mm, expo['inventarnummer'])
        
        c.setFont("Helvetica", 6)
        # Name auf 25 Zeichen kürzen
        name_short = expo['name'][:20]
        c.drawString(x*mm + 17*mm, (y-10)*mm, name_short)
        
        # Nächste Position
        x += etikett_breite + 3
        if x > 200:  # Neue Zeile
            x = 10
            y -= etikett_hoehe + 3
            
            if y < 25:  # Neue Seite
                c.showPage()
                y = 280
    
    c.save()
    print(f"✅ PDF erstellt: {output_file}")

# Verwendung
generate_label_sheet("http://localhost:8055/api")
```

---

## 🌐 Web-Frontend (HTML + Vanilla JS)

Einfache Single-Page App zum Anzeigen von Exponaten:

```html
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Feuerwehrmuseum - Exponat Viewer</title>
    <style>
        * { 
            margin: 0; 
            padding: 0; 
            box-sizing: border-box; 
        }
        
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container { 
            max-width: 900px; 
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 40px;
        }
        
        .loading {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        
        .error {
            background: #fee;
            border: 1px solid #f88;
            color: #d32f2f;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 20px;
        }
        
        h1 { 
            color: #d32f2f; 
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        
        .inventarnummer {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 20px;
        }
        
        .qr-section { 
            text-align: center; 
            margin: 30px 0;
            padding: 20px;
            background: #f9f9f9;
            border-radius: 8px;
        }
        
        .qr-section img { 
            border: 3px solid #333; 
            padding: 10px; 
            background: white;
            max-width: 200px;
            width: 100%;
        }
        
        .metadata {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin: 20px 0;
            padding: 15px;
            background: #f5f5f5;
            border-radius: 6px;
        }
        
        .metadata-item {
            display: flex;
            flex-direction: column;
        }
        
        .metadata-label {
            font-weight: bold;
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            margin-bottom: 5px;
        }
        
        .metadata-value {
            color: #333;
            font-size: 1.1em;
        }
        
        .description {
            background: #f9f9f9;
            padding: 20px;
            border-left: 4px solid #d32f2f;
            margin: 20px 0;
            border-radius: 4px;
            line-height: 1.6;
        }
        
        .gallery { 
            display: grid; 
            grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
            gap: 12px;
            margin: 30px 0;
        }
        
        .gallery img {
            cursor: pointer;
            border-radius: 6px;
            transition: transform 0.2s, box-shadow 0.2s;
            object-fit: cover;
            height: 150px;
            width: 100%;
        }
        
        .gallery img:hover {
            transform: scale(1.05);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }
        
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.9);
        }
        
        .modal.active {
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .modal-content {
            position: relative;
            background: white;
            padding: 0;
            border-radius: 8px;
            max-width: 90%;
            max-height: 90vh;
            overflow: auto;
        }
        
        .modal img {
            width: 100%;
            height: auto;
            display: block;
        }
        
        .close {
            position: absolute;
            right: 20px;
            top: 20px;
            font-size: 40px;
            font-weight: bold;
            color: white;
            cursor: pointer;
            background: rgba(0,0,0,0.5);
            width: 50px;
            height: 50px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .media-section {
            margin: 30px 0;
        }
        
        .media-title {
            font-size: 1.2em;
            font-weight: bold;
            color: #333;
            margin-bottom: 12px;
            border-bottom: 2px solid #d32f2f;
            padding-bottom: 8px;
        }
        
        audio, iframe { 
            width: 100%; 
            margin: 15px 0;
            border-radius: 6px;
        }
        
        audio {
            height: 50px;
        }
        
        iframe {
            height: 600px;
            border: 1px solid #ddd;
        }
        
        .links {
            display: flex;
            flex-direction: column;
            gap: 10px;
        }
        
        .links a {
            display: inline-block;
            padding: 12px 15px;
            background: #d32f2f;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            transition: background 0.2s;
            font-weight: 500;
        }
        
        .links a:hover {
            background: #b71c1c;
        }
        
        .print-button {
            position: fixed;
            bottom: 20px;
            right: 20px;
            padding: 15px 25px;
            background: #4CAF50;
            color: white;
            border: none;
            border-radius: 50px;
            cursor: pointer;
            font-weight: bold;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .print-button:hover {
            transform: scale(1.1);
            box-shadow: 0 6px 16px rgba(0,0,0,0.3);
        }
        
        @media print {
            body { background: white; }
            .container { box-shadow: none; }
            .print-button { display: none; }
            .gallery { grid-template-columns: repeat(2, 1fr); }
            .gallery img { height: 200px; }
        }
        
        @media (max-width: 768px) {
            .container { padding: 20px; }
            h1 { font-size: 1.8em; }
            .metadata { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div id="loading" class="loading">🔄 Laden...</div>
        <div id="content" style="display: none;">
            <div id="error" class="error" style="display: none;"></div>
            
            <h1 id="name"></h1>
            <div class="inventarnummer" id="inventarnummer"></div>
            
            <!-- QR-Code -->
            <div class="qr-section">
                <img id="qr-code" alt="QR-Code">
                <p style="margin-top: 10px; color: #666;">Scannen Sie diesen QR-Code</p>
            </div>
            
            <!-- Metadaten -->
            <div class="metadata" id="metadata"></div>
            
            <!-- Beschreibung -->
            <div id="beschreibung" class="description" style="display: none;"></div>
            
            <!-- Galerie -->
            <div id="galerie-section" style="display: none;">
                <h2 class="media-title">📷 Fotos</h2>
                <div id="bilder" class="gallery"></div>
            </div>
            
            <!-- Audio -->
            <div id="audio-section" style="display: none;">
                <h2 class="media-title">🎙️ Audiobeschreibung</h2>
                <audio id="audio" controls></audio>
            </div>
            
            <!-- PDF -->
            <div id="pdf-section" style="display: none;">
                <h2 class="media-title">📄 Dokumentation</h2>
                <iframe id="pdf"></iframe>
            </div>
            
            <!-- Links -->
            <div id="links-section" style="display: none;">
                <h2 class="media-title">🔗 Weiterführende Links</h2>
                <div id="links" class="links"></div>
            </div>
        </div>
    </div>
    
    <!-- Modal für Bildanzeige -->
    <div id="imageModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeImageModal()">&times;</span>
            <img id="modalImage" src="" alt="">
        </div>
    </div>
    
    <!-- Print Button -->
    <button class="print-button" onclick="window.print()">🖨️ Drucken</button>
    
    <script>
        const API_BASE = "http://localhost:8055/api";
        
        async function loadExponat() {
            try {
                // Exponat-ID aus URL Parameter abrufen
                const params = new URLSearchParams(window.location.search);
                const id = params.get('id');
                
                if (!id) {
                    throw new Error('Keine Exponat-ID in URL übergeben');
                }
                
                // Von Directus API abrufen
                const response = await fetch(`${API_BASE}/items/exponat/${id}`);
                if (!response.ok) throw new Error('Exponat nicht gefunden');
                
                const data = await response.json();
                const expo = data.data;
                
                // DOM aktualisieren
                document.getElementById('loading').style.display = 'none';
                document.getElementById('content').style.display = 'block';
                
                document.getElementById('name').textContent = expo.name;
                document.getElementById('inventarnummer').textContent = `${expo.inventarnummer} | ${expo.status || 'aktiv'}`;
                
                // QR-Code
                document.getElementById('qr-code').src = 
                    `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(window.location.href)}`;
                
                // Metadaten
                const metadata = document.getElementById('metadata');
                if (expo.kategorie?.name) {
                    metadata.innerHTML += `
                        <div class="metadata-item">
                            <span class="metadata-label">📂 Kategorie</span>
                            <span class="metadata-value">${expo.kategorie.name}</span>
                        </div>
                    `;
                }
                if (expo.standort) {
                    metadata.innerHTML += `
                        <div class="metadata-item">
                            <span class="metadata-label">📍 Standort</span>
                            <span class="metadata-value">${expo.standort}</span>
                        </div>
                    `;
                }
                if (expo.baujahr) {
                    metadata.innerHTML += `
                        <div class="metadata-item">
                            <span class="metadata-label">📅 Baujahr</span>
                            <span class="metadata-value">${expo.baujahr}</span>
                        </div>
                    `;
                }
                if (expo.hersteller) {
                    metadata.innerHTML += `
                        <div class="metadata-item">
                            <span class="metadata-label">🏭 Hersteller</span>
                            <span class="metadata-value">${expo.hersteller}</span>
                        </div>
                    `;
                }
                if (expo.gewicht_kg) {
                    metadata.innerHTML += `
                        <div class="metadata-item">
                            <span class="metadata-label">⚖️ Gewicht</span>
                            <span class="metadata-value">${expo.gewicht_kg} kg</span>
                        </div>
                    `;
                }
                
                // Beschreibung
                if (expo.beschreibung) {
                    document.getElementById('beschreibung').innerHTML = expo.beschreibung;
                    document.getElementById('beschreibung').style.display = 'block';
                }
                
                // Galerie
                if (expo.bilder && expo.bilder.length > 0) {
                    const galerie = document.getElementById('bilder');
                    expo.bilder.forEach(bild => {
                        const img = document.createElement('img');
                        img.src = `${API_BASE}/files/${bild.id}`;
                        img.onclick = () => openImageModal(img.src);
                        galerie.appendChild(img);
                    });
                    document.getElementById('galerie-section').style.display = 'block';
                }
                
                // Audio
                if (expo.audio_beschreibung) {
                    document.getElementById('audio').src = `${API_BASE}/files/${expo.audio_beschreibung}`;
                    document.getElementById('audio-section').style.display = 'block';
                }
                
                // PDF
                if (expo.pdf_dokument) {
                    document.getElementById('pdf').src = `${API_BASE}/files/${expo.pdf_dokument}`;
                    document.getElementById('pdf-section').style.display = 'block';
                }
                
                // Links
                if (expo.externe_links && expo.externe_links.length > 0) {
                    const links = document.getElementById('links');
                    expo.externe_links.forEach(link => {
                        const a = document.createElement('a');
                        a.href = link.url;
                        a.textContent = `🔗 ${link.typ}: ${link.label || link.url}`;
                        a.target = '_blank';
                        links.appendChild(a);
                    });
                    document.getElementById('links-section').style.display = 'block';
                }
                
            } catch (error) {
                console.error('Fehler:', error);
                document.getElementById('loading').style.display = 'none';
                document.getElementById('content').style.display = 'block';
                document.getElementById('error').textContent = `❌ Fehler: ${error.message}`;
                document.getElementById('error').style.display = 'block';
            }
        }
        
        function openImageModal(src) {
            document.getElementById('modalImage').src = src;
            document.getElementById('imageModal').classList.add('active');
        }
        
        function closeImageModal() {
            document.getElementById('imageModal').classList.remove('active');
        }
        
        // Modal schließen bei Klick außerhalb
        window.onclick = function(event) {
            const modal = document.getElementById('imageModal');
            if (event.target === modal) {
                closeImageModal();
            }
        }
        
        // Page laden
        loadExponat();
    </script>
</body>
</html>
```

**Verwendung:**
```
http://localhost:8055/expo-viewer.html?id=f47ac10b-58cc-4372-a567-0e02b2c3d479
```

Oder als Direktlink in Ihrem Museum bereitstellen.

---

## 📱 Mobile App Alternativen

- **Progressive Web App (PWA)** - Offline nutzbar
- **React Native / Flutter** - Native Mobile Apps
- **Expo (React Native)** - Schnelle Cross-Platform Lösung

---

## Tipps für Museum

✅ **Touchscreen-freundlich** - Buttons groß genug
✅ **Offline-Modus** - Service Workers für Bilder-Cache
✅ **QR-Code gut sichtbar** - Mindestens 5cm x 5cm auf Etiketten
✅ **Audio-Qualität** - 128kbps MP3 sollte ausreichen
✅ **PDF-Links** - Technische Dokumentation online abrufbar

---

Weitere Infos: [Frontend Setup Guides](https://docs.directus.io/guides/)
