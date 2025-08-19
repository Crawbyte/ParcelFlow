with vt as (
select * from {{ ref('fct_vehicle_trips') }}
)
select
order_id,
pickup_warehouse_id,
dropoff_cell_id,
items,
created_at,
promised_at,
total_prep_min,
trip_start_at,
travel_min,
expected_delivery_at,
status_asof,
(expected_delivery_at - created_at) <= interval '45 minutes' as sla_met
from vt