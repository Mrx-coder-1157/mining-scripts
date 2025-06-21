# ========== StopMining.ps1 ==========
$logTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if ($IsWindows) {
    $logFile = "C:\Miners\Logs\mining_log.txt"
    Add-Content $logFile "`n[$logTime] === Stopping Miner ==="

    # Stop xmrig.exe if running
    $xmrig = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    if ($xmrig) {
        $xmrig | Stop-Process -Force
        Add-Content $logFile "[$logTime] xmrig.exe process killed."
    } else {
        Add-Content $logFile "[$logTime] xmrig.exe not running."
    }

    # Delete miner folder completely
    $folder = "C:\Miners"
    if (Test-Path $folder) {
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction Stop
            Write-Host "[$logTime] Miner folder deleted."
        } catch {
            Write-Host "[$logTime] Failed to delete miner folder: $_"
        }
    }

} elseif ($IsLinux) {
    $logFile = "$HOME/xmrig/build/stop_log.txt"
    echo "`n[$logTime] === Stopping Miner on Android ===" >> $logFile

    # Kill xmrig process
    pkill -f xmrig
    echo "[$logTime] xmrig process killed." >> $logFile

    # Delete xmrig folder
    if (Test-Path "$HOME/xmrig") {
        Remove-Item -Recurse -Force "$HOME/xmrig"
        echo "[$logTime] xmrig folder deleted." >> $logFile
    }
} else {
    Write-Host "Unsupported system. This script works only on Windows and Termux (Linux)."
}
