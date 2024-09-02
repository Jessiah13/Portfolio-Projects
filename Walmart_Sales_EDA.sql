/*
Walmart Sales Data Exploration

- Investigate the data and measure the statistics.
- Analyze measurements to draw insights and possible reccommendations.

*/


SELECT *
FROM projects.walmart_sales;

# Check columns 
SHOW COLUMNS 
FROM projects.walmart_sales;

# Date column appears to be text format.

SELECT str_to_date(`Date`, '%d-%m-%Y')  as  formatted_date
FROM projects.walmart_sales;

UPDATE projects.walmart_sales
SET `Date` = str_to_date(`Date`, '%d-%m-%Y');

# Checking for duplicates
# We need to create a unique_id column given as there is no PRIMARY KEY in this dataset.

WITH CTE_dup_check AS (
SELECT *, 
	ROW_NUMBER() OVER(PARTITION BY unique_id ORDER BY unique_id) as row_num
FROM(
	SELECT *, CONCAT(Store, '-', `Date`) as unique_id
	FROM projects.walmart_sales
    ) as unique_table
) 
SELECT * 
FROM CTE_dup_check
WHERE row_num > 1;
-- 0 rows were returned, there are no duplicates in this dataset


# Checking for nulls
SELECT
	SUM(CASE WHEN Store IS NULL THEN 1 ELSE 0 END) AS Store_null_count, 
	SUM(CASE WHEN `Date` IS NULL THEN 1 ELSE 0 END) AS Date_null_count, 
	SUM(CASE WHEN Weekly_Sales IS NULL THEN 1 ELSE 0 END) AS Weekly_Sales_null_count, 
	SUM(CASE WHEN Holiday_Flag IS NULL THEN 1 ELSE 0 END) AS Holiday_Flag_null_count, 
	SUM(CASE WHEN Temperature IS NULL THEN 1 ELSE 0 END) AS Temperature_null_count, 
	SUM(CASE WHEN Fuel_Price IS NULL THEN 1 ELSE 0 END) AS Fuel_Price_null_count, 
	SUM(CASE WHEN CPI IS NULL THEN 1 ELSE 0 END) AS CPI_null_count, 
	SUM(CASE WHEN Unemployment IS NULL THEN 1 ELSE 0 END) AS Unemployment_null_count 
FROM projects.walmart_sales;
-- 0 returned for all columns, there are no nulls in this dataset


--------------------------------------------------------------------------------------------


# What is the date range? 
SELECT MIN(YEAR(`DATE`)) as min_year, MAX(YEAR(`DATE`)) as max_year
FROM projects.walmart_sales;
-- dataset spans from 2010 - 2012

# What is the higest, lowest and avareage weekly_sales
SELECT MAX(Weekly_Sales) as max_week_sales, 
	MIN(Weekly_Sales) as min_week_sales, 
    AVG(Weekly_Sales) avg_week_sales
FROM projects.walmart_sales;

# Sticking with the Max, min and avg weekly sales, broken out by store
# Which Store has the highest   avg sales
SELECT Store, MAX(Weekly_Sales) as max_week_sales, 
	MIN(Weekly_Sales) as min_week_sales, 
    ROUND(AVG(Weekly_Sales),2) avg_week_sales,
    DENSE_RANK() OVER(ORDER BY AVG(Weekly_Sales) DESC) as store_avg_sales_rank
FROM projects.walmart_sales
GROUP BY Store;


# Which month is the best in terms of avraege sales per store
WITH CTE_best_month AS (
SELECT Store, MONTHNAME(`Date`) as months, MONTH(`Date`) as month_num, 
	ROUND(SUM(Weekly_Sales),2) total_month_sales, 
    ROUND(AVG(Weekly_Sales),2) as avg_month_sales,
	DENSE_RANK() OVER(PARTITION BY Store ORDER BY AVG(Weekly_Sales) DESC) as store_rank
FROM projects.walmart_sales
GROUP BY months, month_num, Store) 

SELECT Store, months, avg_month_sales 
FROM CTE_best_month
WHERE store_rank = 1
ORDER BY month_num ASC, avg_month_sales DESC;


# How does Holidays affect weekly sale? 
SELECT round((SELECT SUM(Weekly_Sales) FROM projects.walmart_sales WHERE Holiday_Flag = 1)/SUM(Weekly_Sales) *100, 2)  holiday_sales_impact
FROM projects.walmart_sales;


