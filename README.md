<strong>SYNOPSIS</strong>


This script will download and install the Robot Framework, all it's required dependencies (if not already available) and some extra libraries and tools.
If necessary, it will also modify the user 'path' environment variable, so to include the necessary folders.
In the end of the process, the following resources should be installed:
- Python 2.7.x
- PIP (used to install RF, Selenium2library and RIDE)
- Robot Framework
- Selenium2library
- Selenium driver for Internet Explorer
- Selenium driver for Chrome 
- wxPython (version 2.8.12.1, necessary to run RIDE)
- RIDE

Two versions of the script are provided:
- A PowerShell script for Windows (RF_Install.ps1).
- A Bash script for Ubuntu  (RF_Install.sh).

IMPORTANT! The installer download locations were valid at the time of this scrip conception, but these may change. 
If you find some invalid URL please report an issue at https://github.com/joao-carloto/RF_Install_Script/issues


Author: João Carloto, Twitter: @JMCarloto<br>
Github repo: https://github.com/joao-carloto/RF_Install_Script<br>
License: Apache 2.0


<br>
<strong>USAGE</strong>

<strong>Windows:</strong>

- Download or copy/paste the script into a file. Don't forget the .ps1 extension.
- Right click the file and choose 'Run with PowerShell'.
- If script execution is disabled in you system, follow the instructions at http://www.tech-recipes.com/rx/6679/windows-7-enable-execution-of-windows-powershell-scripts/
- If you want more feedback from the script remove/comment the redirects to Out-Null
- In Windows, the only part of the script that's not fully automatic is the wxPython installation. You'll still have to go thru the wizard.

IMPORTANT! This script uses the 'setx' command to modify the PATH user variable. 
This means it won't work in Windows XP or previous, unless it's installed from the Service Pack 2 Support Tools.

IMPORTANT! If you really want to do selenium tests on IE, beware that there are some necessary browser configurations to be made.
This script doesn't deal with those. For more info check https://code.google.com/p/selenium/wiki/InternetExplorerDriver#Required_Configuration


<strong>Ubuntu:</strong>

- Don't forget to make the script file executable, e.g. 'chmod a+x RF_Install.sh'
- Don't forget to run the script with root privileges, e.g. 'sudo ./RF_Install.sh'
- If you want more feedback from the script remove/comment the redirects to /dev/null
