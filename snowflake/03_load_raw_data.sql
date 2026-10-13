-- =====================================================================
-- 03_load_raw_data.sql: load the 7 CSVs into CLICKSTREAM_DB.RAW
-- Run as ACCOUNTADMIN (from the repo root):
--   snow sql -c admin -f snowflake/03_load_raw_data.sql -D data_dir="$(pwd)/data/raw"
-- Idempotent: tables are recreated, so re-running reloads everything.
--
-- RAW keeps the source format (e.g. dates as text, float IDs).
-- Type fixes happen later in dbt Bronze (see EDA findings #5, #6).
-- =====================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA CLICKSTREAM_DB.RAW;

-- 1. File format: comma-separated, header row, quoted text, empty -> NULL
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('');

-- 2. Internal stage: landing area for the uploaded files
CREATE OR REPLACE STAGE CSV_STAGE
    FILE_FORMAT = CSV_FORMAT;

-- 3. Upload local CSVs to the stage (gzip-compressed on upload)
PUT 'file://<% data_dir %>/*.csv' @CSV_STAGE AUTO_COMPRESS = TRUE OVERWRITE = TRUE;
LIST @CSV_STAGE;

-- 4. RAW tables (column order = CSV column order)
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id       NUMBER,
    name              VARCHAR,
    email             VARCHAR,
    country           VARCHAR,
    age               NUMBER,
    signup_date       VARCHAR,        -- M/D/YYYY -> parsed in Bronze
    marketing_opt_in  BOOLEAN
);

CREATE OR REPLACE TABLE PRODUCTS (
    product_id  NUMBER,
    category    VARCHAR,
    name        VARCHAR,
    price_usd   NUMBER(10,2),
    cost_usd    NUMBER(10,2),
    margin_usd  NUMBER(10,2)
);

CREATE OR REPLACE TABLE SESSIONS (
    session_id   NUMBER,
    customer_id  NUMBER,
    start_time   VARCHAR,             -- ISO 8601 text -> TIMESTAMP in Bronze
    device       VARCHAR,
    source       VARCHAR,
    country      VARCHAR
);

CREATE OR REPLACE TABLE EVENTS (
    event_id      NUMBER,
    session_id    NUMBER,
    event_timestamp VARCHAR,          -- CSV column "timestamp", renamed to avoid the SQL keyword. ISO text -> TIMESTAMP in Bronze
    event_type    VARCHAR,
    product_id    FLOAT,              -- stored as 93.0 -> INTEGER in Bronze
    qty           FLOAT,
    cart_size     FLOAT,
    payment       VARCHAR,
    discount_pct  FLOAT,
    amount_usd    FLOAT
);

CREATE OR REPLACE TABLE ORDERS (
    order_id        NUMBER,
    customer_id     NUMBER,
    order_time      VARCHAR,          -- ISO 8601 text -> TIMESTAMP in Bronze
    payment_method  VARCHAR,
    discount_pct    NUMBER,
    subtotal_usd    NUMBER(10,2),
    total_usd       NUMBER(10,2),
    country         VARCHAR,
    device          VARCHAR,
    source          VARCHAR
);

CREATE OR REPLACE TABLE ORDER_ITEMS (
    order_id        NUMBER,
    product_id      NUMBER,
    unit_price_usd  NUMBER(10,2),
    quantity        NUMBER,
    line_total_usd  NUMBER(10,2)
);

CREATE OR REPLACE TABLE REVIEWS (
    review_id    NUMBER,
    order_id     NUMBER,
    product_id   NUMBER,
    rating       NUMBER,
    review_text  VARCHAR,
    review_time  VARCHAR              -- ISO 8601 text -> TIMESTAMP in Bronze
);

-- 5. Load: one COPY per table; stop on the first bad row
COPY INTO CUSTOMERS   FROM @CSV_STAGE FILES = ('customers.csv.gz')   ON_ERROR = ABORT_STATEMENT;
COPY INTO PRODUCTS    FROM @CSV_STAGE FILES = ('products.csv.gz')    ON_ERROR = ABORT_STATEMENT;
COPY INTO SESSIONS    FROM @CSV_STAGE FILES = ('sessions.csv.gz')    ON_ERROR = ABORT_STATEMENT;
COPY INTO EVENTS      FROM @CSV_STAGE FILES = ('events.csv.gz')      ON_ERROR = ABORT_STATEMENT;
COPY INTO ORDERS      FROM @CSV_STAGE FILES = ('orders.csv.gz')      ON_ERROR = ABORT_STATEMENT;
COPY INTO ORDER_ITEMS FROM @CSV_STAGE FILES = ('order_items.csv.gz') ON_ERROR = ABORT_STATEMENT;
COPY INTO REVIEWS     FROM @CSV_STAGE FILES = ('reviews.csv.gz')     ON_ERROR = ABORT_STATEMENT;

-- 6. Verify: row counts must match the EDA
SELECT 'customers'   AS table_name, COUNT(*) AS row_count, 20000  AS expected FROM CUSTOMERS   UNION ALL
SELECT 'products',    COUNT(*), 1197   FROM PRODUCTS    UNION ALL
SELECT 'sessions',    COUNT(*), 120000 FROM SESSIONS    UNION ALL
SELECT 'events',      COUNT(*), 760958 FROM EVENTS      UNION ALL
SELECT 'orders',      COUNT(*), 33580  FROM ORDERS      UNION ALL
SELECT 'order_items', COUNT(*), 59163  FROM ORDER_ITEMS UNION ALL
SELECT 'reviews',     COUNT(*), 10780  FROM REVIEWS
ORDER BY table_name;
