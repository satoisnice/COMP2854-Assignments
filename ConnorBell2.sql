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
	, CAST(SUM([EnrolledOver3]) AS FLOAT) / CAST(SUM([EnrolledOver3]) AS FLOAT) * 100 AS [TotalEnrolledPopPct]
FROM [ZipCensus]
WHERE [state] = 06;

-- Ex. 2: Coalesce, ISNULL, CASE
-- Amount of Regular days vs Holiday days in a calendar year
DECLARE @calendar_reduced TABLE (holiday_name nvarchar(255), monthAbbr nvarchar(255), DOM nvarchar(255), DOY nvarchar(255), [Number of days] int);

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
		DOY,
		COUNT(*) as [Number of days]
	FROM Calendar
	WHERE [YEAR]=1952
	GROUP BY
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
		),
		[MonthAbbr],
		DOM,
		DOY;

DECLARE @reg_vs_hol TABLE (day_type nvarchar(255))

INSERT INTO @reg_vs_hol
SELECT
	(ISNULL([holiday_name], 'Regular Day')) AS [Day Type]
from @calendar_reduced

SELECT 
	COUNT( CASE WHEN [day_type] = 'Regular Day' then 1 END) as [Regular Day Count],
	COUNT( CASE WHEN [day_type] <> 'Regular Day' then 1 END) as [Holiday Day Count]
FROM @reg_vs_hol;

-- Practice 1: PIVOT
-- Day Type as Col. headers showing more in depth count representation of holidays vs regular days
-- REQUIRES @calendar_reduced & @reg_vs_hol
select * from calendar;
SELECT
	[Regular Day], [New Year's Day], [Martin Luther King Day], [Groundhog Day], [Valentine's Day], [Chinese New Year], [President's Day], [Ash Wednesday], [St. Patrick's Day], [Vernal Equinox], [April Fools' Day], [Passover], [Good Friday], [Easter Sunday], [Mother's Day], [Shavuot], [Memorial Day], [Flag Day], [Ramadan Begins], [Father's Day], [Summer Solstice], [Independence Day], [Labor Day], [Rosh HaShanah], [Yom Kippur], [Autumnal Equinox], [Sukkot], [Shemini Atzeret], [Simchat Torah], [Columbus Day], [Islamic New Year], [Daylight Savings Time Ends], [Halloween], [Minor], [Veteran's Day], [Thanksgiving], [Hanukkah], [Winter Solstice], [Christmas]
FROM 
	(SELECT [day_type] from @reg_vs_hol) as src
PIVOT(
	COUNT([day_type])
	FOR day_type IN ([Regular Day], [New Year's Day], [Martin Luther King Day], [Groundhog Day], [Valentine's Day], [Chinese New Year], [President's Day], [Ash Wednesday], [St. Patrick's Day], [Vernal Equinox], [April Fools' Day], [Passover], [Good Friday], [Easter Sunday], [Mother's Day], [Shavuot], [Memorial Day], [Flag Day], [Ramadan Begins], [Father's Day], [Summer Solstice], [Independence Day], [Labor Day], [Rosh HaShanah], [Yom Kippur], [Autumnal Equinox], [Sukkot], [Shemini Atzeret], [Simchat Torah], [Columbus Day], [Islamic New Year], [Daylight Savings Time Ends], [Halloween], [Minor], [Veteran's Day], [Thanksgiving], [Hanukkah], [Winter Solstice], [Christmas])
) as pvt;

-- Ex. 3: STRING_AGG, (SUBSTRING)
-- Revenue by Year with each order and product
DROP TABLE IF EXISTS #order_lines_reduced;
CREATE TABLE #order_lines_reduced ([year] nvarchar(4), order_total decimal(19,2), orderId nvarchar(255), productId nvarchar(255))
INSERT INTO #order_lines_reduced
	SELECT 
		SUBSTRING(cast([BillDate] as nvarchar), 1, 4) as [year],
		TotalPrice as [order_total],
		OrderId,
		ProductId
	FROM OrderLines;


