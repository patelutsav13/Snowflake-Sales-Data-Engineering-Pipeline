-- =============================================================================
-- FILE: 05_gold_layer.sql
-- PURPOSE:
--   Create 4 simple, business-ready analytical tables in the GOLD schema from
--   cleaned SILVER_SALES_CLEANED data:
--     1. GOLD_MONTHLY_SALES   - Monthly revenue and order trend
--     2. GOLD_CATEGORY_SALES  - Revenue breakdown by product category
--     3. GOLD_REGIONAL_SALES  - Revenue breakdown by region with performance tier
--     4. GOLD_TOP_PRODUCTS    - Top 10 products ranked by revenue
--
-- WHERE TO RUN:
--   Snowsight SQL Worksheet (run after 04_silver_layer.sql).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SALES_WH;
USE DATABASE SALES_DB;
USE SCHEMA GOLD;

-- -----------------------------------------------------------------------------
-- 1. GOLD_MONTHLY_SALES: Monthly revenue, orders, units sold & average order value
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE SALES_DB.GOLD.GOLD_MONTHLY_SALES AS
SELECT
    DATE_TRUNC('MONTH', order_date) AS sales_month,
    TO_CHAR(order_date, 'YYYY-MM')  AS year_month,
    COUNT(DISTINCT order_id)        AS total_orders,
    COUNT(DISTINCT customer_id)     AS total_customers,
    SUM(quantity)                   AS total_units_sold,
    ROUND(SUM(sales_amount), 2)     AS total_revenue,
    ROUND(AVG(sales_amount), 2)     AS average_order_value
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
GROUP BY
    DATE_TRUNC('MONTH', order_date),
    TO_CHAR(order_date, 'YYYY-MM')
ORDER BY sales_month;

-- -----------------------------------------------------------------------------
-- 2. GOLD_CATEGORY_SALES: Category revenue, units, share % and revenue rank
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE SALES_DB.GOLD.GOLD_CATEGORY_SALES AS
WITH category_totals AS (
    SELECT
        category,
        COUNT(DISTINCT order_id)    AS total_orders,
        SUM(quantity)               AS total_units_sold,
        ROUND(SUM(sales_amount), 2) AS total_revenue,
        ROUND(AVG(sales_amount), 2) AS average_order_value
    FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
    GROUP BY category
)
SELECT
    RANK() OVER (ORDER BY total_revenue DESC)                               AS category_rank,
    category,
    total_orders,
    total_units_sold,
    total_revenue,
    average_order_value,
    ROUND((total_revenue / NULLIF(SUM(total_revenue) OVER (), 0)) * 100, 2) AS revenue_share_pct
FROM category_totals
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------------
-- 3. GOLD_REGIONAL_SALES: Region revenue with CASE WHEN performance tier
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE SALES_DB.GOLD.GOLD_REGIONAL_SALES AS
WITH region_totals AS (
    SELECT
        region,
        COUNT(DISTINCT order_id)    AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customers,
        SUM(quantity)               AS total_units_sold,
        ROUND(SUM(sales_amount), 2) AS total_revenue,
        ROUND(AVG(sales_amount), 2) AS average_order_value
    FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
    GROUP BY region
),
overall_avg AS (
    SELECT AVG(total_revenue) AS avg_region_revenue
    FROM region_totals
)
SELECT
    RANK() OVER (ORDER BY r.total_revenue DESC) AS region_rank,
    r.region,
    r.total_orders,
    r.total_customers,
    r.total_units_sold,
    r.total_revenue,
    r.average_order_value,
    CASE
        WHEN r.total_revenue >= o.avg_region_revenue THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_tier
FROM region_totals r
CROSS JOIN overall_avg o
ORDER BY r.total_revenue DESC;

-- -----------------------------------------------------------------------------
-- 4. GOLD_TOP_PRODUCTS: Top 10 products ranked by total revenue
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TABLE SALES_DB.GOLD.GOLD_TOP_PRODUCTS AS
WITH product_totals AS (
    SELECT
        product_id,
        product_name,
        category,
        COUNT(DISTINCT order_id)    AS total_orders,
        SUM(quantity)               AS total_units_sold,
        ROUND(SUM(sales_amount), 2) AS total_revenue
    FROM SALES_DB.SILVER.SILVER_SALES_CLEANED
    GROUP BY product_id, product_name, category
)
SELECT
    RANK() OVER (ORDER BY total_revenue DESC) AS product_rank,
    product_id,
    product_name,
    category,
    total_orders,
    total_units_sold,
    total_revenue
FROM product_totals
ORDER BY total_revenue DESC, product_id ASC
LIMIT 10;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Overall Sales Summary KPIs
SELECT
    ROUND(SUM(sales_amount), 2) AS total_revenue,
    COUNT(DISTINCT order_id)    AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(AVG(sales_amount), 2) AS average_order_value
FROM SALES_DB.SILVER.SILVER_SALES_CLEANED;

-- Inspect all 4 Gold tables
SELECT * FROM SALES_DB.GOLD.GOLD_MONTHLY_SALES;
SELECT * FROM SALES_DB.GOLD.GOLD_CATEGORY_SALES;
SELECT * FROM SALES_DB.GOLD.GOLD_REGIONAL_SALES;
SELECT * FROM SALES_DB.GOLD.GOLD_TOP_PRODUCTS;
