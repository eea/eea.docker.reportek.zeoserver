#!/bin/bash
set -e
set -x

START="start"
CMD="bin/zeoserver"
if [ -z "$HEALTH_CHECK_TIMEOUT" ]; then
  HEALTH_CHECK_TIMEOUT=1
fi

if [ -z "$HEALTH_CHECK_INTERVAL" ]; then
  HEALTH_CHECK_INTERVAL=1
fi

python /docker-initialize.py

if [[ $START == *"$1"* ]]; then
    _stop() {
        $CMD stop
        kill -TERM $child 2>/dev/null
    }

    trap _stop SIGTERM SIGINT

    source /docker-manage-permissions.sh; sync;

    gosu $ZEO_USERNAME $CMD start
    gosu $ZEO_USERNAME $CMD logtail &

    child=$!
    pid=`$CMD status | sed 's/[^0-9]*//g'`
    if [ ! -z "$pid" ]; then
        echo "Application running on pid=$pid"
        sleep "$HEALTH_CHECK_TIMEOUT"
        while kill -0 "$pid" 2> /dev/null; do
          sleep "$HEALTH_CHECK_INTERVAL"
        done
    else
        echo "Application didn't start normally. Shutting down!"
        _stop
    fi
else
  exec "$@"
fi
