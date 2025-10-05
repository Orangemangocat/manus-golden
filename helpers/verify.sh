#!/usr/bin/env bash
set -euo pipefail
SERVICE="${1:?service name}"
URL="${2:-}"
EXPECT="${3:-OK}"
# container exists & running?
docker ps --format '{{.Names}} {{.State}}' | awk '{print $1}' | grep -q "$SERVICE"
# optional HTTP health
if [[ -n "$URL" ]]; then
  curl -fsS "$URL" | grep -q "$EXPECT"
fi
