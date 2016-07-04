<#
.SYNOPSIS

This Windows PowerShell script will download and install the Robot Framework, all it's required dependencies 
(if not already available) and some extra libraries and tools.
If necessary, it will also modify the user 'Path' environment variable, so to include the necessary folders.
In the end of the process, the following resources should be installed:
- Python 2.7.x
- PIP (used to install RF, Selenium2library and RIDE)
- Robot Framework
- Selenium2library
- Selenium driver for Internet Explorer
- Selenium driver for Chrome 
- wxPython (version 3.0.2 necessary to run RIDE)
- RIDE

The only part of the script that's not fully automatic is the wxPython installation. You'll still have to go thru the wizard.
If you are not interested in using RIDE, just comment that part of the script along with wxPython.
If outdated versions of the Robot Framework or the Selenium2library are found, the user will be prompted to update them.

IMPORTANT! This script uses the 'setx' command to modify the PATH user variable. 
This means it won't work in Windows XP or previous, unless it's installed from the Service Pack 2 Support Tools.

IMPORTANT! The installer download locations were valid at the time of this scrip conception, but these may change. 
If you find some invalid URL, please report an issue at https://github.com/joao-carloto/RF_Install_Script/issues

IMPORTANT! If you really want to do selenium tests on IE, beware that there are some necessary browser configurations to be made.
This script doesn't deal with those. 
For more info check https://code.google.com/p/selenium/wiki/InternetExplorerDriver#Required_Configuration

Script: RF_Installer.ps1
Author: João Carloto, Twitter: @JMCarloto
Github repo: https://github.com/joao-carloto/RF_Install_Script
License: Apache 2.0
Version: 0.5
Dependencies: Internet connectivity
              The 'setx' command



.USAGE

- Download or copy/paste this script into a file. Don't forget the .ps1 extension.
- Right click the file and choose 'Run with PowerShell'.
- If script execution is disabled in you system, follow the instructions at 
  http://www.tech-recipes.com/rx/6679/windows-7-enable-execution-of-windows-powershell-scripts/



.DESCRIPTION

Python Installation

Starts by running the 'python -V' command
If a compatible version is found (2.7.x) it will read the PATH environment variable to get it's location and store it.
Python 2.5 and 2.6 are supposed to be compatible with RF, but they would not be OK for the PIP and wxPython versions we are using.
If an incompatible version is found, it will show a warning to remove it from the PATH environment variable 
or rename python.exe to something else (e.g. python3.exe) and rerun this script.
If the 'python -V' command fails, it will search for python.exe in it's standard location (c:\python27\).
If it's present, it will assume that there's already a valid installation and just add it's location to 'PATH'.
If it can't find it, it will download a compatible python .msi installer and run it. Afterwards it will add it's location to 'path'.


PIP Installation

Starts by running the 'pip -V' command
If the 'pip -V' command fails, it will search for pip.exe in it's standard locations (e.g. c:\python27\Scripts\).
If it's present, it will assume that there's already a valid installation and just add it's location to 'PATH'.
If it can't find it, it will download the installer and run it, afterwards it will add it's location to 'PATH'.


Robot Framework Installation

Starts by running the 'pybot --version' command
If it fails, will install the robot framework using PIP


Selenium2Library Installation

Starts by checking if the <python folder>\Lib\site-packages.\Selenium2Library folder exists.
If it fails, will install the selenium2library using PIP.


Selenium Drivers for Internet Explorer and Chrome

Starts by running the --help command of the drivers.
If it fails, downloads the .zip files with the drivers.
If necessary, creates a folder to place the drivers.
Unzips the drivers to that folder.
Adds the folder to PATH

 
wxPython Installation

#### Starts by checking if the <python folder>\Lib\site-packages\wx-2.8-msw-unicode\wxPython folder exists.
Starts by running a Python command that shows the installed wxPython version.
If it fails, downloads the wxPython installer and runs it.


RIDE Installation

Starts by running the 'ride.py --version' command, to check the RIDE version (from 1.5.2.1).
If it fails, will install RIDE using PIP.
Tries to open RIDE again.


Demo Test

If Firefox or Chrome are installed, writes a demo test script on a .robot file.
IE won't be used because of needed additional configurations.
Runs the test script using pybot.
#>

