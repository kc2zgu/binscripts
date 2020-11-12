#!/bin/sh

HOST=$1
KEY=$2
KEYROOT=$HOME/.ssh

. /lib/gentoo/functions.sh

if [ -z $KEY ]; then
    eerror "Usage: `basename $0` [user@]host key"
    einfo "Available keys in $KEYROOT:"
    for k in $KEYROOT/*.pub; do
        kname=`basename $k`
        kinfo=`cut -d' ' -f1,3 < $k`
        echo "     * $kname ($kinfo)"
    done
    exit 1
fi

einfo "Installing public key $KEY from $KEYROOT onto $HOST"

if [ -f "$KEYROOT/$KEY" ]; then
    KEYDATA=`cat "$KEYROOT/$KEY"`
    einfo "Public key: $KEYDATA"
    ebegin "Updating authorized_keys"
    ssh $HOST "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo $KEYDATA >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    eend $?
else
    eerror "Key file $KEY not found"
fi
