[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir    = Split-Path -Parent $scriptDir
$relSubPath = "rocketstation_Data\StreamingAssets\Language"

$newEnDir   = Join-Path -Path $rootDir -ChildPath "StationeersEN\$relSubPath"
$oldEnDir   = Join-Path -Path $rootDir -ChildPath "StationeersEN_OLD\$relSubPath"
$curDeDir   = Join-Path -Path $rootDir -ChildPath "StationeersDE\$relSubPath"
$outputDir  = Join-Path -Path $rootDir -ChildPath "Diff_Results"

if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$fileMapping = @(
    @{ EN = "english.xml";          DE = "german.xml" },
    @{ EN = "english_help.xml";     DE = "german_help.xml" },
    @{ EN = "english_keys.xml";     DE = "german_keys.xml" },
    @{ EN = "english_tips.xml";     DE = "german_tips.xml" },
    @{ EN = "english_tooltips.xml"; DE = "german_tooltips.xml" }
)

function Parse-StationeersXml {
    param ([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    [xml]$xml = Get-Content -LiteralPath $Path -Encoding UTF8
	$data = [ordered]@{}

    foreach ($section in $xml.Language.ChildNodes) {
        if ($section.NodeType -ne 'Element' -or$section.Name -in @('Name', 'Code', 'Font')) {
            continue
        }

        $sectionName =$section.Name
        foreach ($record in $section.ChildNodes) {
            if ($record.NodeType -ne 'Element') { continue }

            $key =$record.Key
            if (-not $key) { continue }

            $uniqueId = "$sectionName/$key"
            $data[$uniqueId] = [PSCustomObject]@{
                Section     = $sectionName
                Key         = $key
                Value       = $record.Value
                Description = if ($record.Description) { $record.Description } else {$null }
                Unit        = if ($record.Unit) { $record.Unit } else {$null }
                RecordTag   = $record.Name
            }
        }
    }
    return $data
}

Write-Host "Starte Sprachdateien-Abgleich...`n" -ForegroundColor Cyan

foreach ($item in $fileMapping) {
    $enFile    = Join-Path -Path $newEnDir -ChildPath $item.EN
    $deFile    = Join-Path -Path $curDeDir -ChildPath $item.DE
    $oldEnFile = Join-Path -Path $oldEnDir -ChildPath $item.EN

    Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "Pruefe: $($item.EN) <--> $($item.DE)" -ForegroundColor White

    if (-not (Test-Path -LiteralPath $enFile)) {
        Write-Warning "EN-Datei nicht gefunden: $enFile"
        continue
    }
    if (-not (Test-Path -LiteralPath $deFile)) {
        Write-Warning "DE-Datei nicht gefunden: $deFile"
        continue
    }

    $newEn = Parse-StationeersXml -Path $enFile
    $curDe = Parse-StationeersXml -Path $deFile
    $oldEn = if (Test-Path -LiteralPath $oldEnFile) { Parse-StationeersXml -Path $oldEnFile } else { $null }

    $missingInDe  = @()
    $obsoleteInDe = @()
    $modifiedInEn = @()

    foreach ($key in $newEn.Keys) {
        if (-not $curDe.Contains($key)) {
            $missingInDe += $newEn[$key]
        } elseif ($oldEn -and $oldEn.Contains($key)) {
            $oldItem = $oldEn[$key]
            $newItem = $newEn[$key]
            if ($oldItem.Value -ne $newItem.Value -or $oldItem.Description -ne $newItem.Description) {
                $modifiedInEn += [PSCustomObject]@{
                    Section        = $newItem.Section
                    Key            = $newItem.Key
                    OldEnValue     = $oldItem.Value
                    NewEnValue     = $newItem.Value
                    OldEnDesc      = $oldItem.Description
                    NewEnDesc      = $newItem.Description
                    CurrentDeValue = $curDe[$key].Value
                    CurrentDeDesc  = $curDe[$key].Description
                }
            }
        }
    }

    foreach ($key in $curDe.Keys) {
        if (-not $newEn.Contains($key)) {
            $obsoleteInDe += $curDe[$key]
        }
    }

    Write-Host "  Fehlt in DE  : $($missingInDe.Count)" -ForegroundColor $(if ($missingInDe.Count -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host "  Geaendert    : $($modifiedInEn.Count)" -ForegroundColor $(if ($modifiedInEn.Count -gt 0) { 'Magenta' } else { 'Green' })
    Write-Host "  Veraltet     : $($obsoleteInDe.Count)" -ForegroundColor $(if ($obsoleteInDe.Count -gt 0) { 'Red' } else { 'Green' })

    if ($missingInDe.Count -gt 0 -or $modifiedInEn.Count -gt 0 -or $obsoleteInDe.Count -gt 0) {
        $exportPath = Join-Path -Path $outputDir -ChildPath "$($item.EN -replace '\.xml$', '.diff.json')"
        $exportData = [PSCustomObject]@{
            File         = $item.EN
            MissingInDe  = $missingInDe
            ModifiedInEn = $modifiedInEn
            ObsoleteInDe = $obsoleteInDe
        }
        $exportData | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $exportPath -Encoding UTF8
        Write-Host "  -> Exportiert nach: Diff_Results\$($item.EN -replace '\.xml$', '.diff.json')" -ForegroundColor Cyan
    }
}

Write-Host "`nAlle Dateien geprueft." -ForegroundColor Green
