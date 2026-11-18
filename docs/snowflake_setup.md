# Snowflake Setup & Execution Guide (Step-by-Step)

This guide explains how to set up Snowflake, upload the CSV file to the Snowflake Internal Stage, and run all 6 SQL scripts in Snowsight.

---

## Step 1: Create a Free Snowflake Trial Account

1. Go to [https://signup.snowflake.com/](https://signup.snowflake.com/).
2. Sign up for the 30-day free trial (no credit card required).
3. Choose **Standard Edition** and select a cloud region close to your location.
4. Activate your account via email and log in to **Snowsight**.
5. Confirm your active role is **`ACCOUNTADMIN`**.

---

## Step 2: Execute Scripts 01 and 02

In Snowsight, go to **Projects → Worksheets → `+` (SQL Worksheet)**.

### Run `sql/01_setup.sql`
- Creates:
  - Warehouse: `SALES_WH` (`XSMALL`, `AUTO_SUSPEND = 60`, `AUTO_RESUME = TRUE`)
  - Database: `SALES_DB`
  - Schemas: `BRONZE`, `SILVER`, `GOLD`

### Run Parts 1 & 2 of `sql/02_file_format_and_stage.sql`
- Creates `SALES_DB.BRONZE.CSV_SALES_FORMAT` and `SALES_DB.BRONZE.SALES_INTERNAL_STAGE`.
- Pause before running Part 3 (`LIST` and preview) until you upload the CSV file in Step 3.

---

## Step 3: Upload CSV File to Snowflake Internal Stage

1. In Snowsight's left sidebar, open **Catalog / Data → Databases**.
2. Navigate to **`SALES_DB` → `BRONZE` → `Stages` → `SALES_INTERNAL_STAGE`**.
3. Click **`+ Files`** (top-right), choose your sales CSV file, and click **Upload**.
4. Return to your worksheet for `sql/02_file_format_and_stage.sql` and run **Part 3**:
   - `LIST @SALES_DB.BRONZE.SALES_INTERNAL_STAGE;`
   - `SELECT ... FROM @SALES_DB.BRONZE.SALES_INTERNAL_STAGE LIMIT 10;`

---

## Step 4: Run the Medallion Pipeline (Scripts 03 to 06)

1. **`sql/03_bronze_layer.sql`**
   - Creates `SALES_DB.BRONZE.BRONZE_SALES_RAW` and runs `COPY INTO` from `SALES_INTERNAL_STAGE`.
   - **Confirmed execution result:** `82` raw rows loaded (including `2` exact duplicates).

2. **`sql/04_silver_layer.sql`**
   - Creates `SALES_DB.SILVER.SILVER_SALES_CLEANED` using:
     ```sql
     SELECT DISTINCT *
     FROM SALES_DB.BRONZE.BRONZE_SALES_RAW;
     ```
   - **Confirmed execution result:** `80` deduplicated rows (`2` exact duplicates removed).

3. **`sql/05_gold_layer.sql`**
   - Creates the 4 analytical tables in `SALES_DB.GOLD`:
     - `GOLD_MONTHLY_SALES`
     - `GOLD_CATEGORY_SALES`
     - `GOLD_REGIONAL_SALES`
     - `GOLD_TOP_PRODUCTS`
   - **Confirmed total revenue result:** `33,077.47`.

4. **`sql/06_data_validation.sql`**
   - Checks Bronze vs. Silver row counts, duplicate records in Bronze, NULL inspection in Silver, numeric sanity checks, and Silver vs. Gold revenue reconciliation.

---

## Common Beginner Issues & Quick Fixes

| Error Message | Cause | Quick Fix |
| :--- | :--- | :--- |
| `Object 'SALES_DB.BRONZE.SALES_INTERNAL_STAGE' does not exist` | Script 01 or 02 has not been run yet | Run `01_setup.sql` and `02_file_format_and_stage.sql` first |
| `Copy executed with 0 files processed` | CSV wasn't uploaded, or it was already loaded previously | Check `LIST @SALES_INTERNAL_STAGE`; `COPY INTO` automatically skips already-loaded files |
| `Insufficient privileges` | Active role lacks permissions | Switch your Snowsight role to `ACCOUNTADMIN` |
| `No active warehouse selected` | Warehouse not set in session | Run `USE WAREHOUSE SALES_WH;` |
