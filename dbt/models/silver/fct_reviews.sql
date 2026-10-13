-- Silver: one row per review, with a data-quality flag (EDA finding #7)
with reviews as (
    select * from {{ ref('src_reviews') }}
),

orders as (
    select order_id, ordered_at from {{ ref('src_orders') }}
)

select
    r.review_id,
    r.order_id,
    r.product_id,
    r.rating,
    r.review_text,
    r.reviewed_at,
    o.ordered_at,
    r.reviewed_at < o.ordered_at as is_review_before_order
from reviews r
left join orders o
    on r.order_id = o.order_id
