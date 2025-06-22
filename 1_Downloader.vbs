'====================================================================================
' File: DownloadAndExtractMiner.vbs
' Description: Downloads the XMRig ZIP and extracts it to the designated miner folder.
'              Then immediately renames the extracted xmrig.exe to systemcache.exe.
'              Designed as the first stage of a multi-stage deployment.
'              Handles download failures by prompting for manual placement.
'              Output is sent directly to the console (WScript.StdOut.WriteLine)
'              and captured by the calling script (2_MinerConf.vbs) for logging.
'====================================================================================

Option Explicit ' Enforce explicit declaration of all variables

' --- Global Objects ---
Dim WshShell, fso
Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' --- Configuration ---
' Miner folder in %APPDATA% (fully visible folder)
Dim appDataPath: appDataPath = WshShell.SpecialFolders("AppData")
Dim minerFolder: minerFolder = appDataPath & "\XMRigMiner"

' XMRig download URL (ensure this is a direct download link, e.g., from GitHub Releases)
Dim xmrigDownloadUrl: xmrigDownloadUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"

' The name of the subfolder *inside* the XMRig ZIP.
' CRITICAL: This MUST match the folder name you observed inside the ZIP after extraction.
' If the ZIP contains xmrig.exe directly (no subfolder), set this to an empty string: ""
Dim expectedExeSubFolderName: expectedExeSubFolderName = "xmrig-6.21.0" ' <--- VERIFY THIS EXACTLY!

' The final desired executable name (renamed from xmrig.exe)
Const FINAL_MINER_EXE_NAME = "systemcache.exe"

' Derived paths
Dim finalMinerExePath, minerWorkingDirectory
Dim isFlatExtraction ' Flag to track if xmrig.exe is extracted directly or in a subfolder

' --- Script Logic ---
LogToConsole "--- Miner Download & Extraction Script (DownloadAndExtractMiner.vbs) ---"
LogToConsole "Current time: " & Now() & " (Chandigarh, India)"

' 1. Create the main miner folder
LogToConsole "Target miner folder: " & minerFolder
If Not FolderExists(minerFolder) Then
    LogToConsole "Miner folder does not exist. Attempting to create: " & minerFolder
    CreateFolder minerFolder
Else
    LogToConsole "Miner folder already exists: " & minerFolder
End If

' Set initial paths based on expected subfolder structure
If expectedExeSubFolderName <> "" Then
    finalMinerExePath = minerFolder & "\" & expectedExeSubFolderName & "\" & FINAL_MINER_EXE_NAME
    minerWorkingDirectory = minerFolder & "\" & expectedExeSubFolderName
Else ' Flat extraction
    finalMinerExePath = minerFolder & "\" & FINAL_MINER_EXE_NAME
    minerWorkingDirectory = minerFolder ' Miner will be directly in XMRigMiner folder
End If

' 2. Clean up old temporary extraction files and ZIP
Dim tempExtractFolder: tempExtractFolder = minerFolder & "\temp_xmrig_extract"
Dim downloadZipPath: downloadZipPath = minerFolder & "\xmrig_download.zip"

LogToConsole "Performing cleanup of old temp files..."
DeleteFolder tempExtractFolder
DeleteFile downloadZipPath

