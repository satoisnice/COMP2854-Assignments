/*
COMP 2854 - Assignment 1
Connor Bell A01442859
*/

---------------------------------------------------------------------------------
---------------- Part 1: 6 Common Table Expressions -----------------------------
---------------------------------------------------------------------------------
USE SQLBook;

-- CTE 1 (no args) professional commuters by state
WITH pro_commuters AS (
SELECT 
	[state], 
	[commuters], 
	[professional]
FROM ZipCensus
)
SELECT [state], [commuters], [professional] FROM pro_commuters
order by [state];


-- CTE 2 (args) NY state code to label
-- adds label to NY state code ONLY
WITH state_text([state_code], [state_label]) AS (
SELECT
	[state] as [state_code],
	CASE
		WHEN [state] = 36 THEN 'New York'
		ELSE 'Not New York'
	END
FROM ZipCensus
)
SELECT distinct[state_code], [state_label] FROM [state_text];


-- CTE 3 (args) subscription length in years
WITH subscription_length_months([months]) AS (
	SELECT
		DATEDIFF(m, [StartDate], IIF([StopDate] != NULL, [StopDate], CURRENT_DATE))
	FROM
		Subscribers
)
SELECT months from subscription_length_months;


-- CTE 4 (args) longitute & latitude combined
WITH long_lat([coordinates]) AS (
	SELECT
		CONCAT(Latitude, ', ', Longitude)
	FROM
		ZipCensus
)
SELECT coordinates from long_lat;


-- CTE 5 (args) Government workers by state (no DC)
WITH govt_workers_by_state([emp_count], [state_code]) AS (
	SELECT
		COUNT(GovWorkers) AS emp_count,
		[state]
	FROM
		ZipCensus
	WHERE [state] != 11
	GROUP BY [state]
)
SELECT [emp_count], [state_code] FROM govt_workers_by_state;


-- CTE 6 (args) Civilian information workers percentage of workers over 16
WITH real_states([state_code]) AS (
	SELECT [state]
	FROM [ZipCensus]
	WHERE [state] != 11
),
inf_worker_pct([state_code], [worker_pct]) AS (
	SELECT
		[state],
		ROUND(
			SUM(cast([information] AS FLOAT))
			/
			SUM(IIF(cast([worker16] AS FLOAT) = 0, NULL, [worker16])) 
			* 100, 2, 1
			)  AS worker_pct
	FROM
		ZipCensus
	WHERE [state] in (select state_code from real_states)
	GROUP by [state]
)
SELECT [worker_pct], [state_code] from inf_worker_pct;


---------------------------------------------------------------------------------
---------------- Part 1 END -----------------------------------------------------
---------------------------------------------------------------------------------



---------------------------------------------------------------------------------
---------------- Part 2: 3 TABLE data type examples -----------------------------
---------------------------------------------------------------------------------

-- TABLE data type 1: D.C. Is not a real state, store it (with a label) for future queries involving states
DECLARE @DC_label TABLE (state_code INT, state_label NVARCHAR(255));
INSERT INTO @DC_label
	SELECT [state], CASE [state] WHEN 11 THEN 'District of Columbia' END [state_label]
	FROM [ZipCensus]
	WHERE [state] = 11
	GROUP BY [state]
SELECT [state_code], state_label from @DC_label;
	

-- TABLE data type 2: Store state labels with their numerical codes
-- REQUIRES @DC_label
DECLARE @state_labels TABLE (
	state_code NVARCHAR(255),
	state_label NVARCHAR(255)
);

INSERT INTO @state_labels
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
	FROM [ZipCensus]
	WHERE [state] not in (select [state_code] from @dc_label)
	GROUP BY [state]

SELECT * from @state_labels order by [state_label];

-- TABLE Data type 3: Native population by state and percentage of total state population
-- REQURES @state_labels
DECLARE @NativePop TABLE([state] nvarchar(255), pop INT, pop_pct FLOAT)
INSERT INTO @NativePop
	SELECT
		[state],
		SUM(USNative) as pop,
		ROUND(
			SUM(CAST(USNative AS FLOAT)) 
			/ 
			SUM(IIF(CAST(TotPop AS FLOAT) = 0, NULL, [TotPop])),
			2,
			1
		)
		AS pop_pct
	FROM ZipCensus
	WHERE [TotPop] != 0
	GROUP BY [state]
