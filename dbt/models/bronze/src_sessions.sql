-- Bronze: rename + cast only, no business logic
select
    session_id::int as session_id,
    customer_id::int as customer_id,
    try_to_timestamp_ntz(start_time) as session_started_at,
    device,
    source as traffic_source,
    country
from {{ source('raw', 'sessions') }}
