/*
Assignment 7
A01442859
Connor Bell
*/

-- Ex. 1: Applying data model on the following dimensions: rateplan. To New Subscriptions in 2001. Using subscribers who started in 2000 while excluding those who stopped in 2000. 
-- 1. Model set is 2000 data grouped by rate plan
-- 2. Score set for data in 2000 (plans ending same year excluded)
-- 3. Fallback of the average monthly fee in 2000 to account for NULLs
-- 4. Result Set distributed into 10 groups using NTILE. Predicted vs Actual rev. for 2001
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

-- Ex. 2: ~10% test set using TABLESAMPLE with seed (77)
SELECT COUNT(*) [Total Orders] FROM Orders
SELECT * FROM Orders
	TABLESAMPLE(10 PERCENT) REPEATABLE(77);

-- Ex. 3: Exact 10% test set using ROW_NUMBER, prime numbers and modulo
with ts as (
	SELECT 
	ROW_NUMBER() OVER (ORDER BY [subscriberid]) as [RN],
	*
	FROM subscribers
)
SELECT * FROM ts WHERE (RN * 71 + 199) % 100 < 10;

-- Ex. 4: Balanced random stratified sample of Gotham vs Not Gotham markets. ROWNUMBER() numbers each record in each group, ordering by GUID ensures randomness. Rownumber <= 100, means a random subset of 100 from each group.
WITH s as (
	SELECT
		*,
		ROW_NUMBER() over (partition by IsGotham order by NEWID()) as RowNumber
	FROM (
		SELECT
			*,
			IIF(Market = 'Gotham', 1, 0) as IsGotham
		FROM Subscribers
	)s
)
SELECT
	StartDate,
	IIF(IsGotham = 1, cast(MonthlyFee as varchar(15)), '') as Gotham,
	IIF(IsGotham = 0, cast(MonthlyFee as varchar(15)), '') as NotGotham
FROM s
WHERE rownumber <= 100;

-- Ex. 5: Balanced random stratified sample of Gotham vs Non Gotham markets. Using Binary checksum to get 10% of table then order by NEWID to randomly order the 10%
WITH s as (
	SELECT
		*,
		ROW_NUMBER() over (partition by IsGotham  ORDER BY NEWID()) as RowNumber
	FROM (
		SELECT
			*,
			IIF(Market = 'Gotham', 1, 0) as IsGotham
		FROM Subscribers
		WHERE ABS(CAST(BINARY_CHECKSUM(*) * RAND() AS INT)) % 100 < 10
	)a
)
SELECT
	StartDate,
	IIF(IsGotham = 1, cast(MonthlyFee as varchar(15)), '') as Gotham,
	IIF(IsGotham = 0, cast(MonthlyFee as varchar(15)), '') as NotGotham
FROM s
WHERE rownumber <= 100;

-- Ex. 6: Exact 1% of total orders.
WITH t as (
	SELECT ROW_NUMBER() over (ORDER BY PaymentType) as RN, *
	FROM Orders
)
SELECT * FROM t
where RN % 100 = 1
order by paymenttype