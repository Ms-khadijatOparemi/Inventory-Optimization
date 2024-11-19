This is still a work in process

use tech_electro;

#Create a database/schema - In MySql, a Database is the same as a schema
# Load Data

-- KNOW THE DATA
SELECT * FROM External_Factors LIMIT 5;
SELECT * FROM Inventory_data LIMIT 5;
SELECT * FROM Product_Information LIMIT 5;
SELECT * FROM sales_data LIMIT 5;

-- UNDERSTAND THE DATA STRUCTURE ( SHOW, DESCRIBE and DESC are functions that can be used to  understand the structure of a dataset)
SHOW COLUMNS FROM external_factors;
DESCRIBE product_information;
DESC sales_data;
-- Some variables are in the wrong data, we need to change them to the appropriate data type before we can do our analysis.
-- The Sales Date is in the wrong data type

-- CLEAN DATA 
# 1)  DATA TYPE- Change columns to the right data type
    # A) external_factors table
--     SalesDate Date, GDP DECIMAL(15'2), InflationRate DECIMAL(5,2), SeasonalFactor DECIMAL(5,2)
ALTER TABLE external_factors
ADD COLUMN New_Sales_Date DATE; -- Add a new column for date
SET SQL_SAFE_UPDATES = 0; -- turning off safe updates (This is to enable the next line of query to run)
UPDATE external_factors
SET New_Sales_Date = STR_TO_DATE(New_Sales_Date, '%d/%m/%Y');  -- Set the date to the desired format for the new date column
ALTER TABLE external_factors
DROP COLUMN  `Sales Date`; -- Drop the former date
ALTER TABLE external_factors
CHANGE COLUMN  New_Sales_Date Sales_Date DATE; -- Change the new date column name to the desired column name(usually the forner column date name)

ALTER TABLE external_factors
MODIFY COLUMN GDP DECIMAL(15,2);

ALTER TABLE external_factors
MODIFY COLUMN `Inflation Rate` DECIMAL(5,2);
ALTER TABLE external_factors
CHANGE COLUMN `Inflation Rate` inflation_rate DECIMAL;

ALTER TABLE external_factors
MODIFY COLUMN `Seasonal Factor` DECIMAL(5,2);
ALTER TABLE external_factors
CHANGE COLUMN `Seasonal Factor` seasonal_factor DECIMAL (5,2);

ALTER TABLE external_factors
DROP COLUMN  New_Sales_Date;

    # B) product_information table
--     ProductID INT NOT NULL, ProductCategory TEXT, Promotions ENUM('yes','no')
ALTER TABLE product_information 
ADD COLUMN New_Promotions ENUM('yes','no'); -- Add a new column for promotion
UPDATE product_information 
SET New_Promotions = CASE 
	WHEN Promotions = 'yes' THEN 'yes'
    when Promotions = 'no' Then 'no'
    ELSE NULL
    END;

ALTER TABLE product_information
DROP COLUMN  Promotions; -- Drop the former promotion
ALTER TABLE product_information
CHANGE COLUMN  New_Promotions Promotions ENUM('yes','no'); -- Change the new promotions column name to the desired column name(usually the forner column date name)
ALTER TABLE product_information
CHANGE COLUMN `Product ID` product_id INT NOT NULL;
ALTER TABLE product_information
CHANGE COLUMN `Product Category` product_category TEXT;



 # C) sales_data table
  -- ProductID INT NOT NULL, SalesDate Date, InventoryQuantity INT, ProductCost DECIMAL(5,2)
ALTER TABLE sales_data
CHANGE COLUMN `Product ID` product_id INT NOT NULL;

ALTER TABLE sales_data
ADD COLUMN New_Sales_Date DATE; -- Add a new column for date
SET SQL_SAFE_UPDATES = 0; -- turning off safe updates (This is to enable the next line of query to run)
UPDATE sales_data
SET New_Sales_Date = STR_TO_DATE(New_Sales_Date, '%d/%m/%Y');  -- Set the date to the desired format for the new date column
ALTER TABLE sales_data
DROP COLUMN  `Sales Date`; -- Drop the former date
ALTER TABLE sales_data
CHANGE COLUMN  New_Sales_Date Sales_Date DATE; -- Change the new date column name to the desired column name(usually the forner column date name)

ALTER  TABLE sales_data
MODIFY  COLUMN `Product Cost` DECIMAL(5,2); 

ALTER TABLE sales_data
CHANGE COLUMN `Product Cost` product_cost DECIMAL(5,2);

ALTER TABLE sales_data
CHANGE COLUMN `Inventory Quantity`  inventory_quantity INT


# 2 MISSING VALUES - Identify missing values using 'IS NULL' function
	# A) external_factors table
;
SELECT
 SUM(CASE WHEN Sales_Date IS NULL THEN 1 ELSE 0 END) AS missing_sales_date,
 SUM(CASE WHEN GDP IS NULL THEN 1 ELSE 0 END) AS missing_gdp,
 SUM(CASE WHEN inflation_rate IS NULL THEN 1 ELSE 0 END) AS missing_inflation_rate,
 SUM(CASE WHEN seasonal_factor IS NULL THEN 1 ELSE 0 END) AS missing_seasonal_factor
 FROM external_factors;

# B) product_information table
SELECT
 SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
 SUM(CASE WHEN product_category IS NULL THEN 1 ELSE 0 END) AS missing_product_category,
 SUM(CASE WHEN promotions IS NULL THEN 1 ELSE 0 END) AS missing_promotions
 FROM product_information;
 
# c) sales_data table 
 SELECT
 SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS missing_product_id,
 SUM(CASE WHEN inventory_quantity IS NULL THEN 1 ELSE 0 END) AS missing_inventory_quantity,
 SUM(CASE WHEN product_cost IS NULL THEN 1 ELSE 0 END) AS missing_product_cost,
 SUM(CASE WHEN Sales_Date IS NULL THEN 1 ELSE 0 END) AS missing_sales_date
 FROM sales_data;
 
 SELECT *
 FROM external_factors LIMIT 10;
 
 SELECT *
 FROM sales_data LIMIT 10

# 3) CHECK FOR DUPLICATE
-- external_factor
;
DELETE e1 FROM external_factors el
INNER JOIN(
 SELECT Sales_Date,
ROW_NUMBER() OVER(PARTITION BY Sales_Date ORDER BY Sales_Date) AS rn
FROM external_factors
) e2 ON e1.Sales_Dates = e2.Sales_Date
WHERE e2.rn> 1;

-- Prouct Data
DELETE p1 FROM product_information p1 
INNER JOIN(
 SELECT product_id,
ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY product_id) AS rn
FROM product_information
) p2 ON p1.product_id = p2.product_id
WHERE p2.rn> 1;

