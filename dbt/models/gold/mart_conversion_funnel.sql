-- Gold: conversion funnel per month x device
-- Question: where do users drop out? (view -> cart -> checkout -> purchase)
-- An incomplete last month is excluded automatically (EDA finding #11)
with sessions as (
    select * from {{ ref('fct_sessions') }}
),

last_month as (
    -- the latest month is partial only if the data stops before its last day
    select
        date_trunc('month', max(session_started_at))                 as month_start,
        max(session_started_at)::date < last_day(max(session_started_at)) as is_partial
    from sessions
),

steps as (
    select
        date_trunc('month', session_started_at)::date as session_month,
        device,
        count(*) as sessions,
        count_if(page_views > 0) as viewed,
        count_if(has_add_to_cart) as added_to_cart,
        count_if(has_checkout) as checked_out,
        count_if(has_purchase) as purchased
    from sessions
    where not (date_trunc('month', session_started_at) = (select month_start from last_month)
               and (select is_partial from last_month))
    group by 1, 2
)

select
    session_month,
    device,
    sessions,
    viewed,
    added_to_cart,
    checked_out,
    purchased,
    -- step conversion rates
    round(added_to_cart / nullif(viewed, 0), 4) as view_to_cart_rate,
    round(checked_out   / nullif(added_to_cart, 0), 4) as cart_to_checkout_rate,
    round(purchased     / nullif(checked_out, 0), 4) as checkout_to_purchase_rate,
    -- overall
    round(purchased     / nullif(sessions, 0), 4) as session_conversion_rate
from steps
