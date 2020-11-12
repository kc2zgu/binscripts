#!/bin/sh

HOST=$1

grep ^$HOST ~/.ssh/known_hosts

if grep ^$HOST ~/.ssh/known_hosts; then
    echo "Removing $HOST SSH key"
    grep --invert-match ^$HOST ~/.ssh/known_hosts > ~/.ssh/known_hosts.new
    mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bak
    mv ~/.ssh/known_hosts.new ~/.ssh/known_hosts
else
    echo "No known key for $HOST"
fi
