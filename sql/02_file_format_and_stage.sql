-- =============================================================================
-- FILE: 02_file_format_and_stage.sql
-- PURPOSE:
--   1. Create a CSV File Format telling Snowflake how to read our CSV file.
--   2. Create a Snowflake Internal Stage where we upload sample_sales.csv
--      directly from our computer inside Snowsight (100% free Snowflake trial).
--
-- HOW TO UPLOAD sample_sales.csv IN SNOWSIGHT:
--   Step 1: Run Parts 1 and 2 below to create the File Format and Stage.
--   Step 2: In Snowsight left sidebar, go to:
--           Catalog / Data -> Databases -> SALES_DB -> BRONZE -> Stages -> SALES_INTERNAL_STAGE
--   Step 3: Click "+ Files" (top-right), choose data/sample_sales.csv from your
--           computer, and click "Upload".
--   Step 4: Come back to this worksheet and run Part 3 (LIST & Preview).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SALES_WH;
USE DATABASE SALES_DB;
USE SCHEMA BRONZE;

-- -----------------------------------------------------------------------------
-- PART 1: Create CSV File Format
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT SALES_DB.BRONZE.CSV_SALES_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', 'N/A', '')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE
    COMMENT = 'CSV format rules for sales data files';

-- -----------------------------------------------------------------------------
-- PART 2: Create Snowflake Internal Stage
--   DIRECTORY = (ENABLE = TRUE) allows uploading files via the Snowsight UI.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE STAGE SALES_DB.BRONZE.SALES_INTERNAL_STAGE
    FILE_FORMAT = SALES_DB.BRONZE.CSV_SALES_FORMAT
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal Snowflake stage for uploading sample_sales.csv';

-- Check that both objects were created
SHOW FILE FORMATS IN SCHEMA SALES_DB.BRONZE;
SHOW STAGES IN SCHEMA SALES_DB.BRONZE;

-- -----------------------------------------------------------------------------
-- PART 3: Verify Uploaded File (RUN AFTER UPLOADING sample_sales.csv IN UI)
-- -----------------------------------------------------------------------------

-- List files inside the internal stage (should show sample_sales.csv)
LIST @SALES_DB.BRONZE.SALES_INTERNAL_STAGE;

-- Preview the first 10 rows directly from the staged CSV file
SELECT
    METADATA$FILENAME        AS source_file_name,
    METADATA$FILE_ROW_NUMBER AS file_row_number,
    $1  AS order_id,
    $2  AS order_date,
    $3  AS customer_id,
    $4  AS customer_name,
    $5  AS product_id,
    $6  AS product_name,
    $7  AS category,
    $8  AS region,
    $9  AS quantity,
    $10 AS unit_price,
    $11 AS sales_amount
FROM @SALES_DB.BRONZE.SALES_INTERNAL_STAGE
LIMIT 10;