DROP TABLE IF EXISTS #rev_by_year_and_order_with_product;
CREATE TABLE #rev_by_year_and_order_with_product ([year] nvarchar(4), revenue decimal(19,2), orderIds nvarchar(max), productIds nvarchar(max))
INSERT INTO #rev_by_year_and_order_with_product
SELECT 
	[year],
	SUM([order_total]) as revenue,
	STRING_AGG(cast(OrderId as nvarchar(max)), '|'),
	STRING_AGG(cast(ProductId as nvarchar(max)), '|')
FROM #order_lines_reduced
GROUP BY [year];

SELECT [year], revenue, orderids, productids from #rev_by_year_and_order_with_product order by [year];

-- Ex. 4: EXCEPT, STRING_SPLIT
-- Products in orders from 2009 but not in 2010 orders
-- REQUIRES #rev_by_year_and_order_with_product
DROP TABLE IF EXISTS #product_list;
SELECT
	t.[year],
	s.value as productId
INTO #product_list
from #rev_by_year_and_order_with_product as t
CROSS APPLY STRING_SPLIT(t.productids, '|', 1) as s;
select * from #product_list;
WITH products_09 ([year], productId)as (
SELECT DISTINCT
	[year],
	[productId]
FROM #product_list
WHERE [year] = 2009
EXCEPT
SELECT DISTINCT
	[year],
	[productId]
FROM #product_list
WHERE [year] = 2010
)
SELECT p.[groupname], count(p.fullprice) as product_count from products_09 p9
JOIN Products p ON p9.[productId] = p.[productId]
GROUP BY p.groupname;

-- Ex. 5: PIVOT, CASE
-- Order Payment Type Counts
WITH pmt_types as (
SELECT
	CASE
		WHEN [PaymentType] = 'DB' THEN 'Direct Debit'
		WHEN [PaymentType] = 'AE' THEN 'American Express'
		WHEN [PaymentType] = 'MC' THEN 'Mastercard'
		WHEN [PaymentType] = '??' THEN 'Unknown'
		WHEN [PaymentType] = 'VI' THEN 'Visa'
		WHEN [PaymentType] = 'AE' THEN 'Other Card'
	END as [PaymentType]
FROM Orders)
SELECT
	[Direct Debit], [American Express], [Mastercard], [Unknown], [Visa], [Other Card]
FROM
	(SELECT * from pmt_types) as src
PIVOT(
	count([PaymentType])
	FOR PaymentType in ([Direct Debit], [American Express], [Mastercard], [Unknown], [Visa], [Other Card])
) as pvt;

-- Ex. 6: INTERSECT 
-- Products that have been ordered in 2016
WITH products_with_orders AS (
	SELECT
		productid
	FROM Products
	INTERSECT
	SELECT
		productid
	FROM OrderLines
)
SELECT
	p.productid,
	p.groupname,
	ol.totalprice,
	o.orderdate,
	ol.shipdate,
	concat(o.city, ', ', o.[state]) as [Location],
	DATEDIFF(d, o.OrderDate, ol.ShipDate) AS ProcessingDays
FROM Products p
JOIN orderlines ol ON p.productid = ol.productid
JOIN orders o on ol.orderid = o.orderid
WHERE SUBSTRING(CAST(o.orderdate as nvarchar(255)), 1, 4) = 2016
ORDER BY OrderDate asc;

-- Ex. 7: STRING_AGG
-- Subscriber count by market
DROP TABLE IF EXISTS #subscribers_by_mkt;

SELECT distinct 
	market,
	STRING_AGG(CAST(subscriberid as nvarchar(max)), '|') AS subscribers
INTO #subscribers_by_mkt
FROM subscribers
GROUP BY Market

DROP TABLE IF EXISTS #subscriber_count_by_mkt;
SELECT 
	market,
	LEN(subscribers) - LEN(REPLACE(subscribers, '|', '')) + 1 as [subscriber_count]
INTO #subscriber_count_by_mkt
FROM #subscribers_by_mkt;

SELECT * FROM #subscriber_count_by_mkt

-- Ex. 8: STRING_AGG
-- Campaigns resulting in a net loss
DECLARE @campaign_orders TABLE (campaignid nvarchar(255), orderid nvarchar(255), totalprice decimal(19,2), productprice decimal(19,2))
INSERT INTO @campaign_orders
SELECT
	c.campaignid,
	o.orderid,
	o.totalprice,
	p.fullprice
	
