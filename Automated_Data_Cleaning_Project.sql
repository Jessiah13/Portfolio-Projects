/*
MySQL Advanced Data Analytics - Project: Automated Data Cleaning

*/

SELECT * 
FROM us_project.us_household_income_staging;

SELECT * 
FROM us_project.us_household_income_cleaned;

--  Data Cleaning Steps 


-- Stored Procedure

DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN

	CREATE TABLE IF NOT EXISTS `us_household_income_cleaned` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` int DEFAULT NULL,
	  `ALand` int DEFAULT NULL,
	  `AWater` int DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL, 
	  `TimeStamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- COPY DATA TO NEW TABLE 

	INSERT INTO us_project.us_household_income_cleaned
    SELECT * , CURRENT_TIMESTAMP 
	FROM us_project.us_household_income_staging;
    
-- DATA CLEANING STEPS 
-- Removing Duplicates
	
    DELETE FROM us_project.us_household_income_cleaned
    WHERE row_id IN ( 
		SELECT row_id 
		FROM(
			SELECT row_id, id, 
			ROW_NUMBER () OVER(PARTITION BY id, `TimeStamp` ORDER BY id, `TimeStamp`)as row_num
			FROM  us_household_income_cleaned) row_table
		WHERE row_num > 1
    );
  
-- Standardizing data

-- update values 'alabama' to 'Alabama'
	UPDATE us_household_income_cleaned
	SET State_Name = 'Alabama'
	WHERE State_name = 'alabama'
	;

-- update values 'georia' to 'Georgia'
	UPDATE us_household_income_cleaned
	SET State_Name = 'Georgia'
	WHERE State_name = 'georia'
	;    

-- fill in missing place    
	UPDATE us_household_income_cleaned
	SET Place = 'Autaugaville'
	WHERE County = 'Autauga County'
	AND City = 'Vinemont'
	;
    
-- standardize location text data to be all uppercase    
	UPDATE us_household_income_clean
	SET County = UPPER(County);

	UPDATE us_household_income_clean
	SET City = UPPER(City);

	UPDATE us_household_income_clean
	SET Place = UPPER(Place);

	UPDATE us_household_income_clean
	SET State_Name = UPPER(State_Name);

-- update values 'CPD' to 'CDP'  
	UPDATE us_household_income_clean
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income_clean
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';
    
END $$
DELIMITER ; 


-- Call procedure
CALL Copy_and_Clean_Data();



-- CREATE EVENT 
DROP EVENT run_data_cleaning;
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 30 DAY
    DO CALL Copy_and_Clean_Data();


-- DEBUGGING AND VERIFICATION 

SHOW EVENTS;

-- Check the timpestamps to verify if the event ran successfully
SELECT DISTINCT TimeStamp
FROM us_project.us_household_income_cleaned;

SELECT * 
FROM us_project.us_household_income_cleaned
LIMIT 500;