[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir    = Split-Path -Parent $scriptDir
$relSubPath = "rocketstation_Data\StreamingAssets\Language"

$curDeDir   = Join-Path -Path $rootDir -ChildPath "StationeersDE\$relSubPath"
$inputDir   = Join-Path -Path $rootDir -ChildPath "Diff_Translation"

$fileMapping = @(
    @{ JSON = "english.diff.json";          DE = "german.xml" },
    @{ JSON = "english_help.diff.json";     DE = "german_help.xml" },
    @{ JSON = "english_keys.diff.json";     DE = "german_keys.xml" },
    @{ JSON = "english_tips.diff.json";     DE = "german_tips.xml" },
    @{ JSON = "english_tooltips.diff.json"; DE = "german_tooltips.xml" }
)

Write-Host "Starte Einpflegen der Uebersetzungen...`n" -ForegroundColor Cyan

foreach ($item in $fileMapping) {
    $jsonPath = Join-Path -Path $inputDir -ChildPath $item.JSON
    $dePath   = Join-Path -Path $curDeDir -ChildPath $item.DE

    if (-not (Test-Path -LiteralPath $jsonPath)) {
        continue
    }
    if (-not (Test-Path -LiteralPath $dePath)) {
        Write-Warning "Zieldatei nicht gefunden: $dePath"
        continue
    }

    Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Verarbeite: $($item.JSON) -> $($item.DE)" -ForegroundColor White

    $rawJson = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8
    $diffData = $rawJson | ConvertFrom-Json

    [xml]$xml = Get-Content -LiteralPath $dePath -Encoding UTF8

    $addedCount    = 0
    $updatedCount  = 0
    $removedCount  = 0

    # 1. Neue Einträge einpflegen
    if ($diffData.MissingInDe) {
        foreach ($entry in $diffData.MissingInDe) {
            $sectionNode = $xml.Language.SelectSingleNode($entry.Section)
            if (-not $sectionNode) {
                $sectionNode = $xml.CreateElement($entry.Section)
                $xml.Language.AppendChild($sectionNode) | Out-Null
            }

            $tagToUse = if ($entry.RecordTag) { $entry.RecordTag } else { "Record" }
            $newRecord = $xml.CreateElement($tagToUse)

            $keyElem = $xml.CreateElement("Key")
            $keyElem.InnerText = $entry.Key
            $newRecord.AppendChild($keyElem) | Out-Null

            $valElem = $xml.CreateElement("Value")
            $valElem.InnerText = if ($entry.Value) { $entry.Value } else { "" }
            $newRecord.AppendChild($valElem) | Out-Null

            if ($entry.Description) {
                $descElem = $xml.CreateElement("Description")
                $descElem.InnerText = $entry.Description
                $newRecord.AppendChild($descElem) | Out-Null
            }

            if ($entry.Unit) {
                $unitElem = $xml.CreateElement("Unit")
                $unitElem.InnerText = $entry.Unit
                $newRecord.AppendChild($unitElem) | Out-Null
            }

            $sectionNode.AppendChild($newRecord) | Out-Null
            $addedCount++
        }
    }

    # 2. Geänderte Einträge aktualisieren
    if ($diffData.ModifiedInEn) {
        foreach ($entry in $diffData.ModifiedInEn) {
            $recordNode = $xml.Language.SelectSingleNode("$($entry.Section)/*[Key='$($entry.Key)']")
            if ($recordNode) {
                if ($entry.CurrentDeValue) {
                    $valNode = $recordNode.SelectSingleNode("Value")
                    if ($valNode) { $valNode.InnerText = $entry.CurrentDeValue }
                }
                if ($entry.CurrentDeDesc) {
                    $descNode = $recordNode.SelectSingleNode("Description")
                    if ($descNode) { $descNode.InnerText = $entry.CurrentDeDesc }
                }
                $updatedCount++
            }
        }
    }

    # 3. Veraltete Einträge entfernen
    if ($diffData.ObsoleteInDe) {
        foreach ($entry in $diffData.ObsoleteInDe) {
            $obsoleteNode = $xml.Language.SelectSingleNode("$($entry.Section)/*[Key='$($entry.Key)']")
            if ($obsoleteNode) {
                $obsoleteNode.ParentNode.RemoveChild($obsoleteNode) | Out-Null
                $removedCount++
            }
        }
    }

    # Speichern mit sauberer XML-Formatierung
    $xmlSettings = New-Object System.Xml.XmlWriterSettings
    $xmlSettings.Indent = $true
    $xmlSettings.IndentChars = "  "
    $xmlSettings.Encoding = [System.Text.Encoding]::UTF8

    $writer = [System.Xml.XmlWriter]::Create($dePath, $xmlSettings)
    try {
        $xml.Save($writer)
    } finally {
        $writer.Dispose()
    }

    Write-Host "  Hinzugefuegt : $addedCount" -ForegroundColor Green
    Write-Host "  Aktualisiert : $updatedCount" -ForegroundColor Cyan
    Write-Host "  Entfernt     : $removedCount" -ForegroundColor Yellow
}

Write-Host "`nAlle Uebersetzungen erfolgreich eingepflegt." -ForegroundColor Green