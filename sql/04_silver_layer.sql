-- =============================================================================
-- FILE: 04_silver_layer.sql
-- PURPOSE:
--   Clean and transform raw data from BRONZE_SALES_RAW into the trusted
--   SILVER_SALES_CLEANED table.
--
-- CLEANING STEPS PERFORMED:
--   1. Remove exact duplicate records using ROW_NUMBER().
--   2. Handle blank/NULL customer names by replacing them with 'Unknown Customer'.
--   3. Safely convert order_date to DATE and quantity/prices to numeric types
--      using TRY_TO_DATE and TRY_TO_NUMBER.
--   4. Keep only valid rows (non-null IDs/dates, positive numbers, and accurate
--      sales_amount = quantity * unit_price).
--
-- WHY CLEAN IN SILVER INSTEAD OF CHANGING BRONZE?
--   Bronze stays an untouched backup of the original CSV file. If cleaning
--   rules ever change, we can re-run Silver cleanly from Bronze.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SALES_WH;
USE DATABASE SALES_DB;
USE SCHEMA SILVER;

-- 1. Create Cleaned Silver Table with proper data types
CREATE TABLE IF NOT EXISTS SALES_DB.SILVER.SILVER_SALES_CLEANED (
    order_id          VARCHAR(50)    NOT NULL,
    order_date        DATE           NOT NULL,
    customer_id       VARCHAR(50)    NOT NULL,
    customer_name     VARCHAR(150)   NOT NULL,
    product_id        VARCHAR(50)    NOT NULL,
    product_name      VARCHAR(150)   NOT NULL,
    category          VARCHAR(100)   NOT NULL,
    region            VARCHAR(100)   NOT NULL,
    quantity          INTEGER        NOT NULL,
    unit_price        NUMBER(10, 2)  NOT NULL,
    sales_amount      NUMBER(12, 2)  NOT NULL,
    source_file_name  VARCHAR(500),
    ingested_at       TIMESTAMP_NTZ,
    cleaned_at        TIMESTAMP_NTZ  DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Silver Layer: Cleaned, deduplicated, and type-cast sales transactions';

-- 2. Clear table before reload so this script can be re-run safely anytime
TRUNCATE TABLE SALES_DB.SILVER.SILVER_SALES_CLEANED;

-- 3. Deduplicate, clean, convert types, and insert valid records
INSERT INTO SALES_DB.SILVER.SILVER_SALES_CLEANED (
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
    ingested_at,
    cleaned_at
)
WITH deduplicated AS (
    -- Number identical rows (1, 2, ...); we will keep only row_num = 1
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                COALESCE(TRIM(order_id), ''),
                COALESCE(TRIM(order_date), ''),
                COALESCE(TRIM(customer_id), ''),
                COALESCE(TRIM(customer_name), ''),
                COALESCE(TRIM(product_id), ''),
                COALESCE(TRIM(product_name), ''),
                COALESCE(TRIM(category), ''),
                COALESCE(TRIM(region), ''),
                COALESCE(TRIM(quantity), ''),
                COALESCE(TRIM(unit_price), ''),
                COALESCE(TRIM(sales_amount), '')
            ORDER BY
                ingested_at ASC,
                source_file_name ASC,
                source_file_row_number ASC
        ) AS row_num
    FROM SALES_DB.BRONZE.BRONZE_SALES_RAW
),
cleaned AS (
    -- Handle blanks/NULLs and safely convert strings to DATE and NUMBER
    SELECT
        NULLIF(TRIM(order_id), '')                                    AS order_id,
        TRY_TO_DATE(TRIM(order_date), 'YYYY-MM-DD')                   AS order_date,
        NULLIF(TRIM(customer_id), '')                                 AS customer_id,
        COALESCE(NULLIF(TRIM(customer_name), ''), 'Unknown Customer') AS customer_name,
        NULLIF(TRIM(product_id), '')                                  AS product_id,
        COALESCE(NULLIF(TRIM(product_name), ''), 'Unknown Product')   AS product_name,
        COALESCE(NULLIF(TRIM(category), ''), 'Uncategorized')         AS category,
        COALESCE(NULLIF(TRIM(region), ''), 'Unknown')                 AS region,
        TRY_TO_NUMBER(TRIM(quantity), 10, 0)                          AS quantity,
        TRY_TO_NUMBER(TRIM(unit_price), 10, 2)                        AS unit_price,
        TRY_TO_NUMBER(TRIM(sales_amount), 12, 2)                      AS sales_amount,
        source_file_name,
        ingested_at
    FROM deduplicated
    WHERE row_num = 1
)
SELECT
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
    ingested_at,
    CURRENT_TIMESTAMP() AS cleaned_at
FROM cleaned
WHERE order_id IS NOT NULL
  AND order_date IS NOT NULL
  AND customer_id IS NOT NULL
  AND product_id IS NOT NULL
  AND quantity IS NOT NULL AND quantity > 0
  AND unit_price IS NOT NULL AND unit_price > 0
  AND sales_amount IS NOT NULL AND sales_amount > 0
  AND ABS(sales_amount - ROUND(quantity * unit_price, 2)) <= 0.01;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Compare Bronze count vs. Silver count
SELECT
    (SELECT COUNT(*) FROM SALES_DB.BRONZE.BRONZE_SALES_RAW) AS bronze_rows,
    (SELECT COUNT(*) FROM SALES_DB.SILVER.SILVER_SALES_CLEANED) AS silver_rows;

-- Verify blank customer names were replaced with 'Unknown Customer'
SELECT order_id, customer_id, customer_name, product_name, sales_amount
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
WHERE customer_name = 'Unknown Customer'
ORDER BY order_id;

-- Preview first 10 cleaned rows
SELECT *
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
ORDER BY order_date, order_id
LIMIT 10;
