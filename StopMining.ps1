# Log file path (same as miner script)
$logFilePath = "C:\Miners\Logs\mining_log.txt"

# Stop the miner process
$minerProcess = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue

if ($minerProcess) {
    Write-Output "[$(Get-Date)] Stopping XMRig miner..." | Tee-Object -FilePath $logFilePath -Append
    Stop-Process -Name "xmrig" -Force
    Write-Output "[$(Get-Date)] Miner stopped successfully." | Tee-Object -FilePath $logFilePath -Append
} else {
    Write-Output "[$(Get-Date)] No XMRig process found to stop." | Tee-Object -FilePath $logFilePath -Append
}
