#!/bin/bash
#**********************************
#*           mus-sync             *
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
winboxurl=https://mt.lv
tempdir=$startdir/temp
repodir=$pgmprefix/repo
winboxdir=$repodir/routeros/winbox
nonvconfig=$configdir/routeros.0.00.conf
winbox3version=LATEST.3
winbox4version=LATEST.4
logdir=$startdir/mus.log
logfile=$logdir/mus-sync.log
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
    echo "*        mus-sync.sh             *"
    echo "***      "$pgmvers "              ***"
    echo "**********************************"
    echo "*        (C) 2024 DL7DET         *"
    echo "*         Detlef Lampart         *"
    echo "**********************************"
    echo "*          MIT License           *"
    echo "**********************************"
    echo
    echo "... initializing."
    echo
    sleep 10
    echo "... Starting at "$(datestamp)"."
    echo
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
if [[ -e $syncpid || -e $startpid ]]
then 
    echo "... Another instance of MUS is running. EXITING with error-code 1."
    echo "... Only one instance at the same time is supported !"
    echo "... Perhaps you have to remove the pid-file in /var/run !"
    exit 1
else
    createpid $syncpid
fi

# Check and create needed directories
trap '' 2   # Disable use of CTRL-C 
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
if [ ! -d $winboxdir ]; then
    mkdir $winboxdir
    if [ $debug -gt 0 ] 
    then
        echo "... WINBOXDIR created."
    fi
fi
if [ $debug -gt 0 ] 
then
    echo
fi
trap 2  # Enable CTRL-C again

# Empty TEMP-directory from previous run
emptytemp

# Check if internet-connection is possible, if not exit
checkinternetconnection

# Download WINBOX®-packages
if [ $debug -gt 0 ]
then
    echo "... Loading WINBOX®packages: winbox64.exe/winbox.exe"
fi		
if [ $debug -lt 3 ]
then
    createpid $dwnlpid
    wget -N $winboxurl/winbox -q -O $tempdir/winbox.exe 
    wget -N $winboxurl/winbox64 -q -O $tempdir/winbox64.exe	
    removepid $dwnlpid
fi