# DATA INTEGRATION	
-- First integrate the sales_data and product_information tables (both have the product_id column
CREATE VIEW sales_product_data AS
SELECT
 s.product_id,
 s.inventory_quantity,
 s.product_cost,
 s.Sales_Date,
 P.product_category, 
 P.Promotions 
 FROM sales_data s
 JOIN product_information p ON s.product_id= p.product_id;
 
 -- then integrate the sales_product_data and external_factors tables
 CREATE VIEW invt_data AS
 SELECT
 sp.product_id,
 sp.inventory_quantity,
 sp.product_cost,
 sp.Sales_Date,
 sp.product_category, 
 sp.Promotions ,
 e.GDP,
 e.inflation_rate,
 e.seasonal_factor 
 FROM sales_product_data sp
 LEFT JOIN external_factors e 
 ON sp.Sales_Date = e.Sales_Date;
          
##### DESCRIPTIVE ANALYSIS -Avg Sales, Medium Stock Level, Product Performance, Top selling and Least Selling Products, Frequency of Sold Out for High Demand, Seasonality pattern
--- BASIC STATISTICS

---  Average Sales (calculated as the product of "Inventory Quantity" and "Product Cost")
SELECT product_id,
AVG(inventory_quantity * product_cost) as avg_sales
FROM invt_data
GROUP BY product_id
ORDER BY avg_sales DESC;


--MEDIAN STOCK LEVEL (i.e "inventory_quantity")

SELECT product_id,
AVG(inventory_quantity) as median_stock
FROM(
  SELECT product_id,
		 inventory_quantity,
ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY inventory_quantity) AS row_num_asc,
ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY inventory_quantity DESC) AS row_num_desc
  FROM invt_data
) AS subquery
WHERE row_num_asc IN (row_num_desc, row_num_desc - 1, row_num_desc + 1)
GROUP BY product_id;

