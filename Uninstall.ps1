Get-Process * | Where-Object { (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine -match "DynamicCursor" } | Stop-Process -Force
Unregister-ScheduledTask -TaskName "DynamicCursor" -Confirm:$false
Remove-Item -Path "$Env:ProgramFiles\DynamicCursor.ps1" -Force
Write-Output "DynamicCursor has been uninstalled!"