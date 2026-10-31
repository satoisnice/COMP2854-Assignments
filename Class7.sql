-- If randomness is important
SELECT COUNT(*) [Total Subscribers] FROM sqlbook.dbo.subscribers
SELECT COUNT(*) [1% of Subscribers] FROM sqlbook.dbo.subscribers
	TABLESAMPLE(1 PERCENT)

-- 
SELECT COUNT(*) [Total Subscribers] FROM sqlbook.dbo.subscribers
SELECT COUNT(*) [~1000 Subscribers] FROM sqlbook.dbo.subscribers
	TABLESAMPLE(1000 ROWS)

-- gives same sample every time
SELECT COUNT(*) [Total Subscribers] FROM sqlbook.dbo.subscribers
SELECT * FROM sqlbook.dbo.subscribers
	TABLESAMPLE(1 PERCENT) REPEATABLE(7)

-- NEWID = GUID
-- appending a GUID and ordering by it will give you random sample
SELECT TOP(1000) 
	BINARY_CHECKSUM(*), 
	NEWID() a, 
	* 
	FROM ORDERS 
	where (ABS(CAST((BINARY_CHECKSUM(*) * RAND()) AS INT)) % 100) < 10-- MODULUS 100, 100 possible return values (0-99), take rows where the return is less than 10
	ORDER BY a;

	-- rand can take a seed making the thing returned

SELECT AVG(IsActive * 1.0) * 100 AS [Percent of Active Subscribers]
FROM sqlbook.dbo.subscribers;

-- proportional stratified sample. selecting every 100th row after ordering will give us 1% while adhering to how distributed the population is
WITH t as (
	SELECT ROW_NUMBER() OVER (ORDER BY [IsActive]) as [RowNumber], *
	FROM [SQLBook].[dbo].[Subscribers]
)
SELECT * FROM t
WHERE [RowNumber] % 100 = 1
ORDER BY [IsActive];


WITH o AS (
   SELECT
      *,				/* 2 split */        /* 3 randomize */
      ROW_NUMBER() OVER (PARTITION BY [IsAE] ORDER BY NEWID()) AS [RowNumber]
   FROM (
      SELECT
         *,
         IIF([PaymentType] = 'AE', 1, 0) AS [IsAE] /* 1 */
      FROM [SQLBook].[dbo].[Orders]
      WHERE TotalPrice <= 200
   ) o
)
SELECT [OrderDate],
   IIF([IsAE] = 1, [TotalPrice], NULL) as [AE],
   IIF([IsAE] = 0, [TotalPrice], NULL) as [NotAE]
FROM o
WHERE [RowNumber] <= 100; /* 4 */

-- model is personal understanding of the data 



DROP TABLE IF EXISTS #Kids;
GO
CREATE TABLE #Kids (Id INT PRIMARY KEY, Gender CHAR(1), Age INT, Toys INT);
GO
INSERT INTO #Kids VALUES 
(1, 'F', 5, 10), (2, 'M', 5, 2), (3, 'F', 5, 10), (4, 'F', 6, 10), (5, 'M', 6, 3);
SELECT * FROM #Kids;

-- lookup model: group by input field, avg -> target
SELECT AVG(Toys*1.0) AS [Overall Average] FROM #Kids;
SELECT Age, AVG(Toys*1.0) AS [Average by Age] FROM #Kids GROUP BY Age;
SELECT Gender, AVG(Toys*1.0) AS [Average by Gender] FROM #Kids GROUP BY Gender;