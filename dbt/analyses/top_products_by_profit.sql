-- Are the most profitable products also the best rated?
select
    product_name,
    category,
    gross_profit_usd,
    avg_rating,
    review_count
from {{ ref('mart_product_performance') }}
qualify row_number() over (order by gross_profit_usd desc) <= 10
order by gross_profit_usd desc