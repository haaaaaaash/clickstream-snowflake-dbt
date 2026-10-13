-- =====================================================================
-- 02_setup_snowflake.sql: Snowflake infrastructure for dbt
-- Run as ACCOUNTADMIN (from the repo root):
--   PUB_KEY=$(grep -v "PUBLIC KEY" ~/.ssh/snowflake/rsa_key.pub | tr -d '\n')
--   snow sql -c admin -f snowflake/02_setup_snowflake.sql -D pub_key="$PUB_KEY"
-- Idempotent: safe to re-run.
-- =====================================================================

USE ROLE ACCOUNTADMIN;

-- 1. Warehouse: dedicated compute for dbt, smallest size, suspends after 60 s idle
CREATE WAREHOUSE IF NOT EXISTS TRANSFORM_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 1b. Cost guard: suspend the warehouse at 90% of a 20-credit quota (protects the trial budget, change if you have a paid account)
CREATE RESOURCE MONITOR IF NOT EXISTS TRANSFORM_MONITOR
    WITH CREDIT_QUOTA = 20
    TRIGGERS ON 90 PERCENT DO SUSPEND;
ALTER WAREHOUSE TRANSFORM_WH SET RESOURCE_MONITOR = TRANSFORM_MONITOR;

-- 2. Database + medallion schemas
--    RAW           = loaded CSVs (COPY INTO)
--    SILVER / GOLD = dbt models (Bronze is ephemeral: no schema needed)
--    TEST_FAILURES = rows of failed dbt tests (store_failures)
CREATE DATABASE IF NOT EXISTS CLICKSTREAM_DB;
CREATE SCHEMA IF NOT EXISTS CLICKSTREAM_DB.RAW;
CREATE SCHEMA IF NOT EXISTS CLICKSTREAM_DB.SILVER;
CREATE SCHEMA IF NOT EXISTS CLICKSTREAM_DB.GOLD;
CREATE SCHEMA IF NOT EXISTS CLICKSTREAM_DB.TEST_FAILURES;

-- 3. Role for dbt (least privilege), attached to SYSADMIN so admins see dbt's objects
CREATE ROLE IF NOT EXISTS TRANSFORM;
GRANT ROLE TRANSFORM TO ROLE SYSADMIN;

-- 4. Grants
-- 4a. Compute + database
GRANT USAGE ON WAREHOUSE TRANSFORM_WH TO ROLE TRANSFORM;
GRANT USAGE ON DATABASE CLICKSTREAM_DB TO ROLE TRANSFORM;

-- 4b. RAW: read-only (FUTURE grants cover tables created later by 03_load_raw_data.sql)
GRANT USAGE ON SCHEMA CLICKSTREAM_DB.RAW TO ROLE TRANSFORM;
GRANT SELECT ON ALL TABLES    IN SCHEMA CLICKSTREAM_DB.RAW TO ROLE TRANSFORM;
GRANT SELECT ON FUTURE TABLES IN SCHEMA CLICKSTREAM_DB.RAW TO ROLE TRANSFORM;

-- 4c. SILVER / GOLD / TEST_FAILURES: dbt builds tables + views here
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA CLICKSTREAM_DB.SILVER        TO ROLE TRANSFORM;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA CLICKSTREAM_DB.GOLD          TO ROLE TRANSFORM;
GRANT USAGE, CREATE TABLE, CREATE VIEW ON SCHEMA CLICKSTREAM_DB.TEST_FAILURES TO ROLE TRANSFORM;

-- 5. Service user for dbt: no password, key-pair authentication only
CREATE USER IF NOT EXISTS DBT_USER
    TYPE = SERVICE
    DEFAULT_ROLE = TRANSFORM
    DEFAULT_WAREHOUSE = TRANSFORM_WH
    DEFAULT_NAMESPACE = CLICKSTREAM_DB.SILVER
    COMMENT = 'dbt service user (key-pair auth)';

GRANT ROLE TRANSFORM TO USER DBT_USER;

-- 6. Register the public key (injected by snow CLI via -D pub_key=...)
ALTER USER DBT_USER SET RSA_PUBLIC_KEY = '<% pub_key %>';

-- 7. Verify
DESC USER DBT_USER;
SHOW GRANTS TO ROLE TRANSFORM;