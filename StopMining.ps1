# StopMining.ps1 - Gracefully stops the mining process

# Specify the path to the miner executable
$minerProcessName = "xmrig.exe"

# Check if the miner process is running
$minerProcess = Get-Process -Name $minerProcessName -ErrorAction SilentlyContinue

if ($minerProcess) {
    Write-Host "Stopping mining process..."
    Stop-Process -Name $minerProcessName -Force
    Write-Host "Mining process stopped successfully!"
} else {
    Write-Host "Miner is not running."
}