--- Product Performance Metric (Total Sales per Product)
SELECT product_id,
 ROUND(SUM(inventory_quantity * product_cost)) as total_sales
FROM invt_data
GROUP BY product_id
ORDER BY total_sales DESC;

--- Identify high-demand products based on average sales
WITH HighDemandProducts AS (
SELECT product_id, AVG(inventory_quantity) as avg_sales
 FROM ivnt_data
 GROUP BY product_id 
HAVING avg_sales > (
SELECT AVG(inventory_quantity) * 0.95 FROM sales_data
	)
)

---  Calculate stockout frequency  of high_demand products

SELECT s.product_id,
COUNT(*) as stockout_frequency
FROM invt_data s
WHERE s.product_id IN (SELECT product_id FROM HighDemandProducts)
AND s.inventory_quantity = 0
GROUP BY s.product_id;

--- INFLUENCE OF EXTERNAL FACTORS
--- GDP: The overall economic health and growth of a nation. Higher GDP leads to more more customers spending which leads to higher sales. 
---        A lower GDP signifies an economic downturn
--- INFLATION RATE: It is the rate at which the general level of prices of goods are rising and purchasing power is decreasing which might 
--- 					deter customers from purchasing non-essential items leading to reduced sales

--- GDP
SELECT product_id,
AVG(CASE WHEN 'GDP' > 0 THEN inventory_quantity ELSE NULL END) AS avg_sales_positive_gdp,
AVG(CASE WHEN 'GDP' <= 0 THEN inventory_quantity ELSE NULL END) AS avg_sales_not_positive_gdp
FROM invt_data
GROUP BY product_id
HAVING avg_sales_positive_gdp IS NOT NULL;

--- INFLATION RATE

SELECT product_id,
AVG(CASE WHEN 'inflation_rate' > 0 THEN inventory_quantity ELSE NULL END) AS avg_sales_positive_inflation_rate,
AVG(CASE WHEN 'inflation_rate' <= 0 THEN inventory_quantity ELSE NULL END) AS avg_sales_not_positive_inflation_rate
FROM invt_data
GROUP BY product_id
HAVING avg_sales_positive_inflation_rate IS NOT NULL;

-- INVENTORY OPTIMIZATION aims to ensure that the right amount of stock is available to meet customers demands while minimizing holding cost and potential stock out.
--- REORDER POINT- the level at which new order should be placed
--- Reorder point = Lead Time Demand + Safety Stock
--- Lead Time Demand = Rolling Agg Sales x Lead Time
--- Safety Stock = z Lead Time^-2 x Standard Deviation of Demand  
--- Z=1.645 
--- Therefore, Reorder point  =Rolling Agg Sales x Lead Time + z Lead Time^-2 x Standard Deviation of Demand  
--- ASSUMPTIONS :
    # 1) A constant lead time of 7 daysfor all products
     # 2)Aim for a 95% service level

     