# Does Temperature have any affect on sales? 
# To better understand the Temperature, it will be converted to celcius
# Celcius = (Fahrenheit - 32) * 0.5556

ALTER TABLE projects.walmart_sales
ADD COLUMN Temperature_Celcius DECIMAL(4,1);

SELECT Temperature, ROUND((Temperature - 32) * 0.5556, 1) as celcius
FROM projects.walmart_sales;

UPDATE projects.walmart_sales
SET Temperature_Celcius = ROUND((Temperature - 32) * 0.5556, 1);

# Let's find the median of the Temperature median = (min + max) /2
SET @temp_median = (
 SELECT ROUND((MIN(Temperature_Celcius) + MAX(Temperature_Celcius)) / 2, 1)
 FROM projects.walmart_sales);


SELECT ROUND(SUM(high_low_avg)/COUNT(high_low_avg) *100,2) as sales_higher_than_avg
FROM
	(SELECT Weekly_Sales,
		CASE WHEN (SELECT AVG(Weekly_Sales) FROM projects.walmart_sales) > Weekly_Sales THEN 1 ELSE 0 END as high_low_avg,
		Temperature_Celcius 
	FROM projects.walmart_sales
	ORDER BY Temperature_Celcius DESC) as temperature_table
    WHERE Temperature_Celcius 	< 0; -- No significant difference with % avg Sales between > temp median and < temp median
    -- Sales are 5% more when the temp is below 0 degress celcius (holiday sales)


SELECT Weekly_Sales, ROUND(CPI,1) CPI
FROM projects.walmart_sales;

# How does CPI relates to Sales?
WITH CTE_CPI AS(
SELECT *, LAG(avg_sales) OVER() previous_sales, avg_sales - LAG(avg_sales) OVER() as diff
FROM (SELECT DISTINCT ROUND(CPI) _CPI, ROUND(AVG(Weekly_Sales)) as avg_sales
	FROM projects.walmart_sales
	GROUP BY _CPI
	ORDER BY 1) cpi_table
)
SELECT
	AVG(CASE WHEN diff < 0 THEN 1 ELSE 0 END)* 100
FROM CTE_CPI;
-- AS Consumer Index Price rises, Sales decrease 54.8% of the time.
-- This indicates that there is relationship between CPI and Sales, can be explored better in other mediums (python/visualations)


# How does unemployment relate to Sales? 
SELECT COUNT(DISTINCT(ROUND(Unemployment,1))) -- 74 unique values for unemployment
FROM projects.walmart_sales;

WITH CTE_unemployment AS (
	SELECT#year(`Date`)as y, 
		(ROUND(Unemployment,1)) as uemployeement, ROUND(AVG(Weekly_Sales)) as avg_sales_per_unemployeemtn, 
		LAG( ROUND(AVG(Weekly_Sales))) OVER( ORDER BY ROUND(Unemployment,1)) as previous_avg_sales, 
		ROUND(AVG(Weekly_Sales)) - LAG( ROUND(AVG(Weekly_Sales))) OVER(ORDER BY ROUND(Unemployment,1)) diff
	FROM projects.walmart_sales
	GROUP BY uemployeement
	ORDER BY 1,2 )
    
    SELECT
       ROUND((SUM(CASE WHEN diff < 0  THEN 1 ELSE 0 END)/COUNT(diff)) * 100,2) as percentage_sales_decrease_when_unemployment_increases
    FROM CTE_unemployment;
    -- 50.68% of the time unemployment raises, weekly sales decreases


/*
------ CONCLUSION --------

- The dataset is fairly clean and retiable with no duplicates and no nulls.
- Data ranges from 2010 - 2012 (3 years)
- Max sales is 3.8 mil and min sales is 209.9k. Average sales 1.07 mil 
- TOP stores with the hihest average sakes (20,4,14,13 & 2)
- Lowest stores based on average sales are (33,44,5,36 & 38)
- December is largely the most profitable month for store slaes
- Stores with the lowest sales do not have december as their most profitable month.
- Holiday weeks account for 7.5% of all sales
- Temperature don't necessarily impact sales when evenly split. However when below freezing sales to increase 
	(this is most likely to be the impact of holiday sales) 
- Consumer Price Index does not directly impact sales, about 54% of the time it raises, average sales decrease. 
	This should be explore more in a visual medium.
- 50% of the time unemployment increases, sales decrease.

*/