# Options
$force32bitApps = $false # Valid for x64bit systems, edit to $true
$useOldRIDEwxPython = $false # Install official RIDE version 1.5.2.1 with wxPython 2.8.12.1
                            # Otherwise install not official RIDE version 2.0a2 with wxPython 3.0.2
$installRIDE = $true        # Install RIDE
# Not implemented ## $installFirefoxESR = $true # Install Firefox ESR if Firefox is not detected
$installChromeDriver = $true # Install ChromeDriver even if GoogleChrome is not detected
# Not implemented ## $installChromeBrowser = $true # Install GoogleChrome if not detected
$installOperaDriver = $false # Install OperaDriver even if Opera is not detected
# Not implemented ## $installOperaBrowser = $false # Install Opera if not detected
$installPhantomJSBrowser = $true # Install PhantomJs if not detected
$installIEDriver = $true # Install Internet Explorer Driver 32bit version (due to known bug in 64bit version)

# Installer locations. Modify these if outdated.
$python32URL = "https://www.python.org/ftp/python/2.7.11/python-2.7.11.msi"
$python64URL = "https://www.python.org/ftp/python/2.7.11/python-2.7.11.amd64.msi"
$pipURL = "https://bootstrap.pypa.io/get-pip.py"
$wxPython32URL = "http://downloads.sourceforge.net/wxpython/wxPython/3.0.2.0/wxPython3.0-win32-3.0.2.0-py27.exe"
$wxPython64URL = "http://downloads.sourceforge.net/wxpython/wxPython/3.0.2.0/wxPython3.0-win64-3.0.2.0-py27.exe"
$selChromeDriverURL = "http://chromedriver.storage.googleapis.com/2.22/chromedriver_win32.zip"
$selIEDriver32URL = "http://selenium-release.storage.googleapis.com/2.53/IEDriverServer_Win32_2.53.1.zip"
$selIEDriver64URL = "http://selenium-release.storage.googleapis.com/2.53/IEDriverServer_x64_2.53.1.zip"
$selOperaDriver32URL = "https://github.com/operasoftware/operachromiumdriver/releases/download/v0.2.2/operadriver_win32.zip"
$selOperaDriver64URL = "https://github.com/operasoftware/operachromiumdriver/releases/download/v0.2.2/operadriver_win64.zip"
$selPhantomJSURL = "https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-windows.zip"
$py32com64URL = "http://downloads.sourceforge.net/project/pywin32/pywin32/Build%20220/pywin32-220.win-amd64-py2.7.exe"
$py32com32URL = "http://downloads.sourceforge.net/project/pywin32/pywin32/Build%20220/pywin32-220.win32-py2.7.exe"


#The IE and Chrome selenium drivers will be placed here if not already installed. 
#Folder is created if not existing and added to PATH.
#Change folder location if necessary.
$selDriversFolder = "c:\Selenium_Drivers"

#We will modify the user 'PATH' environment variable, if necessary.
$userPath = [System.Environment]::GetEnvironmentVariable("path","User")

#To unzip the selenium drivers for IE and Chrome
function Expand-ZIPFile($file, $destination)
{
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item)
    }
}
# Add the alias
new-alias unzip expand-zipfile


#Check if a PIP managed package is up to date
#If not, ask if we want to update
function checkUpdates($package)
{   
    $outdatedList = pip list -o
    $outdated = $outdatedList | select-string  -pattern "^$package.*Current:.*Latest:.*"
    if ($outdated) {
        $outdated
        $confirm = Read-Host "Upgrade now? [Y]es:"
        if($confirm -eq 'Y' -Or $confirm -eq 'y') {
            pip install --upgrade $package  |  Out-Null
            echo "Finished upgrading the $package package"
        }
    } else {
        echo "Package $package is up to date"
    }
}


#TODO is this reliable? Is there a better option?
#Checks if Firefox or Chrome are installed to do a demo test run
#Won't return IE due to the need of additional configurations
$firefoxPath = $env:LOCALAPPDATA + "\Mozilla Firefox"
$firefoxPath2 = $env:LOCALAPPDATA + "\Mozilla\Firefox"
$chromePath = $env:LOCALAPPDATA + "\Google\Chrome"
$operaPath = $env:LOCALAPPDATA + "\Opera Software\Opera Stable"
function getDemoBrowser {
    # Check if Firefox is installed
    if( (Test-Path $firefoxPath -PathType Container) -or (Test-Path $firefoxPath2 -PathType Container) ){ 
       $browser = "Firefox"
       return  $browser
    }
    # Check if Chrome is installed
    if(Test-Path $chromePath -PathType Container) {
       $browser = "Chrome"
       return  $browser
    }
	# Check if Opera is installed
    if(Test-Path $operaPath -PathType Container) {
       $browser = "Opera"
       return  $browser
    }
    return     $false
}


