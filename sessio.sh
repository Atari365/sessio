#!/usr/bin/env bash
#
# Name:        sessio.sh
# Description: Simple script that creates a log file of all terminal typescript
# OS:          Ubuntu, CentOS
# Autor:       <Dmitry Vlasov> dmitry.vlasov@fastmail.com
# Version:     1.0

#==============================================================================

# Settings
rotate_factor=4 # times
size=5 # KB
time_between_checks=5 # sec

# Logrotate will save divide everything into files larger than 5KB ($size). 
# In doing so, it will save 4 ($rotate_factor)such files. 
# There will be 5 ($time_between_checks) seconds between each check.
# You need to understand that the final size of the files depends not only
# on $size, but also on $time_between_checks.
#
# When you want to finish recording, just type "exit" at the console.
# Then you will see that you will only# have a backup folder 
# with 4 ($rotate_factor) files in it.

#==============================================================================

if [[ ! `which logrotate` ]]; then echo Please install logrotate; exit 1; fi
if [[ ! `which script` ]]; then echo Please install script; exit 1; fi

sessio=~/sessio
if [ ! -d $sessio  ]; then mkdir $sessio; fi
if [[ ! -w $sessio ]]; then 
  echo Can\'t write to $sessio
  exit 1
fi

workdir=$sessio/workdir
backup=$sessio/backup

logname=`basename $(tty)`
if [[ "$logname" =~ .*"tty".* ]]; then
  logname="$workdir/$logname.log"
else
  logname="$workdir/pts$logname.log"
fi 

logrotate_conf=$sessio/logrotate_`basename $logname .log`.conf
logrotate_status=$sessio/logrotate_`basename $logname .log`.status

if [ ! -d $workdir ]; then mkdir $workdir;  fi
if [ ! -d $backup  ]; then mkdir $backup;   fi
if [ ! -f $logname ]; then touch $logname;  fi

if [ ! -f $logrotate_conf ]; then 
  echo "$logname {
  rotate $rotate_factor
  copytruncate
  olddir $backup
}" > $logrotate_conf
fi

(sleep 2; while [[ `ps -aux | grep -e "[s]cript -fa $logname"` ]]; do
  sleep $time_between_checks
  logsize=$(expr `stat -c%s $logname` / 1024)
  if [[ $logsize -gt $size ]]; then
    logrotate -f $logrotate_conf -s $logrotate_status
  fi
done;
logrotate -f $logrotate_conf -s $logrotate_status
rm -rf $logrotate_conf $logrotate_status $workdir) &

script -fa $logname
