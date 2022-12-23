# DynamicCursor
A script that runs in the background and switches between black and white cursor schemes depending on the color of the pixel under your cursor.  
Requires the [Windows black cursor](https://www.deviantart.com/twipeep/art/Windows-11-cursor-black-version-572437583) to be installed.

## Preview
https://user-images.githubusercontent.com/63961221/176515985-c6e6b1c0-11ec-445f-9798-6dc3c71d117e.mp4

## Installation
1. Download the [latest release](https://github.com/ItsProfessional/DynamicCursor/releases/latest) and store the script in a convenient location.  
2. Run the script as administrator when you want to start the script.  
The installation can be automated by running the following in a elevated powershell window.  
This will run the script automatically at startup
```
irm raw.githubusercontent.com/ItsProfessional/DynamicCursor/main/Install.ps1 | iex
```
**Note: You can also run the standalone script in the releases page. (Make sure to elevate it, otherwise the cursor won't change.)**

## Uninstallation
If you are using the portable version, stop the script and delete the file.
If you installed it using the automated script, run the following in a elevated powershell window to uninstall CursorInverter
```
irm raw.githubusercontent.com/ItsProfessional/DynamicCursor/main/Uninstall.ps1 | iex
```

## How does it work?
This script detects whether the color of the pixel under your cursor is closer to black or white, and sets your cursor to the opposite color.

## Disclaimer
**This script is in an early stage, and offered as-is. There will be bugs. I am not responsible for any damage, loss of data, or anything caused by this script.**  
This script, as of right now, uses a lot of memory and may slow down your computer.