#THE REAL WORK STARTS HERE

#The Temp folder will be used to download the installers and run the demo test
#All installers will be removed when not longer necessary
if(! (Test-Path "c:\Temp" -PathType Container)) {
    New-Item c:\Temp -type directory  | Out-Null
}

try {
    setx /? | Out-null
} catch { 
    echo "The 'setx' command doesn't seem to be available"
    if(Test-Path c:\Windows\System32\setx.exe) {
        echo "setx.exe is available at c:\Windows\System32"
        echo "We'll add c:\Windows\System32 to the PATH environment variable"
        c:\Windows\System32\setx.exe   path "$userPath;c:\Windows\System32"  | Out-Null
        $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
        $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    } else {
        echo "WARNING! The setx command doesn't seem to be available in you system"
        echo "It's not available by default in Windows XP or previous, unless it's installed from the Service Pack 2 Support Tools"
        echo "Without it, we cannot update the PATH environment variable"
        echo "We will now quit this script"
        Read-Host 'Press Enter to close...' | Out-Null
        exit  
    }
}

#all 64Bits packages
if ( ${env:programfiles(x86)} -And -Not $force32bitApps ) { 
    $selIEDriverURL = $selIEDriver32URL # Disabled $selIEDriver64URL because of sendkeys high delay bug
	$selOperaDriverURL = $selOperaDriver64URL
	if($useOldRIDEwxPython){
        $wxPythonURL = "https://sourceforge.net/projects/wxpython/files/wxPython/2.8.12.1/wxPython2.8-win64-unicode-2.8.12.1-py27.exe/download"
    } else {
        $wxPythonURL = $wxPython64URL
    }
	$pythonURL = $python64URL
	$py32comURL = $py32com64URL
#all 32 bits packages
} else {
        $selIEDriverURL = $selIEDriver32URL
	$selOperaDriverURL = $selOperaDriver32URL
	if($useOldRIDEwxPython){
        $wxPythonURL = "https://sourceforge.net/projects/wxpython/files/wxPython/2.8.12.1/wxPython2.8-win32-unicode-2.8.12.1-py27.exe/download"
    } else {
        $wxPythonURL = $wxPython32URL
    }
	$pythonURL = $python32URL
	$py32comURL = $py32com32URL
}

#Install Python
try {
    $pythonVersion = python -V 2>&1
    $pythonVersion = [String]$pythonVersion
    #Python 2.5 and 2.6 are supposed to be compatible with RF, but they would not be OK for the PIP and wxPython versions we are using. 
    #if (![Regex]::IsMatch($pythonVersion,"Python 2\.[567]")) {
    if (![Regex]::IsMatch($pythonVersion,"Python 2\.7")) {
        echo "The active Python version ($pythonVersion) is incompatible with the Robot Framework and/or other tools we are installing
        Please remove it from the PATH environment variable or rename python.exe to something else (e.g. python3.exe) and rerun this script"
        pause
        Exit 
    } else {
      echo  "A Python version compatible with the Robot Framework is already installed: $pythonVersion"
      $env:path -match "([^;]*\\python2[567])([^\\]|$)" | Out-null
      $pythonPath = $matches[1]
    }
} catch  {
    echo "Could not get the local Python version"
    if (Test-Path "c:\python27\python.exe" -PathType Any) {
        $pythonPath = "c:\python27"
    } 
    <#
    elseif (Test-Path "c:\python26\python.exe" -PathType Any) {
        $pythonPath = "c:\python26"
    } elseif (Test-Path "c:\python25\python.exe" -PathType Any) {
        $pythonPath = "c:\python25"
    } 
    #>
    if ($pythonPath) {
        echo  "A valid Python installation seems to exist in the default location ($pythonPath)"
        echo  "We'll just add it to the PATH environment variable..."
    } else {
        echo "Could not find a compatible Python installation on the root of the c:\ drive"
        echo "Downloading the Python 2.7 installer..."
        $source = $pythonURL
        $Filename = [System.IO.Path]::GetFileName($source)
        $dest = "C:\Temp\$Filename"
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($source, $dest)
        echo "Running the installer..."
        Start-Process $dest  /qn -Wait
        Remove-Item   $dest
        $pythonPath = "c:\python27"
        echo "Adding the Python folder to the PATH environment variable..."
    }
    #This is the user path not the system
    setx path "$userPath;$pythonPath"   | Out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
}

