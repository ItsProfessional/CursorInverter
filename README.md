# CursorInverter
A script that runs in the background and switches between black and white cursor schemes depending on the color under your cursor.  
Requires the [windows black cursor scheme](https://www.deviantart.com/twipeep/art/Windows-11-cursor-black-version-572437583) to be installed.

## Installation
1. Download the [latest release](https://github.com/ItsProfessional/CursorInverter/releases/latest) and store the script in a convenient location.  
2. Run the script as administrator when you want to start the script.  
3. Profit  

Alternatively, the installation can be automated by running the following in a administrative powreshell window.  
This will run the script automatically at startup

```
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ItsProfessional/Scripts/main/CursorInverter.ps1" -OutFile "$Env:ProgramFiles\CursorInverter.ps1"
$Argument = @'
vbscript:Execute("CreateObject(""Wscript.Shell"").Run ""powershell -NoLogo -Command """"& 'C:\Program Files\CursorInverter.ps1'"""""", 0 : window.close")
'@
$Trigger = New-ScheduledTaskTrigger -AtLogon
$Action = New-ScheduledTaskAction -Execute "$Env:SystemRoot\System32\mshta.exe" -Argument $Argument
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "CursorInverter" -Trigger $Trigger -Action $Action -RunLevel Highest -Settings $Settings | Out-Null
Write-Output "CursorInverter has been installed!"
```
## Uninstallation
Ensure the script is not running(Stop the script using using task manager) and run the following in a administrative powershell window
```
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}
Unregister-ScheduledTask -TaskName "CursorInverter"
Remove-Item -Path "$Env:ProgramFiles\CursorInverter.ps1" -Force
Write-Output "CursorInverter has been uninstalled!"
```

## How does it work?
Detects whether the color of the pixel under your cursor is closer to black or white, and setting your cursor to the opposite color.  
# Disclaimer
This script is in an early stage, and offered as-is. There will be bugs. I am not responsible for any damage, loss of data, or anything caused by this script.