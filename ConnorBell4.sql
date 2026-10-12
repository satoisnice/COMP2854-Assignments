/*
COMP 2854 - Assignment 4
Connor Bell A01442859
*/

USE AdventureWorks2025;
-- Ex. 1: Addresses with exact coordinates in decimal degrees
SELECT
	AddressID,
	CONCAT_WS(' - ', AddressLine1, AddressLine2) AS Address,
	City,
	StateProvinceID,
	PostalCode,
	SpatialLocation.Long as Longitude,
	SpatialLocation.Lat AS Latitude,
	SpatialLocation.STSrid as SRID
FROM AdventureWorks2025.person.address
WHERE SpatialLocation.Lat < 50.0 and SpatialLocation.Long > -125.0;

-- Ex. 2: KML Washington households on food stamps
USE SQLBook;
DECLARE @green nvarchar(10) = '14FF46';
DECLARE @red nvarchar(10) = 'FF4B33';
DECLARE @yellow nvarchar(10) = 'FFFC33';
SELECT CONCAT(
	 '<Placemark><name>',zipname, ' (',[zcta5], ')</name><description>Households on Food Stamps: ', 
	 numhhfoodstmp, ' (',FORMAT([pctnumhhfoodstmp], 'P1'), ') 
	 </description><styleUrl>#icon-1603-',
	 CASE 
		WHEN pctnumhhfoodstmp <= 0.2 THEN @green
		WHEN pctnumhhfoodstmp <= 0.35 THEN @yellow
		ELSE @red
	END,
	 '</styleUrl><Point><coordinates>',
     [Longitude],',',[Latitude],',',0,'</coordinates></Point></Placemark>') AS [KML Paste]
FROM zipcensus
WHERE TotHHs <> 0 and Latitude < 50.0 and Longitude > -125.0 and pctnumhhfoodstmp > 0.1 and zipname != '' and [state] = 53;

-- Ex. 3: KML Persons in poverty in WA
USE SQLBook;
SELECT CONCAT(
    '<Placemark><name>', zipname, ' (', [zcta5], ')</name>',
    '<description>People in Poverty: ', poor,
    ' (', FORMAT(1.0 * poor / TotPop, 'P1'), ')</description>',
    '<styleUrl>#',
    CASE
        WHEN 1.0 * poor / TotPop <= 0.20 THEN 'g'
        WHEN 1.0 * poor / TotPop <= 0.35 THEN 'y'
        ELSE 'r'                                  
    END,
    '</styleUrl>',
    '<Point><coordinates>', [Longitude], ',', [Latitude], ',0</coordinates></Point></Placemark>'
) AS [KML Paste]
FROM zipcensus
WHERE TotPop <> 0 AND Latitude < 50.0 AND Longitude > -125.0 AND poor > 0 AND zipname <> '' AND [state] = 53;

-- Ex. 4: Postal code with most military members in each state
USE SQLBook;
WITH mil_ranked AS(
	SELECT
		zcta5,
		stab,
		zipname,
		Military,
		Longitude,
		Latitude,
		ROW_NUMBER() OVER (PARTITION BY stab ORDER BY Military DESC) as [Row Number]
	FROM zipcensus
	WHERE Military > 0
)
SELECT stab, zcta5, zipname, military, Longitude, Latitude
FROM mil_ranked WHERE [Row Number] = 1 ORDER BY Military DESC;

-- Ex. 5: Orders ranked in WA
USE SQLBook;
SELECT
    o.[rank],
    o.zipcode,
    zc.zipname,
    o.num_orders,
    zc.Longitude,
    zc.Latitude
FROM (
    SELECT
        zipcode,
        [state],
        COUNT(*) AS num_orders,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS [rank]
    FROM orders
    WHERE [state] = 'WA'
    GROUP BY zipcode, [state]
) AS o
JOIN zipcensus AS zc
    ON zc.zcta5 = o.zipcode
ORDER BY o.[rank];

