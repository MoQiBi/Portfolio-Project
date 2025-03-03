DROP TABLE IF EXISTS NashvilleHousing;
CREATE TABLE NashvilleHousing(
UniqueID INT,
ParcelID TEXT,
LandUse TEXT,
PropertyAddress TEXT,
SaleDate date,
SalePrice text,
LegalReference int,
SoldAsVacant TEXT,
OwnerName TEXT,
OwnerAddress TEXT,
Acreage DECIMAL,
TaxDistrict text,
LandValue int,
BuildingValue int,
TotalValue int,
YearBuilt int,
Bedrooms int,
FullBath int,
HalfBath int
);

-- SHOW VARIABLES LIKE "local_infile";
-- SET GLOBAL local_infile=1;

LOAD DATA LOCAL INFILE 'C:\\Users\\Dell\\Downloads\\Nashville Housing Data for Data Cleaning.csv'
INTO TABLE NashvilleHousing 
FIELDS TERMINATED BY ','
ENCLOSED BY '"'  
IGNORE 1 ROWS;


SELECT * 
FROM NashvilleHousing;

-- Standardize Data
-- Populate Property Address

SELECT *
FROM nashvillehousing
;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, coalesce(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing a
JOIN nashvillehousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE nashvillehousing a
INNER JOIN nashvillehousing b 
    ON a.ParcelID = b.ParcelID 
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = coalesce(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

UPDATE nashvillehousing a
INNER JOIN nashvillehousing b 
    ON a.ParcelID = b.ParcelID 
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL;

UPDATE NashvilleHousing
SET 
    PropertyAddress = NULLIF(PropertyAddress, ''),
    OwnerName = NULLIF(OwnerName, ''),
    OwnerAddress = NULLIF(OwnerAddress, ''),
    SoldAsVacant = NULLIF(SoldAsVacant, ''),
    TaxDistrict = NULLIF(TaxDistrict, '');

-- Breaking out Address into individual column (Address, City, State)
SELECT PropertyAddress
FROM nashvillehousing;

SELECT 
    PropertyAddress,
    SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address,  -- Extracts everything before the first comma
    SUBSTRING_INDEX(PropertyAddress, ',', -1) AS City     -- Extracts everything after the last comma (-1)
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD SplitAddress nvarchar(255);
ALTER TABLE nashvillehousing
ADD CityAddress nvarchar(255);

UPDATE nashvillehousing
SET SplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);
UPDATE nashvillehousing
SET CityAddress = SUBSTRING_INDEX(PropertyAddress, ',', -1);

ALTER TABLE nashvillehousing 
RENAME COLUMN SplitAddress TO PropertySplitAddress;
ALTER TABLE nashvillehousing 
RENAME COLUMN CityAddress TO PropertySplitCity;



SELECT * 
FROM nashvillehousing;

SELECT 
    OwnerAddress,
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,  -- Extracts everything before the first comma
    SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) as City, -- Extract everything after 2nd comma, THEN extract everything before first comma
    SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State    -- Extracts everything after the last comma (-1)
FROM nashvillehousing;

SELECT 
    OwnerAddress,
      SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
    substring_index(OwnerAddress, ',', -2)     
FROM nashvillehousing;

ALTER TABLE nashvillehousing
ADD OwnerSplitAddress nvarchar(255);
ALTER TABLE nashvillehousing
ADD OwnerSplitCity nvarchar(255);
ALTER TABLE nashvillehousing
ADD OwnerSplitState nvarchar(255);

UPDATE nashvillehousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);
UPDATE nashvillehousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1);
UPDATE nashvillehousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

-- Change Y and N to Yes and No in Sold as vacant
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant;

SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'N' THEN 'No'
		 WHEN SoldAsVacant = 'Y' THEN 'YES'
         ELSE SoldAsVacant -- kalau xde ni nnt no and yes jadi null 
	END as Soldasvac
FROM nashvillehousing;

UPDATE nashvillehousing
SET SoldAsVacant =
	CASE WHEN SoldAsVacant = 'N' THEN 'No'
		 WHEN SoldAsVacant = 'Y' THEN 'YES'
         ELSE SoldAsVacant -- kalau xde ni nnt no and yes jadi null 
	END;
    
-- Remove Duplicates

SELECT *, 
	ROW_NUMBER() OVER(
    PARTITION BY 
ParcelID ,
LandUse ,
PropertyAddress ,
SaleDate ,
SalePrice ,
LegalReference ,
SoldAsVacant ,
OwnerName ,
OwnerAddress ,
Acreage ,
TaxDistrict ,
LandValue ,
BuildingValue ,
TotalValue ,
YearBuilt ,
Bedrooms ,
FullBath ,
HalfBath
ORDER BY UniqueID) AS row_num
FROM nashvillehousing;

-- use cte
WITH dupliCTE AS
(
SELECT *, 
	ROW_NUMBER() OVER(
PARTITION BY 
ParcelID ,
LandUse ,
PropertyAddress ,
SaleDate ,
SalePrice ,
LegalReference ,
SoldAsVacant ,
OwnerName ,
OwnerAddress ,
Acreage ,
TaxDistrict ,
LandValue ,
BuildingValue ,
TotalValue ,
YearBuilt ,
Bedrooms ,
FullBath ,
HalfBath
ORDER BY UniqueID) AS row_num
FROM nashvillehousing)
SELECT *
FROM dupliCTE
WHERE row_num > 1 
order by 2;

-- DELETE
DELETE FROM nashvillehousing
WHERE UniqueID IN (
	SELECT UniqueID FROM (
		SELECT UniqueID, ROW_NUMBER() OVER(PARTITION BY 
			ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
            ORDER BY UniqueID)
		AS row_num
	FROM nashvillehousing 
    ) AS Duplicates WHERE row_num > 1 )
;

-- DELETE UNUSED COLUMNS
ALTER TABLE nashvillehousing
DROP COLUMN PropertyAddress,
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict;
 
