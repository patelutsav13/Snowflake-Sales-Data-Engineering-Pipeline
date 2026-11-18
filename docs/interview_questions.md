# Internship Interview Preparation – Q&A Guide

Use this guide to explain your **Snowflake Sales Data Engineering Pipeline** clearly and honestly in Data Engineering internship interviews.

---

## 1. 60-Second Project Pitch

> "I built a Sales Data Engineering Pipeline in Snowflake using a **Snowflake Internal Stage** and the **Medallion Architecture** (`BRONZE`, `SILVER`, and `GOLD` schemas inside `SALES_DB`). First, I uploaded the raw sales CSV file to `SALES_INTERNAL_STAGE` and loaded all 82 raw records into `BRONZE_SALES_RAW` using `COPY INTO`, keeping duplicates intact for auditing. Next, I created `SILVER_SALES_CLEANED` using `SELECT DISTINCT * FROM SALES_DB.BRONZE.BRONZE_SALES_RAW`, removing 2 exact duplicate rows to produce 80 clean rows with total revenue of 33,077.47. Finally, I built four Gold analytical tables (`GOLD_MONTHLY_SALES`, `GOLD_CATEGORY_SALES`, `GOLD_REGIONAL_SALES`, and `GOLD_TOP_PRODUCTS`) using SQL aggregations and ranking functions, and wrote validation queries to verify row counts and cross-layer revenue totals."

---

## 2. Common Interview Questions & Accurate Answers

### Q1. What is Snowflake, and why is it widely used?
**Answer:** Snowflake is a cloud data warehouse that separates **storage** and **compute**. You can resize Virtual Warehouses independently and configure `AUTO_SUSPEND` and `AUTO_RESUME` so compute only runs when queries execute.

### Q2. What is Medallion Architecture?
**Answer:** It is a three-layer data organization pattern:
- **Bronze (`BRONZE_SALES_RAW`):** Raw ingested data kept unchanged for auditing (`82` rows).
- **Silver (`SILVER_SALES_CLEANED`):** Deduplicated dataset ready for downstream queries (`80` rows).
- **Gold (`GOLD_*` tables):** Pre-aggregated analytical tables built for reporting and dashboards.

### Q3. Why did you keep duplicates in Bronze instead of deleting them during ingestion?
**Answer:** Bronze should stay an exact copy of the source file. Keeping raw data untouched makes it easy to audit what arrived and re-run Silver transformations later if business rules change.

### Q4. How did you remove duplicates in the Silver layer?
**Answer:** Since the duplicates in this dataset were exact row-level duplicates, I created `SILVER_SALES_CLEANED` using:
```sql
SELECT DISTINCT *
FROM SALES_DB.BRONZE.BRONZE_SALES_RAW;
```
This cleanly reduced the dataset from `82` rows in Bronze to `80` unique rows in Silver.

### Q5. What if a future dataset has partial duplicates (same `order_id` with different values) or NULL/dirty fields?
**Answer:** *(Great way to show production thinking without exaggerating what you built!)* In a production upgrade, I would:
1. Keep raw Bronze columns as `VARCHAR` and add ingestion metadata (`METADATA$FILENAME`, `ingested_at`).
2. Use `ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY ingested_at DESC)` in Silver to keep the latest record per order.
3. Add explicit `COALESCE()` defaults for optional text fields, `TRY_TO_DATE`/`TRY_TO_NUMBER` for safe type casting, and a quarantine table for invalid records.

### Q6. What is a Snowflake Internal Stage?
**Answer:** An Internal Stage is a storage location managed directly inside Snowflake where you can upload local CSV files via Snowsight and load them into tables using `COPY INTO`—without setting up external cloud storage.

### Q7. How did you verify that your pipeline worked properly?
**Answer:** I ran SQL validation queries (`06_data_validation.sql`) to compare Bronze (`82` rows) vs. Silver (`80` rows), inspect duplicate rows in Bronze, check for NULLs or non-positive numbers, confirm total Silver revenue (`33,077.47`), and verify that Gold summary tables reconcile with Silver revenue.

### Q8. Why did you configure `AUTO_SUSPEND = 60` and `AUTO_RESUME = TRUE` on `SALES_WH`?
**Answer:** To control cloud costs. The warehouse automatically pauses after 60 seconds of inactivity and resumes automatically when a new SQL query is submitted.