-- Ex. 6: Family vs Non Family households in WA
SELECT
    zcta5,
    stab,
    Families,
    NonFamHHs,
    CASE
        WHEN Families > NonFamHHs THEN 'Families'
        WHEN Families < NonFamHHs THEN 'Non-families'
        ELSE 'Tie'
    END AS Majority,
    1.0 * Families / (Families + NonFamHHs) AS PctFamilies,
    Longitude,
    Latitude
FROM zipcensus
WHERE Families + NonFamHHs > 0 AND Latitude < 50.0 AND Longitude > -125.0 AND stab = 'WA';

-- Ex. 7: 
-- Most ordered product category by ZIP in WA
USE SQLBook;

WITH ProductsByZip AS (
    SELECT
        o.ZipCode,
        ol.ProductId,
        SUM(ol.NumUnits) AS UnitsOrdered,
        ROW_NUMBER() OVER (PARTITION BY o.zipcode ORDER BY SUM(ol.numunits) desc) as [Row Number]
    FROM orders as o
    JOIN Orderlines as ol ON ol.orderid = o.orderid
    WHERE o.state = 'WA'
    GROUP BY o.zipcode, ol.productid
)
SELECT
    pz.zipcode,
    zc.zipname,
    p.groupname as category,
    pz.unitsordered,
    zc.Longitude,
    zc.latitude
FROM productsbyzip as pz
JOIN products as p ON p.productid = pz.productid
JOIN zipcensus as zc on zc.zcta5 = pz.zipcode
WHERE pz.[Row Number] = 1
ORDER BY pz.unitsordered DESC;

-- Ex. 8:zipcode with most used work commute method in each state. Commute methods: drive alone, public trans, walk 
WITH Methods AS (
    SELECT
        zc.zcta5, zc.zipname, zc.stab, zc.Longitude, zc.Latitude,
        m.Method, m.Workers
    FROM ZipCensus AS zc
    CROSS APPLY (VALUES
        ('Drive alone',    zc.DriveAlone),
        ('Public transit', zc.PublicTrans),
        ('Walk',           zc.Walktowork)
    ) AS m(Method, Workers)
    WHERE m.Workers > 0
),
Ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY stab, Method ORDER BY Workers DESC) AS [Row Number]
    FROM Methods
)
SELECT
    stab,
    Method,
    zcta5,
    zipname,
    Workers,
    Longitude,
    Latitude
FROM Ranked
WHERE [Row Number] = 1
ORDER BY stab, Method;

-- Ex. 9: top 5 Furthest distance from downtown seattle
DECLARE @CENTER_ZIP varchar(5) = '98101';
DECLARE @SRID_METRE INT = 4326;

WITH zc AS (
   SELECT
      zc.*,
      geography::Point(latitude, longitude, @SRID_METRE) AS [Point]
   FROM [SQLBook].[dbo].[ZipCensus] zc
   WHERE stab = 'WA'
)
SELECT TOP 6
    z.zcta5 as [ZipCode],
    z.stab as [State],
    z.zipname as [Name],
    z.[distance],
    z.[Longitude],
    z.[Latitude],
    z.totpop as [Population],
    z.tothhs as [number of households],
    z.medianhhinc as [median income],
    IIF(z.zcta5 = @CENTER_ZIP, 'center', 'other') as [type]
FROM (
    SELECT
        a.*,
        a.[Point].STDistance(b.[Point]) / 1000 as [Distance]
    FROM zc a
    CROSS JOIN(
    SELECT zc.*
        FROM zc WHERE zcta5 = @CENTER_ZIP
    ) b
) z
ORDER BY
    CASE WHEN z.zcta5 = @center_zip then 0 else 1 end,
    z.[Distance] DESC;

-- Ex. 10: male vs female pop by zipcode
SELECT
    zcta5,
    zipname,
    longitude,
    latitude,
    males,
    females,
    CASE WHEN males > females THEN 'male' else 'female' END as majority,
    1.0 * females / totpop as [pctfemales]
FROM zipcensus
where females > 0 and males > 0 and totpop > 0 AND Latitude < 50.0 AND Longitude > -125.0;