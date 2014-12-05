<#
.SYNOPSIS

This Windows PowerShell script will download and install the Robot Framework, all it's required dependencies (if not allready available) and some extra libraries and tools.
If necessary, it will also modify the user 'path' environement variable, so to include the necessary folders.
In the end of the process, the following resources should be installed:
- Python (version 2.7.8 will be downloaded if no RF compatible version is allready present).
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

Python Intallation

Starts by running the 'python -V' command
If a compatible version is found (2.5, 2.6 or 2.7) it will read the path environement variable to get it's location and store it.
If an incompatible version is found, it will show a warning to remove it from the PATH environement variable or rename python.exe to something else (e.g. python3.exe) and rerun this script.
If the 'python -V' command fails it will search for python.exe in it's standard locations (e.g. c:\python27\).
If it's present, it will assume that there's allready a valid installation and just add it's location to 'path'.
If it can't find it, it will download a compatible python .msi installer and run it. Afterwards it will add it's location to 'path'.


PIP Installation

Starts by running the 'pip -V' command
If the 'pip -V' command fails, it will search for pip.exe in it's standard locations (e.g. c:\python27\Scripts\).
If it's present, it will assume that there's allready a valid installation and just add it's location to 'path'.
If it can't find it, it will download the installer and run it, afterwars it will add it's location to 'path'.


Robot Framework Installation

Starts by running the 'pybot --version' command
If it fails, will install the robot framework using PIP


Selenium2Library Installation

Starts by checking if the <python folder>\Lib\site-packages.\Selenium2Library folder exists.
If it fails, will install the selenium2libraryu using PIP.


wxPython Installation

Starts by checking if the <python folder>\Lib\site-packages\wx-2.8-msw-unicode\wxPython folder exists
If it fails, downloadds the wxPython installer and runs it.


RIDE Installation

Starts by running the 'ride.py' command, to open the RIDE GUI.
If it fails, will install RIDE using PIP.
Tries to open RIDE again.


Demo Test

Writes a test scrip on temporary .txt file.
Runs the demo test script using pybot
#>


#Installer locations. Modify these if outdated.
$pythonURL = "https://www.python.org/ftp/python/2.7.8/python-2.7.8.msi"
$pipURL = "https://bootstrap.pypa.io/get-pip.py"
$wxPythonURL = "https://log-parser.googlecode.com/files/wxPython2.8-win32-unicode-2.8.12.1-py27.exe"
$selIEDriverURL = "http://selenium-release.storage.googleapis.com/2.44/IEDriverServer_Win32_2.44.0.zip"
$selChromeDriverURL = "http://chromedriver.storage.googleapis.com/2.9/chromedriver_win32.zip"

#The IE and Chrome selenium drivers will be placed here if not already installed. Folder is created if not existing. Added to path.
#Change folder location if necessary.
$selDriversFolder = "c:\Selenium Drivers"

#We will modify the user 'path' environment variable, if necessary.
$userPath = [System.Environment]::GetEnvironmentVariable("path","User")


