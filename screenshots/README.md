# Project Screenshots Checklist

After running the SQL scripts in Snowflake Snowsight, capture screenshots and save them in this folder to showcase your project on GitHub and in interviews.

## Recommended Screenshots

1. `01_database_schemas.png` – Snowsight sidebar showing `SALES_DB` with `BRONZE`, `SILVER`, and `GOLD` schemas.
2. `02_internal_stage_upload.png` – `SALES_INTERNAL_STAGE` showing `sample_sales.csv` uploaded.
3. `03_bronze_copy_into.png` – `COPY INTO` result showing `82` rows loaded into `BRONZE_SALES_RAW`.
4. `04_silver_cleaned.png` – Query output showing `80` cleaned rows in `SILVER_SALES_CLEANED` (and `'Unknown Customer'` handling).
5. `05_gold_tables.png` – Query results of `GOLD_MONTHLY_SALES`, `GOLD_CATEGORY_SALES`, `GOLD_REGIONAL_SALES`, and `GOLD_TOP_PRODUCTS`.
6. `06_validation_pass.png` – Output from `06_data_validation.sql` showing `PASS` on cross-layer revenue reconciliation.
