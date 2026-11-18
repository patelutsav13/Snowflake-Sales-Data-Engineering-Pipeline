-- =============================================================================
-- FILE: 03_bronze_layer.sql
-- PURPOSE:
--   Create the BRONZE_SALES_RAW table and load the uploaded CSV file from
--   SALES_INTERNAL_STAGE using COPY INTO.
--
-- KEY DESIGN POINTS:
--   - Stores the raw uploaded records without removing duplicates so Bronze
--     acts as an untouched historical copy of the source file.
--   - Uses clean business columns so exact duplicate removal in Silver can be
--     performed directly with SELECT DISTINCT *.
--
-- WHERE TO RUN:
--   Snowsight SQL Worksheet (run after uploading the CSV file in Step 02).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SALES_WH;
USE DATABASE SALES_DB;
USE SCHEMA BRONZE;

-- 1. Create Raw Bronze Table
CREATE TABLE IF NOT EXISTS SALES_DB.BRONZE.BRONZE_SALES_RAW (
    order_id       VARCHAR(50),
    order_date     DATE,
    customer_id    VARCHAR(50),
    customer_name  VARCHAR(150),
    product_id     VARCHAR(50),
    product_name   VARCHAR(150),
    category       VARCHAR(100),
    region         VARCHAR(100),
    quantity       INTEGER,
    unit_price     NUMBER(10, 2),
    sales_amount   NUMBER(12, 2)
)
COMMENT = 'Bronze Layer: Raw sales records loaded from Snowflake Internal Stage (duplicates preserved)';

-- 2. Load CSV file(s) from Internal Stage into BRONZE_SALES_RAW
COPY INTO SALES_DB.BRONZE.BRONZE_SALES_RAW
FROM @SALES_DB.BRONZE.SALES_INTERNAL_STAGE
FILE_FORMAT = (FORMAT_NAME = 'SALES_DB.BRONZE.CSV_SALES_FORMAT')
PATTERN = '.*\.csv'
ON_ERROR = 'CONTINUE';

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Total rows loaded into Bronze (actual verified run: 82 rows)
SELECT COUNT(*) AS total_bronze_records
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW;

-- Preview first 10 raw records
SELECT *
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW
LIMIT 10;
