Option Explicit
Dim sh, fso, folder, ps, cmd
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
folder = fso.GetParentFolderName(WScript.ScriptFullName)
ps = sh.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
cmd = """" & ps & """ -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & folder & "\MiAgendaLauncher.ps1"""
sh.Run cmd, 0, False
