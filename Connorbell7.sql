/*
Assignment 7
A01442859
Connor Bell
*/

-- Ex. 1: Applying data model on the following dimensions: rateplan. To New Subscriptions in 2001. Using subscribers who started in 2000 while excluding those who stopped in 2000
USE SQLBOOK;
Declare @FallBack2000Average FLOAT = (
	SELECT avg(monthlyfee * 12.0) FROM Subscribers where YEAR(StartDate) = 2000 AND (StopDate IS NULL OR YEAR(StopDate) <> 2000)
);

WITH [scoreSet] as 
(
	SELECT 
		*, 
		MonthlyFee * 12.0 AS [2001 Revenue] 
		FROM Subscribers 
		WHERE Year(StartDate) = 2001 and (StopDate IS NULL OR year(stopDate) <> 2001)
),
[modelSet] as (
	SELECT 
		RatePlan,
		AVG(MonthlyFee * 12.0) as [2000 Revenue Average]
	FROM Subscribers 
	WHERE YEAR(StartDate) = 2000 AND (StopDate IS NULL OR YEAR(StopDate) <> 2000)
	GROUP BY rateplan
),
resultSet as (
	SELECT
		s.*,
		COALESCE(m.[2000 Revenue Average], @FallBack2000Average) as [2001 Predicted Revenue]
	FROM scoreSet s LEFT JOIN modelSet m ON  s.rateplan = m.rateplan
)
SELECT
	[Decile],
	AVG([2001 Revenue]) as [2001 Revenue Average],
	AVG([2001 Predicted Revenue]) AS [2001 Predicted Revenue Average]
FROM (
	SELECT
		[2001 Revenue],
		[2001 Predicted Revenue],
		NTILE(10) OVER (ORDER BY [2001 Predicted Revenue] DESC) AS [Decile]
	FROM resultSet
) b
GROUP BY b.decile
order by b.decile;

