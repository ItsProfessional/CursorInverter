if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
	Start-Process -FilePath $((Get-Process -Id $PID).Path) -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`" `"$($MyInvocation.MyCommand.UnboundArguments)`""
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

function IsColorBlack([Int[]]$Colors) {
	$Red = $Colors[0]
	$Green = $Colors[1]
	$Blue = $Colors[2]

	$Y = 0.2126*$Red + 0.7152*$Green + 0.0722*$Blue
	return ($Y -lt 128)
}

$Bitmap = New-Object System.Drawing.Bitmap([Int]$Bounds.Width), ([Int]$Bounds.Height)
$Graphics = [Drawing.Graphics]::FromImage($Bitmap)

$RegConnect = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"CurrentUser", "$env:COMPUTERNAME")
$RegConnectHKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]"LocalMachine", "$env:COMPUTERNAME")

$RegCursors = $RegConnect.OpenSubKey("Control Panel\Cursors", $true)
$RegSchemes = $RegConnect.OpenSubKey("Control Panel\Cursors\Schemes", $true)

$RegSchemesSystem = $RegConnectHKLM.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\Cursors\Schemes", $true)

$WhiteCursor = "Windows Aero"
$BlackCursor = "Windows black"

function Get-SchemeData([String]$CursorName) {
	$SchemeSource = "1"
	$FilesString = $RegSchemes.GetValue($CursorName)
	if([String]::IsNullOrEmpty($FilesString)) {
		$SchemeSource = "2"
		$FilesString = $RegSchemesSystem.GetValue($CursorName)
	}
	$Files = $FilesString.Split(',')
	if($SchemeSource -eq "2") {
		# Remove the unnecessary non-file element at the end of system schemes
		$Files = $Files[0..(($Files.Length-1)-1)]
	}
	return @($Files, $SchemeSource)
}

function Set-CursorProperties([String[]]$CursorName) {
	$SchemeData = Get-SchemeData -CursorName $CursorName
	$SchemeSource = $SchemeData[1]

	$RegCursors.SetValue("", $CursorName)
	$RegCursors.SetValue("Scheme Source", $SchemeSource)

	try {
		$CursorFiles = $SchemeData[0]
	} catch {
		Write-Output "You do not have the windows black cursor installed."
		Write-Output "Install it from here: https://www.deviantart.com/twipeep/art/Windows-11-cursor-black-version-572437583"
		Pause
		Exit
	}

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

function Get-CurrentCursor {
	return $RegCursors.GetValue("")
}

function Get-CommonElement($Array) {
	if(@($Array | Select-Object -Unique).Count -eq 1) {
		return $Array[0]
	} else {
		return $null
	}
}

While($true) {
	$Graphics.CopyFromScreen($Bounds.Location, [Drawing.Point]::Empty, $Bounds.size)

	$X = [System.Windows.Forms.Cursor]::Position.X
	$Y = [System.Windows.Forms.Cursor]::Position.Y

	$PixelColors = @()
	# 1..5 | ForEach-Object {
	#     $AdjustmentX = $_
	#     1..5 | ForEach-Object {
	#         $AdjustmentY = $_

			$Adjustment = 1
			$AdjustmentX = $Adjustment 
			$AdjustmentY = $Adjustment 

			# Pixels
			$Pixels = @(
				@($X, $Y), # Default, Default
				@($X, $($Y-$AdjustmentY)) # Default, Minus
				@($($X-$AdjustmentX), $Y) # Minus, Default
				@($X, $($Y+$AdjustmentY)), # Default, Plus
				@($($X+$AdjustmentX), $Y), # Plus, Default
				@($($X-$AdjustmentX), $($X-$AdjustmentY)), # Minus, Minus
				@($($X+$AdjustmentX), $($X+$AdjustmentY)), # Plus, Plus
				@($($X-$AdjustmentX), $($Y+$AdjustmentY)), # Minus, Plus
				@($($X+$AdjustmentX), $($Y-$AdjustmentY)) # Minus, Plus
			)

			foreach($Pixel in $Pixels) {
				$NewX = $Pixel[0]
				$NewY = $Pixel[1]

				try {
					$Color = $Bitmap.GetPixel($NewX, $NewY)
				} catch {
					# Continue to the next iteration if the X or Y of the pixel is a negative number
					continue
				}

				$Colors = @($Color.R, $Color.G, $Color.B)
				$IsColorBlack = IsColorBlack -Colors $Colors
				$PixelColors += ,$IsColorBlack
		#     }
		# }
	}

	$IsColorBlack = Get-CommonElement -Array $PixelColors
	$CurrentCursor = Get-CurrentCursor

	if($null -ne $IsColorBlack) {
		$Updated = $true
		if($IsColorBlack -and $CurrentCursor -ne $WhiteCursor) {
			# Set cursor to white
			Set-CursorProperties -CursorName $WhiteCursor
		} elseif(!($IsColorBlack) -and $CurrentCursor -ne $BlackCursor) {
			# Set cursor to black
			Set-CursorProperties -CursorName $BlackCursor
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

$RegSchemesSystem.Close()

$RegConnectHKCU.Close()
$RegConnectHKLM.Close()