#!/bin/bash
#**********************************
#*          mus-start             *
#**********************************
#*       (C) 2024 DL7DET          *
#*        Detlef Lampart          *
#*         MIT License            *
#**********************************

# Versioninformation
pgmvers="v 1.5.1"

# Debugging functions
presetdebug=1
# presetdebug=0: debug off/quiet/no annoying text
# presetdebug=1: informational (default) 
# presetdebug=2: don't be destructive
# presetdebug=3: don't download repo-files

# Debugging functions
if [[ -z "$1" || $1 != "0" ]]
then
    debug=$presetdebug
else
    debug=0
fi

# Clear screen
if [ $debug -gt 0 ] 
then
    tput reset
fi

#
# Local Definitions
#
pgmprefix=/opt/mikrotik.upgrade.server
startdir=$pgmprefix/tools
configdir=$startdir/mikrotik.configs
baseurl=https://download.mikrotik.com
tempdir=$startdir/temp
repodir=$pgmprefix/repo
ltversion=NEWESTa7.long-term
stableversion=NEWESTa7.stable
betaversion=NEWESTa7.testing
devversion=NEWESTa7.development
winboxversion=LATEST.3
logdir=$startdir/mus.log
logfile=$logdir/mus-start.log
scriptnum=0

#
# Local functions
#
datestamp() {
    local datestring=$(date +"%H:%M %Z on %A, %d.%B %Y")
    echo $datestring
}

# Show startup infos
if [ $debug -gt 0 ] 
then
    echo "**********************************"
    echo "*        mus-start.sh            *"
    echo "***      "$pgmvers "              ***"
    echo "**********************************"
    echo "*       (C) 2024 DL7DET          *"
    echo "*        Detlef Lampart          *"
    echo "**********************************"
    echo "*         MIT License            *"
    echo "**********************************"
    echo
    echo "... initializing."
    echo
    sleep 10
    echo "... Starting at "$(datestamp)"."
fi

# Useful logging
if [ ! -d $logdir ]; then
    mkdir $logdir
    echo "... LOGDIR created."
fi
exec > >(tee -a ${logfile} )
exec 2> >(tee -a ${logfile} >&2)
echo " Starting at $(date -u)." >> $logfile 2>&1

# Check if another process is running and then exit immediatly
scriptnum=$(ps -A | grep -c '{mus-s')
if [ $scriptnum -gt 1 ]
then 
    echo "... Another instance of MUS is running. EXITING with error-code 1."
    echo "... Only one instance at the same time is supported !"
    exit 1
fi

# Check, create and symlink needed directories
if [ ! -d $tempdir ]; then
    mkdir $tempdir
    if [ $debug -gt 0 ] 
    then
        echo "... TEMPDIR created."
    fi
fi
if [ ! -d $repodir ]; then
    mkdir $repodir
    if [ $debug -gt 0 ] 
    then
        echo "... REPODIR created."
    fi
fi
if [ ! -d $repodir/routeros ]; then
    mkdir $repodir/routeros
    if [ $debug -gt 0 ] 
    then
        echo "... REPODIR/routeros created."
    fi
fi
if [ ! -d $repodir/routeros/0.0 ]; then
    mkdir $repodir/routeros/0.0
    if [ $debug -gt 0 ] 
    then
        echo "... REPODIR/routeros/0.0 created."
    fi
fi
if [ ! -d $repodir/routeros/winbox ]; then
    mkdir $repodir/routeros/winbox
    if [ $debug -gt 0 ] 
    then
        echo "... REPODIR/routeros/winbox created."
    fi
fi
if [ ! -d $repodir/winbox ]; then
    ln -s $repodir/routeros/winbox $repodir/winbox
    if [ $debug -gt 0 ] 
    then
        echo "... Symlink REPODIR/routeros/winbox to REPODIR/winbox created."
    fi
fi
if [ $debug -gt 0 ] 
then
    echo
fi

