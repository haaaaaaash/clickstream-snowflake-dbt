-- Bronze: rename + cast only. NO dedup here: repeated lines are valid (EDA #4)
select
    order_id::int as order_id,
    product_id::int as product_id,
    unit_price_usd::number(10,2) as unit_price_usd,
    quantity::int as quantity,
    line_total_usd::number(10,2) as line_total_usd
from {{ source('raw', 'order_items') }}
