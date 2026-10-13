-- Business rule: sum of order lines = order subtotal (EDA finding #4)
-- Proves that keeping the repeated order_items lines is correct:
-- dropping them would break 73 order subtotals.
with line_totals as (
    select order_id, sum(line_total_usd) as lines_total_usd
    from {{ ref('fct_order_items') }}
    group by order_id
)

select
    o.order_id,
    o.subtotal_usd,
    l.lines_total_usd
from {{ ref('fct_orders') }} o
left join line_totals l
    on o.order_id = l.order_id
where abs(coalesce(l.lines_total_usd, 0) - o.subtotal_usd) > 0.02