# Empty TEMP-directory from previous run
rm -rf $tempdir/*

# Check if internet-connection is possible, if not exit
ping -q -c5 8.8.8.8 > /dev/null
if [ $? -ne 0 ]
then
    echo "... NO internet-connection available. Please check routes !"
    echo "... Script stopped - please check your configuration !!!"
    if [[ -e /tmp/last_error ]]
    then
        echo "NO INTERNET CONNECTION-CHECK CONFIG" > /tmp/last_error
    else 
        rm -f /tmp/last_error
        echo "NO INTERNET CONNECTION-CHECK CONFIG" > /tmp/last_error
    fi
    exit 7
fi

# Check if dns-resolution is possible, if not exit
ping -q -c5 google.com > /dev/null
if [ $? -gt 0 ]
then
    echo "... NO name resolution (DNS) available. Please check DNS-configuration !"
    echo "... Script stopped - please check your configuration !!!"
    if [[ -e /tmp/last_error ]]
    then 
        echo "NO DNS RESOLUTION-CHECK CONFIG" > /tmp/last_error
    else
        rm -f /tmp/last_error
        echo "NO DNS RESOLUTION-CHECK CONFIG" > /tmp/last_error    
    fi
    exit 7
fi

# Check if Mikrotik®-master-servers are reachable, if not exit

ping -q -c5 download.mikrotik.com > /dev/null
if [ $? -gt 0 ]
    then
        echo "... MIKROTIK®-master-servers a not reachable. Please check status !"
        echo "... Script stopped - please check your configuration !!!"
        if [[ -e /tmp/last_error ]]
        then 
    	    echo "NO MASTER SERVER REACHABLE" > /tmp/last_error
    	else
    	    rm -f /tmp/last_error
    	    echo "NO MASTER SERVER REACHABLE" > /tmp/last_error    
        fi
        exit 7
fi

if [[ -e /tmp/last_error ]]
then 
    echo "OK" > /tmp/last_error
else
        rm -f /tmp/last_error
        echo "OK" > /tmp/last_error    
fi

# Give some nice informations on the screen
if [ $debug -gt 0 ] 
    then
        echo "... Checking latest versions."
        echo "... Downloading latest version-files."
    fi

# Get latest versions LATESTa7.XXX from download.mikrotik.com
wget -N $baseurl/routeros/$ltversion -q -P $tempdir/
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version-file for long-term version."
fi
wget -N $baseurl/routeros/$stableversion -q -P $tempdir/
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version-file for stable version."
fi
wget -N $baseurl/routeros/$betaversion -q -P $tempdir/
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version-file for beta version."
fi
wget -N $baseurl/routeros/$devversion -q -P $tempdir/
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version-file for development version."
fi

# Get latest version for WINBOX 'LATEST.3' from download.mikrotik.com
wget -N $baseurl/routeros/winbox/$winboxversion -q -P $tempdir/
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-WINBOX-version-file."
fi
if [ $debug -gt 0 ] 
then
    echo
fi

# Reset index variables
i=0

# Generate mikrotik-config-file(s)
trap '' 2   # Disable use of CTRL-C 
for filename in $tempdir/NEWESTa7.*; do
    while IFS= read -r varname; do
    var[$i]=$varname
    i=$(expr $i + 1)    
        done < "$filename"       
    rpcomplete="${var[0]}"
    rpversion=$(sed -n p $filename | cut -d " " -f1)
    if [[ $rpversion != *"0.00"* ]]; then
	    if [[ ! -f $configdir/routeros.$rpversion.conf ]]; then
	        cp $configdir/routeros.raw $configdir/routeros.$rpversion.conf
	        sed -i "s/ROSVERSION/$rpversion/g" $configdir/routeros.$rpversion.conf
    	        if [ $debug -gt 0 ] 
	            then
		            echo "... Generated mikrotik-config-file for version: "$rpversion    
	            fi
	    else 
	        if [ $debug -gt 0 ] 
	        then
		        echo "... Mikrotik-config-file for version: "$rpversion" already generated."    
	        fi
	    fi    
    fi    
done
trap 2  # Enable CTRL-C again

# Copy latest versions LATESTa7.XXX to repo-dir
cp $tempdir/$ltversion $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file long-term version to repo-dir."
fi
cp $tempdir/$stableversion $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file stable version to repo-dir."
fi
cp $tempdir/$betaversion $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file beta version to repo-dir."
fi
cp $tempdir/$devversion $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file development version to repo-dir."
fi
cp $tempdir/$winboxversion $repodir/routeros/winbox/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-WINBOX-file to repo/winbox-dir."
fi

# Empty TEMP-directory from previous run
if [ $debug -lt 3 ] 
    then
    rm -rf $tempdir/*
fi

if [ $debug -gt 0 ] 
then
    echo
    echo "... All mikrotik-config-file(s) generated."
    echo "... All LATEST-file(s) copied to repo-dir."
    echo "... Ready to start 'mus-sync.sh."
    sleep 5
    echo 
    echo "... Starting 'mus-sync.sh'."
fi

# Start mikrotik.sync.repos.sh to download packages 
if [ $debug -eq 0 ]
then
    $startdir/mus-sync.sh 0
else
    $startdir/mus-sync.sh
fi

#
# This is the end, my lonely friend, the end
#