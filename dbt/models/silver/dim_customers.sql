-- Silver: one row per customer, enriched with the country name (seed lookup)
-- PII: name and email are NOT carried into Silver. The email is pseudonymized
-- (SHA-256 hash), so customers stay distinguishable without exposing identity.
with customers as (
    select * from {{ ref('src_customers') }}
),

countries as (
    select * from {{ ref('country_codes') }}
)

select
    c.customer_id,
    sha2(lower(trim(c.email)), 256)   as email_hash,
    c.country,
    k.country_name,
    c.age,
    c.signup_date,
    c.is_marketing_opt_in
from customers c
left join countries k
    on c.country = k.country_code