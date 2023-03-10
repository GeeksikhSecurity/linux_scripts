# Self-Service Linux®: Mastering the Art of Problem Determination
# by Mark Wilding, Dan Behman

#!/bin/bash

#####################################################################
#
#  This script captures basic information for when a problem occurs.
#  It   can be used any time a problem occurs, as root or as a
mortal user.
#
#####################################################################

usage="Usage: vacuum [ -thorough | -perf | -hang <pid> | -trap | - error <cmd> ]"
mode_thorough=0
mode_perf=0
mode_hang=0
mode_trap=0
mode_error=0
topdir=""          # The data collection directory

if [ -n $HOME ]
then
   topdir=$HOME/investigations
else
   topdir=~/investigations/$i
fi

if [ $# -gt 0 ]
then
   while true ; do
      case $1 in
         "-thorough" )
            mode_thorough=1
            shift
         ;;
         "-perf" )
            mode_perf=1
            mode="PERF"
            shift
         ;;
         "-hang" )
            mode_hang=1
            shift
            if [ $# -le 0 ]
            then
               echo $usage
               exit 2
            fi
            pid=$1
         shift
         ;;
         "-trap" )
            mode_trap=1
            shift
            ;;
         "-error" )
            mode_error=1
            shift
            if [ $# -le 0 ]
            then
               echo $usage
               exit 2
            fi
            cmd=$1
            shift
         ;;
         * )
            echo $usage
            exit 2
         ;;
      esac

      if [ $# -le 0 ]
      then
         break ;
      fi
   done
fi

if [ ! -n $USER ]
then
   USER='whoami'
fi

#####################################################################
##  Create the appropriate directory for this problem
#####################################################################

i=0
invdir=$topdir/$i

while [ -d $invdir ]
do
   let "i = i + 1"
   invdir=$topdir/$i
done

echo Investigation directory: $invdir

#####################################################################
##  Create data directory, src directory and the investigation log
#####################################################################

mkdir $invdir
mkdir $invdir/src
datadir=$invdir/data
invlog=$invdir/log
mkdir $datadir
touch $invlog
echo
"###################################################################"
>> $invlog
echo "##                                    Header
##" >> $invlog
echo
"###################################################################"
>> $invlog
echo "Problem number                : $i" >> $invlog
echo -n "Time of data collector run    : " >> $invlog
date >> $invlog
echo "Data collector run as         : \"$0 $1 $2\" " >> $invlog

#####################################################################
##  Ready to go...
#####################################################################

function collectFile
{
   local comment=$1
   local fileName=$2
   local output=""

   echo -n "COLLECT: $fileName ($comment) ... " >> $invlog

   output='cp $fileName $datadir 2>&1'

   if [ $? -ne 0 ]
   then
      echo "failed." >> $invlog
      echo "output from copy:" >> $invlog
      echo '{' >> $invlog
      echo $output >> $invlog
      echo '}' >> $invlog

   else
      echo "success." >> $invlog
   fi

   echo >> $invlog

}

function runCommand
{
   local comment=$1
   local cmd=$2

   echo "RUNCMD: $cmd ($comment) ... " >> $invlog
   echo '{' >> $invlog
   $cmd 2>&1 >> $invlog 2>&1
   echo '}' >> $invlog
   echo >> $invlog

}

function doQuickCollect
{
   echo >> $invlog
   echo
"###################################################################"
>> $invlog
   echo "##                                 Quick Collect
##" >> $invlog
   echo
"###################################################################"
>> $invlog

   #Environmental information
   runCommand "Environment variables"                    "/usr/bin/
env"

   #Network information
   collectFile "DNS resolution configuration file"       "/etc/
resolv.conf"
   collectFile "Name service switch configuration file"  "/etc/
nsswitch.conf"
   collectFile "Static table lookup file"                "/etc/
hosts"
   collectFile "TCP/IP services file"                    "/etc/
services"
   runCommand "Interface information"                    "ifconfig -
a"
   runCommand "Interface information (no DNS)"           "/bin/
netstat -i -n"
   runCommand "Socket information"                       "/bin/
netstat -an"
   runCommand "Extended socket information"              "/bin/
netstat -avn"
   runCommand "Socket owner information"                 "/bin/
netstat -p"
   runCommand "Network routing table"                    "/bin/
netstat -rn"
   runCommand "Network statistics"                       "/bin/
netstat -s"
   runCommand "Extended routing information"             "/bin/
netstat -rvn"
   ## the grep commands below look odd but it is a simple trick to
get the contents of
   ## everything under specific directories
   runCommand "Network information from /proc" "/usr/bin/find /
proc/net -type f -exec /bin/grep -Hv '^$' {} "
   runCommand "System information from /proc" "/usr/bin/find /proc/
sys -type f -exec /bin/grep -Hv '^$' {} "
   runCommand "SYSV IPC info from /proc" '/usr/bin/find /proc/
sysvipc -type f -exec /bin/grep -Hv ^$ {} ;'

   #File system information
   runCommand "Type information"                         "/bin/df -
lT"
   runCommand "Usage information"                        "/bin/df -
lk"
   runCommand "Inode information"                        "/bin/df -
li"
   runCommand "Share information"                        "/usr/sbin/
showmount -e"
   runCommand "SCSI and IDE disk partition tables"       "/sbin/
fdisk -l /dev/sd* /dev/hd*"
   runCommand "NFS statistic"                            "/usr/sbin/
nfsstat -cnrs"
   collectFile "Filesystems supported by the kernel"     "/proc/
filesystems"
   collectFile "Export file"                             "/etc/
exports"
   collectFile "Mount file"                              "/etc/
fstab"
   collectFile "Partition information"                   "/proc/
partitions"

   #Kernel information
   runCommand "User (resource) limits"                   "ulimit -a"
   runCommand "IPC information"                          "/usr/bin/
ipcs -a"
   runCommand "Loaded module info"                       "/sbin/
lsmod"
   runCommand "IPC resource limits"                      "/usr/bin/
ipcs -l"
   runCommand "Kernel information"                       "/sbin/
sysctl -a"
   runCommand "Memory usage"                             "/usr/bin/
free"
   runCommand "Uptime"                                   "/usr/bin/
uptime"
   runCommand "System name, etc"                         "/bin/uname
-a"
   runCommand "Current users"                            "/usr/bin/w"
   runCommand "Process listing"                          "/bin/ps
auwx"
   runCommand "Recent users"                             "/usr/bin/
last|/usr/bin/head -100"
   runCommand "Contents of home directory"               "/bin/ls -
lda $HOME"
   runCommand "Host ID"                                  "/usr/bin/
hostid"
   collectFile "Kernel limits specified by the user"     "/etc/
sysctl.conf"
   collectFile "Load average"                            "/proc/
loadavg"
   collectFile "I/O memory map"                          "/proc/
iomap"
   collectFile "I/O port regions"                        "/proc/
ioports"
   collectFile "Interrupts per each IRQ"                 "/proc/
interupts"
   collectFile "CPU status"                              "/proc/
cpuinfo"
   collectFile "Memory usage"                            "/proc/
meminfo"
   collectFile "Swap partition information"              "/proc/swaps"
   collectFile "Slab information"                    "/proc/slabinfo"
   collectFile "Lock information"                        "/proc/locks"
   collectFile "Module information"                    "/proc/modules"
   collectFile "Version information"                   "/proc/version"
   collectFile "System status information"               "/proc/stat"
   collectFile "PCI information"                         "/proc/pci"

   #Version information
   runCommand "Package information"                     "/bin/rpm -qa"

   #Misc
   collectFile "Main syslog file"                  "/var/log/messages"
     collectFile "Syslog configuration file"                    "/etc/
syslog.conf"


}

function doThoroughCollect
{
   echo >> $invlog
                                                                 echo
"###################################################################"
>> $invlog
   echo "##                                          Thorough Collect
##" >> $invlog
                                                                 echo
"###################################################################"
>> $invlog

   runCommand "Virtual memory statistics"                  "/usr/bin/
vmstat 2 5"
   runCommand "I/O statistics"                             "/usr/bin/
iostat 2 5"
   runCommand "Extended I/O statistics"                    "/usr/bin/
iostat -x 2 5"
   runCommand "CPU statistics"                             "/usr/bin/
mpstat -P ALL 2 5"
   runCommand "System activity"                            "/usr/bin/
sar -A 2 5"

}

function doPerfCollect
{
   echo >> $invlog
                                                                 echo
"###################################################################"

>> $invlog
   echo "##                                       Performance Collect
##" >> $invlog
                                                                 echo
"###################################################################"
>> $invlog

   # Add specific commands here

}

function doHangCollect
{
   echo >> $invlog
                                                                 echo
"###################################################################"
>> $invlog
   echo "##                                              Hang Collect
##" >> $invlog
                                                                 echo
"###################################################################"
>> $invlog
   # NOTE: $pid contains the process ID of the process that is hanging

   ## check whether the process actually exists
   kill -0 $pid 2>/dev/null 1>/dev/null
   if [ ! $? -eq 0 ]
   then
      echo "Process ID \"$pid\" not found."
      exit 3
   fi

   # Add specific commands here

}

   function doErrorCollect
   {
      echo >> $invlog
                                                                 echo
"###################################################################"
>> $invlog
    echo "##                                            Error Collect
##" >> $invlog
                                                                 echo
"###################################################################"
>> $invlog

   # NOTE: $cmd contains the name of the command line that apparently
produces an error

   # Add specific commands here
}

function doTrapCollect
{
   echo >> $invlog
                                                                 echo
"###################################################################"
>> $invlog
   echo "##                                              Trap Collect
##" >> $invlog
                                                                 echo
"###################################################################"
>> $invlog

   # Add specific commands here
}

#############################################  MAIN    SCRIPT    BODY
##########################################

## Do the basics first, then anything else that might be needed
##
doQuickCollect

if [ $mode_thorough -eq 1 ]
then
   echo "Collecting thorough information"
   doThoroughCollect
fi

if [ $mode_perf -eq 1 ]
then
   echo "Collecting perf information"
   doPerfCollect
fi

if [ $mode_hang -eq 1 ]
then
   echo "Collecting hang information"
   doHangCollect
fi

if [ $mode_trap -eq 1 ]
then
   echo "Collecting trap information"
   doTrapCollect
fi

if [ $mode_error -eq 1 ]
then
   echo "Collecting error information"
   doErrorCollect
fi

echo >> $invlog
e                    c                    h                         o
"###################################################################"
>> $invlog
echo "##            End of Data Collection (the rest is for user
investigation)       ##" >> $invlog
e                    c                    h                         o
"###################################################################"
>> $invlog
