-- Where do users drop off in the funnel, per device?
select
    device,
    sum(viewed) as viewed,
    sum(added_to_cart) as added_to_cart,
    sum(checked_out) as checked_out,
    sum(purchased) as purchased,
    round(sum(purchased) / nullif(sum(viewed), 0), 3) as view_to_purchase_rate
from {{ ref('mart_conversion_funnel') }}
group by device
order by view_to_purchase_rate desc