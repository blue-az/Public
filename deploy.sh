#!/usr/bin/env bash
# Deploy Proto assets to IONOS webspace.
# Usage:
#   ./deploy.sh papers            — sync papers index only
#   ./deploy.sh bulkhead-tau      — sync generated papers
#   ./deploy.sh domains           — sync domains catalog index
#   ./deploy.sh local-models      — sync the Local Models umbrella and its nested pages
#   ./deploy.sh operator-shell    — sync the Operator Shell page
#   ./deploy.sh failure-details   — sync the Phoenix Boundary Results page
#   ./deploy.sh local-model-role-suitability — sync the Local Model Role Suitability page
#   ./deploy.sh honeywell         — sync Honeywell prototype
#   ./deploy.sh honeywell-landing — sync standalone Honeywell landing page
#   ./deploy.sh tour-agent       — sync TourAgent demo
#   ./deploy.sh capture-integrity — sync capture-integrity paper site
#   ./deploy.sh deep-dive-tennis-paper — sync Paper 1.32 and its figures
#   ./deploy.sh local-lane-qwen38 — sync the Qwen 3.8 local-lane page
#   ./deploy.sh pose-showcase     — sync pose-from-video showcase
#   ./deploy.sh labwired-serve-hud — sync LabWired serve HUD demo
#   ./deploy.sh groundstroke-demos — sync FH+BH groundstroke demos
#   ./deploy.sh kernelcad-mount   — sync kernelCAD sensor mount demo
#   ./deploy.sh all               — sync everything

set -euo pipefail

# Target lives outside the repo: this file is public. Put the real values in
# deploy.env next to this script (gitignored) or export them before running.
# See deploy.env.example.
if [[ -f "$(dirname "$0")/deploy.env" ]]; then
    # shellcheck disable=SC1091
    source "$(dirname "$0")/deploy.env"
fi
HOST="${IONOS_HOST:?IONOS_HOST is not set -- copy deploy.env.example to deploy.env and fill it in}"
USER="${IONOS_USER:?IONOS_USER is not set -- copy deploy.env.example to deploy.env and fill it in}"
PORT="${IONOS_PORT:-22}"
REMOTE_ROOT="${IONOS_REMOTE_ROOT:-prototypes}"
LOCAL_ROOT="$(cd "$(dirname "$0")" && pwd)"
# Prefer an explicit deploy key; fall back to the account key, then to the
# agent's default identities. Passing -i for a file that does not exist makes
# every ssh/rsync call warn, and IdentitiesOnly=yes would break outright if the
# default key ever stopped being offered.
IDENTITY_FILE="${IONOS_DEPLOY_KEY:-}"
if [[ -z "$IDENTITY_FILE" ]]; then
    for candidate in "$HOME/.ssh/ionos_deploy" "$HOME/.ssh/id_ed25519"; do
        [[ -f "$candidate" ]] && { IDENTITY_FILE="$candidate"; break; }
    done
fi
if [[ -n "$IDENTITY_FILE" && -f "$IDENTITY_FILE" ]]; then
    SSH_IDENTITY_OPTS=(-i "$IDENTITY_FILE" -o IdentitiesOnly=yes)
else
    echo "[!] No deploy key found; using default ssh identities." >&2
    SSH_IDENTITY_OPTS=()
fi

TARGET="${1:-all}"

# --- git parity ------------------------------------------------------------
# rsync publishes the WORKING TREE, so the working tree is what "live" means.
# Commit it before syncing, or the repo quietly becomes a stale second canon
# that the next reader mistakes for the record. Set DEPLOY_AUTOCOMMIT=0 to skip.
REPO_ROOT="$(git -C "$LOCAL_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$REPO_ROOT" && "${DEPLOY_AUTOCOMMIT:-1}" == "1" ]]; then
    if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
        echo "[*] Working tree is dirty; committing before deploy."
        git -C "$REPO_ROOT" add -A
        git -C "$REPO_ROOT" commit -q -m "deploy($TARGET): publish working tree

Committed by deploy.sh: rsync ships the working tree, so this is the
state that went live."
    fi
    git -C "$REPO_ROOT" push -q origin HEAD 2>/dev/null \
        || echo "[!] git push failed; the commit is local only." >&2
fi

# The stamp makes the live site self-describing: one curl says which commit
# is serving, instead of byte-diffing every page against the repo to find out.
write_stamp() {
    [[ -n "$REPO_ROOT" ]] || return 0
    local sha dirty stamp
    sha="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
    dirty=false
    [[ -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]] && dirty=true
    stamp="$(mktemp)"
    # mktemp is 0600 and rsync -a preserves it, which Apache serves as 403.
    chmod 644 "$stamp"
    cat > "$stamp" <<JSON
{
  "commit": "$sha",
  "target": "$TARGET",
  "deployed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployed_from": "$(hostname -s 2>/dev/null || echo unknown)",
  "working_tree_dirty_at_deploy": $dirty
}
JSON
    rsync_push "$stamp" "$REMOTE_ROOT/deploy-stamp.json"
    rm -f "$stamp"
}


CONTROL_SOCKET="/tmp/ionos_deploy_$$"

start_master() {
    ssh -fNM -p "$PORT" \
        "${SSH_IDENTITY_OPTS[@]}" \
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
    # _archive/ is kept locally and never published: superseded copies of a page
    # (an earlier Reflect scan, say) belong next to the current one for
    # reference, but only the current one should be on the site.
    rsync -avz \
        --exclude '_archive/' \
        -e "ssh -p $PORT ${SSH_IDENTITY_OPTS[*]} -o BatchMode=yes -o ControlMaster=no -o ControlPath=$CONTROL_SOCKET" \
        "$src" "$USER@$HOST:$dest"
}

