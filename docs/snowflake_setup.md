# Snowflake Setup & Execution Guide (Step-by-Step)

This guide walks you through creating your free Snowflake trial account, uploading `data/sample_sales.csv` to the Snowflake Internal Stage, and running all 6 SQL scripts in Snowsight.

---

## Step 1: Create a Free Snowflake Trial Account

1. Go to [https://signup.snowflake.com/](https://signup.snowflake.com/).
2. Enter your name, email, and company/college name (no credit card required for the 30-day free trial).
3. Choose **Standard Edition** and pick the default cloud region closest to your location.
4. Activate your account from the verification email and sign in to **Snowsight** (Snowflake's web interface).
5. Confirm your role in the top-left / top-right role switcher is **`ACCOUNTADMIN`**.

---

## Step 2: Execute Scripts 01 and 02

In Snowsight, click **Projects → Worksheets → `+` (SQL Worksheet)** to open a worksheet.

### Run `sql/01_setup.sql`
- Paste the contents of `sql/01_setup.sql` and click **Run All**.
- Creates:
  - Warehouse: `SALES_WH` (`XSMALL`, auto-suspend after 60 seconds, auto-resume enabled)
  - Database: `SALES_DB`
  - Schemas: `BRONZE`, `SILVER`, `GOLD`
- **How to verify:** The `SHOW` queries at the bottom list `SALES_WH`, `SALES_DB`, and all 3 schemas.

### Run Parts 1 & 2 of `sql/02_file_format_and_stage.sql`
- Open a new worksheet, paste `sql/02_file_format_and_stage.sql`, and run **Part 1** (`CSV_SALES_FORMAT`) and **Part 2** (`SALES_INTERNAL_STAGE`).
- Wait before running Part 3 (`LIST` and `SELECT`) until you upload the CSV in Step 3 below!

---

## Step 3: Upload `sample_sales.csv` to Snowflake Internal Stage

1. In Snowsight's left sidebar, click **Catalog** (or **Data**) → **Databases**.
2. Expand **`SALES_DB`** → **`BRONZE`** → **`Stages`** → click **`SALES_INTERNAL_STAGE`**.
3. Click the blue **`+ Files`** button in the top-right corner.
4. Click **Browse**, select `data/sample_sales.csv` from your computer, and click **Upload**.
5. Go back to your worksheet for `sql/02_file_format_and_stage.sql` and run **Part 3**:
   - `LIST @SALES_DB.BRONZE.SALES_INTERNAL_STAGE;` → should list `sample_sales.csv`.
   - `SELECT ... FROM @SALES_DB.BRONZE.SALES_INTERNAL_STAGE LIMIT 10;` → should preview the first 10 rows.

---

## Step 4: Run the Medallion Pipeline (Scripts 03 to 06)

Run each remaining script in order inside Snowsight SQL Worksheets:

1. **`sql/03_bronze_layer.sql`**
   - Creates `SALES_DB.BRONZE.BRONZE_SALES_RAW` and loads `sample_sales.csv` using `COPY INTO`.
   - **Expected result:** `82` rows loaded (including the 2 exact duplicates).

2. **`sql/04_silver_layer.sql`**
   - Creates `SALES_DB.SILVER.SILVER_SALES_CLEANED`, removes the 2 exact duplicate rows, replaces the 2 blank customer names with `'Unknown Customer'`, and converts dates and numbers safely.
   - **Expected result:** `80` cleaned rows in `SILVER_SALES_CLEANED`.

3. **`sql/05_gold_layer.sql`**
   - Creates the 4 analytical tables in `SALES_DB.GOLD`:
     - `GOLD_MONTHLY_SALES`
     - `GOLD_CATEGORY_SALES`
     - `GOLD_REGIONAL_SALES`
     - `GOLD_TOP_PRODUCTS`
   - **Expected result:** All 4 tables populated dynamically from `SILVER_SALES_CLEANED`.

4. **`sql/06_data_validation.sql`**
   - Runs 6 validation checks comparing Bronze vs. Silver counts, duplicate rows, NULL counts, math accuracy, and Silver-to-Gold revenue totals.
   - **Expected result:** `0` NULLs in Silver, `0` math mismatches, and `PASS` on every Gold revenue reconciliation row.

---

## Common Beginner Issues & Quick Fixes

| Error Message | Cause | Quick Fix |
| :--- | :--- | :--- |
| `Object 'SALES_DB.BRONZE.SALES_INTERNAL_STAGE' does not exist` | Script 01 or 02 was not run yet | Run `01_setup.sql` and `02_file_format_and_stage.sql` first |
| `Copy executed with 0 files processed` | Either CSV wasn't uploaded, OR it was already loaded once | Check `LIST @SALES_INTERNAL_STAGE`; remember `COPY INTO` skips already-loaded files by design |
| `Insufficient privileges` | Wrong active role | Switch your Snowsight role to `ACCOUNTADMIN` |
| `No active warehouse selected` | Warehouse context not set | Run `USE WAREHOUSE SALES_WH;` at the top of the worksheet |
