-- =============================================================================
-- FILE: 03_bronze_layer.sql
-- PURPOSE:
--   Create the BRONZE_SALES_RAW raw landing table and load sample_sales.csv from
--   the Snowflake Internal Stage using COPY INTO.
--
-- WHY WE KEEP RAW DATA UNCHANGED IN BRONZE:
--   - All columns are stored as VARCHAR so unexpected values never break loading.
--   - Duplicate records are kept on purpose as an exact audit copy of the file.
--   - Metadata columns track the file name, row number, and load timestamp.
--
-- WHERE TO RUN:
--   Snowsight SQL Worksheet (run after uploading sample_sales.csv in Step 02).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SALES_WH;
USE DATABASE SALES_DB;
USE SCHEMA BRONZE;

-- 1. Create Raw Bronze Table
CREATE TABLE IF NOT EXISTS SALES_DB.BRONZE.BRONZE_SALES_RAW (
    order_id                VARCHAR(50),
    order_date              VARCHAR(50),
    customer_id             VARCHAR(50),
    customer_name           VARCHAR(150),
    product_id              VARCHAR(50),
    product_name            VARCHAR(150),
    category                VARCHAR(100),
    region                  VARCHAR(100),
    quantity                VARCHAR(50),
    unit_price              VARCHAR(50),
    sales_amount            VARCHAR(50),
    source_file_name        VARCHAR(500),
    source_file_row_number  NUMBER(38, 0),
    ingested_at             TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Bronze Layer: Raw sales data loaded directly from Snowflake Internal Stage';

-- 2. Load CSV file(s) from Internal Stage into BRONZE_SALES_RAW
COPY INTO SALES_DB.BRONZE.BRONZE_SALES_RAW (
    order_id,
    order_date,
    customer_id,
    customer_name,
    product_id,
    product_name,
    category,
    region,
    quantity,
    unit_price,
    sales_amount,
    source_file_name,
    source_file_row_number,
    ingested_at
)
FROM (
    SELECT
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        CURRENT_TIMESTAMP()
    FROM @SALES_DB.BRONZE.SALES_INTERNAL_STAGE
)
FILE_FORMAT = (FORMAT_NAME = 'SALES_DB.BRONZE.CSV_SALES_FORMAT')
PATTERN = '.*\.csv'
ON_ERROR = 'CONTINUE';

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Total rows loaded into Bronze
SELECT COUNT(*) AS total_bronze_records
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW;

-- Check loaded file summary
SELECT
    source_file_name,
    COUNT(*)         AS rows_loaded,
    MIN(ingested_at) AS loaded_at
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW
GROUP BY source_file_name;

-- Preview first 10 raw records
SELECT *
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW
ORDER BY source_file_row_number
LIMIT 10;
