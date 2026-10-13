-- Silver: one row per product, with margin %
select
    product_id,
    product_name,
    category,
    price_usd,
    cost_usd,
    margin_usd,
    round(margin_usd / nullif(price_usd, 0), 4) as margin_pct
from {{ ref('src_products') }}
