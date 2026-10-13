-- Data-quality check: a review should not be dated before its order (EDA finding #7)
-- Known issue in the source (5,482 rows) -> severity WARN: reported, but does not fail the build.
{{ config(severity = 'warn') }}

select
    review_id,
    order_id,
    ordered_at,
    reviewed_at
from {{ ref('fct_reviews') }}
where is_review_before_order
