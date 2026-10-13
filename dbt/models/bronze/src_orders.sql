-- Bronze: rename + cast only, no business logic
select
    order_id::int as order_id,
    customer_id::int as customer_id,
    try_to_timestamp_ntz(order_time) as ordered_at,
    payment_method,
    discount_pct::number(5,2) as discount_pct,
    subtotal_usd::number(10,2) as subtotal_usd,
    total_usd::number(10,2) as total_usd,
    country,
    device,
    source as traffic_source
from {{ source('raw', 'orders') }}
