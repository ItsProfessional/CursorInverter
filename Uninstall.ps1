if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath $((Get-Process -Id $PID).Path) -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}

Get-Process * | Where-Object {$_.mainWindowTitle -match "Cursor Inverter" -or $_.Path -match "CursorInverter"} | Stop-Process -Force
Unregister-ScheduledTask -TaskName "CursorInverter"
Remove-Item -Path "$Env:ProgramFiles\CursorInverter.ps1" -Force
Write-Output "CursorInverter has been uninstalled!"