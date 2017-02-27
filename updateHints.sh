#!/bin/sh

# Script to update ISC Bind root hints using OpenNIC servers.
#
# 2017 rfmae <rf.mae.git@gmail.com>
#
# This simple bash script will update your bind hint file if the Tier1 servers
# have changed. This should be run as a daily or weekly cron job.

DEST=/chroot/named/var/named
USER=named

dig . NS @75.127.96.89 > $DEST/named.root.raw

grep "status: NOERROR" $DEST/named.root.raw >/dev/null 2>&1

if [ "$?" == "1" ]; then 
  echo "Updating of the named.root file has failed." 
  echo "The following _discarded_ info was retrieved:"
  cat $DEST/named.root.raw
  rm -f $DEST/named.root.raw
else
  grep -v "^;" $DEST/named.root.raw | sort > $DEST/named.root.new
  if [ `md5sum $DEST/named.root.new | awk {'print $1'}` != `md5sum $DEST/named.root | awk {'print $1'}` ]; then
    chown $USER:$USER $DEST/named.root.new
    chmod 444 $DEST/named.root.new
    rm -f $DEST/named.root.old
    mv $DEST/named.root $DEST/named.root.old
    mv $DEST/named.root.new $DEST/named.root
    /etc/rc.d/rc.bind restart
    rm -f $DEST/named.root.raw
  else
    echo "The OpenNIC root servers did not change since the"
    echo "last update. Keeping the old named.root file."
    rm -f $DEST/named.root.new $DEST/named.root.raw
  fi
fi