' 3. Download XMRig ZIP or use pre-existing one
If Not FileExists(finalMinerExePath) Then ' Check for the *final* named executable
    LogToConsole "Final miner executable ('" & FINAL_MINER_EXE_NAME & "') not found. Proceeding with download and extraction."
    LogToConsole "Attempting to download XMRig from: " & xmrigDownloadUrl & " to " & downloadZipPath

    DownloadFile xmrigDownloadUrl, downloadZipPath
    
    If Not FileExists(downloadZipPath) Then
        LogToConsole "ERROR: Downloaded ZIP file does not exist at expected path after download attempt." & vbCrLf & _
                     "This indicates a network block (firewall, proxy, security software) or Antivirus quarantine." & vbCrLf & _
                     "ACTION REQUIRED: Please manually download the ZIP file from " & xmrigDownloadUrl & vbCrLf & _
                     "and place it as " & downloadZipPath & vbCrLf & _
                     "Then re-run the main script (2_MinerConf.vbs)."
        WScript.Quit 1 ' Exit with error code
    End If
    
    ' 4. Extract the ZIP
    LogToConsole "Extracting XMRig from: " & downloadZipPath & " to " & tempExtractFolder
    ExpandZip downloadZipPath, tempExtractFolder, expectedExeSubFolderName

    ' After extraction, determine if it was a flat extraction or subfolder extraction
    Dim extractedXmrigOriginalPath ' Path to xmrig.exe *after* extraction, *before* rename

    If FileExists(tempExtractFolder & "\xmrig.exe") Then
        isFlatExtraction = True
        extractedXmrigOriginalPath = tempExtractFolder & "\xmrig.exe"
        ' Update minerWorkingDirectory and finalMinerExePath for flat extraction
        minerWorkingDirectory = minerFolder
        finalMinerExePath = minerFolder & "\" & FINAL_MINER_EXE_NAME
        LogToConsole "DEBUG: Detected flat extraction (xmrig.exe directly in temp folder)."
    ElseIf FileExists(tempExtractFolder & "\" & expectedExeSubFolderName & "\xmrig.exe") Then
        isFlatExtraction = False
        extractedXmrigOriginalPath = tempExtractFolder & "\" & expectedExeSubFolderName & "\xmrig.exe"
        ' minerWorkingDirectory and finalMinerExePath are already set correctly for subfolder
        LogToConsole "DEBUG: Detected subfolder extraction (xmrig.exe in temp_xmrig_extract\" & expectedExeSubFolderName & ")."
    Else
        LogToConsole "CRITICAL ERROR: 'xmrig.exe' not found in temp extraction path (neither flat nor subfolder). Aborting."
        WScript.Quit 1
    End If

    ' --- DEBUGGING CHECKS START HERE ---
    LogToConsole "--- Debugging: Post-Extraction Checks ---"
    LogToConsole "DEBUG: Extracted xmrig original path identified as: " & extractedXmrigOriginalPath
    LogToConsole "DEBUG: Final miner EXE path target: " & finalMinerExePath
    LogToConsole "DEBUG: Miner working directory target: " & minerWorkingDirectory
    
    If Not FileExists(extractedXmrigOriginalPath) Then
        LogToConsole "CRITICAL ERROR: 'xmrig.exe' was present for a moment but then disappeared from " & extractedXmrigOriginalPath & ". This is highly indicative of Antivirus interference. Aborting."
        WScript.Quit 1
    End If

    ' 5. Move extracted miner to its final location and rename
    LogToConsole "DEBUG: Performing final move/rename operations."
    
    If Not FolderExists(minerWorkingDirectory) Then CreateFolder minerWorkingDirectory

    If Not isFlatExtraction Then
        ' Move the extracted subfolder (e.g., xmrig-6.21.0) into minerFolder
        LogToConsole "DEBUG: Moving extracted folder from: " & tempExtractFolder & "\" & expectedExeSubFolderName & " to " & minerWorkingDirectory
        MoveFolder tempExtractFolder & "\" & expectedExeSubFolderName, minerWorkingDirectory
        ' After move, the xmrig.exe is now directly in minerWorkingDirectory
        extractedXmrigOriginalPath = minerWorkingDirectory & "\xmrig.exe"
    Else ' Flat extraction means xmrig.exe is directly in tempExtractFolder
        LogToConsole "DEBUG: Flat extraction scenario. Copying xmrig.exe to final location before rename."
        CopyFile extractedXmrigOriginalPath, minerWorkingDirectory & "\xmrig.exe"
        extractedXmrigOriginalPath = minerWorkingDirectory & "\xmrig.exe" ' Update path for rename
    End If
    
    ' --- Rename xmrig.exe to systemcache.exe in the final location ---
    LogToConsole "DEBUG: Attempting to rename '" & extractedXmrigOriginalPath & "' to '" & FINAL_MINER_EXE_NAME & "'."
    
    If FileExists(extractedXmrigOriginalPath) Then
        If Not RenameFile(extractedXmrigOriginalPath, FINAL_MINER_EXE_NAME) Then
            LogToConsole "CRITICAL ERROR: Failed to rename '" & extractedXmrigOriginalPath & "' to '" & FINAL_MINER_EXE_NAME & "'. Aborting."
            WScript.Quit 1
        End If
        LogToConsole "Successfully renamed miner executable to: " & finalMinerExePath
    Else
        LogToConsole "CRITICAL ERROR: 'xmrig.exe' not found at expected path for renaming: " & extractedXmrigOriginalPath & ". It might have been deleted by AV. Aborting."
        WScript.Quit 1
    End If
    ' --- END NEW RENAME ---

    LogToConsole "DEBUG: Final check for " & FINAL_MINER_EXE_NAME & " in final path after rename: " & finalMinerExePath
    If FileExists(finalMinerExePath) Then
        LogToConsole "DEBUG: " & FINAL_MINER_EXE_NAME & " FOUND in final location. File size: " & fso.GetFile(finalMinerExePath).Size & " bytes."
    Else
        LogToConsole "CRITICAL ERROR: " & FINAL_MINER_EXE_NAME & " NOT FOUND in final location after rename. Aborting."
        WScript.Quit 1
    End If
    ' --- DEBUGGING CHECKS END HERE ---

    LogToConsole "Cleaning up temporary extraction folder and downloaded zip..."
    DeleteFolder tempExtractFolder
    DeleteFile downloadZipPath
