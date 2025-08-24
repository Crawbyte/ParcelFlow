-- Schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS control;


-- Simulation clock (default 09:00)
CREATE TABLE IF NOT EXISTS control.sim_time (
current_sim_time TIMESTAMP NOT NULL
);
TRUNCATE control.sim_time;
INSERT INTO control.sim_time VALUES ('2025-01-01 09:00:00');


-- RAW tables
CREATE TABLE IF NOT EXISTS raw.raw_warehouses (
warehouse_id INT PRIMARY KEY,
name TEXT NOT NULL,
lat NUMERIC NOT NULL,
lon NUMERIC NOT NULL,
status TEXT NOT NULL
);
TRUNCATE raw.raw_warehouses;
INSERT INTO raw.raw_warehouses (warehouse_id, name, lat, lon, status) VALUES
(1,'Norte', 1, 0,'active'),
(2,'Centro', 0, 0,'active'),
(3,'Sur', -1, 0,'active');


CREATE TABLE IF NOT EXISTS raw.raw_grid (
cell_id SERIAL PRIMARY KEY,
x INT NOT NULL,
y INT NOT NULL,
cell_status TEXT NOT NULL
);
TRUNCATE raw.raw_grid RESTART IDENTITY;
INSERT INTO raw.raw_grid (x,y,cell_status)
SELECT x,y,'open'
FROM generate_series(-5,4) AS x
CROSS JOIN generate_series(-5,4) AS y;


CREATE TABLE IF NOT EXISTS raw.raw_vehicles (
vehicle_id INT PRIMARY KEY,
warehouse_id INT NOT NULL,
capacity INT NOT NULL,
base_speed_kmh INT NOT NULL,
status TEXT NOT NULL
);
TRUNCATE raw.raw_vehicles;
INSERT INTO raw.raw_vehicles (vehicle_id, warehouse_id, capacity, base_speed_kmh, status)
SELECT (w.warehouse_id-1)*8 + v AS vehicle_id,
w.warehouse_id,
10 AS capacity,
30 AS base_speed_kmh,
'active' AS status
FROM raw.raw_warehouses w
CROSS JOIN generate_series(1,8) AS v;


-- Orders (1 day, minute granularity, two peaks)
CREATE TABLE IF NOT EXISTS raw.raw_orders (
order_id BIGSERIAL PRIMARY KEY,
created_at TIMESTAMP NOT NULL,
pickup_warehouse_id INT NOT NULL,
dropoff_cell_id INT NOT NULL,
items INT NOT NULL,
promised_at TIMESTAMP NOT NULL,
delivered_at TIMESTAMP NULL,
status TEXT NOT NULL
);
TRUNCATE raw.raw_orders;

-- Generate synthetic orders
-- Morning peak (8:00-10:00) and afternoon peak (16:00-18:00)
WITH time_series AS (
  SELECT generate_series(
    TIMESTAMP '2025-01-01 00:00:00',
    TIMESTAMP '2025-01-01 23:59:59',
    INTERVAL '1 minute'
  ) AS created_at
),
order_counts AS (
  SELECT 
    ts.created_at,
    CASE
      WHEN EXTRACT(HOUR FROM ts.created_at) BETWEEN 8 AND 9 THEN 5
      WHEN EXTRACT(HOUR FROM ts.created_at) BETWEEN 16 AND 17 THEN 4
      WHEN EXTRACT(HOUR FROM ts.created_at) BETWEEN 10 AND 15 THEN 2
      ELSE 1
    END AS order_count
  FROM time_series ts
)
INSERT INTO raw.raw_orders (
  created_at,
  pickup_warehouse_id,
  dropoff_cell_id,
  items,
  promised_at,
  delivered_at,
  status
)
SELECT
  oc.created_at,
  (1 + floor(random() * 3))::int AS pickup_warehouse_id,
  (1 + floor(random() * 100))::int AS dropoff_cell_id,
  (1 + floor(random() * 5))::int AS items,
  oc.created_at + INTERVAL '30 minutes' AS promised_at,
  CASE
    WHEN random() < 0.7 THEN oc.created_at + INTERVAL '25 minutes'
    WHEN random() < 0.9 THEN oc.created_at + INTERVAL '35 minutes'
    ELSE NULL
  END AS delivered_at,
  CASE
    WHEN random() < 0.7 THEN 'delivered'
    WHEN random() < 0.9 THEN 'in_transit'
    ELSE 'assigned'
  END AS status
FROM order_counts oc
WHERE random() < 0.2;  -- Only generate about 20% of the potential orders

-- Create events table if it doesn't exist
CREATE TABLE IF NOT EXISTS raw.raw_events (
  event_id SERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  priority TEXT NOT NULL,
  event_start TIMESTAMP NOT NULL,
  event_end TIMESTAMP NOT NULL,
  warehouse_id INT NULL,
  vehicle_id INT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add sample events
TRUNCATE raw.raw_events;
INSERT INTO raw.raw_events (
  event_type, priority, event_start, event_end, warehouse_id, vehicle_id
)
VALUES
  ('depot_down', 'high', TIMESTAMP '2025-01-01 08:30:00', TIMESTAMP '2025-01-01 09:15:00', 3, NULL),
  ('vehicle_maintenance', 'medium', TIMESTAMP '2025-01-01 10:00:00', TIMESTAMP '2025-01-01 11:30:00', NULL, 5),
  ('congestion', 'low', TIMESTAMP '2025-01-01 16:00:00', TIMESTAMP '2025-01-01 18:00:00', NULL, NULL)