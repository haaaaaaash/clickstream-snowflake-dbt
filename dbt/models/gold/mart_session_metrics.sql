-- Gold: session KPIs per month x device x traffic source x country
-- Question: which channels and devices convert best?
-- An incomplete last month is excluded automatically (EDA finding #11)
with sessions as (
    select * from {{ ref('fct_sessions') }}
),

order_revenue as (
    select
        session_id,
        count(*)        as orders,
        sum(total_usd)  as revenue_usd
    from {{ ref('fct_orders') }}
    group by session_id
),

last_month as (
    -- the latest month is partial only if the data stops before its last day
    select
        date_trunc('month', max(session_started_at)) as month_start,
        max(session_started_at)::date < last_day(max(session_started_at)) as is_partial
    from sessions
)

select
    date_trunc('month', s.session_started_at)::date as session_month,
    s.device,
    s.traffic_source,
    s.country,
    count(*) as sessions,
    count_if(s.has_purchase) as converted_sessions,
    round(count_if(s.has_purchase) / count(*), 4) as conversion_rate,
    coalesce(sum(o.orders), 0) as orders,
    coalesce(sum(o.revenue_usd), 0) as revenue_usd,
    round(coalesce(sum(o.revenue_usd), 0) / count(*), 2) as revenue_per_session_usd,
    round(sum(o.revenue_usd) / nullif(sum(o.orders), 0), 2) as avg_order_value_usd,
    round(avg(s.session_duration_min), 2) as avg_session_duration_min
from sessions s
left join order_revenue o
    on s.session_id = o.session_id
where not (date_trunc('month', s.session_started_at) = (select month_start from last_month)
           and (select is_partial from last_month))
group by 1, 2, 3, 4