Else
    LogToConsole "Miner executable ('" & FINAL_MINER_EXE_NAME & "') found at: " & finalMinerExePath & ". Skipping download and extraction."
End If

' Final verification
If Not FileExists(finalMinerExePath) Then
    LogToConsole "CRITICAL ERROR: Final miner executable was not found at " & finalMinerExePath & " after all setup attempts. Aborting."
    WScript.Quit 1
End If

LogToConsole "Miner executable successfully prepared at: " & finalMinerExePath
LogToConsole "You can now proceed to the next stage (configuration and starting)."
LogToConsole "--- Download & Extraction Script Finished ---"

' ===================================
' Function and Subroutine Definitions
' (Error handling uses WScript.Quit 1 to indicate failure to calling script)
' ===================================

Sub LogToConsole(msg)
    WScript.StdOut.WriteLine Now & " - [Downloader] - " & msg
End Sub

Function FolderExists(folderPath)
    On Error Resume Next
    FolderExists = fso.FolderExists(folderPath)
    If Err.Number <> 0 Then
        LogToConsole "WARNING: Error checking folder existence for " & folderPath & ": " & Err.Description
        FolderExists = False
    End If
    Err.Clear
End Function

Sub CreateFolder(folderPath)
    On Error Resume Next
    If FolderExists(folderPath) Then Exit Sub ' If it exists, nothing to do

    Dim parentFolder: parentFolder = fso.GetParentFolderName(folderPath)
    If parentFolder <> "" And Not FolderExists(parentFolder) Then
        CreateFolder parentFolder ' Recursively create parent folders
    End If

    fso.CreateFolder(folderPath)
    If Err.Number <> 0 Then
        LogToConsole "ERROR: Failed to create folder " & folderPath & ". Error: " & Err.Description
        WScript.Quit 1
    End If
    Err.Clear
End Sub

Function FileExists(filePath)
    On Error Resume Next
    FileExists = fso.FileExists(filePath)
    If Err.Number <> 0 Then
        LogToConsole "WARNING: Error checking file existence for " & filePath & ": " & Err.Description
        FileExists = False
    End If
    Err.Clear
End Function

