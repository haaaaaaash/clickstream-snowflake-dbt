-- Silver: one row per session, with event counts and funnel flags
with sessions as (
    select * from {{ ref('src_sessions') }}
),

event_stats as (
    select
        session_id,
        max(event_at) as last_event_at,
        count(*) as event_count,
        count_if(event_type = 'page_view') as page_views,
        count_if(event_type = 'add_to_cart') as add_to_carts,
        count_if(event_type = 'checkout') as checkouts,
        count_if(event_type = 'purchase') as purchases
    from {{ ref('src_events') }}
    group by session_id
)

select
    s.session_id,
    s.customer_id,
    s.session_started_at,
    coalesce(es.last_event_at, s.session_started_at) as session_ended_at,
    round(datediff('second', s.session_started_at,
                   coalesce(es.last_event_at, s.session_started_at)) / 60, 2) as session_duration_min,
    s.device,
    s.traffic_source,
    s.country,
    coalesce(es.event_count, 0) as event_count,
    coalesce(es.page_views, 0) as page_views,
    coalesce(es.add_to_carts, 0) as add_to_carts,
    coalesce(es.checkouts, 0) as checkouts,
    coalesce(es.purchases, 0) as purchases,
    coalesce(es.add_to_carts, 0) > 0 as has_add_to_cart,
    coalesce(es.checkouts, 0) > 0 as has_checkout,
    coalesce(es.purchases, 0) > 0 as has_purchase
from sessions s
left join event_stats es
    on s.session_id = es.session_id