WITH InventoryCalculations AS (
  SELECT product_id,
  AVG(rolling_avg_sales) AS avg_rolling_sales,
  AVG(rolling_variance) AS avg_variance
FROM(
SELECT product_id,
AVG(daily_sales) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_sales,
AVG(squared_diff) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_variance
FROM (
SELECT product_id,
 Sales_Date, inventory_quantity * product_cost as daily_sales,
 (inventory_quantity * product_cost - AVG(inventory_quantity * product_cost) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW))
*(inventory_quantity * product_cost - AVG(inventory_quantity * product_cost) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as squared
 FROM invt_data
  ) subquery
   ) subquery2
	 GROUP BY product_id
)
SELECT product_id,
avg_rolling_sales * 7 as lead_time_demand,
  1.645 * (avg_rolling_variance * 7) as safety_stock,
(avg_rolling_sales * 7)* (1.645*( average_rolling_variance * 7)) as reorder_point
FROM InventoryCalculations;

#AUTOMATION
---  Step 1 : create inventory optimization table
CREATE TABLE inventory_optimization (
	product_id INT,
 reorder_point DOUBLE
 );

---  Step 2 : Create Standard procedure to recalculate reorder point
DELIMITER //
CREATE PROCEDURE RecalculateReorderPoint(productID INT)
BEGIN
	DECLARE avgRollingSales DOUBLE;
    DECLARE avgRollingVariance DOUBLE;
    DECLARE LeadTimeDemand DOUBLE;
    DECLARE SafeyStock DOUBLE;
    DECLARE ReorderPoint DOUBLE;
  SELECT AVG(rolling_avg_sales), AVG(rolling_variance) 
    INTO avgRollingSales, avgRollingVariance
FROM(
SELECT product_id,
AVG(daily_sales) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_avg_sales,
AVG(squared_diff) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as rolling_variance
FROM (
SELECT product_id,
 Sales_Date, inventory_quantity * product_cost as daily_sales,
 (inventory_quantity * product_cost - AVG(inventory_quantity * product_cost) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW))
*(inventory_quantity * product_cost - AVG(inventory_quantity * product_cost) OVER (PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) as squared
 FROM invt_data
  ) InnerDerived
   ) OuterDerived;
SET LeadTimeDemand = avgRollingSales * 7;
SET SafetyStock = 1.645 * SQRT(avgRollingVariance * 7);
SET ReorderPoint = LeadTimeDemand * SafetyStock;

INSERT INTO inventory_optimization (product_id, reorder_point)
VALUES (product_id, reorder_point)
ON DUPLICATE KEY UPDATE reorder_point = ReorderPoint;
END // 
DELIMITER ;

---  Step 3 : make inventory_data a permanent table
CREATE TABLE Inventory_table AS SELECT* FROM Inventory_data;

---  Step 4 : Create the Triggers
DELIMITER //
CREATE TRIGGER AfterInsertUnifiedTable
AFTER INSERT ON Inventory_table
FOR EACH ROW
BEGIN
 CALL RecalculateReorderPoint(NEW.product_id);
 END //
 DELIMITER ;
 
 
 -- OVERSTOCKING AND UNDERSTOCKING
