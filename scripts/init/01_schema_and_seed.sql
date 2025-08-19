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
WITH params AS (
SELECT TIMESTAMP '2025-01-01 00:00:00' AS day_start,
SELECT 'depot_down','low', TIMESTAMP '2025-01-01 08:30', TIMESTAMP '2025-01-01 09:15', 3, NULL;