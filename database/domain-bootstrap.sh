#!/usr/bin/env bash
set -euo pipefail

# domain-bootstrap.sh — Run domain migrations + seeds against postgres
# Called by the domain-bootstrap docker-compose service

PGHOST="${PGHOST:-postgres}"
PGUSER="${POSTGRES_USER:-postgres}"
PGDB="${POSTGRES_DB:-postgres}"

echo "[domain-bootstrap] Waiting for postgres…"
until pg_isready -h "$PGHOST" -U "$PGUSER" -d "$PGDB" 2>/dev/null; do
  sleep 1
done
echo "[domain-bootstrap] Postgres is ready."

# Run migrations in order
echo "[domain-bootstrap] Running migrations…"
for f in /domain/migrations/*.sql; do
  echo "  → $(basename "$f")"
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 -f "$f"
done

# Run seeds in order
echo "[domain-bootstrap] Running seeds…"
for f in /domain/seeds/*.sql; do
  echo "  → $(basename "$f")"
  psql -h "$PGHOST" -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 -f "$f"
done

echo "[domain-bootstrap] Done — all migrations and seeds applied."
