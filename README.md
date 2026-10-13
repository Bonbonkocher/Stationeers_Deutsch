# Stationeers Deutsch-Mod

> [!NOTE]
> Ich bin wie viele andere im Berufsleben tätig – danke für euer Verständnis, dass Updates etwas Zeit in Anspruch nehmen können.

> [!WARNING]
> Diese Übersetzung ist ein fortlaufendes Community-Projekt und noch nicht zu 100 % vollständig.

> [!CAUTION]
> Bitte vor dem Überschreiben oder Ändern von Spieldateien immer eine Sicherungskopie der Originaldateien anlegen!

**Spiel-Version:** v0.2.6428.27798

---

## Status der XML-Dateien

| XML-Datei | Übertragen (Struktur) | Übersetzung |
| :---: | :---: | :---: |
| german.xml | [x] | [x] |
| german_help.xml | [x] | [x] |
| german_keys.xml | [x] | [x] |
| german_tips.xml | [x] | [x] |
| german_tooltips.xml | [x] | [x] |

---

## Links

- **GitHub:** [Stationeers Deutsch auf GitHub](https://github.com/Bonbonkocher/Stationeers/)
- **Steam Workshop:** [Stationeers Deutsch-Mod im Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3694636517)
- **Inspiriert von:** [[BETA] Deutsche Übersetzung von JonasVerzockt](https://steamcommunity.com/sharedfiles/filedetails/?id=3032318024)

---

## Installation für Spieler

Es gibt zwei Möglichkeiten, die deutsche Übersetzung zu nutzen:

### Methode 1: Über den Steam Workshop (Empfohlen)
1. Die Mod im [Steam Workshop abonnieren](https://steamcommunity.com/sharedfiles/filedetails/?id=3694636517).
2. Stationeers starten.
3. Im Hauptmenü unter Workshop / Mods die Mod aktivieren.
4. In den Spieleinstellungen die Sprache auf Deutsch stellen.

---

### Methode 2: Manuelle Installation (GitHub Release)
1. Die neueste Version unter [Releases](https://github.com/Bonbonkocher/Stationeers/releases) herunterladen.
2. Das Stationeers-Installationsverzeichnis öffnen (Standardpfad):  
   C:\Program Files (x86)\Steam\steamapps\common\Stationeers\
3. **Wichtig:** Sichere vorab deine Originaldateien aus dem Ordner:  
   ...\rocketstation_Data\StreamingAssets\Language\ (z. B. auf dem Desktop sichern).
4. Die heruntergeladene ZIP-Datei entpacken und den Ordner rocketstation_Data in das Spielverzeichnis kopieren (**Dateien ersetzen, nichts löschen!**).
5. Spiel starten und in den Einstellungen die Sprache auf Deutsch stellen.

---

## Workflow für Entwickler & Übersetzer

Dieses Projekt nutzt automatisierte PowerShell-Skripte im Ordner Scripts/, um manuelle Sisyphusarbeit bei Updates zu vermeiden.

### Ordnerstruktur

```
Stationeers_Deutsch/
├── Scripts/                                # PowerShell-Automatisierung
│   ├── Compare-StationeersLanguage.ps1     # Ermittelt Differenzen
│   ├── Apply-StationeersTranslations.ps1   # Pflegt übersetzte JSONs ein
│   ├── Git-Helpfer-Programm.ps1            # Release- & Workshop-Manager
│   ├── version.txt                         # Aktuelle Versionsnummer
│   └── name.txt                            # Projektname
├── StationeersEN/                          # Aktuelle englische Spieldateien
├── StationeersEN_OLD/                      # Vorherige englische Spieldateien (Referenz)
├── StationeersDE/                          # Übersetzte deutsche Spieldateien
├── Diff_Results/                           # Automatisch generierte Diff-Dateien (Rohdaten)
├── Diff_Translation/                       # Übersetzte JSON-Dateien für den Import
├── SteamMod/                               # Bereitstellung für Steam Workshop
├── Compare-StationeersLanguage.bat         # 1-Klick-Starter für Diff
├── Apply-StationeersTranslations.bat       # 1-Klick-Starter für Import
└── Git-Helpfer-Start.bat                   # 1-Klick-Starter für Git/Workshop Manager
```
---

### Technische Details zu den Skripten

#### 1. Compare-StationeersLanguage.ps1 (Diff-Tool)
Vergleicht alle 5 Sprachdateien (english.xml, english_help.xml, english_keys.xml, english_tips.xml, english_tooltips.xml) semantisch auf XML-Ebene:
- **Fehlende Einträge:** Findet neue Keys, die im aktuellen Patch hinzugekommen sind.
- **Geänderte Texte:** Vergleicht StationeersEN_OLD mit StationeersEN, um geänderte englische Originaltexte zu erkennen.
- **Veraltete Einträge:** Markiert Keys, die von den Entwicklern aus dem Spiel entfernt wurden.
- **Export:** Schreibt die Differenzen als JSON nach Diff_Results/*.diff.json.

#### 2. Apply-StationeersTranslations.ps1 (Import-Tool)
Liest fertig übersetzte JSON-Dateien aus Diff_Translation/ ein und pflegt sie in StationeersDE/ ein:
- Fügt neue Nodes in die passenden XML-Bereiche ein (Things, GameStrings, Interface, etc.).
- Unterstützt spezielle Record-Typen wie RecordThing (inkl. Description) und RecordReagent (inkl. Unit).
- Aktualisiert modifizierte Texte bestehender Keys.
- Entfernt veraltete Einträge automatisch aus den Zieldateien.
- Speichert sauber formatiertes XML (UTF-8, Einrückung).

#### 3. Git-Helpfer-Programm.ps1 (Projekt- & Release-Manager)
Interaktives Terminal-Menü für Git, GitHub und Steam Workshop:
- [0] Status-Datei: Kompakter Git-Status (git status -s).
- [1] Pull: Neueste Änderungen von GitHub laden.
- [2] Push: Änderungen mit Nachricht committen und pushen.
- [3] Status-Zeile: Detaillierter git diff der Änderungen.
- [4] ZIP & Sync: Synchronisiert Sprachdateien in den SteamMod-Ordner, aktualisiert die Version in SteamAbout.xml und baut Release-ZIPs in zip/.
- [5] Release (gh): Erstellt ein neues GitHub-Release und lädt die ZIP-Archive via GitHub-CLI hoch.
- [6] Steam Update: Erstellt die VDF-Datei und lädt das Mod-Update via SteamCMD in den Workshop hoch.
- [V] / [N]: Version und Mod-Name verwalten.

---

### Update-Ablauf bei neuem Spiel-Patch
1. **Sichern:** Bisherige Dateien aus StationeersEN/ nach StationeersEN_OLD/ verschieben.
2. **Kopieren:** Frische englische XMLs von Steam nach StationeersEN/ kopieren.
3. **Diff ausführen:** Compare-StationeersLanguage.bat starten (Ergebnis landet in Diff_Results/).
4. **Übersetzen:** JSON-Dateien übersetzen und in Diff_Translation/ ablegen.
5. **Importieren:** Apply-StationeersTranslations.bat ausführen (schreibt nach StationeersDE/).
6. **Validieren:** Compare-StationeersLanguage.bat erneut prüfen (alle Zähler auf 0).
7. **Veröffentlichen:** Über Git-Helpfer-Start.bat synchronisieren ([4]), testen und zu Steam/GitHub hochladen ([5], [6]).
