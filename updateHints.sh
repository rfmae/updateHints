#!/bin/sh

# Script to update unbound root hints using OpenNIC servers on pfsense.
#
# 2018 rfmae <rfmae.git@mailbox.org>
#
# This simple bash script will update your root.hints file if the Tier1 servers
# have changed. This should be run as a daily or weekly cron job.

# Redirect stdout/stderr to a file.
exec >> /var/log/updateHints.log 2>&1

DEST=/var/unbound
USER=unbound

DATE=`/bin/date +%Y%m%d-%H:%M:%S`

/usr/local/bin/dig . NS @75.127.96.89 > $DEST/root.hints.raw

/usr/bin/grep "status: NOERROR" $DEST/root.hints.raw >/dev/null 2>&1

if [ "$?" == "1" ]; then 
  echo "$DATE Updating of the root.hints file has failed. The following _discarded_ info was retrieved:" 
  /bin/cat $DEST/root.hints.raw
  /bin/rm -f $DEST/root.hints.raw
else
  /usr/bin/grep -v "^;" $DEST/root.hints.raw | /usr/bin/sort > $DEST/root.hints.new
  if [ `/sbin/md5 $DEST/root.hints.new | /usr/bin/awk '{print $4}'` != `/sbin/md5 $DEST/root.hints | /usr/bin/awk '{print $4}'` ]; then
    echo "$DATE The OpenNIC tier one servers changed. Updating the root.hints file."
    /usr/sbin/chown $USER:$USER $DEST/root.hints.new
    /bin/chmod 444 $DEST/root.hints.new
    /bin/rm -f $DEST/root.hints.old
    /bin/mv $DEST/root.hints $DEST/root.hints.old
    /bin/mv $DEST/root.hints.new $DEST/root.hints
    /usr/local/sbin/pfSsh.php playback svc restart unbound
    /bin/rm -f $DEST/root.hints.raw
  else
    echo "$DATE The OpenNIC root servers did not change since the last update. Keeping the old root.hints file."
    /bin/rm -f $DEST/root.hints.new $DEST/root.hints.raw
  fi
fi
