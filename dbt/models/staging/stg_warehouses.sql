select
warehouse_id,
name,
cast(lat as int) as lat,
cast(lon as int) as lon,
status
from raw.raw_warehouses