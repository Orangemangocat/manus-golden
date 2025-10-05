#!/usr/bin/env bash
set -euo pipefail
docker system prune -af --volumes
/usr/local/bin/proof cleanup
