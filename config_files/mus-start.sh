#!/bin/bash
#**********************************
#*          mus-start             *
#**********************************
#*       (C) 2024 DL7DET          *
#*        Detlef Lampart          *
#*         MIT License            *
#**********************************

# Versioninformation
pgmvers="v 2.1.0"

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
lt7version=NEWESTa7.long-term
lt6version=NEWEST6.long-term
stable6version=NEWEST6.stable
stable7version=NEWESTa7.stable
beta7version=NEWESTa7.testing
beta6version=NEWEST6.testing
dev7version=NEWESTa7.development
dev6version=NEWEST6.development
winbox3version=LATEST.3
winbox4version=LATEST.4
logdir=$startdir/mus.log
logfile=$logdir/mus-start.log
rundir=/var/run
startpid=$rundir/mus-start.pid
syncpid=$rundir/mus-sync.pid
dwnlpid=$rundir/mus-dwnl.pid
muspid=0

#
# Local functions
#
datestamp() {
    local datestring=$(date +"%H:%M %Z on %A, %d.%B %Y")
    echo $datestring
}

createpid() {
    echo $BASHPID > $1
}

removepid() {
    rm -f $1
}

checkinternetconnection() {
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
        removepid $startpid
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
        removepid $startpid
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
        removepid $startpid
        exit 7
    fi

    if [[ -e /tmp/last_error ]]
    then 
        echo "OK" > /tmp/last_error
    else
        rm -f /tmp/last_error
        echo "OK" > /tmp/last_error    
    fi
}

emptytemp() {
    # Empty TEMP-directory from previous run
    rm -rf $tempdir/*
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
if [[ -e $startpid || -e $syncpid ]]
then 
    echo "... Another instance of MUS is running. EXITING with error-code 1."
    echo "... Only one instance at the same time is supported !"
    echo "... Perhaps you have to remove the pid-files in /var/run/ !"
    exit 1
else
    createpid $startpid   
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

checkinternetconnection

# Give some nice informations on the screen
if [ $debug -gt 0 ] 
    then
        echo "... Checking latest versions."
        echo "... Downloading latest version-files."
    fi

emptytemp

# Get latest versions LATEST6.XXX from download.mikrotik.com
createpid $dwnlpid
wget -N $baseurl/routeros/$lt6version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version6-file for long-term version."
fi
createpid $dwnlpid
wget -N $baseurl/routeros/$stable6version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version6-file for stable version."
fi
createpid $dwnlpid
wget -N $baseurl/routeros/$beta6version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version6-file for beta version."
fi
createpid $dwnlpid
wget -N $baseurl/routeros/$dev6version -q -P $tempdir/
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version6-file for development version."
fi

# Get latest versions LATESTa7.XXX from download.mikrotik.com
createpid $dwnlpid
wget -N $baseurl/routeros/$lt7version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version7-file for long-term version."
fi
createpid $dwnlpid
wget -N $baseurl/routeros/$stable7version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version7-file for stable version."
fi
createpid $dwnlpid
wget -N $baseurl/routeros/$beta7version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version7-file for beta version."
fi
createpid $dwnlpid
wget -N $baseurl/routeros/$dev7version -q -P $tempdir/
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-version7-file for development version."
fi

# Get latest version for WINBOX 'LATEST.3' from download.mikrotik.com
createpid $dwnlpid
wget -N $baseurl/routeros/winbox/$winbox3version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-WINBOX3-version-file."
fi
if [ $debug -gt 0 ] 
then
    echo
fi

# Get latest version for WINBOX 'LATEST.4' from download.mikrotik.com
createpid $dwnlpid
wget -N $baseurl/routeros/winbox/$winbox4version -q -P $tempdir/
removepid $dwnlpid
if [ $debug -gt 0 ] 
    then
        echo "... Downloaded LATEST-WINBOX4-version-file."
fi
if [ $debug -gt 0 ] 
then
    echo
fi

# Reset index variables
i=0

# Generate mikrotik-routeros-6-config-file(s)
trap '' 2   # Disable use of CTRL-C 
for filename in $tempdir/NEWEST6.*; do
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


# Reset index variables
i=0

# Generate mikrotik-routeros-7-config-file(s)
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

# Reset index variables
i=0

# Generate mikrotik-winbox-config-file(s)
trap '' 2   # Disable use of CTRL-C 
for filename in $tempdir/LATEST.*; do
    while IFS= read -r varname; do
    var[$i]=$varname
    i=$(expr $i + 1)    
        done < "$filename"       
    wbcomplete="${var[0]}"
    wbversion=$(sed -n p $filename | cut -d " " -f1)
    if [[ $wbversion == "3."* ]]; then
	    if [[ ! -f $configdir/winbox.$wbversion.conf ]]; then
	        cp $configdir/winbox3.raw $configdir/winbox.$wbversion.conf
	        sed -i "s/WINBOXVERSION/$wbversion/g" $configdir/winbox.$wbversion.conf
    	        if [ $debug -gt 0 ] 
	            then
		            echo "... Generated mikrotik-winbox3-config-file for version: "$wbversion    
	            fi
	    else 
	        if [ $debug -gt 0 ] 
	        then
		        echo "... Mikrotik-winbox3-config-file for version: "$wbversion" already generated."    
	        fi
	    fi    
    fi
    if [[ $wbversion == "4."* ]]; then
	    if [[ ! -f $configdir/winbox.$wbversion.conf ]]; then
	        cp $configdir/winbox4.raw $configdir/winbox.$wbversion.conf
	        sed -i "s/WINBOXVERSION/$wbversion/g" $configdir/winbox.$wbversion.conf
    	        if [ $debug -gt 0 ] 
	            then
		            echo "... Generated mikrotik-winbox4-config-file for version: "$wbversion    
	            fi
	    else 
	        if [ $debug -gt 0 ] 
	        then
		        echo "... Mikrotik-winbox4-config-file for version: "$wbversion" already generated."    
	        fi
	    fi    
    fi    
done
trap 2  # Enable CTRL-C again

# Copy latest versions LATEST6.XXX to repo-dir
cp $tempdir/$lt6version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file long-term version to repo-dir."
fi
cp $tempdir/$stable6version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file stable version to repo-dir."
fi
cp $tempdir/$beta6version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file beta version to repo-dir."
fi
cp $tempdir/$dev6version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file development version to repo-dir."
fi

# Copy latest versions LATESTa7.XXX to repo-dir
cp $tempdir/$lt7version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file long-term version to repo-dir."
fi
cp $tempdir/$stable7version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file stable version to repo-dir."
fi
cp $tempdir/$beta7version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file beta version to repo-dir."
fi
cp $tempdir/$dev7version $repodir/routeros/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-file development version to repo-dir."
fi

# Copy latest winbox-versions LATEST.X to repo-dir
cp $tempdir/$winbox3version $repodir/routeros/winbox/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-WINBOX3-file to repo/winbox-dir."
fi
cp $tempdir/$winbox4version $repodir/routeros/winbox/
if [ $debug -gt 0 ] 
    then
    echo "... Copied LATEST-WINBOX4-file to repo/winbox-dir."
fi

# Empty TEMP-directory from previous run
if [ $debug -lt 3 ] 
    then
    emptytemp
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
    removepid $startpid
    #$startdir/mus-sync.sh 0
else
    removepid $startpid
    #$startdir/mus-sync.sh
fi

#
# This is the end, my lonely friend, the end
#