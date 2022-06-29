if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Start-Process -FilePath PowerShell -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
    Exit
}

$Sig = @'
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, uint pvParam, uint fWinIni);

const int SPI_SETCURSORS = 0x0057;
const int SPIF_UPDATEINIFILE = 0x01;
const int SPIF_SENDCHANGE = 0x02;

public static void UpdateUserPreferencesMask() {
    SystemParametersInfo(SPI_SETCURSORS, 0, 0, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
}

[DllImport("user32.dll")]
public static extern bool SetProcessDPIAware();
'@
Add-Type -MemberDefinition $Sig -Name Native -NameSpace Win32
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

[void]([Win32.Native]::SetProcessDPIAware())

$Host.UI.RawUI.WindowTitle = "Cursor Inverter"

$Screens = [Windows.Forms.Screen]::AllScreens
$Top = ($Screens.Bounds.Top | Measure-Object -Minimum).Minimum
$Left = ($Screens.Bounds.Left | Measure-Object -Minimum).Minimum
$Width = ($Screens.Bounds.Right | Measure-Object -Maximum).Maximum
$Height = ($Screens.Bounds.Bottom | Measure-Object -Maximum).Maximum
$Bounds = [Drawing.Rectangle]::FromLTRB($Left, $Top, $Width, $Height)

function IsColorBlack([Int]$Red, [Int]$Green, [Int]$Blue) {
    $Y = 0.2126*$Red + 0.7152*$Green + 0.0722*$Blue
    return ($Y -lt 128)
}

$Bitmap = New-Object System.Drawing.Bitmap([Int]$Bounds.Width), ([Int]$Bounds.Height)
$Graphics = [Drawing.Graphics]::FromImage($Bitmap)

$RegConnect = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"CurrentUser", "$env:COMPUTERNAME")
$RegCursors = $RegConnect.OpenSubKey("Control Panel\Cursors",$true)
$RegSchemes = $RegConnect.OpenSubKey("Control Panel\Cursors\Schemes",$true)

While($true) {
    $Graphics.CopyFromScreen($Bounds.Location, [Drawing.Point]::Empty, $Bounds.size)

    $X = [System.Windows.Forms.Cursor]::Position.X
    $Y = [System.Windows.Forms.Cursor]::Position.Y

    $Default = @($X, $Y)

    $DefaultMinus = @($X, $($Y-1))
    $MinusDefault = @($($X-1), $Y)
    $DefaultPlus = @($X, $($Y+1))
    $PlusDefault = @($($X+1), $Y)

    $MinusMinus = @($($X-1), $($Y-1))
    $PlusPlus = @($($X+1), $($Y+1))

    $MinusPlus = @($($X-1), $($Y+1))
    $PlusMinus = @($($X+1), $($Y-1))
    
    $Pixels = @($Default, $DefaultMinus, $MinusDefault, $DefaultPlus, $PlusDefault, $MinusMinus, $PlusPlus, $MinusPlus, $PlusMinus)
    $PixelColors = @()
    foreach($Pixel in $Pixels) {
        $X = $Pixel[0]
        $Y = $Pixel[1]
        try {
            $Color = $Bitmap.GetPixel($X, $Y)
        } catch {
            continue
        }

        $Colors = @($Color.R, $Color.G, $Color.B)

        $Hex = $Color.Name
        if ($Hex.Length -gt 7) { $Hex = $Hex.Substring(2, $($Hex.Length-2)) }

        $IsColorBlack = IsColorBlack -Red $Colors[0] -Green $Colors[1] -Blue $Colors[2]
        $PixelColors += ,$IsColorBlack
    }

    $WhiteCursor = "Windows Default"
    $BlackCursor = "Windows black"

    try {
        $BlackCursorFiles = $RegSchemes.GetValue($BlackCursor).Split(',')
    } catch {
        Write-Output "You do not have the windows black cursor installed."
        Write-Output "Install it from here: https://www.deviantart.com/twipeep/art/Windows-11-cursor-black-version-572437583"
        Pause
        Exit
    }

    $WhiteCursorFiles = @(
        "C:\Windows\cursors\aero_arrow.cur",
        "C:\Windows\cursors\aero_helpsel.cur",
        "C:\Windows\cursors\aero_working.ani",
        "C:\Windows\cursors\aero_busy.ani",
        "",
        "",
        "C:\Windows\cursors\aero_pen.cur",
        "C:\Windows\cursors\aero_unavail.cur",
        "C:\Windows\cursors\aero_ns.cur",
        "C:\Windows\cursors\aero_ew.cur",
        "C:\Windows\cursors\aero_nwse.cur",
        "C:\Windows\cursors\aero_nesw.cur",
        "C:\Windows\cursors\aero_move.cur",
        "C:\Windows\cursors\aero_up.cur",
        "C:\Windows\cursors\aero_link.cur",
        "C:\Windows\cursors\aero_pin.cur",
        "C:\Windows\cursors\aero_person.cur"
    )

    function SetCursorFiles([String[]]$CursorFiles) {
        $RegCursors.SetValue("Arrow", $CursorFiles[0])
        $RegCursors.SetValue("Help", $CursorFiles[1])
        $RegCursors.SetValue("AppStarting", $CursorFiles[2])
        $RegCursors.SetValue("Wait", $CursorFiles[3])
        $RegCursors.SetValue("Crosshair", $CursorFiles[4])
        $RegCursors.SetValue("IBeam", $CursorFiles[5])
        $RegCursors.SetValue("NWPen", $CursorFiles[6])
        $RegCursors.SetValue("No", $CursorFiles[7])
        $RegCursors.SetValue("SizeNS", $CursorFiles[8])
        $RegCursors.SetValue("SizeWE", $CursorFiles[9])
        $RegCursors.SetValue("SizeNWSE", $CursorFiles[10])
        $RegCursors.SetValue("SizeNESW", $CursorFiles[11])
        $RegCursors.SetValue("SizeAll", $CursorFiles[12])
        $RegCursors.SetValue("UpArrow", $CursorFiles[13])
        $RegCursors.SetValue("Hand", $CursorFiles[14])
        $RegCursors.SetValue("Pin", $CursorFiles[15])
        $RegCursors.SetValue("Person", $CursorFiles[16])
    }

    function AllEqualInArray($Array, $Element) {
        return ($Array | Where-Object {$_ -eq $Element}).Length -eq $Array.Length
    }

    $AllPixelsBlack = AllEqualInArray -Array $PixelColors -Element $true
    $AllPixelsWhite = AllEqualInArray -Array $PixelColors -Element $false

    if($AllPixelsBlack -or $AllPixelsWhite) {
        $Updated = $true
        if($AllPixelsBlack -and ($RegCursors.GetValue("") -ne $WhiteCursor)) {
            # Set cursor to white
            $RegCursors.SetValue("", $WhiteCursor)
            $RegCursors.SetValue("Scheme Source", "2")
            SetCursorFiles -CursorFiles $WhiteCursorFiles
        } elseif($AllPixelsWhite -and ($RegCursors.GetValue("") -ne $BlackCursor)) {
            # Set cursor to black
            $RegCursors.SetValue("", $BlackCursor)
            $RegCursors.SetValue("Scheme Source", "1")
            SetCursorFiles -CursorFiles $BlackCursorFiles
        } else {
            $Updated = $false
        }

        if($Updated) {
            [void]([Win32.Native]::UpdateUserPreferencesMask())
        }
    }
}

$Graphics.Dispose()
$Bitmap.Dispose()

$RegCursors.Close()
$RegSchemes.Close()
$RegConnect.Close()