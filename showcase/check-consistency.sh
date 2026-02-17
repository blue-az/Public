#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/showcase/metrics.env"

failures=0

check_contains() {
    local file="$1"
    local pattern="$2"
    if ! rg -q --fixed-strings "$pattern" "$file"; then
        echo "FAIL: $file missing: $pattern"
        failures=$((failures + 1))
    fi
}

check_contains "$ROOT_DIR/showcase/index.html" "${SHOWCASE_DOMAIN_COUNT}</div>"
check_contains "$ROOT_DIR/showcase/index.html" "${SHOWCASE_TOOL_COUNT_LABEL}</div>"
check_contains "$ROOT_DIR/showcase/index.html" "meta-tools (${SHOWCASE_META_TOOL_COUNT} domain tools)"

check_contains "$ROOT_DIR/showcase/domains.html" "${SHOWCASE_DOMAIN_COUNT} Production Domains | ${SHOWCASE_TOOL_COUNT_LABEL} Tools"
check_contains "$ROOT_DIR/showcase/domains.html" "meta mode (${SHOWCASE_META_TOOL_COUNT} tools)"

check_contains "$ROOT_DIR/showcase/modes.html" "Meta-Tool (${SHOWCASE_META_TOOL_COUNT}) vs Direct (${SHOWCASE_TOOL_COUNT_LABEL})"
check_contains "$ROOT_DIR/showcase/modes.html" "${SHOWCASE_META_TOOL_COUNT} Tools"
check_contains "$ROOT_DIR/showcase/modes.html" "${SHOWCASE_TOOL_COUNT_LABEL} Tools"
check_contains "$ROOT_DIR/showcase/modes.html" "Variation 2: Meta-Tool Mode (${SHOWCASE_META_TOOL_COUNT} tools)"

check_contains "$ROOT_DIR/showcase/benchmark.html" "meta-tools (${SHOWCASE_META_TOOL_COUNT} domain tools)"
check_contains "$ROOT_DIR/showcase/benchmark.html" "Meta-tool (${SHOWCASE_META_TOOL_COUNT} tools) vs Direct (${SHOWCASE_TOOL_COUNT_LABEL} tools)"

check_contains "$ROOT_DIR/project-phoenix/index.html" "${PHOENIX_DOMAIN_COUNT} Domains"
check_contains "$ROOT_DIR/project-phoenix/index.html" "${PHOENIX_TOOL_COUNT} Tools"
check_contains "$ROOT_DIR/project-phoenix/domains.html" "${PHOENIX_TOOL_COUNT} tools across ${PHOENIX_DOMAIN_COUNT} production domains."

check_contains "$ROOT_DIR/project-phoenix/domains.html" "AmericanEconomy"
check_contains "$ROOT_DIR/project-phoenix/domains.html" "GlobalTemperature"

if [[ "$failures" -gt 0 ]]; then
    echo
    echo "Consistency check failed with $failures issue(s)."
    exit 1
fi

echo "Consistency check passed."
