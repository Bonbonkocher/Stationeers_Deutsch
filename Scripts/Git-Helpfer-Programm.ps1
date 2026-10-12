# ==============================================================================
# GIT-HELFER (PowerShell for Windows)
# Copyright (c) 2026 Jens (Bonbonkocher)
# ==============================================================================

# Skript liegt in "Scripts/", Root ist ein Ordner darüber
$ORDNER_SCRIPTS = $PSScriptRoot
$PROJEKT_ROOT   = (Get-Item $PSScriptRoot).Parent.FullName

# Arbeitsverzeichnis auf das Projekt-Root setzen
Set-Location $PROJEKT_ROOT

# --- PFADE ---
$DATEI_VERSION  = Join-Path $ORDNER_SCRIPTS "version.txt"
$DATEI_NAME     = Join-Path $ORDNER_SCRIPTS "name.txt"
$VDF_PFAD       = Join-Path $PROJEKT_ROOT "update_mod.vdf"
$STEAMCMD_PFAD  = Join-Path $PROJEKT_ROOT "steamcmd\steamcmd.exe"

# Definition der Pakete (relativ zum Projekt-Root)
$DATEIEN_NORMAL = @("StationeersDE\rocketstation_Data")
$DATEIEN_MOD    = @("SteamMod\About", "SteamMod\GameData")

# Sicherstellen, dass der Scripts-Ordner existiert
if (!(Test-Path $ORDNER_SCRIPTS)) { New-Item -ItemType Directory -Path $ORDNER_SCRIPTS -Force | Out-Null }

# --- MOD-NAME & VERSION LADEN ---
if (Test-Path $DATEI_NAME) { $MOD_NAME = (Get-Content $DATEI_NAME -Raw).Trim() } else { $MOD_NAME = "Stationeers_Deutsch" }
if (Test-Path $DATEI_VERSION) { $aktuelleVersion = (Get-Content $DATEI_VERSION -Raw).Trim() } else { $aktuelleVersion = "0.0.1" }

$letzteNachricht = ""
$letzteAktion = "Programm gestartet"