try{
      $pythonArch = python -c "import platform; print(platform.architecture()[0])"
      if($pythonArch -like "32*"){
      $force32bitApps = $true # If python 32bit is installed we must use 32bit versions
      }
} catch{
        echo "Warning! Unable to check the Python bit mode"
        echo "output was: $pythonArch"
        echo "This script will exit"
        pause
        Exit 
}

if($force32bitApps){
        $selIEDriverURL = $selIEDriver32URL
	$selOperaDriverURL = $selOperaDriver32URL
	if($useOldRIDEwxPython){
        $wxPythonURL = "https://sourceforge.net/projects/wxpython/files/wxPython/2.8.12.1/wxPython2.8-win32-unicode-2.8.12.1-py27.exe/download"
    } else {
        $wxPythonURL = $wxPython32URL
    }
	$py32comURL = $py32com32URL
}


#Install PIP
try {$pipVersion = pip -V
    echo "PIP is installed with version: $pipVersion"
} catch {
    echo "Unable to get the local PIP version"
    $pipExists = Test-Path "$pythonPath\Scripts\pip.exe" -PathType Any
    if($pipExists) {
        echo  "PIP seems to be installed although not included in the PATH environment variable"
        echo  "We'll just add the Scripts folder to PATH..."
    }
    else {
        echo "PIP doesn't seem to be installed"
        echo "Downloading PIP..."
        $source = $pipURL
        $Filename = [System.IO.Path]::GetFileName($source)
        $dest = "C:\Temp\$Filename"
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($source, $dest)
        echo "Installing PIP..."
        Start-Process python  $dest  -Wait
        Remove-Item   $dest
        echo  "Adding the Scripts folder to the PATH environment variable..."
    }
    setx path "$userPath;$pythonPath\Scripts"  | Out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
}

#Upgrade pip
try {
    $pipup = pip install -U pip
    echo "Upgraded pip if needed."
} catch {
    echo "Unable to upgrade pip."
    pip --version
}


#Install the Robot Framework
try {
    $RFVersion = pybot --version
    echo "Robot Framework is installed with version: $RFVersion"
    echo "Checking if the Robot Framework is up to date..."
    checkUpdates("robotframework")
} catch {
    echo "Unable to get the local Robot Framework version"
    echo "Installing the Robot Framework..."
    pip install robotframework  | Out-null
}


#Install the Selenium2library
$seleniumFolderExists = Test-Path "$pythonPath\Lib\site-packages\Selenium2Library" -PathType Any
if($seleniumFolderExists) {
    echo  "The Selenium2library seems to be installed"
    echo "Checking if the The Selenium2library is up to date..."
    checkUpdates("robotframework-selenium2library")
    }
else { 
    echo "The Selenium2library doesn't seem to be installed"
    echo "Installing the Selenium2library..."
    pip install robotframework-selenium2library  | Out-null
}


if($installIEDriver) {
#Install Selenium IE driver
try {
   #Old versions don't support the --help flag
   #IEDriverServer --help 
   Start-Process -NoNewWindow IEDriverServer
   Stop-Process -processname IEDriverServer
   echo "The Selenium IE driver is installed."
} 
catch {
    echo "Selenium IE driver doesn't seem to be installed"
    echo "Downloading Selenium IE driver ZIP..."
    $source = $selIEDriverURL
    $Filename = [System.IO.Path]::GetFileName($source)
    $dest = "c:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)

    if (!(Test-Path $selDriversFolder)) {
        echo "Creating a folder for the Selenium drivers"
        New-Item -ItemType directory -Path $selDriversFolder  | Out-null
    }
    if(!(Test-Path "$selDriversFolder\IEDriverServer.exe")) {
        echo "Unziping the Selenium IE driver to $selDriversFolder"
        unzip  $dest  $selDriversFolder | Out-null
    }
    echo "Adding $selDriversFolder to PATH"
    setx path "$userPath;$selDriversFolder"   | Out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    $driverFolderIsInPath = $true

    Remove-Item   $dest
}
}

