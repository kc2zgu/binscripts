#!/bin/sh

. /lib/gentoo/functions.sh

ebegin "Checking for USB camera connection"

if gphoto2 --auto-detect |grep usb: > /dev/null; then
    eend 0
else
    eend 1
    exit 1
fi

ebegin "Finding v4l2loopback video device"

if [ -d /sys/module/v4l2loopback ]; then
    for video in /sys/class/video4linux/video*; do
        if [ -z $VIDEODEV ]; then
            if grep 'Dummy video device' $video/name > /dev/null; then
                VIDEODEV=`basename $video`
            fi
        fi
    done
else
    eend 1
    eerror "v4l2loopback module is not loaded"
    exit 1
fi

if [ -n "$VIDEODEV" ]; then
    eend 0
    einfo "Found $VIDEODEV"
else
    eend 1
    eerror "No matching video devices"
fi

if [ ! -w /dev/$VIDEODEV ]; then
    eerror "/dev/$VIDEODEV is not writable"
    exit 1
fi

einfo "Starting video stream"

gphoto2 --stdout --capture-movie | \
    ffmpeg -i - -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 /dev/$VIDEODEV
