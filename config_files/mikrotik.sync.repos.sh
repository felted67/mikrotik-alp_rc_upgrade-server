#!/bin/bash
#**********************************
#***   Mikrotik.sync.repos.sh   ***
#**********************************
#*       (C) 2024 DL7DET          *
#*        Detlef Lampart          *
#*         MIT License            *
#**********************************

# Clear screen
tput reset

# Versioninformation
pgmvers="v 1.4.0"

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
winboxurl=https://mt.lv
tempdir=$startdir/temp
repodir=$pgmprefix/repo
winboxdir=$pgmprefix/repo/winbox
ltversion=NEWESTa7.long-term
stableversion=NEWESTa7.stable
betaversion=NEWESTa7.testing
devversion=NEWESTa7.development

# Show startup infos
echo "**********************************"
echo "***   Mikrotik.sync.repos.sh   ***"
echo "***      "$pgmvers "               ***"
echo "**********************************"
echo "*        (C) 2024 DL7DET         *"
echo "*         Detlef Lampart         *"
echo "**********************************"
echo "*          MIT License           *"
echo "**********************************"
echo
echo ".........initializing."
echo
sleep 10
echo "... Starting at $(date -u)."
echo

# Useful logging
logdir=$startdir/mikrotik.sync.log
logfile=$logdir/mikrotik.sync.repos.log
if [ ! -d $logdir ]; then
    mkdir $logdir
    echo "... LOGDIR created."
fi
exec > >(tee -a ${logfile} )
exec 2> >(tee -a ${logfile} >&2)
echo " Starting at $(date -u)." >> $logfile 2>&1

# Check and create needed directories
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
if [ ! -d $winboxdir ]; then
    mkdir $winboxdir
    echo "... WINBOXDIR created."
fi
echo

# Download WINBOX®-packages
if [ $debug -gt 0 ]
then
    echo "... Loading WINBOX®packages: winbox64.exe/winbox.exe"
fi		
if [ $debug -lt 3 ]
then
    wget -N $winboxurl/winbox -q -O $tempdir/winbox.exe 
    wget -N $winboxurl/winbox64 -q -O $tempdir/winbox64.exe	
fi

# Copy or move from temp-directory to created WINBOX®-dir
if [ $debug -gt 1 ]
then
    cp -f $tempdir/* $winboxdir/
    echo "... Downloaded WINBOX®-packages copied to Winbox-directory."
else
    mv -f $tempdir/* $winboxdir/
    echo "... Downloaded WINBOX®-packages moved to Winbox-directory."
fi
# Empty TEMP-directory from previous run
if [ $debug -lt 3 ] 
    then
    rm -rf $tempdir/*
fi
echo

# Get latest versions LATESTa7.XXX from download.mikrotik.com
wget -N $baseurl/routeros/$ltversion -q -P $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Downloaded LATEST-file long-term version."
fi
wget -N $baseurl/routeros/$stableversion -q -P $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Downloaded LATEST-file stable version."
fi
wget -N $baseurl/routeros/$betaversion -q -P $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Downloaded LATEST-file beta version."
fi
wget -N $baseurl/routeros/$devversion -q -P $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Downloaded LATEST-file development version."
fi

# Empty TEMP-directory from previous run
if [ $debug -lt 3 ] 
    then
    rm -rf $tempdir/*
fi

# Give some nice informations on the screen
echo
echo "... Starting Sync-Loop ..."
echo "... Downloading repo-packages."
echo "... Please be patient - could take some time."

#
# Start loop for read parameters
# Read each *.config-file 
# 

# Reset index variables
    i=0
    j=0
for filename in $configdir/*.conf; do
    while IFS= read -r varname; do
	var[$i]=$varname
	i=$(expr $i + 1)    
        done < "$filename"    
    rptext="${var[0]}"
    rptype="${var[1]}"
    rpvers="${var[2]}"

    if [ $debug -gt 0 ]
    then
	echo
	echo "... Downloading REPO-type: "$rptype
	echo "... with the release-version of the packages: "$rpvers
	echo
    fi
    
    for (( j=3; j<i; j++ )); do
	package=$(echo "${var[j]}" | sed "s/VERSION/$rpvers/g")
	if [ $debug -gt 0 ]
	then
	    echo "... Loading package: "$baseurl/$rptype/$rpvers/$package
	fi		
	if [ $debug -lt 3 ]
	then
	    wget -N $baseurl/$rptype/$rpvers/$package -q -P $tempdir	
	fi
    done

    if [ $debug -gt 0 ]
    then
        sleep 10
    fi
    
# reset index variables
    i=0
    j=0
    
# Check and create repo-dir    
    if [ ! -d $pgmprefix/repo/$rptype/$rpvers ]; then
	mkdir $pgmprefix/repo/$rptype/$rpvers
	if [ $debug -gt 0 ] 
	then
	    echo "... Repo-directory for version: "$rpvers" created."
	fi
    fi

# Copy or move  from temp-directory to created repo-dir
    if [ $debug -gt 1 ]
    then
	cp -f $tempdir/* $pgmprefix/repo/$rptype/$rpvers/
        echo "... Downloaded packages copied to Repo-directory."
    else
	mv -f $tempdir/* $pgmprefix/repo/$rptype/$rpvers/
        echo "... Downloaded packages moved to Repo-directory."
    fi

# Extract all_packages* in repo-directory for update-server to recognize singles packages
    cd $pgmprefix/repo/$rptype/$rpvers
    unzip -o 'all_packages-*.zip' -d $pgmprefix/repo/$rptype/$rpvers/
    if [ $debug -gt 0 ] 
    then
	echo "... Downloaded all-packages-*.zip extracted for update function."
    fi

# Add informational entry to CHANGELOG
    cd $pgmprefix/repo/$rptype/$rpvers
    version=$( cat /root/version.info )
    echo -e "\n " >> $pgmprefix/repo/$rptype/$rpvers/CHANGELOG
    echo "+++ Provided by mikrotik-upgrade-server v"$version" +++" >> $pgmprefix/repo/$rptype/$rpvers/CHANGELOG
    if [ $debug -gt 0 ] 
    then
	echo "... Added informational entry to CHANGELOG."
    fi

# Clear temp-directory for next download run
    if [ $debug -lt 3 ] 
    then
	rm -rf $tempdir/*
	if [ $debug -gt 0 ] 
	then
	    echo "... Temp-directory has been emptied."
	fi
    fi

# End of sync loop
done

# Some end of job informations
if [ $debug -gt 0 ] 
    then
    echo " All packages have been downloaded and all-packages-* have been extracted."
    echo " Please link the repo-directory to your webserver and configure the webserver"
    echo " to serve the repo-directory as root-dir. Then you can add 'upgrade.mikrotik.com'"
    echo " to your Mikrotik©-device as a DNS-static entry with its local IP to update your" 
    echo " devices with the downloaded packages."
    echo
fi

echo
echo " Script(s) ended successfully..."
echo " Completed  at $(date -u)." 
echo
echo " C:\ ... bye-bye"

# Optional compression of logfile for space-saving
#gzip -f $logfile
#mv $logfile.gz $logfile-$(date +%Y%m%d).gz

echo "Completed  at $(date -u)." >> $logfile 2>&1

#
# This is the end, my lonely friend
#