#!/usr/bin/env bash
set -euo pipefail

# Default connection string
PGURL=${PGURL:-"postgresql://parcelflow:parcelflow@localhost:5432/parcelflow"}

echo "🔥 Running ParcelFlow smoke tests..."
echo "--------------------------------"

# Test 1: PostgreSQL connection
echo "Test 1: PostgreSQL connection"
if PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -c "SELECT 1" > /dev/null; then
  echo "✅ Connection to PostgreSQL successful"
else
  echo "❌ Failed to connect to PostgreSQL"
  exit 1
fi

# Test 2: Check raw.raw_orders has rows
echo "Test 2: Check raw.raw_orders has rows"
ORDER_COUNT=$(PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -t -c "SELECT COUNT(*) FROM raw.raw_orders")
ORDER_COUNT=$(echo $ORDER_COUNT | xargs)  # Trim whitespace

if [ "$ORDER_COUNT" -gt 0 ]; then
  echo "✅ raw.raw_orders has $ORDER_COUNT rows"
else
  echo "❌ raw.raw_orders has no rows"
  exit 1
fi

# Test 3: Check marts.agg_kpis_warehouse exists with expected columns
echo "Test 3: Check marts.agg_kpis_warehouse exists and has expected columns"
WAREHOUSE_COLS=$(PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -t -c "
  SELECT COUNT(*) 
  FROM information_schema.columns 
  WHERE table_schema = 'marts' 
    AND table_name = 'agg_kpis_warehouse' 
    AND column_name IN ('sla_rate', 'utilization')
")
WAREHOUSE_COLS=$(echo $WAREHOUSE_COLS | xargs)

if [ "$WAREHOUSE_COLS" -eq 2 ]; then
  echo "✅ marts.agg_kpis_warehouse exists with expected columns"
else
  echo "❌ marts.agg_kpis_warehouse missing expected columns"
  exit 1
fi

# Test 4: Check marts.fct_forecast_minute returns rows
echo "Test 4: Check marts.fct_forecast_minute has rows"
FORECAST_COUNT=$(PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -t -c "
  SELECT COUNT(*) FROM marts.fct_forecast_minute
")
FORECAST_COUNT=$(echo $FORECAST_COUNT | xargs)

if [ "$FORECAST_COUNT" -gt 0 ]; then
  echo "✅ marts.fct_forecast_minute has $FORECAST_COUNT rows"
else
  echo "❌ marts.fct_forecast_minute has no rows"
  exit 1
fi

# Test 5: Move clock forward and verify that forecast updates
echo "Test 5: Move clock and verify forecast updates"
CURRENT_TIME=$(PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -t -c "
  SELECT current_sim_time FROM control.sim_time
")
CURRENT_TIME=$(echo $CURRENT_TIME | xargs)

# Move clock 30 minutes forward
NEW_TIME=$(PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -t -c "
  UPDATE control.sim_time 
  SET current_sim_time = current_sim_time + interval '30 minutes'
  RETURNING current_sim_time
")
NEW_TIME=$(echo $NEW_TIME | xargs)

echo "Clock moved from $CURRENT_TIME to $NEW_TIME"

# Check if forecast has updated
UPDATED_FORECAST=$(PGPASSWORD=parcelflow psql -h localhost -U parcelflow -d parcelflow -t -c "
  SELECT COUNT(*) FROM marts.fct_forecast_minute 
  WHERE forecast_time > '$CURRENT_TIME'
")
UPDATED_FORECAST=$(echo $UPDATED_FORECAST | xargs)

if [ "$UPDATED_FORECAST" -gt 0 ]; then
  echo "✅ Forecast updated after clock change with $UPDATED_FORECAST new rows"
else
  echo "❌ Forecast did not update after clock change"
  exit 1
fi

echo "--------------------------------"
echo "🎉 All smoke tests passed!"
