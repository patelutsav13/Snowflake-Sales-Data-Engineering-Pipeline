# Project Screenshots Checklist

Save your actual Snowflake Snowsight screenshots in this folder to showcase your working pipeline on GitHub and during interviews.

## Recommended Screenshots

1. `01_database_schemas.png` – Snowsight sidebar showing `SALES_DB` with `BRONZE`, `SILVER`, and `GOLD` schemas.
2. `02_internal_stage_upload.png` – `SALES_INTERNAL_STAGE` showing the uploaded sales CSV file.
3. `03_bronze_copy_into.png` – `COPY INTO` / `COUNT(*)` result showing `82` rows in `BRONZE_SALES_RAW`.
4. `04_silver_deduplicated.png` – Query output showing `80` deduplicated rows in `SILVER_SALES_CLEANED`.
5. `05_gold_tables.png` – Query results for `GOLD_MONTHLY_SALES`, `GOLD_CATEGORY_SALES`, `GOLD_REGIONAL_SALES`, and `GOLD_TOP_PRODUCTS`.
6. `06_validation_revenue.png` – Validation query showing total revenue (`33,077.47`) and Bronze/Silver row count comparison.
