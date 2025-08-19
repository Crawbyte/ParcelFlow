with sim as (
select current_sim_time from control.sim_time limit 1
),
active as (
select e.*, s.current_sim_time,
(s.current_sim_time between e.starts_at and e.ends_at) as is_active
from {{ ref('stg_events') }} e
cross join sim s
)
select
event_id,
event_type,
severity,
starts_at,
ends_at,
affected_warehouse_id,
affected_cells,
current_sim_time,
is_active,
case when event_type = 'weather_slowdown' and severity = 'low' then 1.10
when event_type = 'weather_slowdown' and severity = 'medium' then 1.25
when event_type = 'weather_slowdown' and severity = 'high' then 1.40
else 1.00 end as weather_multiplier,
case when event_type = 'route_closed' and severity = 'low' then 10
when event_type = 'route_closed' and severity = 'medium' then 20
when event_type = 'route_closed' and severity = 'high' then 30
else 0 end as route_penalty_min,
case when event_type = 'depot_down' then
case severity when 'low' then 10 when 'medium' then 20 when 'high' then 40 end
else 0 end as depot_prep_penalty_min
from active