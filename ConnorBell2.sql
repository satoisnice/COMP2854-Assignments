/*
COMP 2854 - Assignment 2
Connor Bell A01442859
*/

---------------------------------------------------------------------------------
---------------- IIF queries ----------------------------------------------------
---------------------------------------------------------------------------------
USE SQLBook;

-- Ex. 1: Inline IF (IIF)
-- College population out of all students over 3 and enrolled in school. Represented as a percentage.
SELECT 
	ROUND(
		CAST(SUM(IIF([state]=06, [InCollege], null)) AS FLOAT)
		/
		CAST(SUM(IIF([state]=06, [EnrolledOver3], null)) AS FLOAT)
	, 4, 1) * 100 AS [California College Pop. Pct.]
FROM [ZipCensus]
WHERE [state] = 06;

-- Ex. 2:
DECLARE @calendar_reduced TABLE (holiday_name nvarchar(255), monthAbbr nvarchar(255), DOM nvarchar(255), DOY nvarchar(255));

INSERT INTO @calendar_reduced
	SELECT 
		COALESCE(
			[HolidayName]
			,[HolidayType]
			,[hol_National]
			,[hol_Minor]
			,[hol_Christian]
			,[hol_Jewish]
			,[hol_Muslim]
			,[hol_Chinese]
			,[hol_Other]
		) AS [Holiday Name],
		[MonthAbbr],
		DOM,
		DOY
	FROM Calendar
	WHERE [YEAR]=1952;

SELECT
	ISNULL([holiday_name], 'Regular Day') AS [Day Type]
from @calendar_reduced as cr

-- pivot Ex. from class
USE AdventureWorks2025;

SELECT   Gender, COUNT(*) AS 'Count'
FROM     HumanResources.Employee
GROUP BY Gender;

SELECT 'Count' as 'Gender', pvt.F, pvt.M
FROM (SELECT Gender FROM HumanResources.Employee) AS g 
PIVOT 
(
	COUNT(Gender) 
	FOR Gender
	IN (F, M)
) AS pvt;