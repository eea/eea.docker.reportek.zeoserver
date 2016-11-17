#!/bin/bash
set -e

_terminate() {
    $ZEO_HOME/bin/zeoserver stop
    kill -TERM $child 2>/dev/null
}

trap _terminate SIGTERM SIGINT

if ! test -e $ZEO_HOME/buildout.cfg; then
    python /configure.py
fi

if test -e $ZEO_HOME/buildout.cfg; then
    $ZEO_HOME/bin/buildout -c $ZEO_HOME/buildout.cfg
fi

source /manage_permissions.sh; sync;

gosu $ZEO_USERNAME $ZEO_HOME/bin/zeoserver start
gosu $ZEO_USERNAME $ZEO_HOME/bin/zeoserver logtail &

child=$!
wait "$child"
