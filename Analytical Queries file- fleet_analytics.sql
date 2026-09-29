-- =========================================================================
-- SCRIPT 02: BUSINESS ANALYTICS & EXECUTIVE REPORTING (Q1 - Q24)
-- Database: Fleet_Maintenance_DB
-- =========================================================================
   
   
-- =========================================================================
-- 1. FLEET & MAINTENANCE PERFORMANCE (Q1 - Q7)
-- =========================================================================

-- Q1. What is the total fleet size, total maintenance events, aggregate maintenance spend, 
-- average load carried, and total fleet downtime?

SELECT COUNT(DISTINCT vehicle_id) AS Total_Fleet_Size,
    COUNT(operation_id) AS Total_Service_events,
    ROUND(SUM(maintenance_cost), 2) AS Total_Maintenance_Spend,
    ROUND(AVG(actual_load), 2) AS Avg_Operational_Load,
    ROUND(SUM(downtime_maintenance), 2) AS Total_Downtime_Hours
FROM Fact_Fleet_Operations;
    


-- Q2. What is the total maintenance spend, average downtime and trip count per vehicle type?

SELECT v.vehicle_type, COUNT(f.operation_id) AS total_trips,
   ROUND(SUM(f.maintenance_cost), 2) AS total_maintenance_cost,
   ROUND(AVG(f.downtime_maintenance), 2) AS avg_downtime_hours
FROM Fact_Fleet_Operations f JOIN Dim_Vehicle v ON f.vehicle_id = v.vehicle_id
   GROUP BY v.vehicle_type ORDER BY total_maintenance_cost DESC;



-- Q3. What is the total maintenance cost, average fuel consumption, and trip volume across different
--   delivery routes?

SELECT route_info, COUNT(operation_id) AS total_trips,
 ROUND(SUM(maintenance_cost), 2) AS total_maintenance_cost,
 ROUND(AVG(fuel_consumption), 2) AS avg_fuel_consumption
FROM Fact_Fleet_Operations GROUP BY route_info ORDER BY total_maintenance_cost DESC;



-- Q4. Which trips operated beyond their rated load capacity and what was the overload amount?

SELECT f.operation_id, f.vehicle_id, v.vehicle_type, v.load_capacity, f.actual_load,
    ROUND(f.actual_load - v.load_capacity, 2) AS overload_amount, f.maintenance_cost   
    FROM Fact_Fleet_Operations f JOIN Dim_Vehicle v ON f.vehicle_id = v.vehicle_id
WHERE f.actual_load > v.load_capacity ORDER BY overload_amount DESC;


-- Q5. What is the total volume, total spend, and average repair cost across different maintenance types?

SELECT maintenance_type, COUNT(operation_id) AS total_events,
   ROUND(SUM(maintenance_cost), 2) AS total_spend, ROUND(AVG(maintenance_cost), 2) AS avg_cost_per_event,
   ROUND(AVG(downtime_maintenance), 2) AS avg_downtime_hours
FROM Fact_Fleet_Operations GROUP BY maintenance_type ORDER BY total_spend DESC;


-- Q6. How do different telemetry flag combinations (failure history, anomalies, maintenance alerts)
--  impact fleet downtime and total spend?
SELECT t.telemetry_id, t.failure_history,  t.anomalies_detected, t.maintenance_required,
    COUNT(f.operation_id) AS total_incidents,
    ROUND(AVG(f.downtime_maintenance), 2) AS avg_downtime_hours,
    ROUND(SUM(f.maintenance_cost), 2) AS total_maintenance_spend
FROM Fact_Fleet_Operations f JOIN Dim_Telemetry t ON f.telemetry_id = t.telemetry_id
    GROUP BY t.telemetry_id, t.failure_history,  t.anomalies_detected, t.maintenance_required
    ORDER BY total_maintenance_spend DESC;


-- Q7. Which operations had low operating hours (< 200 hrs) but incurred unexpectedly  
-- high repair costs (> $5,000)?
SELECT operation_id, vehicle_id, usage_hours, maintenance_cost FROM Fact_Fleet_Operations
 WHERE usage_hours < 200 AND maintenance_cost > 5000 ORDER BY maintenance_cost DESC;



  -- =======================================================================
