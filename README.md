.SYNOPSIS

This Windows PowerShell script will download and install the Robot Framework, all it's required dependencies (if not allready available) and some extra libraries and tools.
If necessary, it will also modify the user 'path' environment variable, so to include the necessary folders.
In the end of the process, the following resources should be installed:
- Python (version 2.7.8 will be downloaded if no RF compatible version is already present).
- PIP (used to install RF, Selenium2library and RIDE)
- Robot Framework
- Selenium2library
- Selenium driver for Internet Explorer
- Selenium driver for Chrome 
- wxPython (version 2.8.12.1, necessary to run RIDE)
- RIDE

The only part of the script that's not fully automatic is the wxPython installation. You'll still have to go thru the wizard.
If you are not interested in using RIDE, just comment that part of the script along with wxPython.

IMPORTANT! This script uses the 'setx' command to modify the PATH user variable. 
This means it won't work in Windows XP or previous, unless it's installed from the Service Pack 2 Support Tools.

IMPORTANT! The installer download locations were valid at the time of this scrip conception, but these may change. 
If you find some invalid URL please report an issue at https://github.com/joao-carloto/RF_Install_Script/issues

IMPORTANT! If you really want to do selenium tests on IE, beware that there are some necessary browser configurations to be made.
This script doesn't deal with those. For more info check https://code.google.com/p/selenium/wiki/InternetExplorerDriver#Required_Configuration

Script: RF_Installer.ps1
Author: João Carloto, Twitter: @JMCarloto
Github repo: https://github.com/joao-carloto/RF_Install_Script
License: Apache 2.0
Version: 0.1
Dependencies: Internet connectivity
              The 'setx' command



.USAGE

-Save this script into a file. Don't forget the .ps1 extension.
-Right click the file and choose 'Run with PowerShell'.



.DESCRIPTION

Python Installation

Starts by running the 'python -V' command
If a compatible version is found (2.5, 2.6 or 2.7) it will read the path environment variable to get it's location and store it.
If an incompatible version is found, it will show a warning to remove it from the PATH environment variable or rename python.exe to something else (e.g. python3.exe) and rerun this script.
If the 'python -V' command fails it will search for python.exe in it's standard locations (e.g. c:\python27\).
If it's present, it will assume that there's already a valid installation and just add it's location to 'path'.
If it can't find it, it will download a compatible python .msi installer and run it. Afterwards it will add it's location to 'path'.



PIP Installation

Starts by running the 'pip -V' command
If the 'pip -V' command fails, it will search for pip.exe in it's standard locations (e.g. c:\python27\Scripts\).
If it's present, it will assume that there's already a valid installation and just add it's location to 'path'.
If it can't find it, it will download the installer and run it, afterwards it will add it's location to 'path'.



Robot Framework Installation

Starts by running the 'pybot --version' command
If it fails, will install the robot framework using PIP



Selenium2Library Installation

Starts by checking if the <python folder>\Lib\site-packages.\Selenium2Library folder exists.
If it fails, will install the selenium2libraryu using PIP.



Selenium Drivers for Internet Explorer and Chrome

Starts by running the --help command of the drivers.
If it fails, downloads the .zip files with the drivers.
If necessary, creates a folder to place the drivers.
Unzips the drivers to that folder.
Adds the folder to PATH

 
 
wxPython Installation

Starts by checking if the <python folder>\Lib\site-packages\wx-2.8-msw-unicode\wxPython folder exists.
If it fails, downloads the wxPython installer and runs it.



RIDE Installation

Starts by running the 'ride.py' command, to open the RIDE GUI.
If it fails, will install RIDE using PIP.
Tries to open RIDE again.



Demo Test

If Firefox or Chrome are installed, writes a demo test scrip on a .txt file.
IE won't be used because of needed additional configurations.
Runs the test script using pybot.