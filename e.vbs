' ============================
' StopMiner.vbs - Cleanup Script (Final, Silent)
' ============================
Dim shell, fso, wmi, procs, proc
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set wmi = GetObject("winmgmts:\\.\root\cimv2")

Dim appData, minerExe, minerDir, launcherPath, regPath, regName
appData = shell.ExpandEnvironmentStrings("%APPDATA%")
minerDir = appData & "\XMRigMiner"
minerExe = "systemcache.exe"
launcherPath = appData & "\WindowsUpdate\svchost.vbs"
regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
regName = "WindowsUpdate"

On Error Resume Next

' === Kill miner process
Set procs = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='" & minerExe & "'")
For Each proc In procs
    proc.Terminate()
Next

WScript.Sleep 1000

' === Kill any launcher scripts still running
Dim allProcs, p
Set allProcs = wmi.ExecQuery("SELECT * FROM Win32_Process WHERE Name='wscript.exe' OR Name='cscript.exe'")
For Each p In allProcs
    If InStr(LCase(p.CommandLine), "svchost.vbs") > 0 And InStr(LCase(p.CommandLine), "windowsupdate") > 0 Then
        p.Terminate()
    End If
Next

WScript.Sleep 1000

' === Remove startup registry
shell.RegDelete regPath & "\" & regName

' === Delete launcher file
If fso.FileExists(launcherPath) Then
    fso.DeleteFile launcherPath, True
End If

' === Delete miner folder
If fso.FolderExists(minerDir) Then
    fso.DeleteFolder minerDir, True
End If

On Error GoTo 0

' === Done
MsgBox "Miner stopped and removed successfully.", vbInformation, "Done"
