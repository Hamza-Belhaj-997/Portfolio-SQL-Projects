# Createing a new table
USE portfolio_project; # Specifies the Database to be used
SET AUTOCOMMIT = 0 ; # Makes it possible that changes can be reverted
DROP TABLE IF EXISTS Houses; 
CREATE TABLE Houses (
UniqueID varchar(255),
ParcelID varchar(255),
LandUse varchar(255),
PropertyAddress varchar(255),
SaleDate varchar(255),
SalePrice varchar(255),
LegalReference varchar(255),
SoldAsVacant varchar(255),
OwnerName varchar(255),
OwnerAddress varchar(255),
Acreage varchar(255),
TaxDistrict varchar(255),
LandValue varchar(255),
BuildingValue varchar(255),
TotalValue varchar(255),
YearBuilt varchar(255),
Bedrooms varchar(255),
FullBath varchar(255),
HalfBath varchar(255)
); # the columns are all set to string to avoid any potential errors during import due to unclean data


# Upload data into the table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Houses.csv'
INTO TABLE portfolio_project.Houses
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


# Check if all the rows got imported. The number of rows should be 56477
SELECT count(*) FROM houses;


#Convert and standardize sale date column
UPDATE houses
SET saledate =  STR_TO_DATE(saledate,'%M %d, %Y'); # check the output log to see how many rows got affected, it needs to be 56477
SELECT saledate # check if changes were made
FROM houses;


# Populate property adress data
## Step 1: convert empty cells that aren't recognized as null
UPDATE houses
SET propertyAddress = CASE WHEN propertyAddress = "" THEN propertyAddress = NULL
		ELSE propertyAddress
        END;

## Step 2: Checking the result
SELECT propertyAddress
FROM houses
WHERE propertyAddress IS NULL;

## Step 3: check for rows with the same ParcelID but the adress is missing from one of them
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull(a.propertyaddress,b.propertyaddress)
FROM houses a JOIN houses b ON a.ParcelID = b.ParcelID AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;

## Step 4: update the rows with missing values based on parcelID
UPDATE houses a JOIN houses b ON a.ParcelID = b.ParcelID AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = ifnull(a.propertyaddress,b.propertyaddress)
WHERE a.PropertyAddress IS NULL;

## Step 5: check if the values got updated (should be empty)
SELECT *
FROM houses
WHERE PropertyAddress IS NULL;


# Split the property address into address and city
## Displaying the split address
SELECT substr(propertyaddress, 1, LOCATE(',', propertyaddress)-1) AS address, 
		substr(propertyaddress, LOCATE(',', propertyaddress)+1) AS city
FROM houses;

## Split the address into 2 separate columns
ALTER TABLE Houses
RENAME COLUMN PropertyAddress TO PropertyAddressFull; #change the name of the original column for calrity

ALTER TABLE Houses
ADD PropertyAddress VARCHAR(255) AFTER PropertyAddressFull;

UPDATE Houses
SET PropertyAddress = substr(PropertyAddressFull, 1, LOCATE(',', PropertyAddressFull)-1);

ALTER TABLE Houses
ADD PropertyCity VARCHAR(255) AFTER PropertyAddress;

UPDATE Houses
SET PropertyCity = substr(PropertyAddressFull, LOCATE(',', PropertyAddressFull)+1);

## Check the new table
SELECT * 
FROM Houses;


# Split the owner address column into address, city, state
## Convert empty cells that aren't recognized as null
Update houses
SET OwnerAddress = CASE WHEN OwnerAddress = "" THEN OwnerAddress = NULL
		ELSE OwnerAddress
        END;

## Displaying the split address
SELECT OwnerAddress, substring_index(OwnerAddress, ',',1) AS Address, 
		substring_index(substring_index(OwnerAddress, ',',-2),',',1) AS City, 
		substring_index(OwnerAddress, ',',-1) AS State
FROM Houses
WHERE Owneraddress IS NOT NULL;

## Split the address into the 3 separate columns
ALTER TABLE Houses
RENAME COLUMN OwnerAddress TO OwnerAddressFull; #change the name of the original column for calrity

ALTER TABLE Houses
ADD OwnerAddress VARCHAR(255) AFTER OwnerAddressFull;

UPDATE Houses
SET OwnerAddress = substring_index(OwnerAddressFull, ',',1);

ALTER TABLE Houses
ADD OwnerCity VARCHAR(255) AFTER OwnerAddress;

UPDATE Houses
SET OwnerCity = substring_index(substring_index(OwnerAddressFull, ',',-2),',',1);

ALTER TABLE Houses
ADD OwnerState VARCHAR(255) AFTER OwnerCity;

UPDATE Houses
SET OwnerState = substring_index(OwnerAddressFull, ',',-1);

## Check the new columns
SELECT OwnerAddressFull, OwnerAddress, OwnerCity, OwnerState
FROM Houses;


# Change Y and N to Yes and No in the SoldAsVacant
## Checking the distinct values in this column
SELECT DISTINCT SoldAsVacant, count(SoldAsVacant)
FROM Houses
GROUP BY SoldAsVacant; # we find there are 4 values in the column: 'Y', 'N', 'Yes', 'No'

## Changing Y and N to Yes and No
UPDATE Houses
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
    END;
    

# Remove duplicates
## displaying duplicates
WITH RowNumCTE AS (
SELECT *, row_number() OVER (PARTITION BY  ParcelID, propertyaddress, SaleDate, SalePrice, LegalReference ORDER BY uniqueid) AS row_num
FROM houses) #All rows with the same ParcelID, propertyaddress, SaleDate, SalePrice and LegalReference are considered duplicates
SELECT *
FROM RowNumCTE
WHERE row_num >1;

## Deleting duplicates (Note that removing data directly from the source table isn't standard practice. It's done here for demonstration purposes only)
WITH RowNumCTE AS (
SELECT *, row_number() OVER (PARTITION BY  ParcelID, propertyaddress, SaleDate, SalePrice, LegalReference ORDER BY uniqueid) AS row_num
FROM houses)
DELETE
FROM Houses USING Houses JOIN RowNumCTE ON Houses.UniqueID = RowNumCTE.Uniqueid
WHERE RowNumCTE.row_num >1;


# Delete unused columns
ALTER TABLE Houses
DROP COLUMN PropertyAddressFull,
DROP COLUMN OwnerAddressFull,
DROP COLUMN TaxDistrict;