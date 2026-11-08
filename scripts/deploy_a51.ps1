# Deploy / Install TARANG69 APK to connected Samsung Galaxy A51
param(
    [string]$ApkPath
)

$ErrorActionPreference = "Stop"

$adb = "C:\Users\Advice\.gemini\antigravity\tools\platform-tools\adb.exe"
if (!(Test-Path $adb)) {
    $adb = "adb"
}

Write-Host "=== Deploying TARANG69 to Samsung Galaxy A51 ===" -ForegroundColor Cyan

# 1. Check device
$deviceMatch = (& $adb devices) | Select-String -Pattern "\bdevice\b"
if (-not $deviceMatch) {
    Write-Host "[!] Warning: No authorized device found." -ForegroundColor Yellow
    & $adb devices
    exit 1
}
Write-Host "[OK] Device authorized and connected." -ForegroundColor Green

# 2. Resolve APK
if (-not $ApkPath -or -not (Test-Path $ApkPath)) {
    # Check if local release build exists
    $localApk = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $localApk) {
        $ApkPath = (Resolve-Path $localApk).Path
    } else {
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
Write-Host "[OK] ADB Install successful." -ForegroundColor Green

# 3. Copy to MTP Download folder as backup
try {
    $shell = New-Object -ComObject Shell.Application
    $thisPC = $shell.Namespace(17)
    $device = $thisPC.Items() | Where-Object { $_.Name -like "*A51*" }
    if ($device) {
        $storage = $device.GetFolder.Items() | Select-Object -First 1
        if ($storage) {
            $downloadFolder = $storage.GetFolder.Items() | Where-Object { $_.Name -eq "Download" }
            if ($downloadFolder) {
                $downloadFolder.GetFolder.CopyHere($ApkPath, 16)
                Write-Host "[OK] Backed up APK to phone Download folder." -ForegroundColor Green
            }
        }
    }
} catch {
    # Ignore MTP errors if busy
}

# 4. Launch App
Write-Host "[*] Launching TARANG69 on device..." -ForegroundColor Cyan
& $adb shell am start -n com.example.tarang69/.MainActivity | Out-Null
Write-Host "[OK] TARANG69 installed and launched successfully!" -ForegroundColor Green
