#!/usr/bin/env bash
set -euo pipefail
PGURL=${PGURL:-"postgresql://parcelflow:parcelflow@localhost:5432/parcelflow"}
psql "$PGURL" -v ON_ERROR_STOP=1 -f scripts/init/01_schema_and_seed.sql