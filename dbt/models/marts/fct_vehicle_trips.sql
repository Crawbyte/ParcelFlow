with sim as (select current_sim_time from control.sim_time limit 1),
orders_ranked as (
select o.*, w.lat as wh_lat, w.lon as wh_lon,
row_number() over (partition by o.pickup_warehouse_id order by o.created_at, o.order_id) as seq_in_wh
from {{ ref('stg_orders') }} o
join {{ ref('stg_warehouses') }} w on w.warehouse_id = o.pickup_warehouse_id
), assignment as (
select o.*, ((seq_in_wh - 1) % 8) + 1 as vehicle_index
from orders_ranked o
), vehicles as (
select v.vehicle_id, v.warehouse_id, v.capacity, v.base_speed_kmh,
((v.warehouse_id-1)*8) + (v.vehicle_id - ((v.warehouse_id-1)*8)) as sanity
from {{ ref('stg_vehicles') }} v
), enriched as (
select a.order_id, a.created_at, a.promised_at, a.pickup_warehouse_id,
a.dropoff_cell_id, a.items, a.seq_in_wh, a.vehicle_index,
(a.pickup_warehouse_id-1)*8 + a.vehicle_index as vehicle_id,
g.x, g.y, a.wh_lat, a.wh_lon,
v.base_speed_kmh
from assignment a
join {{ ref('stg_grid') }} g on g.cell_id = a.dropoff_cell_id
join {{ ref('stg_vehicles') }} v on v.vehicle_id = (a.pickup_warehouse_id-1)*8 + a.vehicle_index
), base_times as (
select e.*,
-- Manhattan distance in grid units (1 unit ≈ 1 km)
(abs(e.x - e.wh_lon) + abs(e.y - e.wh_lat))::numeric as dist_km,
-- 30 km/h = 0.5 km/min → minutes = dist / 0.5 = 2*dist
(2.0 * (abs(e.x - e.wh_lon) + abs(e.y - e.wh_lat)))::numeric as base_travel_min
from enriched e
), prep_time as (
select b.*,
-- deterministic 5..15 min via md5(order_id)
(5 + (('x' || substr(md5(b.order_id::text), 1, 8))::bit(32)::int % 11))::int as prep_min
from base_times b
), event_effects as (
select p.*, fa.current_sim_time,
coalesce(max(case when fa.is_active and fa.event_type='depot_down' and (fa.affected_warehouse_id = p.pickup_warehouse_id) then fa.depot_prep_penalty_min end) over (partition by p.order_id), 0) as depot_prep_penalty_min,
greatest(1.0, max(case when fa.is_active and fa.event_type='weather_slowdown' and (fa.affected_warehouse_id is null or fa.affected_warehouse_id = p.pickup_warehouse_id) then fa.weather_multiplier end) over (partition by p.order_id)) as weather_mult,
coalesce(max(case when fa.is_active and fa.event_type='route_closed' and (
fa.affected_cells is not null and p.dropoff_cell_id = any(fa.affected_cells)
) then fa.route_penalty_min end) over (partition by p.order_id), 0) as route_penalty_min
from prep_time p
left join {{ ref('fct_events_active') }} fa on true
), timeline as (
select ee.*,
(ee.prep_min + ee.depot_prep_penalty_min)::int as total_prep_min,
ee.created_at + make_interval(mins => (ee.prep_min + ee.depot_prep_penalty_min)) as trip_start_at,
ceil(ee.base_travel_min * ee.weather_mult)::int + ee.route_penalty_min as travel_min,
ee.base_travel_min, ee.weather_mult
from event_effects ee
), final as (
select t.*,
t.trip_start_at + make_interval(mins => t.travel_min) as expected_delivery_at,
case when (t.trip_start_at + make_interval(mins => t.travel_min)) <= t.current_sim_time then 'delivered' else 'in_progress' end as status_asof
from timeline t
)
select * from final