# Copy or move from temp-directory to created WINBOX®-dir
if [ $debug -gt 1 ]
then
    cp -f $tempdir/* $winboxdir/
    if [ $debug -gt 0 ] 
    then
        echo "... Downloaded WINBOX®-packages copied to Winbox-directory."
    fi
else
    mv -f $tempdir/* $winboxdir/
    if [ $debug -gt 0 ] 
    then
        echo "... Downloaded WINBOX®-packages moved to Winbox-directory."
    fi
fi

# Rename WINBOX®-files to reflect version
if [ $debug -lt 3 ]
then
    wbversion=$( cat $winboxdir/$winboxversion )
    cp -f $winboxdir/winbox.exe $winboxdir/winbox_$wbversion.exe
    cp -f $winboxdir/winbox64.exe $winboxdir/winbox64_$wbversion.exe
    if [ $debug -gt 0 ] 
    then
        echo "... WINBOX®-files renamed to reflect current version."
    fi
fi

# Empty TEMP-directory from previous run
if [ $debug -lt 3 ] 
    then
    emptytemp
fi
if [ $debug -gt 0 ] 
then
    echo
fi

# Check if *.conf-file is DOS-mode file and convert to unix-mode
trap '' 2   # Disable use of CTRL-C 
isInFile=0
for filename in $configdir/*.conf; do
    isInFile=$(cat $filename | grep -c "\r")    
    if [ $isInFile -gt 0 ]
    then 
        dos2unix $filename
        if [ $debug -gt 0 ] 
        then
            echo "... Changed dos-style-config-file $filename to unix-style."
        fi
    fi
done
trap 2  # Enable CTRL-C again

# Give some nice informations on the screen
if [ $debug -gt 0 ] 
then
    echo
    echo "... Starting Sync-Loop ..."
    echo "... Downloading repo-packages."
    echo "... Please be patient - could take some time."
fi

#
# Start loop for read parameters
# Read each *.config-file 
# 

# Reset index variables
i=0
j=0
isInFile=0

# Start loop
trap '' 2   # Disable use of CTRL-C 
for filename in $configdir/*.conf; do
    if [[ $filename !=  $nonvconfig ]]
    then
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
                createpid $dwnlpid
	            wget -N $baseurl/$rptype/$rpvers/$package -q -P $tempdir	
                removepid $dwnlpid
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
            if [ $debug -gt 0 ] 
            then    
                echo "... Downloaded packages moved to Repo-directory."
            fi
        fi

        # Extract all_packages* in repo-directory for update-server to recognize singles packages
        cd $pgmprefix/repo/$rptype/$rpvers
        unzip -o 'all_packages-*.zip' -d $pgmprefix/repo/$rptype/$rpvers/
        unzip_status=$?
        if [ $unzip_status -gt 0 ]
        then
            if [ $debug -gt 0 ] 
            then
	            echo "... Unzip error encountered during extraction. Error code:"$unzip_status
                echo "... Script stopped - please check files manually !!!"
            else
                echo "... Unzip error during unzip. Error code:"$unzip_status
            fi

            if [[ -e /tmp/last_error ]]
            then
                echo "UNZIP ERROR:"$unzip_status > /tmp/last_error
            else 
                rm -f /tmp/last_error
                echo "UNZIP ERROR:"$unzip_status > /tmp/last_error
            fi
            exit 8
        fi

        if [ $debug -gt 0 ] 
        then
	        echo "... Downloaded all-packages-*.zip extracted for update function."
        fi

        # Add informational entry to CHANGELOG
        cd $pgmprefix/repo/$rptype/$rpvers
        version=$( cat /root/version.info )
        isInFile=$(cat $pgmprefix/repo/$rptype/$rpvers/CHANGELOG | grep -c "+++ Provided by mikrotik.upgrade.server")
        if [ $isInFile -eq 0 ]
        then
            echo -e "\n " >> $pgmprefix/repo/$rptype/$rpvers/CHANGELOG
            echo "+++ Provided by mikrotik.upgrade.server v"$version" +++" >> $pgmprefix/repo/$rptype/$rpvers/CHANGELOG
            if [ $debug -gt 0 ] 
            then
	            echo "... Added informational entry to CHANGELOG."
            fi
        else 
            sed -i '/^+++ Provided by mikrotik.upgrade.server/d' $pgmprefix/repo/$rptype/$rpvers/CHANGELOG
            echo "+++ Provided by mikrotik.upgrade.server v"$version" +++" >> $pgmprefix/repo/$rptype/$rpvers/CHANGELOG
            if [ $debug -gt 0 ] 
            then
	            echo "... Changed informational entry to CHANGELOG."
            fi
        fi

        # Clear temp-directory for next download run
        if [ $debug -lt 3 ] 
        then
	        emptytemp
	        if [ $debug -gt 0 ] 
	        then
	        echo "... Temp-directory has been emptied."
	        fi
        fi
    else
        cd $pgmprefix/repo/routeros/0.0
        version=$( cat /root/version.info )
        isInFile=$(cat $pgmprefix/repo/routeros/0.0/CHANGELOG | grep -c "+++ Provided by mikrotik.upgrade.server")
        if [ $isInFile -eq 0 ]
        then
            echo -e "\n " >> $pgmprefix/repo/routeros/0.0/CHANGELOG
            echo "+++ Provided by mikrotik.upgrade.server v"$version" +++" >> $pgmprefix/repo/routeros/0.0/CHANGELOG
            if [ $debug -gt 0 ] 
            then
	            echo "... Added informational entry to CHANGELOG for non-existent version 0.0."
            fi
        else 
            sed -i '/^+++ Provided by mikrotik.upgrade.server/d' $pgmprefix/repo/routeros/0.0/CHANGELOG
            echo "+++ Provided by mikrotik.upgrade.server v"$version" +++" >> $pgmprefix/repo/routeros/0.0/CHANGELOG
            if [ $debug -gt 0 ] 
            then
	            echo "... Changed informational entry to CHANGELOG for non-existent version 0.0."
            fi
        fi
    fi
# End of sync loop
done
trap 2  # Enable CTRL-C again

# Some end of job information
if [ $debug -gt 0 ] 
then
    echo " All packages have been downloaded and all-packages-* have been extracted."
    echo " Please link the repo-directory to your webserver and configure the webserver"
    echo " to serve the repo-directory as root-dir. Then you can add 'upgrade.mikrotik.com'"
    echo " to your Mikrotik©-device as a DNS-static entry with its local IP to update your" 
    echo " devices with the downloaded packages."
    echo
fi

if [ $debug -gt 0 ] 
then
    echo
    echo " Script(s) ended successfully..."
    echo " Completed  at "$(datestamp)"." 
    echo
    echo " C:\ ... bye-bye"
fi
# Optional compression of logfile for space-saving
#gzip -f $logfile
#mv $logfile.gz $logfile-$(date +%Y%m%d).gz

echo "Completed  at "$(date -u)"-" >> $logfile 2>&1

if [ -e /tmp/last_completed ]
then
    rm -f /tmp/last_completed
    touch /tmp/last_completed
    echo $(datestamp) > /tmp/last_completed
else
    touch /tmp/last_completed
    echo $(datestamp) > /tmp/last_completed
fi
 
removepid $syncpid

#
# This is the end, my lonely friend,the end
#