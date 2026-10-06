-- =========================================================================
-- SCRIPT 01: DATABASE CREATION, SCHEMA DDL & ETL INSERT PIPELINE
-- Database: Fleet_Maintenance_DB
-- Architecture: Kimball Star Schema (1 Fact, 2 Dimensions)
-- =========================================================================
CREATE DATABASE Fleet_Maintenance_DB;
USE Fleet_Maintenance_DB;

SELECT COUNT(*) AS total_rows FROM stg_fleet_raw;

-- =============================================
-- 1. Dim_Vehicle (Vehicle Master)
-- =============================================
CREATE TABLE Dim_Vehicle (
    vehicle_id INT PRIMARY KEY,
    make_and_model VARCHAR(100),
    year_of_manufacture INT,
    vehicle_type VARCHAR(50),
    load_capacity DECIMAL(10,2)
);
INSERT INTO Dim_Vehicle (vehicle_id, make_and_model, year_of_manufacture, vehicle_type, load_capacity)
SELECT DISTINCT vehicle_id, make_and_model, year_of_manufacture, vehicle_type, load_capacity
   FROM stg_fleet_raw; 

-- =============================================
-- 2. Dim_Telemetry (Telemetry & Failure Master)
-- =============================================
CREATE TABLE Dim_Telemetry (
  telemetry_id INT IDENTITY(1,1) PRIMARY KEY, failure_history VARCHAR(100), 
  anomalies_detected VARCHAR(50), maintenance_required VARCHAR(20) );

INSERT INTO Dim_Telemetry (failure_history, anomalies_detected, maintenance_required)
  SELECT DISTINCT failure_history, anomalies_detected, maintenance_required 
  FROM stg_fleet_raw;
    
-- =============================================
-- 3. Fact_Fleet_Operations (Operational Logs)
-- =============================================
CREATE TABLE Fact_Fleet_Operations ( 
  operation_id INT IDENTITY(1,1) PRIMARY KEY, vehicle_id INT, telemetry_id INT, last_maintenance_date DATE,
  route_info VARCHAR(100), maintenance_type VARCHAR(50), usage_hours DECIMAL(10,2), actual_load DECIMAL(10,2),
  fuel_consumption DECIMAL(10,2), downtime_maintenance DECIMAL(10,2), maintenance_cost DECIMAL(10,2),
  CONSTRAINT fk_fact_vehicle FOREIGN KEY (vehicle_id) REFERENCES Dim_Vehicle(vehicle_id),
  CONSTRAINT fk_fact_telemetry FOREIGN KEY (telemetry_id) REFERENCES Dim_Telemetry(telemetry_id));

 INSERT INTO Fact_Fleet_Operations (vehicle_id, telemetry_id, last_maintenance_date, route_info,
   maintenance_type, usage_hours, actual_load, fuel_consumption, downtime_maintenance,maintenance_cost)
 SELECT s.vehicle_id, t.telemetry_id, s.last_maintenance_date, s.route_info, s.maintenance_type,
 s.usage_hours, s.actual_load, s.fuel_consumption, s.downtime_maintenance, s.maintenance_cost 
 FROM stg_fleet_raw s JOIN Dim_Telemetry t
    ON s.failure_history = t.failure_history
   AND s.anomalies_detected = t.anomalies_detected
   AND s.maintenance_required = t.maintenance_required;  


SELECT TOP 5 * FROM Fact_Fleet_Operations; 