while ($true) {
    Clear-Host
    Write-Host "--- GitHub & Steam Workshop Manager ---" -ForegroundColor Cyan
    Write-Host "Projekt: $MOD_NAME | Version: $aktuelleVersion" -ForegroundColor Green
    Write-Host "Letzte Aktion: $letzteAktion" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Was moechtest du tun?" -ForegroundColor White
    Write-Host "------------------------------------------------"
    Write-Host "[0] Status-Datei    - Kurzer Git-Status"
    Write-Host "[1] Pull            - Lade die neusten Dateien von GitHub"
    Write-Host "[2] Push (Git)      - Lade die geaenderten Dateien auf GitHub"
    Write-Host "[3] Status-Zeile    - Diff ansehen"
    Write-Host "[4] ZIP & Sync      - Kopiert Language, aktualisiert XML & baut ZIPs"
    Write-Host "[5] Release (gh)    - Upload zu GitHub Releases"
    Write-Host "[6] Steam Update    - Upload in den Steam Workshop"
    Write-Host "------------------------------------------------"
    Write-Host "[V] Version aendern [N] Name aendern"
    Write-Host "[Q] Beenden"
    Write-Host ""

    $eingabe = (Read-Host "-> Auswahl").Trim().ToLower()

    switch ($eingabe) {
      
        "0" { 
            Write-Host "`n--- DATEI STATUS ---" -ForegroundColor Yellow
            git status -s
            $letzteAktion = "Status geprueft"
            $null = [Console]::ReadKey() 
        }
        
        "1" { 
            Write-Host "`n--- GIT PULL ---" -ForegroundColor Yellow
            git pull
            $letzteAktion = "Pull erledigt"
            $null = [Console]::ReadKey() 
        }
        
        "2" {
            Write-Host "`n--- GIT PUSH ---" -ForegroundColor Yellow
            $msg = Read-Host "Commit-Nachricht (leer lassen fuer Zeitstempel)"
            if (-not $msg) { $msg = "Update $(Get-Date -Format 'dd.MM.yyyy HH:mm')" }
            $letzteNachricht =$msg
            git add .
            git commit -m "$msg"
            git push
            $letzteAktion = "Git Push: $msg"
            $null = [Console]::ReadKey()
        }

        "3" { 
            Write-Host "`n--- DETAIL STATUS ---" -ForegroundColor Yellow
            git --no-pager diff
            git --no-pager diff --cached
            $letzteAktion = "Diff geprueft"
            $null = [Console]::ReadKey() 
        }
        
        "4" {
            Write-Host "`n--- SYNCHRONISIEREN & ZIP ERSTELLUNG ---" -ForegroundColor Yellow
            
            # 1. Sprachdateien synchronisieren (aus Projekt-Root)
            $quelleLang = Join-Path $PROJEKT_ROOT "StationeersDE\rocketstation_Data\StreamingAssets\Language"
            $zielLang   = Join-Path $PROJEKT_ROOT "SteamMod\GameData\Language"
            if (Test-Path $quelleLang) {
                if (Test-Path $zielLang) { Remove-Item $zielLang -Recurse -Force }
                Copy-Item -Path $quelleLang -Destination $zielLang -Recurse -Force
                Write-Host "Sprachdateien synchronisiert." -ForegroundColor Green
            } else {
                Write-Host "WARNUNG: Quellordner nicht gefunden: $quelleLang" -ForegroundColor Red
            }

            # 2. XML Version aktualisieren (Verwendet Set-Content, keine Pipe!)
            $xmlPfad = Join-Path $PROJEKT_ROOT "SteamMod\About\About.xml"
            if (Test-Path $xmlPfad) {
				$content = Get-Content $xmlPfad -Raw
				$neuerContent = $content -replace '<Version>.*</Version>', "<Version>v$aktuelleVersion</Version>"
                Set-Content -Path $xmlPfad -Value $neuerContent -Encoding utf8 -Force
                Write-Host "About.xml auf v$aktuelleVersion aktualisiert." -ForegroundColor Green
            } else {
                Write-Host "WARNUNG: About.xml nicht gefunden: $xmlPfad" -ForegroundColor Red
            }
            
			# 3. ZIPs erstellen
            $zipOrdner = Join-Path $PROJEKT_ROOT "zip"
            if (!(Test-Path $zipOrdner)) { New-Item -ItemType Directory -Path $zipOrdner -Force | Out-Null }
            Remove-Item (Join-Path $zipOrdner "*.zip") -ErrorAction SilentlyContinue
            
            $pfadNormal = Join-Path $zipOrdner "$MOD_NAME-$aktuelleVersion.zip"
            $quellenNormal = Join-Path $PROJEKT_ROOT "StationeersDE\rocketstation_Data"
            Compress-Archive -Path $quellenNormal -DestinationPath $pfadNormal -Force
            
            $pfadMod = Join-Path $zipOrdner "${MOD_NAME}_Mod-$aktuelleVersion.zip"
            $quellenMod = @(
				(Join-Path $PROJEKT_ROOT "SteamMod\About"),
				(Join-Path $PROJEKT_ROOT "SteamMod\GameData")
			)
            Compress-Archive -Path $quellenMod -DestinationPath $pfadMod -Force

            $letzteAktion = "ZIPs erstellt ($aktuelleVersion)"
            Write-Host "ZIP-Dateien erfolgreich in '$zipOrdner' erstellt!" -ForegroundColor Green
            $null = [Console]::ReadKey()
        }
        
        "5" {
            Write-Host "`n--- GITHUB RELEASE ---" -ForegroundColor Yellow
            $zipNormal = Join-Path $PROJEKT_ROOT "zip\$MOD_NAME-$aktuelleVersion.zip"
            $zipMod    = Join-Path $PROJEKT_ROOT "zip\${MOD_NAME}_Mod-$aktuelleVersion.zip"
            
            $uploadFiles = @()
            if (Test-Path $zipNormal) { $uploadFiles += $zipNormal }
            if (Test-Path $zipMod)    { $uploadFiles += $zipMod }
            
            if ($uploadFiles.Count -gt 0) {
                $tagName = "v$aktuelleVersion"
                gh release create $tagName @uploadFiles --title "Version $aktuelleVersion" --generate-notes
                $letzteAktion = "GitHub Release v$aktuelleVersion"
            } else {
                Write-Host "Keine ZIP-Dateien zum Hochladen gefunden. Erst Punkt [4] ausfuehren!" -ForegroundColor Red
            }
            $null = [Console]::ReadKey()
        }
        
        "6" {
            Write-Host "`n--- STEAM WORKSHOP UPDATE ---" -ForegroundColor Yellow
            $steamNotes = Read-Host "Changenotes (Enter fuer: '$letzteNachricht')"
            if (-not $steamNotes) { $steamNotes =$letzteNachricht }
            if (-not $steamNotes) {$steamNotes = "Update v$aktuelleVersion" }

            $contentFolder = Join-Path $PROJEKT_ROOT "SteamMod"

            # Here-String sauber beendet
            $vdfContent = @"
"workshopitem"
{
 "appid"              "544550"
 "publishedfileid"    "3694636517"
 "contentfolder"      "$contentFolder"
 "changenotes"        "$steamNotes"
}
"@
            # Set-Content statt Pipe
            Set-Content -Path $VDF_PFAD -Value $vdfContent -Encoding ascii -Force

            if (Test-Path $STEAMCMD_PFAD) {
                Start-Process -FilePath $STEAMCMD_PFAD -ArgumentList "+login Bonbonkocher", "+workshop_build_item `"$VDF_PFAD`"", "+quit" -Wait
                $letzteAktion = "Steam Update erledigt"
            } else { 
                Write-Host "SteamCMD nicht gefunden unter: $STEAMCMD_PFAD" -ForegroundColor Red 
            }
            $null = [Console]::ReadKey()
        }
        
        "v" {
            $aktuelleVersion = (Read-Host "Neue Version").Trim()
            Set-Content -Path $DATEI_VERSION -Value$aktuelleVersion -Encoding utf8 -Force
            $letzteAktion = "Version -> $aktuelleVersion"
            Write-Host "Version gespeichert." -ForegroundColor Green
            Start-Sleep -Milliseconds 800
        }
        
        "n" {
            $MOD_NAME = (Read-Host "Neuer Projekt-Name").Trim()
            Set-Content -Path $DATEI_NAME -Value$MOD_NAME -Encoding utf8 -Force
            $letzteAktion = "Name -> $MOD_NAME"
            Write-Host "Name gespeichert." -ForegroundColor Green
            Start-Sleep -Milliseconds 800
        }
        
        "q" { 
            Write-Host "Beende..." -ForegroundColor Gray
            exit 
        }
    }
}