#Install Chrome
# https://www.google.com/chrome/browser/desktop/index.html?system=true&standalone=1&platform=win64
# ChromeStandaloneSetup64.exe /silent /install

#Install Firefox
# https://download.mozilla.org/?product=firefox-45.2.0esr-SSL&os=win64&lang=en-GB
# "Firefox Setup 45.2.0esr.exe" /S

#Install Opera
# http://www.opera.com/computer/thanks?ni=stable&os=windows
# Opera_38.0.2220.31_Setup.exe --silent

#Install Phantomjs (like a webdriver)
# https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-windows.zip

if($installChromeDriver){
#Install Selenium Chrome driver
try {
    chromedriver --help | Out-null
    echo "The Selenium Chrome driver is installed"
} 
catch {
    echo "Selenium Chrome driver doesn't seem to be installed"
    echo "Downloading Selenium Chrome driver ZIP..."
    $source = $selChromeDriverURL
    $Filename = [System.IO.Path]::GetFileName($source)
    $dest = "c:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)

    if (!(Test-Path $selDriversFolder)) {
        echo "Creating a folder for the Selenium drivers"
        New-Item -ItemType directory -Path $selDriversFolder  | Out-null
    }
    if(!(Test-Path "$selDriversFolder\chromedriver.exe")) {
        echo "Unziping the Selenium Chrome driver to $selDriversFolder"
        unzip  $dest  $selDriversFolder  | Out-null
    }
    if(! $driverFolderIsInPath) {
        echo "Adding $selDriversFolder to PATH"
        setx path "$userPath;$selDriversFolder"  | Out-null
        $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
        $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    }
    Remove-Item   $dest  | Out-null
}
}

if($installOperaDriver){
#Install Opera driver
try {
    operadriver --version | Out-null
    echo "The Selenium Opera driver is installed"
} 
catch {
    echo "Selenium Opera driver doesn't seem to be installed"
    echo "Downloading Opera driver ZIP..."
    $source = $selOperaDriverURL
    $Filename = [System.IO.Path]::GetFileName($source)
    $dest = "c:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)

    if (!(Test-Path $selDriversFolder)) {
        echo "Creating a folder for the Selenium drivers"
        New-Item -ItemType directory -Path $selDriversFolder  | Out-null
    }
    if(!(Test-Path "$selDriversFolder\operadriver.exe")) {
        echo "Unziping the Selenium Chrome driver to $selDriversFolder"
        unzip  $dest  $selDriversFolder  | Out-null
    }
    if(! $driverFolderIsInPath) {
        echo "Adding $selDriversFolder to PATH"
        setx path "$userPath;$selDriversFolder"  | Out-null
        $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
        $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    }
    Remove-Item   $dest  | Out-null
}
}

if($installPhantomJSBrowser){
#Install PhantomJs driver/browser
try {
    phantomjs --version | Out-null
    echo "PhantomJS is installed"
} 
catch {
    echo "PhantomJS doesn't seem to be installed"
    echo "Downloading PhantomJS ZIP..."
    $source = $selPhantomJSURL
    $Filename = [System.IO.Path]::GetFileName($source)
    $dest = "c:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)

    if (!(Test-Path $selDriversFolder)) {
        echo "Creating a folder for the Selenium drivers"
        New-Item -ItemType directory -Path $selDriversFolder  | Out-null
    }
    if(!(Test-Path "$selDriversFolder\phantomjs.exe")) {
        echo "Unziping PhantomJS to $selDriversFolder"
		unzip  $dest  "c:\Temp" | Out-null
        move   "c:\Temp\phantomjs-2.1.1-windows\bin\phantomjs.exe" $selDriversFolder  | Out-null
    }
    if(! $driverFolderIsInPath) {
        echo "Adding $selDriversFolder to PATH"
        setx path "$userPath;$selDriversFolder"  | Out-null
        $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
        $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    }
    Remove-Item   $dest  | Out-null
}
}
#Writes a demo test script, if Firefox, Chrome or Opera are installed
$demoBrowser = getDemoBrowser