-- 2. DATA TRANSFORMATION & TIME ANALYSIS (Q8 - Q12)
-- =========================================================================

-- Q8. How do we extract just the manufacturer/brand name from the concatenated 'make_and_model' column?
SELECT vehicle_id, make_and_model, 
LEFT(make_and_model, CHARINDEX(' ', make_and_model + ' ') - 1) AS vehicle_brand
   FROM Dim_Vehicle;


-- Q9. How do we extract the specific model/variant name (excluding the brand)
--  from the 'make_and_model' column?
SELECT vehicle_id, make_and_model,
  TRIM(SUBSTRING(make_and_model, CHARINDEX(' ', make_and_model + ' ') + 1, LEN(make_and_model)))
  AS model_variant FROM Dim_Vehicle;


-- Q10. What is the total volume of maintenance services conducted each year across the fleet?
SELECT YEAR(last_maintenance_date) AS service_year,
    COUNT(operation_id) AS total_services FROM Fact_Fleet_Operations
GROUP BY YEAR(last_maintenance_date) ORDER BY service_year ASC;
  

-- Q11. What is the total maintenance expenditure for each calendar month and year across the fleet?
SELECT YEAR(last_maintenance_date) AS service_year, MONTH(last_maintenance_date) AS month_number,
  DATENAME(MONTH, last_maintenance_date) AS month_name,
  ROUND(SUM(maintenance_cost), 2) AS total_spend FROM Fact_Fleet_Operations
GROUP BY YEAR(last_maintenance_date),MONTH(last_maintenance_date), DATENAME(MONTH, last_maintenance_date)
   ORDER BY service_year ASC, month_number ASC;


-- Q12. What was the vehicle's age (in years) at the time of each maintenance event?
SELECT f.operation_id, f.vehicle_id, v.year_of_manufacture,
    YEAR(f.last_maintenance_date) AS service_year,
DATEDIFF(YEAR, DATEFROMPARTS(v.year_of_manufacture, 1, 1), f.last_maintenance_date) AS vehicle_age_years
    FROM Fact_Fleet_Operations f JOIN Dim_Vehicle v ON f.vehicle_id = v.vehicle_id
    ORDER BY vehicle_age_years DESC;

  

-- =========================================================================
-- 3. ADVANCED BUSINESS ANALYSIS (Q13 - Q18)
-- =========================================================================

-- Q13. Which vehicles have a total maintenance cost strictly higher than the fleet-wide 
-- average vehicle maintenance spend?
SELECT  vehicle_id, ROUND(SUM(maintenance_cost), 2) AS total_vehicle_spend
  FROM Fact_Fleet_Operations GROUP BY vehicle_id HAVING SUM(maintenance_cost) > (
      SELECT AVG(total_vehicle_spend) FROM 
    ( SELECT SUM(maintenance_cost) AS total_vehicle_spend
      FROM Fact_Fleet_Operations GROUP BY vehicle_id ) AS fleet_avg )
ORDER BY total_vehicle_spend DESC;
 

-- Q14. Are there any registered vehicles in Dim_Vehicle that have zero logged maintenance 
-- operations in Fact_Fleet_Operations?
SELECT v.vehicle_id, v.make_and_model, v.vehicle_type
     FROM Dim_Vehicle v WHERE NOT EXISTS (
SELECT 1 FROM Fact_Fleet_Operations f WHERE f.vehicle_id = v.vehicle_id );


-- Q15. How can we classify telemetry health into 'Critical', 'Warning' or 'Healthy'
--  using binary failure and anomaly indicators?
SELECT f.operation_id, f.vehicle_id, t.failure_history, t.anomalies_detected, t.maintenance_required,
    CASE 
        WHEN t.maintenance_required = 1 AND (t.failure_history = 1 OR t.anomalies_detected = 1)
            THEN 'Critical'
        WHEN t.maintenance_required = 1 OR t.anomalies_detected = 1 OR t.failure_history = 1
            THEN 'Warning'
        ELSE 'Healthy'
    END AS telemetry_risk_status
FROM Fact_Fleet_Operations f
JOIN Dim_Telemetry t ON f.telemetry_id = t.telemetry_id;

