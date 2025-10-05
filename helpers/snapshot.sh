#!/usr/bin/env bash
set -euo pipefail
OUT="/var/lib/manus/snapshots/sys_$(date +%F_%H%M%S).txt"
{
  uname -a
  df -h
  free -m
  docker ps
  uptime
  systemctl --failed || true
} > "$OUT"
/usr/local/bin/proof snapshot "$OUT"
echo "$OUT"