echo "Browser is $demoBrowser "
if($demoBrowser) {
#Be carefull with the test indentation and spacing.
    echo "*Settings*
Documentation	     Test suite created with FireRobot
Library	   Selenium2Library   15.0   5.0
*Test Cases *
EA Installer Demo Test
    Open Browser  	http://joao-carloto.github.io/RF_Install_Script/test.html   	$demoBrowser
    Page Should Contain   	RF Install Script Test Page
    Input Text   	sometextbox   	Congratulations!
    Input Text   	sometextarea    If you are reading this, you have completed your Robot Framework setup.\n\nTo run this test again on RIDE, click on the 'Run Tests' button.\n\nTo learn more about the immense possibilities of the Robot Framework go to http://robotframework.org/." | Out-File -encoding utf8 c:\Temp\test.robot | Out-null
}


if($installRIDE){
#Install wxPython
$wxPythonVersion = python -c "import wx; print(wx.VERSION)"
$wxPythonVersion = [String]$wxPythonVersion
if([Regex]::IsMatch($wxPythonVersion,"(2, 8, 12, 1, '')") -and $useOldRIDEwxPython ){
echo  "wxPython seems to be installed"
} elseif([Regex]::IsMatch($wxPythonVersion,"(3, 0, 2, 0, '')") -and -not $useOldRIDEwxPython) {
    echo  "wxPython seems to be installed"
}
else {
    echo "wxPython doesn't seem to be installed"

  #  $pythonBitMode = python -c "import platform; print platform.architecture()"
  #  $pythonBitMode = [String]$pythonBitMode
  #  if ([Regex]::IsMatch($pythonBitMode,"32bit")) {
  #      $wxpythonURL = $wxPython32URL
  #  } 
  #  elseif ([Regex]::IsMatch($pythonBitMode,"64bit"))  {
  #      $wxpythonURL = $wxPython64URL
  #  } else {
  #      echo "Warning! Unable to check the Python bit mode (necessary to choose the wxPython version to install)"
  #      echo "This script will exit"
  #      pause
  #      Exit 
  #  }
    echo "Downloading wxPython..."
    $source = $wxpythonURL
    # The filename might contain URL parameters, so we use a static name.
    # $Filename = [System.IO.Path]::GetFileName($source)
    $Filename = "wxPython_installer.exe"
    $dest = "C:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    echo "command to download wx"
    echo $source, $dest
    $wc.DownloadFile($source, $dest)

    echo "Installing wxPython..."
    echo "Please use the default actions of the Installer..."
    #Silent install mode does not work with this one
    Start-Process $dest /qn -Wait
    Remove-Item   $dest
}

if(-Not $useOldRIDEwxPython){
#Install Pywin32
try{
$pywinVersion = python -c "import pywin; print('PyWin32')"  | Out-null
# echo $pywinVersion
if([Regex]::IsMatch($pywinVersion,"PyWin32")) {
    echo  "pywin32 seems to be installed"
}
}
catch {
    echo "pywin32 doesn't seem to be installed"
    echo "You must install dependency for RIDE Desktop Shortcut creation."
    echo "Download http://downloads.sourceforge.net/project/pywin32/pywin32/Build%20220/"
    echo "Downloading pywin32..."
    $source = $py32comURL
    $Filename = "pywin32.exe"
    $dest = "C:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)

    echo "Installing pywin32..."
    #Silent install mode does not work with this one
    Start-Process $dest /qn -Wait
    Remove-Item   $dest
}
}

#Install RIDE and open it
#RIDE checks for updates on start by default, we don't have to use our checkUpdates function
try {
   echo "Trying to open RIDE..."
   if($demoBrowser)  {
        Start-Process ride.py  c:\Temp\test.robot
   } else {
        Start-Process ride.py --version
   }
} 
catch {
   echo "RIDE doesn't seem to be installed"
   echo "Installing RIDE..."
   if($useOldRIDEwxPython){
   echo "Installing RIDE 1.5.2.1 from PyPY"
   pip install robotframework-ride==1.5.2.1  | Out-null
   } else {
      echo "Installing RIDE from https://github.com/HelioGuilherme66/RIDE/"
      pip install -U https://github.com/HelioGuilherme66/RIDE/archive/v2.0a2.zip | Out-null
   }

   echo "Opening RIDE..."
   if($demoBrowser)  {
        Start-Process ride.py  c:\Temp\test.robot
   } else {
        Start-Process ride.py --version
   }
}
}

#Run a sample test with pybot
if($demoBrowser)  {
    echo "Running a sample test..."
    pybot -d c:\Temp  c:\Temp\test.robot 
}


echo "Everything is concluded"

#A simple 'pause' doesn't work on older versions of PS
Read-Host 'Press Enter to close this shell...' | Out-Null
