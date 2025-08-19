with vt as (
select * from {{ ref('fct_vehicle_trips') }}
)
select
vehicle_id,
pickup_warehouse_id as warehouse_id,
avg(travel_min)::numeric(10,2) as avg_route_min,
avg(total_prep_min)::numeric(10,2) as avg_prep_min,
avg(case when status_asof='in_progress' then 1 else 0 end)::numeric(10,4) as share_en_route
from vt
group by 1,2