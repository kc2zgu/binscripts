#!/bin/bash

# dochroot.sh: set up and enter chroot environment for a Gentoo install
#
# Copyright 2019 Stephen Cavilia <sac@atomicradi.us>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# load einfo and friends
. /lib/gentoo/functions.sh

# define the shell to run in the chroot
NEWSHELL=/bin/bash

einfo "Gentoo installation chroot helper"

# find the root path (directory this script is in)
SCRIPTPATH=`dirname $0`
#einfo "Script path: $SCRIPTPATH"
cd $SCRIPTPATH
GENROOT=`pwd`
einfo "Gentoo FS root: $GENROOT"

if [ $GENROOT = "/" ]; then
    eerror "This script cannot run from real root"
    exit 2
fi

# check for root user
if [[ "$UID" != "0" ]]; then
    eerror "This script must be run as root"
    exit 2
fi

# list of filesystems to mount - relative paths
# bind these to the host mounts
BINDMOUNTS="dev sys"
# mount new tmpfs on these
TMPMOUNTS="run tmp"

# this will store a list of all filesystems that have been auto-mounted
ALLMOUNTS=

# mount required filesystems

# proc is special (and simple)
ebegin "Mounting procfs"
mount -t proc proc $GENROOT/proc
ALLMOUNTS="$ALLMOUNTS $GENROOT/proc"
eend $?

# recursive bind mounts (may have various submounts)
for MP in $BINDMOUNTS; do
    ebegin "Bind mounting /$MP"
    mount --rbind /$MP $GENROOT/$MP
    ALLMOUNTS="$ALLMOUNTS $GENROOT/$MP"
    eend $?
done

# new tmpfs mounts
for MP in $TMPMOUNTS; do
    ebegin "Mounting tmpfs on /$MP"
    mount -t tmpfs tmpfs $GENROOT/$MP
    ALLMOUNTS="$ALLMOUNTS $GENROOT/$MP"
    eend $?
done

# copy resolv.conf from host so DNS will work
ebegin "Copyng DNS info"
cp /etc/resolv.conf $GENROOT/etc/resolv.conf
eend $?

einfo "Running chroot shell $NEWSHELL in $GENROOT"

# generate a special bashrc (in tmpfs so it goes away)
TMPRC=$GENROOT/tmp/bashrc
echo "source /etc/profile" > $TMPRC
# set a special prompt for the chroot shell
echo "PS1=\"\[\033[01;35m\][chroot:$GENROOT] \[\033[01;31m\]\h\[\033[01;34m\] \w \$\[\033[00m\] \"" >> $TMPRC

# run the chroot shell
chroot $GENROOT $NEWSHELL --rcfile /tmp/bashrc

# clean up after the chroot shell exits
einfo "Chroot exited, unmounting filesystems"
sleep 1

# unmount everything
for MP in $ALLMOUNTS; do
    # find all filesystems under the top mount (rbind will create multiple mounts)
    SUBMOUNTS=`grep $MP/ /proc/mounts | cut -d' ' -f2`
    # reverse the list so more deeply nested get unmounted first
    RSUBMOUNTS=
    for SM in $SUBMOUNTS; do
	RSUBMOUNTS="$SM $RSUBMOUNTS"
    done
    # unmount submounts
    for SM in $RSUBMOUNTS; do
	ebegin "Unmounting $SM (under $MP)"
	umount $SM
	eend $?
    done
    # unmount the top level mount
    ebegin "Unmounting $MP"
    umount $MP
    eend $?
done
