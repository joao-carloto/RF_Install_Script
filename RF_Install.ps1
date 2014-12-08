<#
.SYNOPSIS

This Windows PowerShell script will download and install the Robot Framework, all it's required dependencies 
(if not allready available) and some extra libraries and tools.
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
This script doesn't deal with those. 
For more info check https://code.google.com/p/selenium/wiki/InternetExplorerDriver#Required_Configuration

Script: RF_Installer.ps1
Author: João Carloto, Twitter: @JMCarloto
Github repo: https://github.com/joao-carloto/RF_Install_Script
License: Apache 2.0
Version: 0.1
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
If a compatible version is found (2.5, 2.6 or 2.7) it will read the path environment variable to get it's location and store it.
If an incompatible version is found, it will show a warning to remove it from the PATH environment variable 
or rename python.exe to something else (e.g. python3.exe) and rerun this script.
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
#>



#Installer locations. Modify these if outdated.
$pythonURL = "https://www.python.org/ftp/python/2.7.8/python-2.7.8.msi"
$pipURL = "https://bootstrap.pypa.io/get-pip.py"
$wxPythonURL = "https://log-parser.googlecode.com/files/wxPython2.8-win32-unicode-2.8.12.1-py27.exe"
$selChromeDriverURL = "http://chromedriver.storage.googleapis.com/2.9/chromedriver_win32.zip"

#64Bits
if (${env:programfiles(x86)}) { 
    $selIEDriverURL = "http://selenium-release.storage.googleapis.com/2.44/IEDriverServer_x64_2.44.0.zip"
#32 bits
} else {
    $selIEDriverURL = "http://selenium-release.storage.googleapis.com/2.44/IEDriverServer_Win32_2.44.0.zip"
}

#The IE and Chrome selenium drivers will be placed here if not already installed. 
#Folder is created if not existing and added to path.
#Change folder location if necessary.
$selDriversFolder = "c:\Selenium Drivers"

#We will modify the user 'path' environment variable, if necessary.
$userPath = [System.Environment]::GetEnvironmentVariable("path","User")

#To unzip the selenium drivers for IE and Chrome
function Expand-ZIPFile($file, $destination)
    {
        $shell = new-object -com shell.application
        $zip = $shell.NameSpace($file)
        foreach($item in $zip.items())
        {
            $shell.Namespace($destination).copyhere($item)
        }
}
# Add the alias
new-alias unzip expand-zipfile


function getDemoBrowser {
	#.Synopsis
	#  Check if Firefox or Chrome are installed to do a demo test run
    #  Won't return IE due to the need of additional configurations

    #Check if Firefox is installed
    if (${env:programfiles(x86)}) {
         $firefox_path = join-path "${env:programfiles(x86)}" "Mozilla Firefox\firefox.exe" 
    } else { 
        $firefox_path = join-path "${env:programfiles}" "Mozilla Firefox\firefox.exe" 
    }
    if (test-path $firefox_path) {
       $browser = "Firefox"
       return  $browser
    } 

    #Check if Chrome is installed
    if (${env:programfiles(x86)}){ 
        $firefox_path = join-path "${env:programfiles(x86)}" "Google\Chrome\Application\chrome.exe" 
    } else {
        $firefox_path = join-path "${env:programfiles}" "Google\Chrome\Application\chrome.exe" 
    }
    if (test-path $firefox_path) {
       $browser = "Chrome"
       return  $browser
    }

    return     $false
}


#THE REAL WORK STARTS HERE

try {
    setx /? | Out-null
} catch { 
    echo "The 'setx' command doesn't seem to be available"
    if(Test-Path c:\Windows\System32\setx.exe) {
        echo "setx.exe is available at c:\Windows\System32"
        echo "We'll add c:\Windows\System32 to the Path environment variable"
        c:\Windows\System32\setx.exe   path "$userPath;c:\Windows\System32"  | Out-Null
        $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
        $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    } else {
        echo "WARNING! The setx command doesn't seem to ba available in you system."
        echo "It's not available by default in Windows XP or previous, unless it's installed from the Service Pack 2 Support Tools."
        echo "Without it, we cannot update the Path environment variable."
        echo "We will now quit this script"
        Read-Host 'Press Enter to close...' | Out-Null
        exit  
    }
}