Sub DownloadFile(url, savePath)
    On Error Resume Next
    Dim objXMLHTTP, objStream
    Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    If Err.Number <> 0 Or Not IsObject(objXMLHTTP) Then
        LogToConsole "DOWNLOAD ERROR: Failed to create MSXML2.ServerXMLHTTP.6.0 object. " & Err.Description
        WScript.Quit 1
    End If
    Err.Clear
    
    LogToConsole "Attempting HTTP GET for: " & url
    objXMLHTTP.open "GET", url, False ' Synchronous
    objXMLHTTP.send

    If Err.Number <> 0 Then
        LogToConsole "DOWNLOAD ERROR (VBScript COM or network): " & Err.Description & " (Error Number: " & Err.Number & ")"
        WScript.Quit 1
    End If

    If objXMLHTTP.status = 200 Then
        Set objStream = CreateObject("ADODB.Stream")
        If Err.Number <> 0 Or Not IsObject(objStream) Then
            LogToConsole "DOWNLOAD ERROR: Failed to create ADODB.Stream object. " & Err.Description
            WScript.Quit 1
        End If
        Err.Clear
        objStream.Type = 1 ' Binary
        objStream.Open
        objStream.Write objXMLHTTP.responseBody
        objStream.SaveToFile savePath, 2 ' 2 = Overwrite
        objStream.Close
        LogToConsole "Successfully downloaded " & url & " to " & savePath
    Else
        LogToConsole "DOWNLOAD FAILED (HTTP Status): " & objXMLHTTP.status & " (" & objXMLHTTP.statusText & ")"
        WScript.Quit 1
    End If
    Set objStream = Nothing
    Set objXMLHTTP = Nothing
    Err.Clear
End Sub

Sub ExpandZip(zipPath, destinationPath, expectedSubfolder)
    On Error Resume Next
    If Not FolderExists(destinationPath) Then CreateFolder destinationPath

    Dim objShell, objSource, objTarget
    Set objShell = CreateObject("Shell.Application")
    If Err.Number <> 0 Or Not IsObject(objShell) Then
        LogToConsole "EXTRACTION ERROR: Failed to create Shell.Application object. " & Err.Description
        WScript.Quit 1
    End If
    Err.Clear

    If FileExists(zipPath) Then
        Set objSource = objShell.NameSpace(zipPath)
        If Err.Number <> 0 Or Not IsObject(objSource) Then
            LogToConsole "EXTRACTION ERROR: Failed to access ZIP file namespace (" & zipPath & "). " & Err.Description
            WScript.Quit 1
        End If
        Err.Clear

        Set objTarget = objShell.NameSpace(destinationPath)
        If Err.Number <> 0 Or Not IsObject(objTarget) Then
            LogToConsole "EXTRACTION ERROR: Failed to access destination folder namespace (" & destinationPath & "). " & Err.Description
            WScript.Quit 1
        End If
        Err.Clear

        objTarget.CopyHere objSource.Items, 16 ' 16 suppresses progress dialog

        If Err.Number <> 0 Then
            LogToConsole "EXTRACTION ERROR (CopyHere): " & Err.Description & " (Error Number: " & Err.Number & ")"
            WScript.Quit 1
        End If
        Err.Clear

        LogToConsole "Waiting for extraction to complete and verifying 'xmrig.exe' existence (max 60s)..."
        Dim maxWaitSeconds: maxWaitSeconds = 60 ' Increased timeout to 60 seconds
        Dim currentWaitTime: currentWaitTime = 0
        Dim extractionComplete: extractionComplete = False

        Dim subfolderPathToCheck, flatPathToCheck
        subfolderPathToCheck = destinationPath & "\" & expectedSubfolder & "\xmrig.exe"
        flatPathToCheck = destinationPath & "\xmrig.exe"

        Do While Not extractionComplete And currentWaitTime < maxWaitSeconds
            WScript.Sleep 1000 ' Wait 1 second
            currentWaitTime = currentWaitTime + 1

            ' Check for subfolder extraction first
            If expectedSubfolder <> "" And fso.FolderExists(fso.GetParentFolderName(subfolderPathToCheck)) Then
                If fso.FileExists(subfolderPathToCheck) Then
                    extractionComplete = True
                End If
            End If

            If Not extractionComplete Then ' If not found in subfolder, check for flat extraction
                If fso.FileExists(flatPathToCheck) Then
                    extractionComplete = True
                End If
            End If
            
            If Not extractionComplete Then
                LogToConsole "DEBUG (ExpandZip Loop): xmrig.exe not yet found after " & currentWaitTime & "s. Checking: " & subfolderPathToCheck & " (if subfolder exists) and " & flatPathToCheck
            End If
        Loop

        If Not extractionComplete Then
            LogToConsole "EXTRACTION ERROR: 'xmrig.exe' not found after " & maxWaitSeconds & " second(s) timeout. This likely means Antivirus/security software removed it during extraction or the expected path is still incorrect."
            WScript.Quit 1
        End If
        LogToConsole "ZIP file extracted successfully and 'xmrig.exe' verified."
    Else
        LogToConsole "ERROR: ZIP file not found at " & zipPath & ". Cannot extract."
        WScript.Quit 1
    End If
    Set objSource = Nothing
    Set objTarget = Nothing
    Set objShell = Nothing
    Err.Clear
