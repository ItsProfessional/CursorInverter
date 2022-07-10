Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ItsProfessional/DynamicCursor/main/DynamicCursor.ps1" -OutFile "$Env:ProgramFiles\DynamicCursor.ps1"

$FilePath = "$Env:SystemRoot\System32\mshta.exe"
$Argument = @'
vbscript:Execute("CreateObject(""Wscript.Shell"").Run ""powershell -NoLogo -Command """"& 'C:\Program Files\DynamicCursor.ps1'"""""", 0 : window.close")
'@

$Trigger = New-ScheduledTaskTrigger -AtLogon
$Action = New-ScheduledTaskAction -Execute $FilePath -Argument $Argument
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "DynamicCursor" -Trigger $Trigger -Action $Action -RunLevel Highest -Settings $Settings | Out-Null

Start-Process -FilePath $FilePath -ArgumentList $Argument
Write-Output "DynamicCursor has been installed!"