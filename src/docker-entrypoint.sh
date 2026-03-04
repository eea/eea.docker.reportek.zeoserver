#!/bin/bash
set -e

# ============================================================================
# Docker Entrypoint for Reportek ZEO Server
# ============================================================================

ZEO_HOME=${ZEO_HOME:-/opt/zeo}
ZEO_USER=${ZEO_USER:-zeo}
ZEO_UID=${ZEO_UID:-1000}
ZEO_GID=${ZEO_GID:-1000}
ZEO_PACK_KEEP_OLD=${ZEO_PACK_KEEP_OLD:-true}
ZEO_DATA_DIR=${ZEO_DATA_DIR:-/data}

# ============================================================================
# Helper Functions
# ============================================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

# ============================================================================
# User/Permission Setup
# ============================================================================

setup_permissions() {
    log "Setting up permissions for UID:GID = $ZEO_UID:$ZEO_GID"

    if [ "$(id -u)" = "0" ]; then
        # Update user/group IDs if needed
        if [ "$(id -u $ZEO_USER)" != "$ZEO_UID" ]; then
            usermod -u $ZEO_UID $ZEO_USER 2>/dev/null || true
        fi

        if [ "$(id -g $ZEO_USER)" != "$ZEO_GID" ]; then
            groupmod -g $ZEO_GID $ZEO_USER 2>/dev/null || true
        fi

        # Ensure proper ownership of var directory
        # Chown only the blobstorage and filestorage natively
        mkdir -p $ZEO_DATA_DIR/blobstorage $ZEO_DATA_DIR/filestorage
        chown -R $ZEO_UID:$ZEO_GID $ZEO_DATA_DIR
    else
        log "Running as non-root user. Skipping usermod and chown."
    fi
}

# ============================================================================
# ZODB / ZEO Setup
# ============================================================================

setup_zeo_conf() {
    local zeo_conf="$ZEO_HOME/etc/zeo.conf"

    log "Generating ZEO configuration at $zeo_conf"

    cat <<EOF > "$zeo_conf"
<zeo>
  address 8100
  read-only false
  invalidation-queue-size 100
</zeo>

<filestorage 1>
  path $ZEO_DATA_DIR/filestorage/Data.fs
  blob-dir $ZEO_DATA_DIR/blobstorage
  pack-gc true
  pack-keep-old $ZEO_PACK_KEEP_OLD
</filestorage>

<eventlog>
  level info
  <logfile>
    path STDOUT
    format %(asctime)s %(message)s
  </logfile>
</eventlog>

<runner>
  program $ZEO_HOME/bin/runzeo
  socket-name $ZEO_HOME/var/zeo.zdsock
  daemon true
  forever false
  backoff-limit 10
  exit-codes 0, 2
  directory $ZEO_HOME/var
  default-to-interactive true
  user $ZEO_USER
</runner>
EOF

    if [ "$(id -u)" = "0" ]; then
        chown $ZEO_UID:$ZEO_GID "$zeo_conf"
    fi
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    local command=$1
    shift || true

    # Setup permissions
    setup_permissions

    # Generate ZEO configuration dynamically based on env vars
    setup_zeo_conf

    case "$command" in
        start|fg)
            log "Starting ZEO Server"
            if [ "$(id -u)" = "0" ]; then
                exec gosu $ZEO_USER $ZEO_HOME/bin/runzeo -C $ZEO_HOME/etc/zeo.conf
            else
                exec $ZEO_HOME/bin/runzeo -C $ZEO_HOME/etc/zeo.conf
            fi
            ;;

        python)
            log "Starting Python interpreter"
            if [ "$(id -u)" = "0" ]; then
                exec gosu $ZEO_USER $ZEO_HOME/bin/python "$@"
            else
                exec $ZEO_HOME/bin/python "$@"
            fi
            ;;

        shell|bash)
            log "Starting bash shell as $ZEO_USER"
            if [ "$(id -u)" = "0" ]; then
                exec gosu $ZEO_USER /bin/bash "$@"
            else
                exec /bin/bash "$@"
            fi
            ;;

        help|--help|-h)
            cat <<EOF
Reportek ZEO Server Docker Container

Usage: docker run [options] reportek-zeo [command]

Commands:
  start       Start ZEO (default)
  fg          Start ZEO in foreground mode (same as start)
  python      Run Python interpreter
  shell       Start bash shell as zeo user
  help        Show this help message

Environment Variables:
  ZEO_HOME             ZEO installation directory (default: /opt/zeo)
  ZEO_DATA_DIR         Directory where data and sockets are kept (default: /data)
  ZEO_USER             User to run ZEO as (default: zeo)
  ZEO_UID              UID for ZEO user (default: 1000)
  ZEO_GID              GID for ZEO group (default: 1000)
  ZEO_PACK_KEEP_OLD    Keep old ZODB pack files (default: true)

EOF
            ;;

        *)
            if [ -n "$command" ]; then
                log "Running custom command: $command $*"
                if [ "$(id -u)" = "0" ]; then
                    exec gosu $ZEO_USER "$command" "$@"
                else
                    exec "$command" "$@"
                fi
            else
                log "No command specified, starting ZEO"
                if [ "$(id -u)" = "0" ]; then
                    exec gosu $ZEO_USER $ZEO_HOME/bin/runzeo -C $ZEO_HOME/etc/zeo.conf
                else
                    exec $ZEO_HOME/bin/runzeo -C $ZEO_HOME/etc/zeo.conf
                fi
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"