remote_mkdir() {
    local path="$1"
    ssh -p "$PORT" \
        "${SSH_IDENTITY_OPTS[@]}" \
        -o BatchMode=yes \
        -o ControlMaster=no \
        -o ControlPath="$CONTROL_SOCKET" \
        "$USER@$HOST" "mkdir -p '$path'"
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

    local-models)
        rsync_push "$LOCAL_ROOT/local-models/" "$REMOTE_ROOT/local-models/"
        # the umbrella's URLs depend on the 301s in the root .htaccess
        rsync_push "$LOCAL_ROOT/.htaccess" "$REMOTE_ROOT/.htaccess"
        ;;
    sensor-simulation)
        rsync_push "$LOCAL_ROOT/sensor-simulation/" "$REMOTE_ROOT/sensor-simulation/"
        ;;
    periodic-agent)
        rsync_push "$LOCAL_ROOT/periodic-agent/" "$REMOTE_ROOT/periodic-agent/"
        ;;
    domains)
        rsync_push "$LOCAL_ROOT/domains/" "$REMOTE_ROOT/domains/"
        rsync_push "$LOCAL_ROOT/local-models/" "$REMOTE_ROOT/local-models/"
        ;;
    honeywell)
        rsync_push "$LOCAL_ROOT/honeywell/" "$REMOTE_ROOT/honeywell/"
        ;;
    honeywell-landing)
        rsync_push "$LOCAL_ROOT/honeywell-landing/" "$REMOTE_ROOT/honeywell-landing/"
        ;;
    tour-agent)
        rsync_push "$LOCAL_ROOT/tour-agent/" "$REMOTE_ROOT/tour-agent/"
        ;;
    capture-integrity)
        rsync_push "$LOCAL_ROOT/capture-integrity/" "$REMOTE_ROOT/capture-integrity/"
        ;;
    operator-shell)
        rsync_push "$LOCAL_ROOT/operator-shell/" "$REMOTE_ROOT/operator-shell/"
        ;;
    failure-details)
        rsync_push "$LOCAL_ROOT/failure-details/" "$REMOTE_ROOT/failure-details/"
        ;;
    local-model-role-suitability)
        rsync_push "$LOCAL_ROOT/local-model-role-suitability/" "$REMOTE_ROOT/local-model-role-suitability/"
        ;;
    deep-dive-tennis-paper)
        rsync_push "$LOCAL_ROOT/bulkhead-tau/generated-papers/deep-dive-tennis-match-pool.html" "$REMOTE_ROOT/bulkhead-tau/generated-papers/"
        remote_mkdir "$REMOTE_ROOT/bulkhead-tau/domains/SensorAgents/TennisAgent/data/papers/match_pool_2023"
        rsync_push "$LOCAL_ROOT/bulkhead-tau/domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/" "$REMOTE_ROOT/bulkhead-tau/domains/SensorAgents/TennisAgent/data/papers/match_pool_2023/"
        ;;
    local-lane-qwen38)
        rsync_push "$LOCAL_ROOT/local-models/local-lane/qwen38/" "$REMOTE_ROOT/local-models/local-lane/qwen38/"
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
        rsync_push "$LOCAL_ROOT/local-models/" "$REMOTE_ROOT/local-models/"
        rsync_push "$LOCAL_ROOT/sensor-simulation/" "$REMOTE_ROOT/sensor-simulation/"
        rsync_push "$LOCAL_ROOT/domains/" "$REMOTE_ROOT/domains/"
        rsync_push "$LOCAL_ROOT/honeywell/" "$REMOTE_ROOT/honeywell/"
        rsync_push "$LOCAL_ROOT/honeywell-landing/" "$REMOTE_ROOT/honeywell-landing/"
        rsync_push "$LOCAL_ROOT/tour-agent/" "$REMOTE_ROOT/tour-agent/"
        rsync_push "$LOCAL_ROOT/capture-integrity/" "$REMOTE_ROOT/capture-integrity/"
        rsync_push "$LOCAL_ROOT/operator-shell/" "$REMOTE_ROOT/operator-shell/"
        rsync_push "$LOCAL_ROOT/failure-details/" "$REMOTE_ROOT/failure-details/"
        rsync_push "$LOCAL_ROOT/local-model-role-suitability/" "$REMOTE_ROOT/local-model-role-suitability/"
        rsync_push "$LOCAL_ROOT/pose-showcase/" "$REMOTE_ROOT/pose-showcase/"
        rsync_push "$LOCAL_ROOT/labwired-serve-hud/" "$REMOTE_ROOT/labwired-serve-hud/"
        rsync_push "$LOCAL_ROOT/skeleton-study/" "$REMOTE_ROOT/skeleton-study/"
        rsync_push "$LOCAL_ROOT/skeleton-hud/" "$REMOTE_ROOT/skeleton-hud/"
        rsync_push "$LOCAL_ROOT/groundstroke-demos/" "$REMOTE_ROOT/groundstroke-demos/"
        rsync_push "$LOCAL_ROOT/kernelcad-mount/" "$REMOTE_ROOT/kernelcad-mount/"
        rsync_push "$LOCAL_ROOT/.htaccess" "$REMOTE_ROOT/.htaccess"
        ;;
    *)
        echo "Usage: $0 [papers|bulkhead-tau|local-models|domains|honeywell|honeywell-landing|tour-agent|capture-integrity|operator-shell|failure-details|local-model-role-suitability|deep-dive-tennis-paper|local-lane-qwen38|pose-showcase|labwired-serve-hud|skeleton-study|skeleton-hud|groundstroke-demos|kernelcad-mount|all]"
        exit 1
        ;;
esac

write_stamp

echo "[✓] Deploy complete."
