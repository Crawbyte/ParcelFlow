with sim as (select current_sim_time from control.sim_time limit 1),
minutes_ahead as (
select generate_series((select current_sim_time from sim) + interval '1 minute',
(select current_sim_time from sim) + interval '60 minute',
interval '1 minute') as ts
),
history as (
select pickup_warehouse_id as warehouse_id,
date_trunc('minute', created_at) as ts_min,
count(*) as orders_min
from {{ ref('stg_orders') }}
group by 1,2
),
recent as (
select h.warehouse_id,
avg(orders_min) as recent_rate_per_min
from history h, sim s
where h.ts_min >= s.current_sim_time - interval '120 minutes'
and h.ts_min < s.current_sim_time
group by 1
),
profile as (
select pickup_warehouse_id as warehouse_id,
(extract(hour from created_at)::int * 60 + extract(minute from created_at)::int) as mod_minute,
avg(1.0) as base_rate_per_min
from {{ ref('stg_orders') }}
group by 1,2
),
alpha as (
select 0.7::numeric as a
),
forecast as (
select m.ts,
w.warehouse_id,
(extract(hour from m.ts)::int * 60 + extract(minute from m.ts)::int) as mod_minute
from minutes_ahead m
cross join {{ ref('stg_warehouses') }} w
)
select f.ts,
f.warehouse_id,
coalesce(r.recent_rate_per_min, 0.0) * a.a + coalesce(p.base_rate_per_min, 0.0) * (1 - a.a) as forecast_orders_per_min,
sum(coalesce(r.recent_rate_per_min, 0.0) * a.a + coalesce(p.base_rate_per_min, 0.0) * (1 - a.a)) over (partition by f.warehouse_id order by f.ts) as cum_forecast
from forecast f
left join recent r on r.warehouse_id = f.warehouse_id
left join profile p on p.warehouse_id = f.warehouse_id and p.mod_minute = f.mod_minute
cross join alpha a