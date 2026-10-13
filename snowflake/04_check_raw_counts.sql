-- 04_check_raw_counts.sql: verify RAW row counts without reloading
-- Run (CLI): snow sql -c admin -f snowflake/04_check_raw_counts.sql
-- Run (Snowsight): copy/paste into a worksheet

SELECT table_name, row_count, expected,
       IFF(row_count = expected, 'OK', 'MISMATCH') AS status
FROM (
    SELECT 'customers'   AS table_name, COUNT(*) AS row_count, 20000  AS expected FROM CLICKSTREAM_DB.RAW.CUSTOMERS   UNION ALL
    SELECT 'events',      COUNT(*), 760958 FROM CLICKSTREAM_DB.RAW.EVENTS      UNION ALL
    SELECT 'order_items', COUNT(*), 59163  FROM CLICKSTREAM_DB.RAW.ORDER_ITEMS UNION ALL
    SELECT 'orders',      COUNT(*), 33580  FROM CLICKSTREAM_DB.RAW.ORDERS      UNION ALL
    SELECT 'products',    COUNT(*), 1197   FROM CLICKSTREAM_DB.RAW.PRODUCTS    UNION ALL
    SELECT 'reviews',     COUNT(*), 10780  FROM CLICKSTREAM_DB.RAW.REVIEWS     UNION ALL
    SELECT 'sessions',    COUNT(*), 120000 FROM CLICKSTREAM_DB.RAW.SESSIONS
)
ORDER BY table_name;