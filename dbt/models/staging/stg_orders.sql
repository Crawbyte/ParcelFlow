with base as (
select
o.order_id,
o.created_at,
o.pickup_warehouse_id,
o.dropoff_cell_id,
o.items,
o.promised_at,
o.delivered_at,
o.status
from raw.raw_orders o
)
select
b.*,
extract(hour from b.created_at)::int * 60 + extract(minute from b.created_at)::int as minute_of_day
from base b