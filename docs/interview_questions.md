# Internship Interview Preparation – Q&A Guide

Use this quick-reference guide to explain your **Snowflake Sales Data Engineering Pipeline** confidently during Data Engineering internship interviews.

---

## 1. 60-Second Project Pitch (Memorize the Flow)

> "I built an end-to-end Sales Data Engineering Pipeline in Snowflake using the **Medallion Architecture** (Bronze, Silver, and Gold layers). I uploaded a raw sales CSV file into a Snowflake Internal Stage and ingested it into the **Bronze** layer using `COPY INTO`, keeping all raw records and duplicates along with file metadata for auditing. In the **Silver** layer, I cleaned the data using SQL—removing exact duplicates with `ROW_NUMBER()`, handling missing customer names with `COALESCE()`, safely casting dates and numbers with `TRY_TO_DATE` and `TRY_TO_NUMBER`, and validating sales math. Finally, in the **Gold** layer, I created four analytical tables for monthly trends, category performance, regional performance, and top 10 products, and wrote a validation script to verify row counts, NULLs, and cross-layer revenue reconciliation."

---

## 2. Common Interview Questions & Simple Answers

### Q1. What is Snowflake, and why is it popular?
**Answer:** Snowflake is a cloud-based data warehouse that separates **storage** and **compute**. You can scale compute (Virtual Warehouses) up or down independently, and configure `AUTO_SUSPEND` and `AUTO_RESUME` so you only pay when queries are actually running.

### Q2. What is Medallion Architecture?
**Answer:** It is a three-layer data design pattern:
- **Bronze:** Raw, unchanged source data (for backup and auditing).
- **Silver:** Cleaned, deduplicated, validated, and typed data (single source of truth).
- **Gold:** Pre-aggregated business tables ready for dashboards and reporting.

### Q3. Why didn't you remove duplicates directly in the Bronze layer?
**Answer:** Bronze should always stay an exact historical copy of what arrived from the source. If a stakeholder questions a figure or if our cleaning rules change later, we can re-run the Silver transformation from Bronze without needing the source file again.

### Q4. Why did you store Bronze columns as `VARCHAR` instead of `DATE` or `NUMBER`?
**Answer:** Storing raw columns as text prevents `COPY INTO` from failing if a future CSV file contains a bad date or typo in a number. We safely cast types in Silver using `TRY_TO_DATE` and `TRY_TO_NUMBER`, which return `NULL` instead of crashing the query.

### Q5. How did you remove exact duplicate records in SQL?
**Answer:** I used the `ROW_NUMBER()` window function partitioned by all business columns and ordered deterministically by `ingested_at`, `source_file_name`, and `source_file_row_number`, then kept only `WHERE row_num = 1`.

### Q6. How did you handle missing (`NULL`) values?
**Answer:** First, my `CSV_SALES_FORMAT` converts empty CSV fields (`EMPTY_FIELD_AS_NULL = TRUE`) into SQL `NULL`. In Silver, optional descriptive fields like blank `customer_name` are replaced with `'Unknown Customer'` using `COALESCE()`, while rows missing critical fields like `order_id`, `order_date`, or `sales_amount` are filtered out.

### Q7. What is a Snowflake Internal Stage?
**Answer:** An Internal Stage is a built-in storage area managed directly by Snowflake where you can upload local files (like CSVs) and then load them into tables using `COPY INTO`—without needing external cloud storage.

### Q8. How did you verify that your pipeline results are accurate?
**Answer:** I created `06_data_validation.sql` to check:
1. Bronze row count vs. Silver row count (confirming only exact duplicates/invalid rows were removed).
2. Zero remaining `NULL` values in `SILVER_SALES_CLEANED`.
3. Zero negative quantities/prices or `quantity * unit_price` mismatches.
4. Cross-layer revenue reconciliation confirming that total revenue in `GOLD_MONTHLY_SALES`, `GOLD_CATEGORY_SALES`, and `GOLD_REGIONAL_SALES` equals `SILVER_SALES_CLEANED` with `0.00` variance.

### Q9. Why did you set `AUTO_SUSPEND = 60` and `AUTO_RESUME = TRUE` on `SALES_WH`?
**Answer:** To save Snowflake compute credits. The warehouse automatically pauses after 60 seconds of inactivity and wakes up automatically the next time someone runs a query.
