/*
<<<<<<< HEAD
COMP 2854 - Assignment 3
Connor Bell A01442859
*/

USE SQLBOOK;
-- Remove zipcodes not found in zipcensus
BEGIN TRAN;
DELETE FROM Orders where
ZIPCODE IN (
SELECT zipcode FROM Orders
EXCEPT
SELECT zcta5 from zipcensus
);
commit;

-- Remove orderids not found in orders
BEGIN TRAN;
DELETE FROM OrderLines where
Orderid in (
SELECT OrderId FROM orderlines
EXCEPT
SELECT OrderId from [orders]
);
commit;


INSERT INTO ZipCounty (ZipCode)
SELECT zcta5 from zipcensus
EXCEPT
SELECT zipcode from zipcounty

--------------------------------------------
------------ Cursor Example ----------------
--------------------------------------------
-- Subscriber count and monthly revenue by market
DECLARE @subscriptions int;
DECLARE @market char(10);
DECLARE @prevstate char(10) = '##########';
DECLARE @monthlyRevenue int;
DECLARE @tmpTable TABLE ([market] char(10), [subscriptions] int, [monthlyRevenue] int);

DECLARE cursor_values CURSOR FOR
SELECT
	s.[market],
	SUM(s.[MonthlyFee]),
	COUNT(*)
FROM [Subscribers] s
GROUP BY s.[market]
ORDER BY s.[market], COUNT(*) DESC;

OPEN cursor_values;
FETCH NEXT FROM cursor_values INTO @market, @monthlyRevenue, @subscriptions;

WHILE @@FETCH_STATUS = 0
BEGIN
	IF (@prevstate != @market) INSERT INTO @tmpTable VALUES (@market, @subscriptions, @monthlyRevenue);
	SET @prevstate = @market;
	FETCH NEXT FROM cursor_values INTO @market, @monthlyRevenue, @subscriptions;
END

CLOSE cursor_values;
DEALLOCATE cursor_values;

SELECT * FROM @tmpTable
ORDER BY [market], [monthlyRevenue];
--------------------------------------------
---------- Cursor Example  END -------------
--------------------------------------------

-- Window Func. 1: RANK
-- Months with the most holidays ranked
WITH named AS (
	SELECT
		[month],
		[MonthAbbr],
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
		) AS [holiday]
	FROM [Calendar]
),
monthly AS (
	SELECT
		[month],
		[MonthAbbr],
		COUNT(DISTINCT [holiday]) AS [holidays]
	FROM named
	WHERE [holiday] IS NOT NULL
	GROUP BY [month], [MonthAbbr]
)
SELECT
	[MonthAbbr],
	[holidays],
	RANK() OVER (ORDER BY [holidays] DESC) AS [busiest_rank]
FROM monthly
ORDER BY [holidays] DESC, [month];

-- Window Func. 2: LEAD
-- Days till next holiday
WITH holidays AS (
	SELECT
		[Date],
		CONCAT([MonthAbbr], ' ', [DOM]) AS [readable_date],
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
		) AS [holiday]
	FROM [Calendar]
	WHERE YEAR([Date]) = 2010
)
SELECT
	[readable_date],
	[holiday],
	LEAD([holiday]) OVER (ORDER BY [Date]) AS [next_holiday],
	DATEDIFF(day, [Date], LEAD([Date]) OVER (ORDER BY [Date])) AS [days_until_next]
FROM holidays
WHERE [holiday] IS NOT NULL
ORDER BY [Date];

-- Window Func. 3: LAG
-- Time since last holiday
WITH holidays AS (
	SELECT
		[Date],
		CONCAT([MonthAbbr], ' ', [DOM]) AS [readable_date],
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
		) AS [holiday]
	FROM [Calendar]
	WHERE YEAR([Date]) = 2010
)
SELECT
	[readable_date],
	[holiday],
	LAG([holiday]) OVER (ORDER BY [Date]) AS [prev_holiday],
	DATEDIFF(day, LAG([Date]) OVER (ORDER BY [Date]), [Date]) AS [days_since_last]
