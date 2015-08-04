#!/bin/bash

####################################################################################################

# .SYNOPSIS

# This shell script will download and install the Robot Framework, all it's required dependencies 
# (if not already available) and some extra libraries and tools.
# In the end of the process, the following resources should be installed:
# - Python 2.7.x
# - PIP (used to install RF, Selenium2library and RIDE)
# - Robot Framework
# - Selenium2library
# - Selenium driver for Chrome 
# - wxPython (version 2.8.12.1, necessary to run RIDE)
# - RIDE

# Script: RF_Installer.ps1
# Author: João Carloto, Twitter: @JMCarloto
# Github repo: https://github.com/joao-carloto/RF_Install_Script
# License: Apache 2.0
# Version: 0.1
# Dependencies: Internet connectivity


# .USAGE

# Don't forget to make this file executable e.g. 'chmod a+x RF_Install.sh'
# Don't forget to run this with root privileges e.g. 'sudo ./RF_Install.sh'
# If you want more feedback from the script remove/comment the redirects to /dev/null


# .DISCLAIMER: This was tested on Ubuntu 14.04.1 32 Bits, with Python 2.7.6 and 3.4.0 already 
# installed by default, where calling 'python' means calling python 2.7 and calling 'python3' means 
# calling python 3.4. Running this script on different setups may cause unwanted results,
# unless you know what you are doing.

####################################################################################################

#This folder should already be on $PATH
selDriverFolder="/usr/local/bin"

bitMode=$(uname -m)
if [ "$bitMode" == "i686" ]; then
	selChromeDriver="chromedriver_linux32.zip"
elif [ "$bitMode" == "x86_64" ]; then
	selChromeDriver="chromedriver_linux64.zip"
else
	echo "Warning! Unable to get the Kernel bit mode"
	echo "Exiting the script"
	exit
fi

#Update these if necessary
selChromeDriverURL="http://chromedriver.storage.googleapis.com/2.9/$selChromeDriver"
pythonVersionToInstall="2.7.8"
pythonURL="http://python.org/ftp/python/$pythonVersionToInstall/Python-$pythonVersionToInstall.tgz"


#Not used because it takes too much time to do "pip list --outdated" in Ubuntu (compared to Windows)
#Uncomment the corresponding lines if you want to use it
function checkUpdates()
{   
	outdatedList=$(pip list -o | grep *"$1 (Current:"*"Latest:"*)
	if [[ "$outdatedList" == *"$1 (Current:"*"Latest:"* ]]; then
		echo "$outdatedList"
		while true; do
			read -p "Upgrade now?" yn
		    	case $yn in
				[Yy]* ) pip install --upgrade $1; \
				echo "Finished upgrading the $1 package"; break;;
				[Nn]* ) break;;
				* ) echo "Please answer yes or no.";;
		    	esac
		done
	else
        	echo "Package $package is up to date"
    	fi
}


#THE REAL WORK STARTS HERE

#Install Python
pythonVersion=$(python -V 2>&1)
#Unlikely to happen. In Ubuntu 14.04 python 2.7.6 is already installed
if [[ "$pythonVersion" == *"command not found"* ]]; then
	echo "Unable to check the local Python version"
	echo "We will download and install Python $pythonVersionToInstall"	
	apt-get install build-essential
	apt-get install libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev \
	libgdbm-dev libc6-dev libbz2-dev
	cd ~/Downloads/
	wget $pythonURL
	tar -xvf Python-$pythonVersionToInstall.tgz
	cd Python-$pythonVersionToInstall
	./configure
	make
	make install
else
	#Unlikely to happen. In Ubuntu 14.04 python 3.4 is already installed and must be called as python3
	if [[ "$pythonVersion" != "Python 2.7"* ]]; then
		printf "The active Python version ($pythonVersion) is incompatible with the Robot Framework and/or other tools we are installing. 
Please uninstall it or rename the python executable to something else (e.g. python3) and rerun this script\n"
		exit
	else
		echo  "A Python version compatible with the Robot Framework is already installed: $pythonVersion"
	fi
fi


#Install PIP
pipVersion=$(pip -V 2>&1)
if [[ "$pipVersion" == *"command not found"* ]] || \
[[ "$pipVersion" = *"currently not installed"* ]]; then
	echo "PIP doesn't seem to be installed"
	echo "Installing PIP and dependencies..."
	apt-get install --yes python-pip \
	python-dev build-essential > /dev/null
