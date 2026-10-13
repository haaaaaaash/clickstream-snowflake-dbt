-- Bronze: rename + cast only, no business logic
select
    event_id::int as event_id,
    session_id::int as session_id,
    try_to_timestamp_ntz(event_timestamp) as event_at,
    event_type,
    product_id::int as product_id,       -- EDA #5: stored as 93.0
    qty::int as quantity,
    cart_size::int as cart_size,
    payment as payment_method,
    discount_pct::number(5,2) as discount_pct,
    amount_usd::number(10,2) as amount_usd
from {{ source('raw', 'events') }}