FROM holidays
WHERE [holiday] IS NOT NULL
ORDER BY [Date];

-- Window Func. 4: FIRST_VALUE
-- First holiday of each month
WITH holidays AS (
	SELECT
		[Date],
		[MonthAbbr],
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
		) AS [holiday]
	FROM [Calendar]
	WHERE YEAR([Date]) = 2010
)
SELECT DISTINCT
	MONTH([Date]) AS [month_num],
	[MonthAbbr],
	FIRST_VALUE([holiday]) OVER (PARTITION BY MONTH([Date]) ORDER BY [Date]) AS [first_holiday],
	FIRST_VALUE(DAY([Date])) OVER (PARTITION BY MONTH([Date]) ORDER BY [Date]) AS [first_holiday_day]
FROM holidays
WHERE [holiday] IS NOT NULL
ORDER BY [month_num];

-- Window Func. 5: ROW_NUMBER
-- Holidays numbered within each month
WITH holidays AS (
	SELECT
		[Date],
		CONCAT([MonthAbbr], ' ', [DOM]) AS [readable_date],
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
		) AS [holiday]
	FROM [Calendar]
	WHERE YEAR([Date]) = 2010
)
SELECT
	MONTH([Date]) AS [month_num],
	[readable_date],
	[holiday],
	ROW_NUMBER() OVER (PARTITION BY MONTH([Date]) ORDER BY [Date]) AS [holiday_num_in_month]
FROM holidays
WHERE [holiday] IS NOT NULL
ORDER BY [Date];

-- Window Func. 6: SUM
-- Holiday count by month with running total
WITH holidays AS (
	SELECT
		[Date],
		[MonthAbbr],
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
		) AS [holiday]
	FROM [Calendar]
	WHERE YEAR([Date]) = 2010
)
SELECT
	MONTH([Date]) AS [month_num],
	[MonthAbbr],
	COUNT(*) AS [holidays_in_month],
	SUM(COUNT(*)) OVER (ORDER BY MONTH([Date])) AS [holidays_so_far]
FROM holidays
WHERE [holiday] IS NOT NULL
GROUP BY MONTH([Date]), [MonthAbbr]
ORDER BY [month_num];

-- Window Func. 7: SUM
-- Monthly revenue with running total
SELECT
	MONTH([OrderDate]) AS [month_num],
	DATENAME(month, [OrderDate]) AS [month_name],
	SUM([TotalPrice]) AS [monthly_revenue],
	SUM(SUM([TotalPrice])) OVER (ORDER BY MONTH([OrderDate])) AS [revenue_so_far]
FROM [Orders]
WHERE YEAR([OrderDate]) = 2015
GROUP BY MONTH([OrderDate]), DATENAME(month, [OrderDate])
ORDER BY [month_num];

-- Window Func. 8: NTILE
-- Customer spending in 4 groups
WITH customer_spend AS (
	SELECT
		[CustomerId],
		SUM([TotalPrice]) AS [total_spent]
	FROM [Orders]
	WHERE [CustomerId] <> 0
	GROUP BY [CustomerId]
)
SELECT
	[CustomerId],
	[total_spent],
	NTILE(4) OVER (ORDER BY [total_spent] DESC) AS [spend_quartile]
FROM customer_spend
ORDER BY [total_spent] DESC;

-- Window Func. 9: LAST_VALUE
-- Orders by year with latest year orders
SELECT
	YEAR([OrderDate]) AS [order_year],
	COUNT(*) AS [orders],
	LAST_VALUE(COUNT(*)) OVER (
		ORDER BY YEAR([OrderDate])
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
	) AS [latest_year_orders]
FROM [Orders]
GROUP BY YEAR([OrderDate])
ORDER BY [order_year];

-- Window Func. 10: FIRST_VALUE
-- Most expensive product in each group
SELECT DISTINCT
	[GroupName],
	FIRST_VALUE([FullPrice]) OVER (PARTITION BY [GroupName] ORDER BY [FullPrice] DESC) AS [highest_price]
FROM [Products]
ORDER BY [highest_price] DESC;