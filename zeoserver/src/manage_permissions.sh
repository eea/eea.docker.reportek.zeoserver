#!/bin/bash
set -e

DEFAULT_ZEO_USER="zope-www"

if [ -z "$ZEO_USERNAME" ]; then
  export ZEO_USERNAME=$DEFAULT_ZEO_USER
fi

if [ -z "$ZEO_UID" ]; then
  export ZEO_UID="500"
fi

if [ -z "$ZEO_GID" ]; then
  export ZEO_GID="500"
fi

if [ -z "$(getent passwd $ZEO_UID)" ]; then
    if [ "$ZEO_USERNAME" != "$DEFAULT_ZEO_USER" ]; then
        usermod -l $ZEO_USERNAME $DEFAULT_ZEO_USER
        groupmod -n $ZEO_USERNAME $DEFAULT_ZEO_USER
    fi
    usermod -u $ZEO_UID $ZEO_USERNAME
fi

if [ -z "$(getent group $ZEO_GID)" ]; then
    groupmod -g $ZEO_GID $ZEO_USERNAME
fi

if [ "$(stat -c %U $ZEO_HOME)" != "$ZEO_USERNAME" ] || [ "$(stat -c %G $ZEO_HOME)" != "$ZEO_USERNAME" ]; then
    chown -R $ZEO_USERNAME:$ZEO_USERNAME $ZEO_HOME
fi
