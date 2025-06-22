' ============================
' StopMiner.vbs - Cleanup Script
' ============================
Dim shell, fso, wmi, procs, proc
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

Dim appData, minerExe, minerDir, launcherPath, regPath, regName
appData = shell.ExpandEnvironmentStrings("%APPDATA%")
minerDir = appData & "\XMRigMiner"
minerExe = "systemcache.exe"
launcherPath = appData & "\WindowsUpdate\svchost.vbs"
regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
regName = "WindowsUpdate"

' === Kill Miner Process
Set wmi = GetObject("winmgmts:\\.\root\cimv2")
Set procs = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='" & minerExe & "'")

For Each proc In procs
    proc.Terminate()
Next

WScript.Sleep 2000 ' Wait for termination

' === Delete Miner Folder
If fso.FolderExists(minerDir) Then
    On Error Resume Next
    fso.DeleteFolder minerDir, True
    On Error GoTo 0
End If

' === Delete Persistent Launcher
If fso.FileExists(launcherPath) Then
    On Error Resume Next
    fso.DeleteFile launcherPath, True
    On Error GoTo 0
End If

' === Remove from Registry Startup
On Error Resume Next
shell.RegDelete regPath & "\" & regName
On Error GoTo 0

MsgBox "Miner stopped and removed successfully.", vbInformation, "Done"
