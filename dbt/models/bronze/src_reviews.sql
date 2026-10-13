-- Bronze: rename + cast only, no business logic
select
    review_id::int as review_id,
    order_id::int as order_id,
    product_id::int as product_id,
    rating::int as rating,
    review_text,
    try_to_timestamp_ntz(review_time) as reviewed_at
from {{ source('raw', 'reviews') }}
