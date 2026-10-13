-- Silver: one row per clickstream event, enriched with customer_id from the session
with events as (
    select * from {{ ref('src_events') }}
),

sessions as (
    select session_id, customer_id from {{ ref('src_sessions') }}
)

select
    e.event_id,
    e.session_id,
    s.customer_id,
    e.event_at,
    e.event_type,
    e.product_id,       -- only page_view / add_to_cart
    e.quantity,         -- only add_to_cart
    e.cart_size,        -- only checkout
    e.payment_method,   -- only purchase
    e.discount_pct,     -- only purchase
    e.amount_usd        -- only purchase
from events e
left join sessions s
    on e.session_id = s.session_id
