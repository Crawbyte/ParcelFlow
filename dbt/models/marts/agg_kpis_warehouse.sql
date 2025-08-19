with o as (
select * from {{ ref('fct_orders') }}
), v as (
select * from {{ ref('stg_vehicles') }}
), cap as (
select warehouse_id, count(*) * max(capacity) as nominal_capacity
from v group by 1
), recent as (
select pickup_warehouse_id as warehouse_id,
avg(total_prep_min)::numeric(10,2) as prep_min_avg,
avg(travel_min)::numeric(10,2) as route_min_avg,
avg(case when sla_met then 1 else 0 end)::numeric(10,4) as sla_rate,
sum(case when status_asof='in_progress' then items else 0 end) as pending_items
from o
group by 1
)
select r.warehouse_id,
r.prep_min_avg,
r.route_min_avg,
r.sla_rate,
r.pending_items,
c.nominal_capacity,
(r.pending_items::numeric / nullif(c.nominal_capacity,0))::numeric(10,4) as utilization
from recent r
join cap c using (warehouse_id)