# Enterprise Fleet Maintenance & Telemetry Operations Analytics

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2019%2B-CC292B?style=for-the-badge\&logo=microsoftsqlserver\&logoColor=white)](https://www.microsoft.com/sql-server)
[![Architecture](https://img.shields.io/badge/Architecture-Kimball%20Star%20Schema-blue?style=for-the-badge)](#data-architecture--my-modeling-approach)
[![Records Analyzed](https://img.shields.io/badge/Records%20Analyzed-92%2C000%2B-green?style=for-the-badge)](#core-kpi-snapshot)
[![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)](#technical-tooling)

An end-to-end SQL and business analytics project analyzing **92,000+ fleet maintenance and telemetry records**. The project transforms raw operational data into a dimensional **Kimball Star Schema** and uses advanced SQL techniques to identify maintenance cost drivers, fleet utilization patterns, and operational inefficiencies.

---

## Executive Summary

Across **92,000 fleet service events**, total maintenance expenditure reached **$95.95M**, with **295,345 downtime hours**. Dimensional and statistical analysis identified significant cost concentration across maintenance types, vehicle segments, and operating conditions.

* **Budget Concentration:** The top 25% highest-spending vehicles (Cost Quartile 1) accounted for **$76.15M (79.35%)** of total maintenance expenditure.
* **Engine Overhaul Cost:** Engine Overhauls represented **20.06% of service events (18,459 repairs)** but accounted for **77.05% ($73.93M)** of total maintenance expenditure, with an average cost of **$4,005.36 per overhaul**.
* **Fleet Type Breakdown:** Vans represented **55.27% of operations (50,850 trips)** and accounted for **$53.22M** in maintenance costs, compared with **$42.72M** across 41,150 truck trips.
* **Highway Exposure:** Highway operations represented **50.05% of all trips (46,052 events)** and generated **$48.17M** in cumulative maintenance expenditure.

---

## Core KPI Snapshot

| Metric                              | Measured Value       | Business Interpretation                                 |
| :---------------------------------- | :------------------- | :------------------------------------------------------ |
| **Total Fleet Operations**          | **92,000**           | Total operational records analyzed                      |
| **Total Maintenance Spend**         | **$95,956,435.87**   | Aggregate fleet maintenance expenditure                 |
| **Total Fleet Downtime**            | **295,345.79 hrs**   | Cumulative recorded downtime                            |
| **Average Operational Load**        | **23.77 Tons**       | Average payload carried per operation                   |
| **Quartile 1 Spend Share**          | **79.35% ($76.15M)** | Share of total spend from highest-cost quartile         |
| **Overhaul vs. Routine Multiplier** | **13.35x**           | Average overhaul cost compared with routine maintenance |

---

## Data Architecture & My Modeling Approach

The original dataset was stored as a flat staging table (`stg_fleet_raw`) containing 92,000 records. To improve analytical structure and reduce repeated descriptive attributes, I transformed the data into a **Kimball-style Star Schema** consisting of two dimension tables and one fact table.

### Key Engineering Decisions

* **Dim_Vehicle:** Extracted unique vehicle profiles so static attributes such as make, model, manufacture year, capacity, and vehicle type are stored once.
* **Dim_Telemetry:** Extracted distinct telemetry flag combinations (`failure_history`, `anomalies_detected`, `maintenance_required`) using `SELECT DISTINCT` and generated an integer surrogate key (`telemetry_id IDENTITY(1,1)`).
* **Fact_Fleet_Operations:** Centralized transactional measures including fuel consumption, load, operating hours, downtime, and maintenance cost, with foreign keys connecting the fact table to the dimension tables.

---

## In-Depth Business Analysis & Key Findings

### 1. Maintenance Type Imbalance & Failure Costs

Preventive services such as Oil Changes and Tire Rotations represented nearly **80% of maintenance volume**, but only around **23% of total expenditure**.

Engine Overhauls occurred less frequently but had a significantly higher average cost per event, indicating that major mechanical repairs were the primary driver of maintenance expenditure.

| Maintenance Type    | Total Events | Total Spend ($) | Avg Cost/Event ($) | Avg Downtime (Hrs) |
| :------------------ | :----------- | :-------------- | :----------------- | :----------------- |
| **Engine Overhaul** | 18,459       | $73,934,916.25  | $4,005.36          | 3.24               |
| **Oil Change**      | 41,488       | $12,407,583.81  | $299.06            | 3.22               |
| **Tire Rotation**   | 32,053       | $9,613,935.81   | $299.94            | 3.18               |

### 2. Vehicle Cost Quartile Segmentation (NTILE(4)) & Pareto Cost Distribution

Using the SQL `NTILE(4)` window function, fleet records were segmented into four spending quartiles to identify concentration of maintenance expenditure.

The highest-cost quartile accounted for **79.35% of total maintenance expenditure**, while the remaining three quartiles collectively accounted for **20.65%**.

| Quartile Tier            | Asset Count | Min Spend ($) | Max Spend ($) | Avg Spend ($) | Tier Total Spend ($) | % of Total Spend |
| :----------------------- | :---------- | :------------ | :------------ | :------------ | :------------------- | :--------------- |
| **Quartile 1 (Highest)** | 23,000      | $474.93       | $5,999.91     | $3,310.80     | $76,148,452.55       | **79.35%**       |
| **Quartile 2**           | 23,000      | $348.72       | $474.93       | $411.73       | $9,469,681.48        | **9.87%**        |
| **Quartile 3**           | 23,000      | $225.22       | $348.72       | $286.86       | $6,597,710.56        | **6.88%**        |
| **Quartile 4 (Lowest)**  | 23,000      | $100.00       | $225.21       | $162.63       | $3,740,591.28        | **3.90%**        |

### 3. Route Exposure & Operational Wear

* **Highway Dominance:** Highway operations represented **50.05% of all trips (46,052)** and generated **$48.17M** in maintenance expenditure.
* **Fuel Consumption:** Average fuel consumption remained relatively consistent across terrains at approximately **10.65 L/100km**.
* The analysis indicates that differences in maintenance expenditure cannot be explained by average fuel consumption alone and may require further investigation into factors such as operating hours, vehicle utilization, and maintenance patterns.

---

## Business Recommendations

1. **Condition-Based Maintenance:** Use telemetry indicators such as failure history, detected anomalies, and maintenance-required flags to support earlier identification of vehicles requiring attention.

2. **High-Cost Asset Review:** Prioritize the highest-spending vehicle segment for deeper maintenance and reliability analysis to identify recurring failure patterns and potential opportunities for cost reduction.

3. **Highway Fleet Analysis:** Investigate the relationship between highway operations, operating hours, vehicle utilization, and maintenance expenditure to identify potential operational efficiency opportunities.

---

## Repository Structure

```text
fleet-operations-sql-analytics/
│
├── README.md
│
└── sql/
    ├── 01_schema_and_etl.sql
    └── 02_fleet_analytics_queries.sql
```

### SQL Files

* **01_schema_and_etl.sql** — Star Schema DDL, constraints, staging transformation, and ETL logic.
* **02_fleet_analytics_queries.sql** — 24 business-focused analytical queries covering fleet performance, maintenance costs, downtime, utilization, and operational patterns.

---

## Technical Tooling

| Category                  | Technologies                                                                          |
| :------------------------ | :------------------------------------------------------------------------------------ |
| **Database**              | Microsoft SQL Server                                                                  |
| **Language**              | T-SQL                                                                                 |
| **Data Modeling**         | Kimball Dimensional Modeling / Star Schema                                            |
| **SQL Techniques**        | CTEs, Window Functions, `LAG`, `DENSE_RANK`, `NTILE`, Aggregations, Joins, Subqueries |
| **Data Transformation**   | SQL-based ETL / Staging                                                               |
| **Version Control**       | Git & GitHub                                                                          |
| **Business Intelligence** | Power BI                                                                              |

