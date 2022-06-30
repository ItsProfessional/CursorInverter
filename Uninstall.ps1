Get-Process * | Where-Object { (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "CursorInverter" } | Stop-Process -Force
Unregister-ScheduledTask -TaskName "CursorInverter" -Confirm:$false
Remove-Item -Path "$Env:ProgramFiles\CursorInverter.ps1" -Force
Write-Output "CursorInverter has been uninstalled!"