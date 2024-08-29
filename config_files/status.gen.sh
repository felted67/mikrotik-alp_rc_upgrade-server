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
# Local Definitions
#
chkmount=/opt/mikrotik.upgrade.server/repo


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
echo "... Starting at $datestamp."

dsktot=$( df -h | grep $chkmount | awk '{print $1}')
dskfre=$( df -h | grep $chkmount | awk '{print $2}')
dskuse=$( df -h | grep $chkmount | awk '{print $3}')

echo
if [ $debug -gt 0 ] 
    then
    echo "... Disk total space is : "$dsktot"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk free space is : "$dskfre"."
fi

if [ $debug -gt 0 ] 
    then
    echo "... Disk used space is : "$dskuse"."
fi

#
# This is the end, my lonely friend, the end
#