-- Q16. What is the distribution of trip health statuses (Critical, Warning, Healthy) 
-- across different vehicle types?
WITH CategorizedTrips AS (
  SELECT v.vehicle_type,
    CASE 
    WHEN t.maintenance_required = 1 AND (t.failure_history = 1 OR t.anomalies_detected = 1)THEN 'Critical'
    WHEN t.maintenance_required = 1 OR t.anomalies_detected = 1 OR t.failure_history = 1 THEN 'Warning'
    ELSE 'Healthy' END AS trip_status    
    FROM Fact_Fleet_Operations f
    JOIN Dim_Telemetry t ON f.telemetry_id = t.telemetry_id
    JOIN Dim_Vehicle v ON f.vehicle_id = v.vehicle_id )
SELECT vehicle_type, COUNT(*) AS total_trips,
    SUM(CASE WHEN trip_status = 'Critical' THEN 1 ELSE 0 END) AS critical_trips,
    SUM(CASE WHEN trip_status = 'Warning' THEN 1 ELSE 0 END) AS warning_trips,
    SUM(CASE WHEN trip_status = 'Healthy' THEN 1 ELSE 0 END) AS healthy_trips
FROM CategorizedTrips GROUP BY vehicle_type ORDER BY critical_trips DESC;

-- Q17. How are fleet operations distributed across cost tiers('Low Cost', 'Moderate Cost', 'High Cost'),
-- and what is the total spend in each?
WITH CostBandedOperations AS (
    SELECT operation_id, vehicle_id, maintenance_cost,
        CASE 
            WHEN maintenance_cost >= 1000 THEN 'High Cost'
            WHEN maintenance_cost >= 400 THEN 'Moderate Cost'
            ELSE 'Low Cost'
        END AS cost_tier
    FROM Fact_Fleet_Operations )
SELECT cost_tier, COUNT(operation_id) AS total_operations,
    ROUND(SUM(maintenance_cost), 2) AS total_tier_spend, 
    ROUND(AVG(maintenance_cost), 2) AS avg_tier_spend
FROM CostBandedOperations GROUP BY cost_tier ORDER BY total_tier_spend DESC;


-- Q18. What percentage of the overall fleet maintenance budget does each individual 
-- high-impact vehicle represent?
SELECT f.operation_id, f.vehicle_id, v.vehicle_type, f.maintenance_cost,
    CAST((f.maintenance_cost * 100.0) / (SELECT SUM(maintenance_cost) FROM Fact_Fleet_Operations)
    AS DECIMAL(6, 4)) AS pct_of_total_fleet_spend
FROM Fact_Fleet_Operations f JOIN Dim_Vehicle v ON f.vehicle_id = v.vehicle_id
ORDER BY pct_of_total_fleet_spend DESC;


 -- ========================================================================
-- 4. RANKING & COST SEGMENTATION (Q19 - Q21)
-- =========================================================================

-- Q19. What are the Top 3 most expensive vehicles within  each vehicle type based on maintenance spend?
WITH RankedVehicles AS (
  SELECT f.operation_id, f.vehicle_id, v.vehicle_type, v. make_and_model, f.maintenance_cost,
      DENSE_RANK() OVER (PARTITION BY v.vehicle_type ORDER BY f.maintenance_cost DESC) AS cost_rank
      FROM Fact_Fleet_Operations f JOIN Dim_Vehicle v ON f.vehicle_id = v.vehicle_id)
  SELECT vehicle_type, vehicle_id, make_and_model,maintenance_cost, cost_rank
FROM RankedVehicles WHERE cost_rank <= 3 ORDER BY vehicle_type, cost_rank;


-- Q20. How can we bucket all vehicles into 4 cost quartiles (Top 25% spenders to lowest 25%),
--  and what are the min/max limits for each?
WITH VehicleQuartiles AS (
    SELECT operation_id, vehicle_id, maintenance_cost,
    NTILE(4) OVER (ORDER BY maintenance_cost DESC) AS cost_quartile
    FROM Fact_Fleet_Operations )
SELECT cost_quartile, COUNT(vehicle_id) AS total_vehicles,
    CAST(MIN(maintenance_cost) AS DECIMAL(10, 2)) AS min_spend_in_tier,
    CAST(MAX(maintenance_cost) AS DECIMAL(10, 2)) AS max_spend_in_tier,
    CAST(AVG(maintenance_cost) AS DECIMAL(10, 2)) AS avg_spend_in_tier,
    CAST(SUM(maintenance_cost) AS DECIMAL(10, 2)) AS Total_spend_in_tier
