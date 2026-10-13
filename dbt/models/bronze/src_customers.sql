-- Bronze: rename + cast only, no business logic
select
    customer_id::int as customer_id,
    name as customer_name,
    email,
    country,
    age::int as age,
    try_to_date(signup_date, 'MM/DD/YYYY') as signup_date,  -- EDA #6: M/D/YYYY text
    marketing_opt_in::boolean  as is_marketing_opt_in
from {{ source('raw', 'customers') }}
