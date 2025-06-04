#
.SYNOPSIS
    Installiert oder aktualisiert PDF24 Creator.

.DESCRIPTION
    Prüft die installierte Version von PDF24 Creator und vergleicht sie mit der aktuellen Online-Version.
    Falls ein Update nötig ist, wird die MSI-Datei heruntergeladen und installiert.

.EXITCODES
    0: Erfolgreich, keine Aktion nötig
    1: Fehler beim Download
    2: Fehler bei der Installation
#

# Funktion: Installierte Version auslesen
function Get-InstalledPDF24Version {
    $regPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\PDF24\PDF24 Creator",
        "HKLM:\SOFTWARE\PDF24\PDF24 Creator"
    )
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            try {
                $version = Get-ItemProperty -Path $regPath -Name "Version" -ErrorAction Stop
                return $version.Version
            } catch {
                Write-Warning "Fehler beim Abrufen der Version aus $regPath."
            }
        }
    }
    return $null
}

# Aktuelle Version (manuell gepflegt)
$currentOnlineVersion = "11.26.1"

# Installierte Version ermitteln
$installedVersion = Get-InstalledPDF24Version

Write-Host "Installierte Version: $installedVersion"
Write-Host "Verfügbare Version: $currentOnlineVersion"

# Vergleich
if ($installedVersion -and [System.Version]$installedVersion -ge [System.Version]$currentOnlineVersion) {
    Write-Host "PDF24 Creator ist bereits auf dem neuesten Stand."
    exit 0
}

# Download-URL der MSI-Datei
$pdf24InstallerUrl = "https://www.pdf24.org/products/pdf-creator/download/pdf24-creator.msi"
$pdf24Installer = "$env:TEMP\pdf24-creator.msi"

# MSI herunterladen
try {
    Invoke-WebRequest -Uri $pdf24InstallerUrl -OutFile $pdf24Installer
    if (-not (Test-Path $pdf24Installer)) {
        Write-Host "Fehler: Die heruntergeladene Datei wurde nicht gefunden."
        exit 1
    }
} catch {
    Write-Host "Fehler: Download der PDF24 MSI-Datei fehlgeschlagen. Details: $($_.Exception.Message)"
    exit 1
}

# Installation mit benutzerdefinierten Parametern
# AUTOUPDATE=No → deaktiviert automatische Updates
# FAXPRINTER=No → Faxdrucker wird nicht installiert
# SETDEFAULTPRINTER=No → PDF24 wird nicht als Standard-PDF-Programm gesetzt

$process = Start-Process "msiexec.exe" -ArgumentList "/i `"$pdf24Installer`" /qn AUTOUPDATE=No FAXPRINTER=No SETDEFAULTPRINTER=No" -Wait -PassThru
	if ($process.ExitCode -ne 0) {
  	  Write-Host "Fehler: Die Installation ist fehlgeschlagen mit ExitCode $($process.ExitCode)."
  	  exit 2
}

# MSI-Datei entfernen
try {
    Remove-Item -Path $pdf24Installer -Force
} catch {
    Write-Warning "Hinweis: Die MSI-Datei konnte nicht gelöscht werden. Details: $($_.Exception.Message)"
}

Write-Host "PDF24 Creator wurde erfolgreich installiert oder aktualisiert!"