SELECT SL.state_label, np.[pop] as [native population], np.[pop_pct] FROM @NativePop as NP
JOIN @state_labels AS SL ON
sl.[state_code] = np.[state];

---------------------------------------------------------------------------------
---------------- Part 2: END ----------------------------------------------------
---------------------------------------------------------------------------------

---------------------------------------------------------------------------------
---------------- Part 3: 3 temporary tables -------------------------------------
---------------------------------------------------------------------------------
-- Temp table 1: total fuel types in the USA
DROP TABLE IF EXISTS #tot_fuel_types;

SELECT 	
		SUM([HHFUtilGas]) AS [Utility Gas],
		SUM([HHfnofuel]) AS [No Fuel Used],
		SUM(HHFLPgas) AS [Bottled, tank, or LP gas],
		SUM(HHFElectric) AS [Electricity],
		SUM(HHFKerosene) AS [Fuel oil & kerosene],
		SUM(HHFCoal) AS [Coal or coke],
		SUM(HHFwood) AS [Wood],
		SUM(HHFSolar) as [Solar Energy],
		SUM(HHFOther) as [Other fuel] 
INTO #tot_fuel_types
FROM Zipcensus;

SELECT * FROM #tot_fuel_types;


-- Temp table 2: GROSS RENT by state (median statistics ommitted)
-- REQUIRES @state_labels

DROP TABLE IF EXISTS #gross_rent

SELECT
	[state],
	sum(renterocc) as [renter-occupied units],
	sum(cashrenter) as [Paying cash rent],
	sum(nocashrenter) as [paying no cash rent],
	--(mediangrossrent) as [median gross rent],
	AVG(nullif(avggrossrent, 0)) as [avg gross rent], -- sum wontt work
	sum(cashrenterover30pct) as [gross rent 30% or more of HH income],
	sum(cashrenterover750) as [gross rent of $750 or more]
INTO #gross_rent
FROM zipcensus
GROUP BY [state];
SELECT SL.[state_label], gs.* from #gross_rent as gs
JOIN @state_labels AS SL ON
gs.[state] = SL.[state_code]


-- Temp table 3: Computer ownership and internet use with expanded labels grouped by state
DROP TABLE IF EXISTS #military_and_veteran
SELECT
	[state],
	[Veteran],
	[Military]
INTO #military_and_veteran
FROM ZipCensus;
SELECT SUM(veteran) as [Total veterans], SUM(Military) as [Total Military personnel]
FROM #military_and_veteran;

---------------------------------------------------------------------------------
---------------- Part 3: END ----------------------------------------------------
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
---------------- Practice CTE using AdventureWorksDw2022 ------------------------
---------------------------------------------------------------------------------
USE AdventureWorksDW2022;

-- CTE 1b (args) Full address of prospective buyers
WITH full_address_buyers([full_address]) as (
	SELECT
		CONCAT(AddressLine1, ' ', [City], ' ', [StateProvinceCode], ' ', [PostalCode])
	FROM
		ProspectiveBuyer
)
SELECT [full_address] from full_address_buyers;

-- CTE 2b (args) delta of average rate & end of day rate
WITH currency_rate_avg_vs_delta([currency_delta]) as (
	SELECT
		AverageRate - EndOfDayRate
	FROM
		NewFactCurrencyRate
)
SELECT [currency_delta] FROM currency_rate_avg_vs_delta;

-- CTE 3b (args) manually processed calls
WITH manually_processed_calls([calls]) as (
	SELECT
		Calls - AutomaticResponses
	FROM
		FactCallCenter
)
select [calls] from manually_processed_calls;

-- CTE 4b (args) employed time in years
WITH employed_age_years([time_employed]) as (
	SELECT
		DATEDIFF(yyyy, HireDate, IIF([endDate] != NULL, [endDate], CURRENT_DATE)) AS [time_employed]
	FROM
		DimEmployee
)
SELECT [time_employed] from employed_age_years;
---------------------------------------------------------------------------------
---------------- Practice CTE END -----------------------------------------------
---------------------------------------------------------------------------------