#To unzip the selenium drivers for IE and Chrome
#Copied form http://poshcode.org/4845
#The 'easy' examples on the net wouldn't work, check better later
Add-Type -As System.IO.Compression.FileSystem
function Expand-ZipFile {
	#.Synopsis
	#  Expand a zip file, ensuring it's contents go to a single folder ...
	[CmdletBinding()]
	param(
		# The path of the zip file that needs to be extracted
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=0, Mandatory=$true)]
		[Alias("PSPath")]
		$FilePath,
 
		# The path where we want the output folder to end up
		[Parameter(Position=1)]
		$OutputPath = $Pwd,
 
		# Make sure the resulting folder is always named the same as the archive
		[Switch]$Force
	)
	process {
		$ZipFile = Get-Item $FilePath
		$Archive = [System.IO.Compression.ZipFile]::Open( $ZipFile, "Read" )
 
		# Figure out where we'd prefer to end up
		if(Test-Path $OutputPath) {
			# If they pass a path that exists, we want to create a new folder
			$Destination = Join-Path $OutputPath $ZipFile.BaseName
		} else {
			# Otherwise, since they passed a folder, they must want us to use it
			$Destination = $OutputPath
		}
 
		# The root folder of the first entry ...
		$ArchiveRoot = ($Archive.Entries[0].FullName -Split "/|\\")[0]
 
		Write-Verbose "Desired Destination: $Destination"
		Write-Verbose "Archive Root: $ArchiveRoot"
 
		# If any of the files are not in the same root folder ...
		if($Archive.Entries.FullName | Where-Object { @($_ -Split "/|\\")[0] -ne $ArchiveRoot }) {
			# extract it into a new folder:
			New-Item $Destination -Type Directory -Force
			[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory( $Archive, $Destination )
		} else {
			# otherwise, extract it to the OutputPath
			[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory( $Archive, $OutputPath )
 
			# If there was only a single file in the archive, then we'll just output that file...
			if($Archive.Entries.Count -eq 1) {
				# Except, if they asked for an OutputPath with an extension on it, we'll rename the file to that ...
				if([System.IO.Path]::GetExtension($Destination)) {
					Move-Item (Join-Path $OutputPath $Archive.Entries[0].FullName) $Destination
				} else {
					Get-Item (Join-Path $OutputPath $Archive.Entries[0].FullName)
				}
			} elseif($Force) {
				# Otherwise let's make sure that we move it to where we expect it to go, in case the zip's been renamed
				if($ArchiveRoot -ne $ZipFile.BaseName) {
					Move-Item (join-path $OutputPath $ArchiveRoot) $Destination
					Get-Item $Destination
				}
			} else {
				Get-Item (Join-Path $OutputPath $ArchiveRoot)
			}
		}
 
		$Archive.Dispose()
	}
}
# Add the alias
new-alias unzip expand-zipfile


#THE REAL WORK STARTS HERE

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
      echo  "A Python version ($pythonVersion) compatible with Robot Framework is already installed"
      $env:path -match "([^;]*\\python2[567])([^\\]|$)" | out-null
      $pythonPath = $matches[1]
    }
} catch  {
    echo "Could not get the python version"
    if (Test-Path "c:\python27\python.exe" -PathType Any) {
        $pythonPath = "c:\python27"
    } elseif (Test-Path "c:\python26\python.exe" -PathType Any) {
        $pythonPath = "c:\python26"
    } elseif (Test-Path "c:\python25\python.exe" -PathType Any) {
        $pythonPath = "c:\python25"
    } 

    if ($pythonPath) {
        echo  "A valid python installation seems to exist in the default location ($pythonPath)"
        echo  "We'll just add it to the PATH environment variable..."
    } else {
        echo "Could not find a python installation on the root of the c:\ drive"
        echo "Downloading the python 2.7.8 installer..."
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
    setx path "$userPath;$pythonPath"   | out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
}


#Install PIP
try {$pipVersion = pip -V
    echo "PIP is installed with version: $pipVersion" 
} catch {
    echo "Unable to get PIP version"
    $pipExists = Test-Path "$pythonPath\Scripts\pip.exe" -PathType Any
    if($pipExists) {
        echo  "PIP seems to be installed"
        echo  "We'll just add the Scripts folder to the PATH environment variable..."
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
    setx path "$userPath;$pythonPath\Scripts"  | out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
}


#Install the Robot Framework
try {
$RFVersion = pybot --version
echo "Robot Framework is installed with version: $RFVersion"
} catch {
    echo "Unable to get the Robot Framework version"
    echo "Installing RobotFramework..."
    pip install robotframework  | out-null
}


#Install the Selenium2library
$seleniumFolderExists = Test-Path "$pythonPath\Lib\site-packages\Selenium2Library" -PathType Any
if($seleniumFolderExists) {
    echo  "The selenium2library seems to be installed."
    }
else { 
    echo "The selenium2library doesn't seem to be installed"
    echo "Installing the selenium2library..."
    pip install robotframework-selenium2library  | out-null
}


#Install selenium IE driver
try {
   IEDriverServer --help | out-null
   echo "The Selenium IE driver seems to be installed."
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
      New-Item -ItemType directory -Path $selDriversFolder  | out-null
   }
   echo "Extracting Selenium IE driver to $selDriversFolder"

   try {
    unzip  $dest  $selDriversFolder | out-null
    } catch {
        echo "Warning! The unzip of $dest failed. Did the file already exist at $selDriversFolder?"
    }
    echo "Adding $selDriversFolder to path"
    setx path "$userPath;$selDriversFolder"   | out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    $driverFolderIsInPath = $true
    Remove-Item   $dest
}


#Install selenium Chrome driver
try {
   chromedriver --help | out-null
   echo "The Selenium Chrome driver seems to be installed."
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
      New-Item -ItemType directory -Path $selDriversFolder  | out-null
   }
   echo "Extracting Selenium Chrome driver to $selDriversFolder"
   try {
    unzip  $dest  $selDriversFolder | out-null
    } catch {
        echo "Warning! The unzip of $dest failed. Did the file already exist at $selDriversFolder?"
    }
    if(! $driverFolderIsInPath) {
    echo "Adding $selDriversFolder to path"
    setx path "$userPath;$selDriversFolder"  | out-null
    $userPath = [System.Environment]::GetEnvironmentVariable("path","User")
    $env:path = [System.Environment]::GetEnvironmentVariable("path","Machine") + ";$userPath"
    Remove-Item   $dest
    }
}

#TODO check wich browsers are available. Don't use IE (too unreliable).
#Make a RF demonstration test
echo "*Settings*
Library    Selenium2Library    15.0    5
*Test Cases*
Demo Test Case
    Open Browser  	http://robotframework.org/   	Chrome" | Out-File -encoding utf8 c:\Temp\test.txt



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
   Start-Process ride.py
} 
catch {
   echo "RIDE doesn't seem to be installed"
   echo "Installing RIDE..."
   pip install robotframework-ride   | out-null
   echo "Opening RIDE..."
   Start-Process ride.py   c:\Temp\test.txt
}

#TODO put report in specific folder

#Run a sample test with pybot
echo "Running a sample test..."
pybot  c:\Temp\test.txt

<#
if(Test-Path c:\Temp\report.html) {Invoke-Item c:\Temp\report.html}

if(Test-Path c:\Temp\report.html) {Remove-Item   c:\Temp\report.html  | out-null}
if(Test-Path c:\Temp\log.html) {Remove-Item   c:\Temp\log.html   | out-null}
if(Test-Path c:\Temp\test.txt) { Remove-Item   c:\Temp\test.txt  | out-null}
#>

echo "Everything is concluded"
pause

