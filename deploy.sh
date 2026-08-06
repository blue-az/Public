#!/usr/bin/env bash
# Deploy Proto assets to IONOS webspace.
# Usage:
#   ./deploy.sh papers            — sync papers index only
#   ./deploy.sh bulkhead-tau      — sync generated papers
#   ./deploy.sh domains           — sync domains catalog index
#   ./deploy.sh pose-showcase     — sync pose-from-video showcase
#   ./deploy.sh labwired-serve-hud — sync LabWired serve HUD demo
#   ./deploy.sh groundstroke-demos — sync FH+BH groundstroke demos
#   ./deploy.sh kernelcad-mount   — sync kernelCAD sensor mount demo
#   ./deploy.sh all               — sync everything

set -euo pipefail

HOST="access993872858.webspace-data.io"
PORT="22"
USER="u115257687"
REMOTE_ROOT="prototypes"
LOCAL_ROOT="$(cd "$(dirname "$0")" && pwd)"
IDENTITY_FILE="${IONOS_DEPLOY_KEY:-$HOME/.ssh/ionos_deploy}"

TARGET="${1:-all}"

CONTROL_SOCKET="/tmp/ionos_deploy_$$"

start_master() {
    ssh -fNM -p "$PORT" \
        -i "$IDENTITY_FILE" \
        -o IdentitiesOnly=yes \
        -o BatchMode=yes \
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
        -e "ssh -p $PORT -i $IDENTITY_FILE -o IdentitiesOnly=yes -o BatchMode=yes -o ControlMaster=no -o ControlPath=$CONTROL_SOCKET" \
        "$src" "$USER@$HOST:$dest"
}

start_master
trap stop_master EXIT

case "$TARGET" in
    papers)
        rsync_push "$LOCAL_ROOT/papers/" "$REMOTE_ROOT/papers/"
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
    domains)
        rsync_push "$LOCAL_ROOT/domains/" "$REMOTE_ROOT/domains/"
        ;;
    pose-showcase)
        rsync_push "$LOCAL_ROOT/pose-showcase/" "$REMOTE_ROOT/pose-showcase/"
        ;;
    labwired-serve-hud)
        rsync_push "$LOCAL_ROOT/labwired-serve-hud/" "$REMOTE_ROOT/labwired-serve-hud/"
        ;;
    skeleton-study)
        rsync_push "$LOCAL_ROOT/skeleton-study/" "$REMOTE_ROOT/skeleton-study/"
        ;;
    skeleton-hud)
        rsync_push "$LOCAL_ROOT/skeleton-hud/" "$REMOTE_ROOT/skeleton-hud/"
        ;;
    groundstroke-demos)
        rsync_push "$LOCAL_ROOT/groundstroke-demos/" "$REMOTE_ROOT/groundstroke-demos/"
        ;;
    kernelcad-mount)
        rsync_push "$LOCAL_ROOT/kernelcad-mount/" "$REMOTE_ROOT/kernelcad-mount/"
        ;;
    all)
        rsync_push "$LOCAL_ROOT/papers/" "$REMOTE_ROOT/papers/"
        rsync_push "$LOCAL_ROOT/bulkhead-tau/" "$REMOTE_ROOT/bulkhead-tau/"
        rsync_push "$LOCAL_ROOT/sensor-simulation/" "$REMOTE_ROOT/sensor-simulation/"
        rsync_push "$LOCAL_ROOT/domains/" "$REMOTE_ROOT/domains/"
        rsync_push "$LOCAL_ROOT/pose-showcase/" "$REMOTE_ROOT/pose-showcase/"
        rsync_push "$LOCAL_ROOT/labwired-serve-hud/" "$REMOTE_ROOT/labwired-serve-hud/"
        rsync_push "$LOCAL_ROOT/skeleton-study/" "$REMOTE_ROOT/skeleton-study/"
        rsync_push "$LOCAL_ROOT/skeleton-hud/" "$REMOTE_ROOT/skeleton-hud/"
        rsync_push "$LOCAL_ROOT/groundstroke-demos/" "$REMOTE_ROOT/groundstroke-demos/"
        rsync_push "$LOCAL_ROOT/kernelcad-mount/" "$REMOTE_ROOT/kernelcad-mount/"
        rsync_push "$LOCAL_ROOT/.htaccess" "$REMOTE_ROOT/.htaccess"
        ;;
    *)
        echo "Usage: $0 [papers|bulkhead-tau|domains|pose-showcase|labwired-serve-hud|skeleton-study|skeleton-hud|groundstroke-demos|kernelcad-mount|all]"
        exit 1
        ;;
esac

echo "[✓] Deploy complete."