FROM VehicleQuartiles GROUP BY cost_quartile ORDER BY cost_quartile ASC;
    

-- Q21. How do individual operational routes rank based on total maintenance downtime
-- and what is their corresponding financial impact?
SELECT route_info, COUNT(vehicle_id) AS total_vehicles_serviced,
    CAST(SUM(downtime_maintenance) AS DECIMAL(10, 2)) AS total_downtime_hours,
    CAST(AVG(downtime_maintenance) AS DECIMAL(10, 2)) AS avg_downtime_per_trip,
    CAST(SUM(maintenance_cost) AS DECIMAL(10, 2)) AS total_route_maintenance_cost,
    DENSE_RANK() OVER (ORDER BY SUM(downtime_maintenance) DESC
    ) AS downtime_rank
FROM Fact_Fleet_Operations  GROUP BY route_info ORDER BY downtime_rank ASC;


-- =========================================================================
-- 5. TIME-SERIES DELTAS & EXECUTIVE PORTFOLIO CAPSTONES (Q22 - Q24)
-- =========================================================================

-- Q22. How does the total maintenance spend on each service date compare to the immediately
--  preceding service date (day-over-day delta)?
WITH DailySpend AS (
   SELECT last_maintenance_date, COUNT(vehicle_id) AS vehicles_serviced,
      CAST(SUM(maintenance_cost) AS DECIMAL(12, 2)) AS daily_total_spend
      FROM Fact_Fleet_Operations GROUP BY last_maintenance_date )
   SELECT last_maintenance_date, vehicles_serviced, daily_total_spend,
      LAG(daily_total_spend, 1) OVER (ORDER BY last_maintenance_date ASC) AS previous_day_spend,
      CAST(daily_total_spend - LAG(daily_total_spend, 1) OVER (ORDER BY last_maintenance_date ASC)
      AS DECIMAL(12, 2) ) AS spend_difference,
   CASE 
      WHEN LAG(daily_total_spend, 1) OVER (ORDER BY last_maintenance_date ASC) IS NULL THEN 'Baseline'
      WHEN daily_total_spend > LAG(daily_total_spend, 1) OVER (ORDER BY last_maintenance_date ASC) THEN 'Spend Increased'
      WHEN daily_total_spend < LAG(daily_total_spend, 1) OVER (ORDER BY last_maintenance_date ASC) THEN 'Spend Decreased'
        ELSE 'No Change'
    END AS trend_direction
FROM DailySpend ORDER BY last_maintenance_date ASC;


-- Q23. What is the maintenance cost per operating hour for each vehicle and
--  which vehicles exceed the overall fleet hourly benchmark?
WITH VehicleHourlyEfficiency AS (
     SELECT vehicle_id,route_info, usage_hours,maintenance_cost,
           CAST( maintenance_cost / NULLIF(usage_hours, 0) AS DECIMAL(10, 2)
           ) AS cost_per_operating_hour FROM Fact_Fleet_Operations )
     SELECT vehicle_id,route_info, usage_hours,maintenance_cost, cost_per_operating_hour
          FROM VehicleHourlyEfficiency WHERE cost_per_operating_hour > 
          (SELECT AVG(cost_per_operating_hour) FROM VehicleHourlyEfficiency )
     ORDER BY cost_per_operating_hour DESC;


-- Q24. Which top 5 older vehicles (manufactured <= 2018) with logged telemetry alerts
--  demonstrated the lowest maintenance expenditure?
SELECT TOP 5  f.vehicle_id, v.make_and_model, v.vehicle_type, v.year_of_manufacture,
    f.maintenance_cost,  f.downtime_maintenance,t.failure_history, t.anomalies_detected,
    'High Cost-Efficiency / Retain' AS operational_status
FROM Fact_Fleet_Operations f
    JOIN Dim_Vehicle v ON f.vehicle_id = v.vehicle_id
    JOIN Dim_Telemetry t ON f.telemetry_id = t.telemetry_id
    WHERE v.year_of_manufacture <= 2018
AND (t.failure_history = 1 OR t.anomalies_detected = 1) ORDER BY f.maintenance_cost ASC;