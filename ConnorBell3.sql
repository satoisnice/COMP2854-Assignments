/*
COMP 2854 - Assignment 3
Connor Bell A01442859
*/

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
---------- Cursor Example ------------------
--------------------------------------------
DECLARE @subscriptions int;
DECLARE @market char(10)
DECLARE @prevstate char(10) = '##########'
DECLARE @monthlyRevenue int
declare @tmpTable table (
	[market] char(10),
	[subscriptions] int,
	[monthlyRevenue] int
);

DECLARE cursor_values cursor for
SELECT
	s.[market],
	sum(s.[MonthlyFee]),
	count(*)
FROM Subscribers s
GROUP BY s.[market]
order by s.[market], count(*) desc;

OPEN cursor_values;
fetch next from cursor_values into @market, @monthlyRevenue, @subscriptions

while @@FETCH_STATUS = 0
begin
	if(@prevstate != @market) insert into @tmpTable values (@market, @subscriptions, @monthlyRevenue);
	set @prevstate = @market;
	fetch next from cursor_values into @market, @monthlyRevenue, @subscriptions;
END

CLOSE cursor_values;
DEALLOCATE cursor_values;

SELECT * from @tmpTable
order by market, monthlyRevenue;
--------------------------------------------
---------- Cursor Example  END -------------
--------------------------------------------

-- Window Func. 1: RANK
-- Holidays By Month
WITH named AS (
    SELECT [month],
           MonthAbbr,
           COALESCE(HolidayName, HolidayType, hol_National, hol_Minor, hol_Christian, hol_Jewish, hol_Muslim, hol_Chinese, hol_Other) AS holiday
    FROM Calendar
),
monthly AS (
    SELECT [month], MonthAbbr, COUNT(DISTINCT holiday) AS holidays
    FROM named
    WHERE holiday IS NOT NULL
    GROUP BY [month], MonthAbbr
)
SELECT MonthAbbr,
       holidays,
       RANK() OVER (ORDER BY holidays DESC) AS busiest_rank
FROM monthly
ORDER BY holidays DESC, [month];

-- Window Func. 2: LEAD
-- days till next holiday
WITH holidays AS (
    SELECT [Date],
           CONCAT(MonthAbbr, ' ', DOM) AS readable_date,
           COALESCE(HolidayName, HolidayType, hol_National, hol_Minor, hol_Christian, hol_Jewish, hol_Muslim, hol_Chinese, hol_Other) AS holiday
    FROM Calendar
    WHERE YEAR([date]) = 2010
)
SELECT readable_date,
       holiday,
       LEAD(holiday) OVER (ORDER BY [Date])  AS next_holiday,
       DATEDIFF(day, [Date],
                LEAD([Date]) OVER (ORDER BY [Date])) AS days_until_next
FROM holidays
WHERE holiday IS NOT NULL
ORDER BY [Date];


-- Window Func. 3: LAG
-- Time since last holiday
WITH holidays AS (
    SELECT [Date],
           CONCAT(MonthAbbr, ' ', DOM) AS readable_date,
           COALESCE(HolidayName, HolidayType, hol_National, hol_Minor, hol_Christian, hol_Jewish, hol_Muslim, hol_Chinese, hol_Other) 
            AS holiday
    FROM Calendar
    WHERE YEAR([date]) = 2010
)
SELECT readable_date,
       holiday,
       LAG(holiday) OVER (ORDER BY [Date])  AS prev_holiday,
       DATEDIFF(day, LAG([Date]) OVER (ORDER BY [Date]),
        [Date]) AS days_since_last
FROM holidays
WHERE holiday IS NOT NULL
ORDER BY [Date];

-- Window Func. 4: FIRST_VALUE
-- First Holiday of each month
WITH holidays AS (
    SELECT [Date],
           MonthAbbr,
           COALESCE(HolidayName, HolidayType, hol_National, hol_Minor, hol_Christian, hol_Jewish, hol_Muslim, hol_Chinese,hol_Other) AS holiday
    FROM Calendar
    WHERE YEAR([Date]) = 2010
)
SELECT DISTINCT
       MONTH([Date]) AS month_num,
       MonthAbbr,
       FIRST_VALUE(holiday) OVER (PARTITION BY MONTH([Date]) ORDER BY [Date]) AS first_holiday,
       FIRST_VALUE(DAY([Date])) OVER (PARTITION BY MONTH([Date]) ORDER BY [Date]) AS first_holiday_day
FROM holidays
WHERE holiday IS NOT NULL
ORDER BY month_num;

-- Window Func. 5: ROW_NUMBER
WITH holidays AS (
    SELECT [Date],
           CONCAT(MonthAbbr, ' ', DOM) AS readable_date,
           COALESCE(HolidayName, HolidayType, hol_National, hol_Minor, hol_Christian, hol_Jewish, hol_Muslim, hol_Chinese, hol_Other) AS holiday
    FROM Calendar
    WHERE YEAR([Date]) = 2010
)
SELECT MONTH([Date]) AS month_num,
       readable_date,
       holiday,
       ROW_NUMBER() OVER (PARTITION BY MONTH([Date]) ORDER BY [Date]) AS holiday_num_in_month
FROM holidays
WHERE holiday IS NOT NULL
ORDER BY [Date];

-- Window Func. 6: COUNT
-- Holiday count by month with running total
WITH holidays AS (
    SELECT [Date],
           MonthAbbr,
           COALESCE(HolidayName, HolidayType, hol_National, hol_Minor,
                    hol_Christian, hol_Jewish, hol_Muslim, hol_Chinese,
                    hol_Other) AS holiday
    FROM Calendar
    WHERE YEAR([Date]) = 2010
)
SELECT MONTH([Date]) AS month_num,
       MonthAbbr,
       COUNT(*) AS holidays_in_month,
       SUM(COUNT(*)) OVER (ORDER BY MONTH([Date]))  AS holidays_so_far
FROM holidays
WHERE holiday IS NOT NULL
GROUP BY MONTH([Date]), MonthAbbr
ORDER BY month_num;


-- Window Func. 7: SUM (RE_READ
SELECT MONTH(OrderDate)                   AS month_num,
       DATENAME(month, OrderDate)         AS month_name,
       SUM(TotalPrice)                    AS monthly_revenue,
       SUM(SUM(TotalPrice)) OVER (ORDER BY MONTH(OrderDate)) AS revenue_so_far,
       CAST(100.0 * SUM(TotalPrice) / SUM(SUM(TotalPrice)) OVER ()
            AS decimal(5,1))              AS pct_of_year
FROM Orders
WHERE YEAR(OrderDate) = 2015
GROUP BY MONTH(OrderDate), DATENAME(month, OrderDate)
ORDER BY month_num;