else
	echo "PIP is installed with version $pipVersion"
	#echo "Checking if the PIP is up to date..."
	#checkUpdates python-pip	
fi


#Install Robot Framework
rfVersion=$(pybot --version 2>&1)
if [[ "$rfVersion" == *"command not found"* ]]; then
	echo "The Robot Framework doesn't seem to be installed"
	echo "Installing the Robot Framework..."
	pip install robotframework > /dev/null
else
	echo "Robot Framework is installed with version $rfVersion"
	#echo "Checking if the Robot Framework is up to date..."
	#checkUpdates robotframework	
fi


#Install the Selenium2Library
if [ -d "/usr/local/lib/python2.7/dist-packages/Selenium2Library" ]; then
	echo  "The Selenium2library seems to be installed"
 	#echo "Checking if the Selenium2library is up to date..."
	#checkUpdates robotframework-selenium2library	
else
	echo "The Selenium2library doesn't seem to be installed"
    	echo "Installing the Selenium2library..."
        pip install robotframework-selenium2library  > /dev/null
fi


#Download and unzip the Selenium Chrome driver
chromeDriverHelp=$(chromedriver --help 2>&1)
if [[ "$chromeDriverHelp" == *"command not found"* ]]; then
    	echo "The Selenium Chrome driver doesn't seem to be installed"
    	echo "Downloading Selenium Chrome driver ZIP..."
	wget -O "/tmp/$selChromeDriver"  "$selChromeDriverURL"  &> /dev/null
	echo "Unziping the chromedriver to $selDriverFolder"
	unzip "/tmp/$selChromeDriver" -d "$selDriverFolder"  > /dev/null
	chmod a+x "$selDriverFolder/chromedriver"
	if [[ ":$PATH:" != *":$selDriverFolder:"* ]]; then
		PATH=$PATH:$selDriverFolder
		echo  "export PATH=\$PATH:$selDriverFolder" >> ~/.bashrc
		source  ~/.bashrc
	fi 
else
	echo "The Selenium Chrome driver seems to be installed"
fi


#Choose a browser to run a sample test
#In Ubuntu Firefox, Selenium takes a long time to fill out a text field, so we will prefer Chrome
firefoxIsInstalled=$(dpkg -s firefox 2>&1)
chromeIsInstalled=$(dpkg -s google-chrome-stable 2>&1)
if  [[ "$chromeIsInstalled" == *"install ok installed"* ]]; then
	demoBrowser="Chrome"
elif [[ "$firefoxIsInstalled" == *"install ok installed"* ]]; then
	demoBrowser="Firefox"
fi


#Create a sample test if we have Firefox or Chrome available
if ! [ -z "$demoBrowser" ]; then
echo "*Settings*
Documentation	     Test suite created with FireRobot
Library	   Selenium2Library   15.0   5.0
*Test Cases *
EA Installer Demo Test
	Open Browser  	http://joao-carloto.github.io/RF_Install_Script/test.html   	$demoBrowser
	Page Should Contain   	RF Install Script Test Page
	Input Text   	sometextbox   	Congratulations!
	Input Text   	sometextarea    If you are reading this, you have completed your Robot Framework setup.\n\nTo run this test again on RIDE, click on the 'Run Tests' button.\n\nTo learn more about the immense possibilities of the Robot Framework go to http://robotframework.org/." > /tmp/test.txt
fi


#Install wxPython
wxPythonPackage=$(dpkg -s python-wxgtk2.8 2>&1)
if [[ "$wxPythonPackage" == *"is not installed"* ]]; then
	echo "wPython 2.8 doesn't seem to be installed"
	echo "Installing wxPython..."	
	apt-get install --yes python-wxgtk2.8 > /dev/null
else
	echo "wPython 2.8 seems to be installed"
fi


#Install RIDE
rideHelp=$(ride.py --help 2>&1)
if [[ "$rideHelp" == *"command not found"* ]]; then
	echo "RIDE doesn't seem to be installed"
    	echo "Installing RIDE..."
        pip install robotframework-ride > /dev/null
	chmod a+w /home/ubuntu/.robotframework/ride/settings.cfg
fi


#Open RIDE and run a sample test (if Firefox or Chrome is available)
echo "Trying to open RIDE..."
if ! [ -z "$demoBrowser" ]; then
	ride.py  /tmp/test.txt &> /dev/null  &
	echo "Running a sample test..."
	pybot -d /tmp  /tmp/test.txt  
else
	ride.py  &> /dev/null  &
fi
