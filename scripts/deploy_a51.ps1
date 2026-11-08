<#
.SYNOPSIS
  Deploy / Install TARANG69 APK to connected Samsung Galaxy A51 (Tomtt)
.DESCRIPTION
  1. Checks if ADB is ready and device is connected.
  2. If APK path is passed, uses that. Otherwise gets latest APK from GitHub Release or local build.
  3. Installs / updates the APK via ADB (reinstall & downgrade allowed: adb install -r -d).
  4. Copies APK to phone's Download folder via Windows MTP for backup.
  5. Launches the app automatically on the phone.
#>
param(
    [string]$ApkPath
)

$ErrorActionPreference = "Stop"

$adb = "C:\Users\Advice\.gemini\antigravity\tools\platform-tools\adb.exe"
if (!(Test-Path $adb)) {
    $adb = "adb"
}

Write-Host "=== 📱 Deploying TARANG69 to Samsung Galaxy A51 ===" -ForegroundColor Cyan

# 1. Check device
$devices = & $adb devices
if ($devices -notmatch "device\b") {
    Write-Host "[!] Warning: No authorized device found. Output:" -ForegroundColor Yellow
    Write-Host $devices
    exit 1
}
Write-Host "[✓] Device authorized and connected." -ForegroundColor Green

# 2. Resolve APK
if (-not $ApkPath -or -not (Test-Path $ApkPath)) {
    # Check if local release build exists
    $localApk = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $localApk) {
        $ApkPath = (Resolve-Path $localApk).Path
    } else {
        # Download latest from GitHub
        Write-Host "[*] Fetching latest APK from GitHub Releases..." -ForegroundColor Yellow
        $scratchDir = "$env:TEMP\tarang69_deploy"
        if (!(Test-Path $scratchDir)) { New-Item -ItemType Directory -Path $scratchDir | Out-Null }
        gh release download --clobber -p "*.apk" -D $scratchDir
        $downloaded = Get-ChildItem -Path $scratchDir -Filter "*.apk" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($downloaded) {
            $ApkPath = $downloaded.FullName
        }
    }
}

if (-not $ApkPath -or -not (Test-Path $ApkPath)) {
    Write-Host "[X] Error: Could not locate APK file to install." -ForegroundColor Red
    exit 1
}

Write-Host "[*] Installing APK: $ApkPath" -ForegroundColor Cyan
& $adb install -r -d "$ApkPath"

# 3. Copy to MTP Download folder as backup
try {
    $shell = New-Object -ComObject Shell.Application
    $thisPC = $shell.Namespace(17)
    $device = $thisPC.Items() | Where-Object { $_.Name -like "*A51*" }
    if ($device) {
        $internal = $device.GetFolder.Items() | Where-Object { $_.Name -like "*ที่จัดเก็บข้อมูลภายใน*" }
        if ($internal) {
            $downloadFolder = $internal.GetFolder.Items() | Where-Object { $_.Name -eq "Download" }
            if ($downloadFolder) {
                $downloadFolder.GetFolder.CopyHere($ApkPath, 16)
                Write-Host "[✓] Backed up APK to phone's Download folder." -ForegroundColor Green
            }
        }
    }
} catch {
    # Ignore MTP errors if busy
}

# 4. Launch App
Write-Host "[*] Launching TARANG69 on device..." -ForegroundColor Cyan
& $adb shell am start -n com.example.tarang69/.MainActivity | Out-Null
Write-Host "[✓] TARANG69 installed and launched successfully! 🎉" -ForegroundColor Green
