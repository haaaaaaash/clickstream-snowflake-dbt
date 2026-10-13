-- Gold: one row per product with sales, profit, engagement and reviews
-- Question: which products and categories drive profit?
with products as (
    select * from {{ ref('dim_products') }}
),

sales as (
    select
        product_id,
        count(distinct order_id) as orders,
        sum(quantity) as units_sold,
        sum(line_total_usd) as revenue_usd
    from {{ ref('fct_order_items') }}
    group by product_id
),

engagement as (
    select
        product_id,
        count_if(event_type = 'page_view') as page_views,
        count_if(event_type = 'add_to_cart') as add_to_carts
    from {{ ref('fct_events') }}
    where product_id is not null
    group by product_id
),

reviews as (
    select
        product_id,
        count(*) as review_count,
        round(avg(rating), 2) as avg_rating
    from {{ ref('fct_reviews') }}
    group by product_id
)

select
    p.product_id,
    p.product_name,
    p.category,
    p.price_usd,
    p.cost_usd,
    coalesce(s.orders, 0)                                       as orders,
    coalesce(s.units_sold, 0)                                   as units_sold,
    coalesce(s.revenue_usd, 0)                                  as revenue_usd,
    coalesce(s.revenue_usd, 0) - coalesce(s.units_sold, 0) * p.cost_usd   as gross_profit_usd,
    coalesce(e.page_views, 0)                                   as page_views,
    coalesce(e.add_to_carts, 0)                                 as add_to_carts,
    round(coalesce(e.add_to_carts, 0) / nullif(e.page_views, 0), 4)       as view_to_cart_rate,
    coalesce(r.review_count, 0)                                 as review_count,
    r.avg_rating
from products p
left join sales s       on p.product_id = s.product_id
left join engagement e  on p.product_id = e.product_id
left join reviews r     on p.product_id = r.product_id