WITH RollingSales AS (
  SELECT product_id,
  sales_date,
AVG(inventory_quantITY * product_cost) OVER (PARTITION BY product_id ORDER BY sales_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)as rolling_avg_sales
FROM Inventory-TABLE
),
-- Calculate the number of days the product was out of stock
StockoutDays AS (
SELECT product_id,
 COUNT(*) as stockout_days
 FROM Inventory_table
 WHERE inventory_quantity = 0
 GROUP BY product_id
 
 -- Join the above CTEs with the main table to get the results
 SELECT f.product_id
 AVG(f.inventory_quantity * * f.product_cost) as avg_inventory_value,
 avg(rs.rollinga-avg_sales) as avg_rolling_sales,
   COALESCE(sd.stockout_days, 0) as stockout_days
FROM Inventory_table f
JOIN RollingSales rs ON f.product_id = rs.product_id AND f.Sales_Date = rs.Sales_Date
LEFT JOIN StockoutDays sd ON f.product_id = sd.product_id
GROUP BY f.product_id, sd.stockout_days;


-- MONITOR AND ADJUST incorprating stored procedures to monitor some variables about our data e.g inventory levels, sales trend, stockout frequency

-- Inventory Levels
DELIMITER //
CREATE PROCEDURE MonitorInventoryLevels()
BEGIN
SELECT product_id, AVG(inventory_quantity) AS AvgInventory
FROM Inventory_table
GROUP BY product_id
ORDER BY AvgInventory DESC;
END//
DELIMITER ;

-- Sales Trends
DELIMITER //
CREATE PROCEDURE SalesTrends()
BEGIN
SELECT product_id,Sales_Date,
AVG(inventory_quantity * product_cost) OVER(PARTITION BY product_id ORDER BY Sales_Date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS RollingSales
	FROM Inventory_table
		ORDER BY product_id,Sales_Date;
END//
DELIMITER ;

-- Stockout Freqencies
DELIMITER //
CREATE PROCEDURE MonitorStockout()
BEGIN
SELECT product_id, COUNT(*) AS StockoutDays
FROM Inventory_table
 WHERE inventory_quantity = 0
GROUP BY product_id
ORDER BY StockoutDays desc;
END//
DELIMITER ;

-- FEEDBACK LOOP

  -- Feedback Loop Establishment:
   -- Feedback Portal: Develop an online platform for stackholders to easily submit feedback on inventory performance and challenges.
   -- Review Meetings: Organize perioic sessions to discuss inventory system performance and gather direct insight.
   -- System Monitoring: Use established SQL proceures to track sysytem metrics, with deviations from expectations flagged for review.
   
  -- Refinement based on feedback
   -- Feedback Analysis: Regularly compile and scrutinize feedback to identify recuringthemes or pressing issues.
   -- Action Implementation: Prioritize and act on feedback to  adjust reorder point, safety stock levels and overall proesses.
   -- Change Communication: Inform stakeholders about changes, underscoring the valueof their feedback and ensuring transperebcy.
   
   -- INSIGHTS AND RECOMMENDATION
   
    -- General Insights:
    
    
     -- Inventory Descripancies : The initial stages of analysis revelved significant descripancies in inventory levels, with instances of both overstocking and understocking
       -- These inconsistencies were contributing to capital inefficiencies and customer dissatisfaction.
       
	-- Sales Trends and External Influences: The analysis indicate that sales trends werenotably influenced by various external factors.
     -- Recognising this patterns provide an opportunity to forecast demand more accurately.
     
	-- Suboptimal Inventory Levels: Through the inventory optimization analysis, it was evident that the existing inventory levels werenot optimized for current sales trends.
     -- Products was identified that had either close excess inventory.
     
     -- Recommendation:
       -- 1. Implement Dynamic Inventory Management: The company should transition from a ststic to a dynamic inventory management system
        --  Adjusting inventory based on real-time sales trends,seasonality and ecternal factors
	
       -- 2. Optimize Reorder Points and Saftety Stocks: Utilize the reorder points and safety stocks calculated during the analysis to to minimize stockouts and reduce excess inventory
        -- Regularly review these metrics to ensure they align with current market conditions.
        
	   -- 3. Enhance Pricing Strategy: Conduct a thorough reviewof product pricing strategieds especially for products identified as unprofitable.
        -- Consider factors such as competitor pricing, market demand, and product acquisition cost.
        
	  -- 4. Reduce Overstock : Identify products that are consistently overstocked and take steps to reduce their inventory levels.
       -- This could include promotional sales, discounts, or even discontinuing products with low sales performance.
       
	  -- 5. Establish A feedback loop: Develop a systematic approach to collect and analyze feedback from various stackholders.
       -- Use this feedback for continuos improvement and alighment with business objectives
       
	  -- 6. Regular Monitoring and Adjustment: Adopt a proactive appraoch to inventory management by regularly monitoring key metrics and making
       -- neccessary adjustments to inventory levels, order quantities, and safety stocks.
