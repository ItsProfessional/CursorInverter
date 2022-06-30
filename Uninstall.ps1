Get-Process * | Where-Object { (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "CursorInverter" } | Stop-Process -Force
Unregister-ScheduledTask -TaskName "CursorInverter"
# Remove-Item -Path "$Env:ProgramFiles\CursorInverter.ps1" -Force -Confirm:$false
cmd /c 'del /f "%ProgramFiles%\CursorInverter.ps1"'
Write-Output "CursorInverter has been uninstalled!"