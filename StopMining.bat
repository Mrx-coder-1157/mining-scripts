@echo off
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://github.com/Mrx-coder-1157/mining-scripts/raw/main/StopMining.ps1' -OutFile 'C:\Miners\StopMining.ps1'; & 'C:\Miners\StopMining.ps1'"
exit
