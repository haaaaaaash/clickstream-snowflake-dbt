-- Bronze: rename + cast only, no business logic
select
    product_id::int as product_id,
    category,
    name as product_name,
    price_usd::number(10,2) as price_usd,
    cost_usd::number(10,2) as cost_usd,
    margin_usd::number(10,2) as margin_usd
from {{ source('raw', 'products') }}
