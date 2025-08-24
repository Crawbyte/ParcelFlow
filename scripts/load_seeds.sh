#!/usr/bin/env bash
set -euo pipefail

# Default connection string
PGURL=${1:-"postgresql://parcelflow:parcelflow@localhost:5432/parcelflow"}

# Function to load CSV into database
load_csv() {
  local file=$1
  local table=$2
  echo "Loading $file into $table..."
  
  # Extract just the filename without path or extension
  local filename=$(basename "$file" .csv)
  
  # Use psql to copy data from CSV to table
  # Extract host from PGURL
  local host=$(echo $PGURL | sed -n 's/.*@\([^:]*\).*/\1/p')
  host=${host:-"localhost"}
  
  PGPASSWORD=parcelflow psql -h $host -U parcelflow -d parcelflow -c "\
    TRUNCATE raw.raw_${table}; \
    COPY raw.raw_${table} FROM STDIN WITH CSV HEADER;" < "$file"
  
  echo "✓ Loaded $file into raw.raw_${table}"
}

echo "Loading seed data from CSV files..."

# Check if data directory exists
if [ ! -d "data" ]; then
  echo "Error: data directory not found"
  exit 1
fi

# Load each CSV file into its corresponding table
[ -f "data/seed_warehouses.csv" ] && load_csv "data/seed_warehouses.csv" "warehouses"
[ -f "data/seed_grid.csv" ] && load_csv "data/seed_grid.csv" "grid"
[ -f "data/seed_vehicles.csv" ] && load_csv "data/seed_vehicles.csv" "vehicles"
[ -f "data/seed_orders.csv" ] && load_csv "data/seed_orders.csv" "orders"
[ -f "data/seed_events.csv" ] && load_csv "data/seed_events.csv" "events"

echo "✅ All seed data loaded successfully"
