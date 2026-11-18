-- =============================================================================
-- FILE: 04_silver_layer.sql
-- PURPOSE:
--   Create the SILVER_SALES_CLEANED table by removing exact duplicate rows
--   from SALES_DB.BRONZE.BRONZE_SALES_RAW using SELECT DISTINCT *.
--
-- WHY DEDUPLICATE IN SILVER INSTEAD OF MODIFYING BRONZE?
--   Bronze keeps the original raw records (including duplicates) as an audit
--   copy. Silver provides the deduplicated table that Gold analytics queries.
--
-- WHERE TO RUN:
--   Snowsight SQL Worksheet (run after 03_bronze_layer.sql).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SALES_WH;
USE DATABASE SALES_DB;
USE SCHEMA SILVER;

-- 1. Create Deduplicated Silver Table directly from Bronze
CREATE OR REPLACE TABLE SALES_DB.SILVER.SILVER_SALES_CLEANED AS
SELECT DISTINCT *
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Compare Bronze count vs. Silver count (actual verified run: 82 -> 80)
SELECT
    (SELECT COUNT(*) FROM SALES_DB.BRONZE.BRONZE_SALES_RAW)     AS bronze_rows,
    (SELECT COUNT(*) FROM SALES_DB.SILVER.SILVER_SALES_CLEANED) AS silver_rows;

-- Preview first 10 deduplicated Silver rows
SELECT *
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
ORDER BY order_date, order_id
LIMIT 10;
