
-- all GEODETic systems
SELECT * FROM sys.spatial_reference_systems
--WHERE unit_of_measure <> 'metre'
ORDER BY spatial_reference_id;
-- wgs84

SELECT * FROM sys.spatial_reference_systems
WHERE spatial_reference_id = 4326;

-- binary data of location
INSERT INTO [test].[dbo].[Table_1] ([GeoData])
VALUES(geography::Point(49.283427, -123.115337, 4326));
SELECT * FROM [test].[dbo].[Table_1]

-- extract Lat. & Long. 
SELECT [GeoData]
	, [GeoData].Lat  AS Latitude
	, [GeoData].Long AS Longitude
	, [GeoData].STSrid AS SRID
FROM [test].[dbo].[Table_1]

-- only continental us is lat < 50 and long > -125
