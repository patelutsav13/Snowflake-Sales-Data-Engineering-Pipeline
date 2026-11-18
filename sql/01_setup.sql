-- =============================================================================
-- FILE: 01_setup.sql
-- PURPOSE:
--   Create the Snowflake Virtual Warehouse, Database, and Medallion Schemas
--   (BRONZE, SILVER, GOLD) for the Sales Data Pipeline.
--
-- WHERE TO RUN:
--   Snowsight -> Projects -> Worksheets -> "+ SQL Worksheet" -> Paste & Run All.
--   Role: ACCOUNTADMIN (default in Snowflake free trial).
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- 1. Create Compute Warehouse (X-Small = lowest cost, auto-pauses after 60 sec)
CREATE WAREHOUSE IF NOT EXISTS SALES_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Compute warehouse for Sales Medallion Pipeline';

USE WAREHOUSE SALES_WH;

-- 2. Create Project Database
CREATE DATABASE IF NOT EXISTS SALES_DB
    COMMENT = 'End-to-End Sales Data Engineering Pipeline (Medallion Architecture)';

USE DATABASE SALES_DB;

-- 3. Create Medallion Architecture Schemas
CREATE SCHEMA IF NOT EXISTS SALES_DB.BRONZE
    COMMENT = 'Bronze Layer: Raw CSV data exactly as uploaded';

CREATE SCHEMA IF NOT EXISTS SALES_DB.SILVER
    COMMENT = 'Silver Layer: Cleaned, deduplicated, and validated sales data';

CREATE SCHEMA IF NOT EXISTS SALES_DB.GOLD
    COMMENT = 'Gold Layer: Aggregated analytics tables for business reporting';

-- Verification
SHOW WAREHOUSES LIKE 'SALES_WH';
SHOW DATABASES LIKE 'SALES_DB';
SHOW SCHEMAS IN DATABASE SALES_DB;