#Install Python
try {
    $pythonVersion = python -V 2>&1
    $pythonVersion = [String]$pythonVersion 
    if (![Regex]::IsMatch($pythonVersion,"Python 2\.[567]")) {
        echo "The active Python version ($pythonVersion) is incompatible with the Robot Framework
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
    } elseif (Test-Path "c:\python26\python.exe" -PathType Any) {
        $pythonPath = "c:\python26"
    } elseif (Test-Path "c:\python25\python.exe" -PathType Any) {
        $pythonPath = "c:\python25"
    } 
    if ($pythonPath) {
        echo  "A valid Python installation seems to exist in the default location ($pythonPath)"
        echo  "We'll just add it to the PATH environment variable..."
    } else {
        echo "Could not find a compatible Python installation on the root of the c:\ drive"
        echo "Downloading the Python 2.7.8 installer..."
        $source = $pythonURL
        $Filename = [System.IO.Path]::GetFileName($source)
        $dest = "C:\Temp\$Filename"
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($source, $dest)
        echo "Running the installer..."
        Start-Process $dest  /qn -Wait
        Remove-Item   $dest
        $pythonPath = "c:\python27"
        echo "Adding the python folder to the PATH environment variable..."
    }
    #This is th user path not the system
    setx path "$userPath;$pythonPath"   | Out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
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


#Install the Robot Framework
try {
    $RFVersion = pybot --version
    echo "Robot Framework is installed with version: $RFVersion"
} catch {
    echo "Unable to get the local Robot Framework version"
    echo "Installing RobotFramework..."
    pip install robotframework  | Out-null
}


#Install the Selenium2library
$seleniumFolderExists = Test-Path "$pythonPath\Lib\site-packages\Selenium2Library" -PathType Any
if($seleniumFolderExists) {
    echo  "The Selenium2library seems to be installed."
    }
else { 
    echo "The Selenium2library doesn't seem to be installed"
    echo "Installing the Selenium2library..."
    pip install robotframework-selenium2library  | Out-null
}


#Install Selenium IE driver
try {
   #Old versions don't support the --help flag
   #IEDriverServer --help 
   Start-Process -NoNewWindow IEDriverServer
   Stop-Process -processname IEDriverServer
   echo "The Selenium IE driver is installed."
} 
catch {
    echo "Selenium IE driver doesn't seem to be installed."
    echo "Downloading Selenium IE driver ZIP..."
    $source = $selIEDriverURL
    $Filename = [System.IO.Path]::GetFileName($source)
    $dest = "c:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)

    if (!(Test-Path $selDriversFolder)) {
        echo "Creating a folder for the Selenium drivers."
        New-Item -ItemType directory -Path $selDriversFolder  | Out-null
    }
    if(!(Test-Path "$selDriversFolder\IEDriverServer.exe")) {
        echo "Unziping the Selenium IE driver to $selDriversFolder"
        unzip  $dest  $selDriversFolder | Out-null
    }
    echo "Adding $selDriversFolder to path"
    setx path "$userPath;$selDriversFolder"   | Out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    $driverFolderIsInPath = $true

    Remove-Item   $dest
}


#Install Selenium Chrome driver
try {
    chromedriver --help | Out-null
    echo "The Selenium Chrome driver is installed."
} 
catch {
    echo "Selenium Chrome driver doesn't seem to be installed."
    echo "Downloading Selenium Chrome driver ZIP..."
    $source = $selChromeDriverURL
    $Filename = [System.IO.Path]::GetFileName($source)
    $dest = "c:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)

    if (!(Test-Path $selDriversFolder)) {
        echo "Creating a folder for the Selenium drivers."
        New-Item -ItemType directory -Path $selDriversFolder  | Out-null
    }
    if(!(Test-Path "$selDriversFolder\chromedriver.exe")) {
        echo "Unziping the Selenium Chrome driver to $selDriversFolder"
        unzip  $dest  $selDriversFolder  | Out-null
    }
    if(! $driverFolderIsInPath) {
        echo "Adding $selDriversFolder to path"
        setx path "$userPath;$selDriversFolder"  | Out-null
        $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
        $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    }
    Remove-Item   $dest  | Out-null
}


#Writes a demo test script, if Firefox or Chrome are installed
$demoBrowser = getDemoBrowser
if($demoBrowser) {
#Be carefull with the test indentation and spacing.
    echo "*Settings*
Documentation	     Test suite created with FireRobot.
Library	   Selenium2Library   15.0   5.0
*Test Cases *
FireRobot Test Case
    Open Browser  	http://joao-carloto.github.io/RF_Install_Script/test.html   	$demoBrowser
    Page Should Contain   	RF Install Script Test Page
    Input Text   	sometextbox   	Congratulations!
    Input Text   	sometextarea    If you are reading this, you have completed your Robot Framework setup.\n\nTo run this test again on RIDE, click on the 'Run Tests' button.\n\nTo learn more about the immense possibilities of the Robot Framework go to http://robotframework.org/." | Out-File -encoding utf8 c:\Temp\test.txt | Out-null
}


#Install wxPython
$wxPythonFolderExists = Test-Path "$pythonPath\Lib\site-packages\wx-2.8-msw-unicode\wxPython" -PathType Any
if($wxPythonFolderExists) {
    echo  "wxPython seems to be installed"
}
else {
    echo "wxPython doesn't seem to be installed"
    echo "Installing wxPython..."
    $source = $wxPythonURL

    $Filename = [System.IO.Path]::GetFileName($source)
    $dest = "C:\Temp\$Filename"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($source, $dest)
    #Silent install mode does not work with this one
    Start-Process $dest /qn -Wait
    Remove-Item   $dest
}


#Install RIDE and open it
try {
   echo "Trying to open RIDE..."
   if($demoBrowser)  {
        Start-Process ride.py  c:\Temp\test.txt
   } else {
        Start-Process ride.py 
   }
} 
catch {
   echo "RIDE doesn't seem to be installed"
   echo "Installing RIDE..."
   pip install robotframework-ride   | Out-null
   echo "Opening RIDE..."
   if($demoBrowser)  {
        Start-Process ride.py  c:\Temp\test.txt
   } else {
        Start-Process ride.py 
   }
}


#Run a sample test with pybot
if($demoBrowser)  {
    echo "Running a sample test..."
    pybot -d c:\Temp  c:\Temp\test.txt  
}


echo "Everything is concluded"

#A simple 'pause' doesn't work on older versions of PS
Read-Host 'Press Enter to close this shell...' | Out-Null