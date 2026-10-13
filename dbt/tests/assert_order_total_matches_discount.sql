-- Business rule: total = subtotal x (1 - discount %)
-- Returns the orders that break the rule -> test fails if any row is returned.
select
    order_id,
    subtotal_usd,
    discount_pct,
    total_usd,
    round(subtotal_usd * (1 - discount_pct / 100), 2) as expected_total_usd
from {{ ref('fct_orders') }}
where abs(round(subtotal_usd * (1 - discount_pct / 100), 2) - total_usd) > 0.02
