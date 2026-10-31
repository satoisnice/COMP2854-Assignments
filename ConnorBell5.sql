/* 
Assignment 5
Connor Bell
A01442859
*/

-- Ex. 1: Total Population of a state
USE SQLBook;
GO
CREATE OR ALTER FUNCTION A01442859_GetTotPopInState(
	@state char(2)
)
RETURNS TABLE
AS
RETURN
(
SELECT sum(totpop) as TotPop, stab as [state abbreviation]
FROM zipcensus WHERE [stab] = @state GROUP BY stab
)
GO

SELECT * FROM A01442859_GetTotPopInState('WA');
GO

-- Ex. 2: Total Population of state with optional filter
USE SQLBook;
GO
CREATE OR ALTER FUNCTION A01442859_GetTotPopInStateFilter(
	@state char(2)
)
RETURNS TABLE
AS
RETURN
(
SELECT sum(totpop) as TotPop, stab as [state abbreviation]
FROM zipcensus 
WHERE @state = '' or @state IS NULL or stab = @state
GROUP BY stab
)
GO

SELECT * FROM A01442859_GetTotPopInStateFilter(null);
GO

-- Ex. 3: new subscribers by year
USE SQLBook;
GO
CREATE OR ALTER FUNCTION A01442859_NewSubsByYear(
	@year int
)
RETURNS TABLE
AS
RETURN
(
SELECT
	SubscriberId,
	RatePlan,
	MonthlyFee,
	Market,
	Channel,
	StartDate
FROM subscribers
WHERE year(StartDate) = @year
)
GO
SELECT * FROM A01442859_NewSubsByYear(2000);
GO

-- Ex. 4: *overloaded* New subscribers within time frame
USE SQLBook;
GO
CREATE OR ALTER FUNCTION A01442859_NewSubsByYearTF(
	@StartDate DateTime,
	@EndDate DateTime
)
RETURNS TABLE
AS
RETURN
(
SELECT
	Subscriberid,
	RatePlan,
	MonthlyFee,
	Market,
	Channel,
	StartDate
FROM subscribers
WHERE StartDate BETWEEN @startDate and @endDate
)
GO
SELECT * FROM A01442859_NewSubsByYearTF('2002-01-01', '2002-01-31');
GO

-- Ex. 5: *overloaded* New subscribers within time frame & filter down by monthly fee
USE SQLBook;
GO
CREATE OR ALTER FUNCTION A01442859_NewSubsByYearTimeFrameMonthlyFee(
	@StartDate DateTime,
	@EndDate DateTime,
	@monthlyFee int
)
RETURNS TABLE
AS
RETURN
(
SELECT
	Subscriberid,
	RatePlan,
	MonthlyFee,
	Market,
	Channel,
	StartDate
FROM subscribers
WHERE StartDate BETWEEN @startDate and @endDate and MonthlyFee = @monthlyFee
)
GO
SELECT * FROM A01442859_NewSubsByYearTimeFrameMonthlyFee('2002-01-01', '2002-01-31', 10);
GO

-- Ex. 6: *overloaded* New subscribers within time frame, filter down by monthly fee and market
USE SQLBook;
GO
CREATE OR ALTER FUNCTION A01442859_NewSubsByYearTimeFrameMonthlyFeeMarket(
	@StartDate DateTime,
	@EndDate DateTime,
	@monthlyFee int,
	@market char(25)
)
RETURNS TABLE
AS
RETURN
(
SELECT
	Subscriberid,
	RatePlan,
	MonthlyFee,
	Market,
	Channel,
	StartDate
FROM subscribers
WHERE StartDate BETWEEN @startDate and @endDate and (@MonthlyFee = '' or @MonthlyFee is NULL OR MonthlyFee = @monthlyFee) and (@Market = '' or @Market is NULL or Market = @Market)
)
GO
SELECT * FROM A01442859_NewSubsByYearTimeFrameMonthlyFeeMarket('2002-01-01', '2002-01-31', null, '');
SELECT * FROM A01442859_NewSubsByYearTimeFrameMonthlyFeeMarket('2002-01-01', '2002-01-15', 25, 'Gotham');
GO

-- Ex. 7: array arg - state abbreviation and code expanded to full state name
USE SQLBook;
GO
DROP FUNCTION IF EXISTS A01442859_ExpandStateNames;
GO
DROP TYPE IF EXISTS StateInputList;
GO
CREATE TYPE StateInputList AS TABLE (Abbr VARCHAR(2));
GO
CREATE FUNCTION A01442859_ExpandStateNames
(
    @states StateInputList READONLY
)
RETURNS TABLE
AS
RETURN
(
    SELECT DISTINCT
        z.[state] AS [State Code],
        z.stab    AS [Abbreviation],
        CASE z.[state]
            WHEN 1 THEN 'Alabama'         WHEN 2 THEN 'Alaska'
            WHEN 4 THEN 'Arizona'         WHEN 5 THEN 'Arkansas'
            WHEN 6 THEN 'California'      WHEN 8 THEN 'Colorado'
            WHEN 9 THEN 'Connecticut'     WHEN 10 THEN 'Delaware'
            WHEN 11 THEN 'District of Columbia'
            WHEN 12 THEN 'Florida'        WHEN 13 THEN 'Georgia'
            WHEN 15 THEN 'Hawaii'         WHEN 16 THEN 'Idaho'
            WHEN 17 THEN 'Illinois'       WHEN 18 THEN 'Indiana'
            WHEN 19 THEN 'Iowa'           WHEN 20 THEN 'Kansas'
            WHEN 21 THEN 'Kentucky'       WHEN 22 THEN 'Louisiana'
            WHEN 23 THEN 'Maine'          WHEN 24 THEN 'Maryland'
            WHEN 25 THEN 'Massachusetts'  WHEN 26 THEN 'Michigan'
            WHEN 27 THEN 'Minnesota'      WHEN 28 THEN 'Mississippi'
            WHEN 29 THEN 'Missouri'       WHEN 30 THEN 'Montana'
            WHEN 31 THEN 'Nebraska'       WHEN 32 THEN 'Nevada'
            WHEN 33 THEN 'New Hampshire'  WHEN 34 THEN 'New Jersey'
            WHEN 35 THEN 'New Mexico'     WHEN 36 THEN 'New York'
            WHEN 37 THEN 'North Carolina' WHEN 38 THEN 'North Dakota'
            WHEN 39 THEN 'Ohio'           WHEN 40 THEN 'Oklahoma'
            WHEN 41 THEN 'Oregon'         WHEN 42 THEN 'Pennsylvania'
            WHEN 44 THEN 'Rhode Island'   WHEN 45 THEN 'South Carolina'
            WHEN 46 THEN 'South Dakota'   WHEN 47 THEN 'Tennessee'
            WHEN 48 THEN 'Texas'          WHEN 49 THEN 'Utah'
            WHEN 50 THEN 'Vermont'        WHEN 51 THEN 'Virginia'
            WHEN 53 THEN 'Washington'     WHEN 54 THEN 'West Virginia'
            WHEN 55 THEN 'Wisconsin'      WHEN 56 THEN 'Wyoming'
            WHEN 72 THEN 'Puerto Rico'
        END AS [State Name]
    FROM @states AS s
    JOIN zipcensus AS z
        ON  z.stab    = s.Abbr                       
        OR  z.[state] = TRY_CAST(s.Abbr AS INT)      
)
GO

DECLARE @list StateInputList;
INSERT INTO @list VALUES ('AZ'), ('CA'), ('53'), ('OR'), ('6');
SELECT * FROM A01442859_ExpandStateNames(@list);