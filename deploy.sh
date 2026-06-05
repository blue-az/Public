#!/usr/bin/env bash
# Deploy Proto assets to IONOS webspace.
# Usage:
#   ./deploy.sh papers            — sync papers index only
#   ./deploy.sh bulkhead-tau-core — sync core generated papers
#   ./deploy.sh all               — sync everything

set -euo pipefail

HOST="access993872858.webspace-data.io"
PORT="22"
USER="u115257687"
REMOTE_ROOT="prototypes"
LOCAL_ROOT="$(cd "$(dirname "$0")" && pwd)"

TARGET="${1:-all}"

CONTROL_SOCKET="/tmp/ionos_deploy_$$"

start_master() {
    ssh -fNM -p "$PORT" \
        -o ControlMaster=yes \
        -o ControlPath="$CONTROL_SOCKET" \
        -o StrictHostKeyChecking=accept-new \
        "$USER@$HOST"
}

stop_master() {
    ssh -O exit -o ControlPath="$CONTROL_SOCKET" "$USER@$HOST" 2>/dev/null || true
}

rsync_push() {
    local src="$1"
    local dest="$2"
    echo "[*] Syncing $src → $USER@$HOST:$dest"
    rsync -avz \
        -e "ssh -p $PORT -o ControlMaster=no -o ControlPath=$CONTROL_SOCKET" \
        "$src" "$USER@$HOST:$dest"
}

start_master
trap stop_master EXIT

case "$TARGET" in
    papers)
        rsync_push "$LOCAL_ROOT/papers/" "$REMOTE_ROOT/papers/"
        ;;
    bulkhead-tau-core)
        rsync_push "$LOCAL_ROOT/bulkhead-tau-core/" "$REMOTE_ROOT/bulkhead-tau-core/"
        ;;
    bulkhead-tau)
        rsync_push "$LOCAL_ROOT/bulkhead-tau/" "$REMOTE_ROOT/bulkhead-tau/"
        ;;
    sensor-simulation)
        rsync_push "$LOCAL_ROOT/sensor-simulation/" "$REMOTE_ROOT/sensor-simulation/"
        ;;
    periodic-agent)
        rsync_push "$LOCAL_ROOT/periodic-agent/" "$REMOTE_ROOT/periodic-agent/"
        ;;
    all)
        rsync_push "$LOCAL_ROOT/papers/" "$REMOTE_ROOT/papers/"
        rsync_push "$LOCAL_ROOT/bulkhead-tau-core/" "$REMOTE_ROOT/bulkhead-tau-core/"
        rsync_push "$LOCAL_ROOT/bulkhead-tau/" "$REMOTE_ROOT/bulkhead-tau/"
        rsync_push "$LOCAL_ROOT/sensor-simulation/" "$REMOTE_ROOT/sensor-simulation/"
        rsync_push "$LOCAL_ROOT/.htaccess" "$REMOTE_ROOT/.htaccess"
        ;;
    *)
        echo "Usage: $0 [papers|bulkhead-tau-core|bulkhead-tau|all]"
        exit 1
        ;;
esac

echo "[✓] Deploy complete."
