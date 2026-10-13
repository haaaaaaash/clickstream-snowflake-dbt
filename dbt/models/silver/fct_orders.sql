-- Silver: one row per order, linked to the session it was placed in
-- Purchase events have no order_id: they are matched to orders on
-- customer_id + timestamp (100% match in the EDA, finding #8)
with orders as (
    select * from {{ ref('src_orders') }}
),

purchase_events as (
    select
        e.session_id,
        s.customer_id,
        e.event_at
    from {{ ref('src_events') }} e
    join {{ ref('src_sessions') }} s
        on e.session_id = s.session_id
    where e.event_type = 'purchase'
),

order_lines as (
    select
        order_id,
        count(*) as line_count,
        sum(quantity) as item_quantity
    from {{ ref('src_order_items') }}
    group by order_id
)

select
    o.order_id,
    o.customer_id,
    p.session_id,
    o.ordered_at,
    o.payment_method,
    o.discount_pct,
    o.subtotal_usd,
    o.subtotal_usd - o.total_usd as discount_usd,
    o.total_usd,
    coalesce(l.line_count, 0) as line_count,
    coalesce(l.item_quantity, 0) as item_quantity,
    o.country,
    o.device,
    o.traffic_source
from orders o
left join purchase_events p
    on  o.customer_id = p.customer_id
    and o.ordered_at  = p.event_at
left join order_lines l
    on o.order_id = l.order_id
