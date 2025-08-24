#!/usr/bin/env bash
set -e
export SUPERSET_HOME=/app/superset_home
superset db upgrade
superset fab create-admin \
--username admin \
--firstname Admin \
--lastname User \
--email admin@parcelflow.local \
--password admin || true
superset init
python /app/superset_home/extras/add_db.py
# Import dashboards/datasets (best-effort; harmless if already imported)
superset import-dashboards -p /app/superset_home/extras/dashboards_export/parcelflow_dashboard.json || true
# Start
/usr/bin/run-server.sh