FROM campaigns c
JOIN orders o on c.campaignid = o.campaignid
JOIN orderlines ol on o.orderid = ol.orderid
JOIN products p on ol.productid = p.productid

DROP TABLE IF EXISTS #campaign_orders_agg;
SELECT 
	campaignId,
	STRING_AGG(cast(orderid as nvarchar(max)), '|') as orders,
	SUM(totalprice) as campaign_return,
	SUM(productprice) as inventory_price
INTO #campaign_orders_agg
FROM @campaign_orders
GROUP BY campaignid

select *, len([orders]) - len(replace(orders, '|', '')) + 1 as order_count from #campaign_orders_agg where campaign_return = 0;

-- Ex. 9: IIF, PIVOT
-- Uninhabited zipcodes and their delivery types
DECLARE @zero_pop_areas TABLE (zipcode nvarchar(255), lat_long nvarchar(255), Accepting_mail nvarchar(255));
WITH uninhabited_zips as (
	SELECT
		ZipCode,
		CONCAT(latitude, ', ', longitude) as lat_long,
		CONCAT(countyname, ' ', state) as loc,
		zipclass,
		countypop
	FROM ZipCounty
)
INSERT INTO @zero_pop_areas
SELECT 
	ZipCode,
	lat_long,
	IIF(ZipClass = 'P', 'PO Box', 'Undeliverable') as [Accepting Mail]
from uninhabited_zips 
where loc='';

DROP TABLE IF EXISTS #po_vs_undeliverable
SELECT 
	count(*) as 'Count',
	Accepting_mail
INTO #po_vs_undeliverable
from @zero_pop_areas
GROUP BY Accepting_mail;

SELECT * from #po_vs_undeliverable
SELECT
	[PO Box], [Undeliverable]
