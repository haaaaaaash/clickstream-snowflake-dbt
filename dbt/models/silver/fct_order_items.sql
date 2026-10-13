-- Silver: one row per (order_id, product_id)
-- Repeated raw lines are valid (EDA finding #4), so they are aggregated, not dropped
select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'product_id']) }}  as order_item_key,
    order_id,
    product_id,
    count(*) as line_count,
    sum(quantity) as quantity,
    sum(line_total_usd) as line_total_usd,
    round(sum(line_total_usd) / nullif(sum(quantity), 0), 2) as avg_unit_price_usd
from {{ ref('src_order_items') }}
group by order_id, product_id
