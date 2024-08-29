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
pgmvers="v 0.0.1"

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
    <h4>Memory-total: $memtot Bytes  * Memory-free: $memfre Bytes * Memory-available: $memava Bytes</h4>
  </body>
</html>

EOF
    mv /tmp/status.html /var/www/localhost/htdocs/mikrotikmirror/index-style/
}

# Show startup infos
echo "**********************************"
echo "*         status.gen.sh          *"
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
echo "... Starting at "$(datestamp)" ."

dsktot=$( df -h | grep $chkmount | awk '{print $2}')
dskfre=$( df -h | grep $chkmount | awk '{print $4}')
dskuse=$( df -h | grep $chkmount | awk '{print $3}')

memtot=$(grep -m 1 "MemTotal" /proc/meminfo | awk '{ print $2 }')
memfre=$(grep -m 1 "MemFree" /proc/meminfo | awk '{ print $2 }')
memava=$(grep -m 1 "MemAvailable" /proc/meminfo | awk '{ print $2 }')

echo
if [ $debug -gt 0 ] 
    then
    echo "... Disk total space is : "$dsktot"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk free space is  : "$dskfre"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk used space is  : "$dskuse"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Total memory is     : "$memtot"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Free memory is      : "$memfre"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Available memory is : "$memava"."
fi

createhtmlfile

#
# This is the end, my lonely friend, the end
#