FROM
	(SELECT * FROM #po_vs_undeliverable)  as src
PIVOT(
	Sum([Count])
	FOR Accepting_mail in ([PO Box], [Undeliverable])
) as pvt;

-- Ex. 10: PIVOT, CASE
-- Customers by Gender
WITH aux_customer as (
SELECT
	CASE 
		WHEN Gender = 'F' then 'Female'
		WHEN Gender = 'M' then 'Male'
		ELSE 'Unspecified'
	END [Gender],
	IIF([FirstName] = '', null, FirstName) as [FirstName]
FROM [Customers]
),
gender_count as (
SELECT
	[gender],
	count(gender) as [Count]
FROM aux_customer
GROUP BY [gender]
),
pivoted_gender as (
	SELECT
		[Female],
		[Male],
		[Unspecified]
	FROM (SELECT * FROM gender_count) as src
	PIVOT(
		SUM([Count])
		FOR [Gender] IN ([Female],
		[Male],
		[Unspecified])
	) as pvt
)
SELECT * FROM pivoted_gender;



-- failed unpivot
-- state with most building time frame count
WITH structure_build_range as (
SELECT
      sl.state_label,
      SUM(z.Built2010orLater) AS [Built2010orLater],
      SUM(z.Built2000_2009)   AS [Built2000_2009],
      SUM(z.Built1990_1999)   AS [Built1990_1999],
      SUM(z.Built1980_1989)   AS [Built1980_1989],
      SUM(z.Built1970_1979)   AS [Built1970_1979],
      SUM(z.Built1960_1969)   AS [Built1960_1969],
      SUM(z.Built1950_1959)   AS [Built1950_1959],
      SUM(z.Built1940_1949)   AS [Built1940_1949],
      SUM(z.BuiltBefore1940)  AS [BuiltBefore1940]
FROM zipcensus z
JOIN #state_labels sl on z.[state] = sl.[state]
GROUP BY [state_label]
),
unpivoted as (
	SELECT state_label, time_range, [count]
	FROM structure_build_range
	UNPIVOT ([count] for time_range in (
		[Built2010orLater], [Built2000_2009], [Built1990_1999], [Built1980_1989], [Built1970_1979], [Built1960_1969], [Built1950_1959], [Built1940_1949], [BuiltBefore1940]
		)
	) as upvt
)
SELECT * from unpivoted;
/*
SELECT
	[state_label],
	MAX([Built2000_2009 Count]),
	MAX([Built2000_2009 Count]),
	MAX([Built1990_1999 Count]),
	MAX([Built1980_1989 Count]),
	MAX([Built1970_1979 Count]),
	MAX([Built1960_1969 Count]),
	MAX([Built1950_1959 Count]),
	MAX([Built1940_1949 Count]),
	MAX([BuiltBefore1940 Count])
FROM structure_build_range
GROUP BY [state_label];
*/


-- string_split practice
WITH free_orders as (
SELECT 
	orderid.value as orderid,
	orders.orderdate,
	orders.totalprice,
	orders.numunits
FROM #campaign_orders_agg

CROSS APPLY STRING_SPLIT(orders, '|') as orderid
JOIN orders on orderid.value = orders.orderid
WHERE campaign_return = 0
)
SELECT * from free_orders


 




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

-- helper tables
DECLARE @DC_label TABLE (state_code INT, state_label NVARCHAR(255));
INSERT INTO @DC_label
	SELECT [state], CASE [state] WHEN 11 THEN 'District of Columbia' END [state_label]
	FROM [ZipCensus]
	WHERE [state] = 11
	GROUP BY [state]
SELECT [state_code], state_label from @DC_label;
DROP TABLE IF EXISTS #state_labels
	SELECT
		[state],
		CASE [state]
			WHEN 1 THEN 'Alabama'
			WHEN 2 THEN 'Alaska'
			WHEN 4 THEN 'Arizona'
			WHEN 5 THEN 'Arkansas'
			WHEN 6 THEN 'California'
			WHEN 8 THEN 'Colorado'
			WHEN 9 THEN 'Connecticut'
			WHEN 10 THEN 'Delaware'
			WHEN 12 then 'Florida'
			WHEN 13 THEN 'Georgia'
			WHEN 15 THEN 'Hawaii'
			WHEN 16 THEN 'Idaho'
			WHEN 17 THEN 'Illinois'
			WHEN 18 THEN 'Indiana'
			WHEN 19 THEN 'Iowa'
			WHEN 20 THEN 'Kansas'
			WHEN 21 THEN 'Kentucky'
			WHEN 22 THEN 'Louisiana'
			WHEN 23 THEN 'Maine'
			WHEN 24 THEN 'Maryland'
			WHEN 25 THEN 'Massachusetts'
			WHEN 26 THEN 'Michigan'
			WHEN 27 THEN 'Minnesota'
			WHEN 28 then 'Mississippi'
			WHEN 29 then 'Missouri'
			WHEN 30 THEN 'Montana'
			WHEN 31 THEN 'Nebraska'
			WHEN 32 then 'Nevada'
			WHEN 33 then 'New Hampshire'
			WHEN 34 THEN 'New Jersey'
			WHEN 35 THEN 'New Mexico'
			WHEN 36 THEN 'New York'
			WHEN 37 THEN 'North Carolina'
			WHEN 38 THEN 'North Dakota'
			WHEN 39 THEN 'Ohio'
			WHEN 40 THEN 'Oklahoma'
			WHEN 41 THEN 'Oregon'
			WHEN 42 THEN 'Pennsylvania'
			WHEN 44 THEN 'Rhode Island'
			WHEN 45 THEN 'South Carolina'
			WHEN 46 THEN 'South Dakota'
			WHEN 47 THEN 'Tennessee'
			WHEN 48 THEN 'Texas'
			WHEN 49 THEN 'Utah'
			WHEN 50 THEN 'Vermont'
			WHEN 51 THEN 'Virginia'
			WHEN 53 THEN 'Washington'
			WHEN 54 THEN 'West Virginia'
			WHEN 55 THEN 'Wisconsin'
			WHEN 56 THEN 'Wyoming'
		END [state_label]
	INTO #state_labels
	FROM [ZipCensus]
	WHERE [state] not in (select [state_code] from @dc_label)
	GROUP BY [state]
	order by [state]

