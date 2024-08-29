#!/bin/bash
#**********************************
#*         status.gen.sh          *
#**********************************
#*       (C) 2024 DL7DET          *
#*        Detlef Lampart          *
#*         MIT License            *
#**********************************

# Clear screen
tput reset

# Versioninformation
pgmvers="v 0.3.0"

# Debugging functions
debug=1
# debug=0: debug off/quiet/no annoying text
# debug=1: informational (default) 
# debug=2: don't be destructive
# debug=3: don't download repo-files

#
# Local definitions
#
chkmount=/opt/mikrotik.upgrade.server/repo
scriptstatus="not running"
scriptnum=0
dwnlstatus="not running"
dwnlnum=0
last_completed=$( cat /tmp/last_completed )

# Local functions
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
    <h4>Disk-total: $dsktot Bytes * Disk-free: $dskfre Bytes * Disk-usage: $dskuse Bytes</h4> 
    <h4>Memory-total: $memtot * Memory-used: $memuse * Memory-free: $memfre * Memory-shared : $memshr * Memory-Buffer/cache: $membuf * Memory-avail.: $memava |-[Bytes]</h4>
    <h4> Script-status: $scriptstatus  ---  Download-status: $dwnlstatus --- Last completed: $last_completed</h4>
  </body>
</html>

EOF
    mv /tmp/status.html /var/www/localhost/htdocs/mikrotikmirror/index-style/
}

# Show startup infos
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
echo "... Starting at "$(datestamp)" ."

dsktot=$(df -h | grep $chkmount | awk '{print $2}')
dskfre=$(df -h | grep $chkmount | awk '{print $4}')
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

echo
if [ $debug -gt 0 ] 
    then
    echo "... Disk total space is   : "$dsktot"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk free space is    : "$dskfre"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk used space is    : "$dskuse"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Total memory is       : "$memtot"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Used memory is        : "$memuse"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Free memory is        : "$memfre"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Shared memory is      : "$memshr"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Buffer/cache memory is: "$membuf"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Available memory is   : "$memava"."
fi

createhtmlfile

#
# This is the end, my lonely friend, the end
#