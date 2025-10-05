#!/usr/bin/env bash
set -euo pipefail
APP="${1:-yourapp}"
docker compose -f /opt/apps/$APP/docker-compose.yml pull web
docker compose -f /opt/apps/$APP/docker-compose.yml up -d web
curl -fsS "http://127.0.0.1:8000/health" | grep -q "OK"
/usr/local/bin/proof "deploy:$APP"
