if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath $((Get-Process -Id $PID).Path) -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ItsProfessional/CursorInverter/main/CursorInverter.ps1" -OutFile "$Env:ProgramFiles\CursorInverter.ps1"

$FilePath = "$Env:SystemRoot\System32\mshta.exe"
$Argument = @'
vbscript:Execute("CreateObject(""Wscript.Shell"").Run ""powershell -NoLogo -Command """"& 'C:\Program Files\CursorInverter.ps1'"""""", 0 : window.close")
'@

$Trigger = New-ScheduledTaskTrigger -AtLogon
$Action = New-ScheduledTaskAction -Execute $FilePath -Argument $Argument
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "CursorInverter" -Trigger $Trigger -Action $Action -RunLevel Highest -Settings $Settings | Out-Null

Start-Process -FilePath $FilePath -ArgumentList $Argument
Write-Output "CursorInverter has been installed!"