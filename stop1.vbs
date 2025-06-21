' StopAndCleanMiner.vbs
' This script identifies and terminates running XMRig miner processes
' (disguised as svchost.exe) and then deletes the miner folder.
' Designed for minimal console output, with improved deletion robustness.

Option Explicit ' Forces declaration of all variables

' --- Configuration ---
Dim minerFolder
minerFolder = "C:\Miners\xmrig" ' The miner folder to target for stopping processes and deletion

' --- Script Logic ---
' No initial WScript.Echo for a more silent start.

' 1. Terminate running miner processes
' This function now returns the count of processes it attempted to terminate
Dim terminatedCount
' CORRECTED LINE: TerminateMinerProcesses is now a Function and returns a value
terminatedCount = TerminateMinerProcesses(minerFolder) 

' Give processes a moment to fully exit and release file handles
If terminatedCount > 0 Then
    WScript.Sleep 2000 ' Wait for 2 seconds (2000 milliseconds)
End If

' 2. Delete the miner folder
DeleteMinerFolder minerFolder ' Using a new sub for robust deletion

' Final confirmation message
WScript.Echo "Miner cleanup complete. Script has finished running."

' --- Function Definitions ---

' CORRECTED: Changed from Sub to Function and added return value
Function TerminateMinerProcesses(targetFolderPath)
    On Error Resume Next ' Enable error handling for WMI queries
    
    Dim wmiService
    Set wmiService = GetObject("winmgmts:\\.\root\cimv2")

    If Err.Number <> 0 Then
        ' WScript.Echo "ERROR: Could not connect to WMI service when attempting to terminate processes. " & Err.Description
        Err.Clear
        TerminateMinerProcesses = 0 ' Return 0 processes terminated
        Exit Function ' Exit Function, not Sub
    End If

    Dim processList, process
    Set processList = wmiService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'svchost.exe'")

    If Err.Number <> 0 Then
        ' WScript.Echo "ERROR: Could not query processes to terminate. " & Err.Description
        Err.Clear
        TerminateMinerProcesses = 0 ' Return 0 processes terminated
        Exit Function ' Exit Function, not Sub
    End If

    Dim processesFound
    processesFound = 0

    For Each process In processList
        If Not IsNull(process.ExecutablePath) Then
            If InStr(LCase(process.ExecutablePath), LCase(targetFolderPath)) > 0 Then
                processesFound = processesFound + 1 ' Count how many we *attempt* to terminate
                process.Terminate
                If Err.Number <> 0 Then
                    ' WScript.Echo "WARNING: Could not terminate process PID " & process.ProcessID & " at " & process.ExecutablePath & ": " & Err.Description
                    Err.Clear
                End If
            End If
        End If
    Next

    Set processList = Nothing
    Set wmiService = Nothing
    On Error GoTo 0 ' Disable error handling
    
    ' CORRECTED: Assign the return value to the function name
    TerminateMinerProcesses = processesFound 
End Function ' Changed from End Sub to End Function

Function FolderExists(folderPath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    FolderExists = fso.FolderExists(folderPath)
    Set fso = Nothing
End Function

Sub DeleteMinerFolder(folderPath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    If Not fso.FolderExists(folderPath) Then
        Exit Sub ' Folder already gone, nothing to do
    End If

    Dim retryCount, maxRetries, sleepTime
    maxRetries = 5 ' Try up to 5 times
    sleepTime = 1000 ' Wait 1 second between retries

    For retryCount = 1 To maxRetries
        On Error Resume Next ' Enable error handling for deletion attempt
        fso.DeleteFolder folderPath, True ' True to delete contents and subfolders
        
        If Err.Number = 0 Then ' Success
            On Error GoTo 0
            Exit Sub ' Folder deleted, exit the sub
        Else ' Deletion failed
            ' WScript.Echo "WARNING: Attempt " & retryCount & "/" & maxRetries & " to delete folder " & folderPath & " failed: " & Err.Description
            Err.Clear ' Clear the error
            If retryCount < maxRetries Then
                WScript.Sleep sleepTime ' Wait before retrying
            End If
        End If
        On Error GoTo 0 ' Disable error handling
    Next

    ' WScript.Echo "ERROR: Failed to delete folder " & folderPath & " after " & maxRetries & " attempts. Manual intervention may be required."
End Sub