End Sub

Sub DeleteFile(filePath)
    On Error Resume Next
    If FileExists(filePath) Then fso.DeleteFile(filePath), True ' True for force delete
    If Err.Number <> 0 Then LogToConsole "WARNING: Failed to delete file " & filePath & ": " & Err.Description
    Err.Clear
End Sub

Sub DeleteFolder(folderPath)
    On Error Resume Next
    If fso.FolderExists(folderPath) Then fso.DeleteFolder folderPath, True ' True for force delete recursive
    If Err.Number <> 0 Then LogToConsole "WARNING: Failed to delete folder " & folderPath & ": " & Err.Description
    Err.Clear
End Sub

Sub MoveFolder(sourceFolder, destinationFolder)
    On Error Resume Next
    If fso.FolderExists(sourceFolder) Then
        If fso.FolderExists(destinationFolder) Then DeleteFolder destinationFolder
        If fso.FileExists(destinationFolder) Then DeleteFile destinationFolder
        
        fso.MoveFolder sourceFolder, destinationFolder
        If Err.Number <> 0 Then
            LogToConsole "ERROR: Failed to move folder " & sourceFolder & " to " & destinationFolder & ": " & Err.Description
            WScript.Quit 1
        End If
    Else
        LogToConsole "ERROR: Source folder not found for move operation: " & sourceFolder & ". Cannot move."
        WScript.Quit 1
    End If
    Err.Clear
End Sub

Sub CopyFile(sourcePath, destinationPath)
    On Error Resume Next
    If FileExists(sourcePath) Then
        Dim destFolder: destFolder = fso.GetParentFolderName(destinationPath)
        If Not fso.FolderExists(destFolder) Then CreateFolder destFolder
        
        If FileExists(destinationPath) Then DeleteFile destinationPath

        fso.CopyFile sourcePath, destinationPath, True ' True = overwrite
        If Err.Number <> 0 Then
            LogToConsole "ERROR: Failed to copy " & sourcePath & " to " & destinationPath & ": " & Err.Description
            WScript.Quit 1
        End If
    Else
        LogToConsole "ERROR: Source file not found for copy operation: " & sourcePath & ". Cannot copy."
        WScript.Quit 1
    End If
    Err.Clear
End Sub

Function RenameFile(oldPath, newFileName)
    LogToConsole "LOG: Attempting to rename '" & oldPath & "' to '" & newFileName & "'"
    On Error Resume Next
    Dim parentFolder: parentFolder = fso.GetParentFolderName(oldPath)
    Dim newPath: newPath = parentFolder & "\" & newFileName

    If Not fso.FileExists(oldPath) Then
        LogToConsole "ERROR: Source file for rename not found: " & oldPath
        RenameFile = False
        Exit Function
    End If

    If fso.FileExists(newPath) Then
        LogToConsole "LOG: Deleting existing target file '" & newPath & "' before rename."
        fso.DeleteFile newPath, True
        If Err.Number <> 0 Then
            LogToConsole "ERROR: Failed to delete existing target file for rename: " & Err.Description
            RenameFile = False
            Exit Function
        End If
    End If

    fso.MoveFile oldPath, newPath
    If Err.Number <> 0 Then
        LogToConsole "ERROR: Failed to rename '" & oldPath & "' to '" & newPath & "'. Error: " & Err.Description
        RenameFile = False
    Else
        LogToConsole "LOG: File renamed successfully to '" & newPath & "'."
        RenameFile = True
    End If
    Err.Clear
End Function
