#!/bin/bash
#**********************************
#* mikrotik.sync.repos.checker.sh *
#**********************************
#*       (C) 2024 DL7DET          *
#*        Detlef Lampart          *
#*         MIT License            *
#**********************************

# Clear screen
tput reset

# Versioninformation
pgmvers="v 1.3.0"

# Debugging functions
debug=1
# debug=0: debug off/quiet/no annoying text
# debug=1: informational (default) 
# debug=2: don't be destructive
# debug=3: don't download repo-files

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
datestamp=$(date +"%H:%M %Z on %A, %d.%B %Y")

# Show startup infos
echo "**********************************"
echo "* Mikrotik.sync.repos.checker.sh *"
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
echo "... Starting at $datestamp."

# Useful logging
logdir=$startdir/mikrotik.sync.log
logfile=$logdir/mikrotik.sync.repos.checker.log
if [ ! -d $logdir ]; then
    mkdir $logdir
    echo "... LOGDIR created."
fi
exec > >(tee -a ${logfile} )
exec 2> >(tee -a ${logfile} >&2)
echo " Starting at $(date -u)." >> $logfile 2>&1

# Check, create and symlink needed directories
if [ ! -d $tempdir ]; then
    mkdir $tempdir
    echo "... TEMPDIR created."
fi
if [ ! -d $repodir ]; then
    mkdir $repodir
    echo "... REPODIR created."
fi
if [ ! -d $repodir/routeros ]; then
    mkdir $repodir/routeros
    echo "... REPODIR/routeros created."
fi
if [ ! -d $repodir/routeros/winbox ]; then
    mkdir $repodir/routeros/winbox
    echo "... REPODIR/routeros/winbox created."
fi
if [ ! -d $repodir/winbox ]; then
    ln -s $repodir/routeros/winbox $repodir/winbox
    echo "... Symlink REPODIR/routeros/winbox to REPODIR/winbox created."
fi
echo

# Empty TEMP-directory from previous run
if [ $debug -lt 3 ] 
    then
    rm -rf $tempdir/*
fi

# Check if internet-connection is possible, if not exit
ping -q -c5 8.8.8.8 > /dev/null
if [ $? -ne 0 ]
    then
        echo "... NO internet-connection available. Please check routes !"
        echo "... Script stopped - please check your configuration !!!"
        exit 7
fi

# Check if dns-resolution is possible, if not exit
ping -q -c5 google.com > /dev/null
if [ $? -gt 0 ]
    then
        echo "... NO name resolution (DNS) available. Please check DNS-configuration !"
        echo "... Script stopped - please check your configuration !!!"
        echo
        exit 7
fi

# Check if Mikrotik®-master-servers are reachable, if not exit

ping -q -c5 download.mikrotik.com > /dev/null
if [ $? -gt 0 ]
    then
        echo "... MIKROTIK®-master-servers a not reachable. Please check status !"
        echo "... Script stopped - please check your configuration !!!"
        exit 7
fi


# Give some nice informations on the screen
echo "... Checking latest versions."
echo "... Downloading latest version-files."

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
echo

# Reset index variables
    i=0

# Generate mikrotik-config-file(s) 
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

echo
echo "... All mikrotik-config-file(s) generated."
echo "... All LATEST-file(s) copied to repo-dir."
echo "... Ready to start 'mikrotik.sync.repos.sh."
sleep 5
echo 
echo "... Starting 'mikrotik.sync.repos.sh'."

# Start mikrotik.sync.repos.sh to download packages 
$startdir/mikrotik.sync.repos.sh

#
# This is the end, my lonely friend
#