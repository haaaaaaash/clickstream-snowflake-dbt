-- Which traffic source converts best?
select
    traffic_source,
    sum(sessions) as sessions,
    sum(orders) as orders,
    round(sum(orders) / nullif(sum(sessions), 0), 3) as conversion_rate,
    round(sum(revenue_usd), 0) as revenue_usd
from {{ ref('mart_session_metrics') }}
group by traffic_source
order by conversion_rate desc