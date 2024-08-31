#!/bin/bash
#**********************************
#*         status.gen.sh          *
#**********************************
#*       (C) 2024 DL7DET          *
#*        Detlef Lampart          *
#*         MIT License            *
#**********************************

# Versioninformation
pgmvers="v 0.5.2"

# Debugging functions
if [[ -z "$1" || "$1" != "0" ]]
then
    debug=1
else
    debug=0
fi
# debug=0: debug off/quiet/no annoying text
# debug=1: informational (default)

# Clear screen
if [ $debug -gt 0 ]
then
    tput reset
fi

#
# Local definitions
#
chkmount=/opt/mikrotik.upgrade.server/repo
scriptstatus="not running"
scriptnum=0
dwnlstatus="not running"
dwnlnum=0
dsklmt=5

#
# Local functions
#
datestamp() {
    local datestring=$(date +"%H:%M %Z on %A, %d.%B %Y")
    echo $datestring
}

createhtmlfile() {
    touch /tmp/status.html
    cat > /tmp/status.html << EOF
<!DOCTYPE html>
<html>
  <body>
    <h4>MUS-System running on host: <font color="green">$uhost</font> using arch: <font color="green">$uarch</font> - MUS-System status: $last_error</h4>
    <h4>Disk-total: $dsktot Bytes * Disk-free: $dskfrestr Bytes * Disk-usage: $dskuse Bytes</h4> 
    <h4>Memory-total: $memtot * Memory-used: $memuse * Memory-free: $memfre * Memory-shared : $memshr * Memory-buffer/cache: $membuf * Memory-avail.: $memava |-[Bytes]</h4>
    <h4> Script-status: $scriptstatus  ---  Download-status: $dwnlstatus --- Last sync completed: $last_completed</h4>
  </body>
</html>

EOF
    mv /tmp/status.html /var/www/localhost/htdocs/mus/index-style/
}

# Show startup infos
if [ $debug -gt 0 ]
then
echo "**********************************"
echo "*         status.gen.sh          *"
echo "***          "$pgmvers "          ***"
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

# Fetch and generate variables for status
trap '' 2   # Disable use of CTRL-C
uhost=$(uname -n)
uarch=$(uname -m)

dsktot=$(df -h | grep $chkmount | awk '{print $2}')
dskfre=$(df -h | grep $chkmount | awk '{print $4}')
dskcrt=$(echo $dskfre | cut -d'.' -f1)
dskuse=$(df -h | grep $chkmount | awk '{print $3}')

memtot=$(free -h | grep 'Mem' | awk '{ print $2 }')
memuse=$(free -h | grep 'Mem' | awk '{ print $3 }')
memfre=$(free -h | grep 'Mem' | awk '{ print $4 }')
memshr=$(free -h | grep 'Mem' | awk '{ print $5 }')
membuf=$(free -h | grep 'Mem' | awk '{ print $6 }')
memava=$(free -h | grep 'Mem' | awk '{ print $7 }')

scriptnum=$(ps -A | grep -c '{mikrotik.sync.r}')
if [ $scriptnum -gt 1 ]
then 
    scriptstatus='<font color="red">Script(s) is/are running</font>'
else 
    scriptstatus='<font color="green">Script(s) is/are NOT running</font>'
fi

dwnlnum=$(ps -A | grep -c 'wget -N')
if [ $dwnlnum -gt 1 ]
then 
    dwnlstatus='<font color="red">Download is running</font>'
else 
    dwnlstatus='<font color="green">Download is NOT running</font>'
fi

if [[ $dskcrt -lt $dsklmt ]]
then
    dskfrestr='<font color="red">'$dskfre'</font>' 
else
    dskfrestr='<font color="black">'$dskfre'</font>'
fi

if [[ -e /tmp/last_completed ]]
then
    last_completed=$( cat /tmp/last_completed )
else
    last_completed="*** Never completed ***"
fi

if [[ -e /tmp/last_error ]]
then
    error=$( cat /tmp/last_error)
    if [[ $error != "OK" ]]
    then
	    last_error='<font color="red">'$error'</font>'
    else
	    last_error='<font color="green">'$error'</font>'
    fi
else
    last_error='<font color="green">OK</font>'
fi

# Create HTML-status-inlay for webserver
createhtmlfile
trap 2  # Enable CTRL-C again

# Display status-variable on console
echo
if [ $debug -gt 0 ] 
    then
    echo "... Hostname is           : "$uhost
fi

if [ $debug -gt 0 ] 
    then
    echo "... System architecure is : "$uarch
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk total space is   : "$dsktot"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk free space is    : "$dskfre"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk used space is    : "$dskuse"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Total memory is       : "$memtot"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Used memory is        : "$memuse"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Free memory is        : "$memfre"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Shared memory is      : "$memshr"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Buffer/cache memory is: "$membuf"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Available memory is   : "$memava"Bytes"
fi

if [ $debug -gt 0 ] 
    then
    echo "... Last sync completed   : "$last_completed"."
fi

if [ $debug -gt 0 ] 
    then
    echo
fi

#
# This is the end, my lonely friend, the end
#