# Deploy / Install TARANG69 APK to Samsung Galaxy A51 (Wireless & USB supported)
param(
    [string]$ApkPath,
    [string]$WirelessEndpoint,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Continue"

$adb = "C:\Users\Advice\.gemini\antigravity\tools\platform-tools\adb.exe"
if (!(Test-Path $adb)) {
    $adb = "adb"
}

function Get-AuthorizedAdbDevices {
    $devices = @()
    foreach ($line in (& $adb devices)) {
        if ($line.Trim() -match "^(\S+)\s+device(?:\s|$)") {
            $devices += $Matches[1]
        }
    }
    return $devices
}

function Find-MdnsWirelessEndpoint {
    $lines = & $adb mdns services 2>$null
    $fallback = $null
    foreach ($line in $lines) {
        if ($line.Trim() -match "^(\S+)\s+_adb-tls-connect\._tcp\s+(\S+)$") {
            $serviceName = $Matches[1]
            $endpoint = $Matches[2]
            if ($serviceName -like "*R58N34WMCKZ*" -or $endpoint -like "192.168.100.151:*") {
                return $endpoint
            }
            if (-not $fallback) {
                $fallback = $endpoint
            }
        }
    }
    return $fallback
}

Write-Host "=== Deploying TARANG69 to Samsung Galaxy A51 ===" -ForegroundColor Cyan
& $adb start-server | Out-Null

# 1. Resolve USB / Wireless ADB connection (auto-discover changing TLS port via mDNS)
if ($WirelessEndpoint) {
    Write-Host "[*] Connecting to specified endpoint $WirelessEndpoint..." -ForegroundColor Gray
    $null = & $adb connect $WirelessEndpoint
}

$authorized = Get-AuthorizedAdbDevices
if (-not $authorized) {
    Write-Host "[*] Waiting for USB or Wireless ADB (mDNS) discovery..." -ForegroundColor Gray
    for ($i = 0; $i -lt 10 -and -not $authorized; $i++) {
        Start-Sleep -Milliseconds 500
        $authorized = Get-AuthorizedAdbDevices
        if (-not $authorized -and $i -ge 2) {
            $mdnsEndpoint = Find-MdnsWirelessEndpoint
            if ($mdnsEndpoint) {
                Write-Host "[*] Discovered Wireless ADB endpoint: $mdnsEndpoint" -ForegroundColor Gray
                $null = & $adb connect $mdnsEndpoint
                $authorized = Get-AuthorizedAdbDevices
            }
        }
    }
}

# 2. Pick preferred target device (USB > Wireless A51 > first online device)
$targetDevice = ($authorized | Where-Object { $_ -eq "R58N34WMCKZ" } | Select-Object -First 1)
if (-not $targetDevice) {
    $targetDevice = ($authorized | Where-Object { $_ -like "adb-R58N34WMCKZ*" -or $_ -like "192.168.100.151:*" } | Select-Object -First 1)
}
if (-not $targetDevice) {
    $targetDevice = ($authorized | Select-Object -First 1)
}
if (-not $targetDevice) {
    Write-Host "[!] Warning: No authorized device found. Please verify USB cable or Wireless Debugging is enabled & paired." -ForegroundColor Yellow
    & $adb devices
    exit 1
}
Write-Host "[OK] Target device connected: $targetDevice" -ForegroundColor Green

if ($CheckOnly) {
    exit 0
}

# 3. Resolve APK
if (-not $ApkPath -or -not (Test-Path $ApkPath)) {
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
& $adb -s $targetDevice install -r -d "$ApkPath"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] ADB install failed." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] ADB Install successful." -ForegroundColor Green

# 4. Copy to MTP Download folder as backup
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
    # Ignore MTP errors
}

# 5. Launch App
Write-Host "[*] Launching TARANG69 on device..." -ForegroundColor Cyan
& $adb -s $targetDevice shell am start -n com.example.tarang69/.MainActivity | Out-Null
Write-Host "[OK] TARANG69 installed and launched successfully! 🎉" -ForegroundColor Green
