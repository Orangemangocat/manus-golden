# Core Operational Knowledge (Manus)
**Last Updated:** 2025-10-05T02:56:53+00:00

## 1. System Overview
- OS: Ubuntu 22.04 LTS
- Services: Nginx, Docker Compose, PostgreSQL, Manus Runner/Bridge
- Paths:
  - /usr/local/bin/ : scripts
  - /etc/manus/     : configs + golden plans + knowledge
  - /var/lib/manus/ : queue, proofs, backups, snapshots
  - /var/log/manus/ : logs
  - /opt/apps/      : app code (e.g., /opt/apps/yourapp)

## 2. Automation Rules
- Always execute via `runjson`; never raw shell.
- Atomic steps; stop on first failure.
- Success = zero exit + health check OK.
- Write proof artifacts under `/var/lib/manus/proofs/`.

## 3. Golden Paths
Stored in `/etc/manus/golden/` as JSON templates; Manus only fills parameters (TAG, ENV, SHA).

## 4. Security
- JWT: `/etc/manus/manus.jwt` (root:root, 640)
- Config: `/etc/manus/manus.json` (root:root, 640)
- No secrets in knowledge or golden JSON.

## 5. Logging & Proofs
- Runner: `/var/log/manus/mq-runner.log`
- Bridge: `/var/log/manus/tinyhttp-bridge.log`
- Results: `/var/lib/manus/queue/outbox/*.result.json`
- Proofs: `/var/lib/manus/proofs/*.txt`

## 6. Queue Bridge
- Submit: `POST http://127.0.0.1:8077/task?agent=manus|local`
- Result: `GET  http://127.0.0.1:8077/result/<task_id>`

## 7. Knowledge Slot Policy
Use 1 slot that says: “Refer to `/etc/manus/knowledge/core.md`.” Reserve the other 19 for special overrides.

