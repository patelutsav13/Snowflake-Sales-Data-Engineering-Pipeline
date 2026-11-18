-- =============================================================================
-- FILE: 06_data_validation.sql
-- PURPOSE:
--   Run validation queries across Bronze, Silver, and Gold layers to verify:
--     1. Bronze vs. Silver record counts and exact duplicates removed
--     2. Exact duplicate rows present in BRONZE_SALES_RAW
--     3. NULL value inspection in BRONZE_SALES_RAW and SILVER_SALES_CLEANED
--     4. Numeric and sales amount sanity checks in SILVER_SALES_CLEANED
--     5. Total revenue check and Silver vs. Gold revenue reconciliation
--
-- WHERE TO RUN:
--   Snowsight SQL Worksheet (run after 05_gold_layer.sql).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SALES_WH;
USE DATABASE SALES_DB;

-- -----------------------------------------------------------------------------
-- CHECK 1: Compare Bronze vs. Silver Record Counts
-- -----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM SALES_DB.BRONZE.BRONZE_SALES_RAW)     AS bronze_total_records,
    (SELECT COUNT(*) FROM SALES_DB.SILVER.SILVER_SALES_CLEANED) AS silver_deduplicated_records,
    (SELECT COUNT(*) FROM SALES_DB.BRONZE.BRONZE_SALES_RAW)
      - (SELECT COUNT(*) FROM SALES_DB.SILVER.SILVER_SALES_CLEANED) AS duplicate_records_removed;

-- -----------------------------------------------------------------------------
-- CHECK 2: Inspect Exact Duplicate Records Found in BRONZE_SALES_RAW
-- -----------------------------------------------------------------------------
SELECT
    order_id,
    order_date,
    customer_id,
    product_id,
    quantity,
    unit_price,
    sales_amount,
    COUNT(*) AS occurrence_count
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW
GROUP BY
    order_id, order_date, customer_id, customer_name,
    product_id, product_name, category, region,
    quantity, unit_price, sales_amount
HAVING COUNT(*) > 1
ORDER BY order_id;

-- -----------------------------------------------------------------------------
-- CHECK 3: NULL Value Inspection in SILVER_SALES_CLEANED
-- -----------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN order_id      IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date    IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN customer_id   IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_customer_name,
    SUM(CASE WHEN product_id    IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN sales_amount  IS NULL THEN 1 ELSE 0 END) AS null_sales_amount
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED;

-- -----------------------------------------------------------------------------
-- CHECK 4: Basic Numeric Sanity Check in SILVER_SALES_CLEANED
-- -----------------------------------------------------------------------------
SELECT
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END)     AS non_positive_quantity_rows,
    SUM(CASE WHEN unit_price <= 0 THEN 1 ELSE 0 END)   AS non_positive_unit_price_rows,
    SUM(CASE WHEN sales_amount <= 0 THEN 1 ELSE 0 END) AS non_positive_sales_amount_rows
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED;

-- -----------------------------------------------------------------------------
-- CHECK 5: Total Revenue from SILVER_SALES_CLEANED
-- -----------------------------------------------------------------------------
SELECT
    ROUND(SUM(sales_amount), 2) AS total_silver_revenue,
    COUNT(*)                    AS total_silver_rows
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED;

-- -----------------------------------------------------------------------------
-- CHECK 6: Cross-Layer Revenue Reconciliation (Silver vs. Gold Tables)
-- -----------------------------------------------------------------------------
WITH silver_rev AS (
    SELECT ROUND(SUM(sales_amount), 2) AS silver_revenue
    FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
),
gold_rev AS (
    SELECT 'GOLD_MONTHLY_SALES'  AS table_name, ROUND(SUM(total_revenue), 2) AS gold_revenue FROM SALES_DB.GOLD.GOLD_MONTHLY_SALES
    UNION ALL
    SELECT 'GOLD_CATEGORY_SALES' AS table_name, ROUND(SUM(total_revenue), 2) AS gold_revenue FROM SALES_DB.GOLD.GOLD_CATEGORY_SALES
    UNION ALL
    SELECT 'GOLD_REGIONAL_SALES' AS table_name, ROUND(SUM(total_revenue), 2) AS gold_revenue FROM SALES_DB.GOLD.GOLD_REGIONAL_SALES
)
SELECT
    g.table_name,
    s.silver_revenue,
    g.gold_revenue,
    ROUND(g.gold_revenue - s.silver_revenue, 2) AS variance,
    CASE
        WHEN ABS(g.gold_revenue - s.silver_revenue) <= 0.01 THEN 'PASS'
        ELSE 'FAIL'
    END AS reconciliation_status
FROM gold_rev g
CROSS JOIN silver_rev s;
