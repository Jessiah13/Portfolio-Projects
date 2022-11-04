/*
Cleaning Data in SQL Queries
*/


Select *
From PortfolioProject.dbo.Nashville_housing

---------------------------------------------------------------------------------------------

-- Standardize Date Format

Select SaleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.Nashville_housing


Update Nashville_housing
Set SaleDate = CONVERT(Date, SaleDate)
-- Update & Set did not work, will try another workaround.

ALTER TABLE Nashville_housing
Add SaleDateConverted Date;

Update Nashville_housing
Set SaleDateConverted = CONVERT(Date, SaleDate)
-- worked!

----------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select PropertyAddress
From PortfolioProject.dbo.Nashville_housing
Where PropertyAddress is null

Select *
From PortfolioProject.dbo.Nashville_housing
Where PropertyAddress is null


-- Self joined table to populate missing data in the property address

Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
From PortfolioProject.dbo.Nashville_housing as A
JOIN PortfolioProject.dbo.Nashville_housing as B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
Where A.PropertyAddress is null


Update A 
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
From PortfolioProject.dbo.Nashville_housing as A
JOIN PortfolioProject.dbo.Nashville_housing as B
	ON A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
Where A.PropertyAddress is null


----------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State).


Select PropertyAddress
From PortfolioProject.dbo.Nashville_housing


-- Uing the SUBSTRING and CHARINDEX method to slip the property address by delimiter. 
Select SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) As Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) As Address
From PortfolioProject.dbo.Nashville_housing


ALTER TABLE Nashville_housing
Add PropertySplitAddress Nvarchar(255);

Update Nashville_housing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE Nashville_housing
Add PropertySplitCity Nvarchar(255);

Update Nashville_housing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))



Select OwnerAddress
From PortfolioProject.dbo.Nashville_housing


-- Using PARSENAME method, as PARSENAME only works with period/full stops '.', the commas were replaced.

Select 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From PortfolioProject.dbo.Nashville_housing


ALTER TABLE Nashville_housing
Add OnwerSplitAddress Nvarchar(255);

Update Nashville_housing
Set OnwerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE Nashville_housing
Add OnwerSplitCity Nvarchar(255);

Update Nashville_housing
Set OnwerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)


ALTER TABLE Nashville_housing
Add OnwerSplitState Nvarchar(255);

Update Nashville_housing
Set OnwerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)




----------------------------------------------------------------------------------------------------

-- Change "Y" and "N" to "Yes" and "No" in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject.dbo.Nashville_housing
Group by SoldAsVacant
Order By 2




-- Using Case Statements
Select SoldAsVacant, 
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
From PortfolioProject.dbo.Nashville_housing


Update Nashville_housing
SET SoldAsVacant = 	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END






----------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- Important note: Usually the imported data is not modified in such a way and instead all the date remaines with the manipulations being done on a view/temp table.

WITH RowNumCTE As (
Select  *, 
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) as row_num
				
From PortfolioProject.dbo.Nashville_housing
--Order by ParcelID
)
DELETE 
From RowNumCTE
Where row_num > 1
-- Order By PropertyAddress



----------------------------------------------------------------------------------------------------


-- Delete Unused Columns
-- Important note: Usually the imported data is not modified in such a way and instead all the date remaines with the manipulations being done on a view/temp table.

Select * 
From PortfolioProject.dbo.Nashville_housing

ALTER TABLE PortfolioProject.dbo.Nashville_housing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict

ALTER TABLE PortfolioProject.dbo.Nashville_housing
DROP COLUMN SalesConverted