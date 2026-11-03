/*
Assignment 8
A01442859
Connor Bell
*/

/* Customer signature
Identification Cols: customerid, firstname, gender
Input Cols: num of orders within time frame, total price of orders, most used payment type, num of units ordered, days since last order
Target window: 6 months from cutoff
*/
USE sqlbook;
GO
CREATE OR ALTER PROCEDURE A01442859_CustomerSignature @CutoffDate DATE
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @startDate DATE = dateadd(month, -6, @cutoffdate);
	
	WITH orderInfo as (
		SELECT
			o.customerid,
			SUM(o.totalprice) as [Total Spent],
			COUNT(*) as [Number of Orders],
			SUm(o.numunits) as [Number of Units],
			DATEDIFF(day, max(o.orderdate), @cutoffdate) as [Days Since Last Order]
		FROM orders o
		WHERE o.orderdate >= @startdate and o.orderdate < @cutoffdate
		group by o.customerid
	),
	payment AS (
		SELECT 
			customerid, 
			paymentType,
			ROW_NUMBER() OVER 
				(PARTITION BY customerid ORDER BY count(*) desc, paymenttype) as rn
		FROM orders
		WHERE orderdate >= @startdate and orderdate < @cutoffdate
		GROUP BY customerid, paymenttype
	)
	SELECT 
		c.customerid, 
		c.firstname, 
		c.gender,
		oi.[Total Spent],
		oi.[Number of Orders],
		oi.[Number of Units],
		oi.[Days Since Last Order],
		p.paymenttype as [Most used Payment Type],
		@cutoffdate as cutoffdate
	FROM customers c
		JOIN orderInfo oi on oi.customerid = c.customerid
		join payment p  on p.customerid = c.customerid and p.rn = 1
	ORDER BY oi.[Total Spent] desc
END;
GO

EXEC A01442859_CustomerSignature @cutoffdate = '2015-01-01';

-- Profiling model for customer payment types
USE sqlbook;
GO
CREATE OR ALTER PROCEDURE A01442859_PaymentProfile @date DATE
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @year int = year(@date);

	WITH paymentPrediction AS (
		SELECT
			city,
			state,
			isnull(IIF(paymentType='??', 'Other', paymentType), 'Other') as paymentType,
			count(*) as cnt,
			ROW_NUMBER() OVER (Partition by City, state order by Count(*) desc, paymenttype) as seqnum
		FROM orders
		WHERE year(orderdate) = @year AND city is not null AND city <> '' and state is not null and state <> ''
		GROUP BY city, state, paymenttype
		
	),
	actualPayments as (
		SELECT
			city,
			state,
			isnull(IIF(paymentType='??', 'Other', paymentType), 'Other') as paymentType,
			count(*) as cnt,
			ROW_NUMBER() OVER (Partition by City, state order by Count(*) desc, paymenttype) as seqnum
		FROM orders
		where year(orderdate) = @year + 1
		GROUP BY city, state, paymenttype
	),
	res as (
		SELECT
			l.PaymentType as [Predicted Payment Type],
			a.PaymentType as [Actual Payment Type],
			COUNT(*) as [Number of Cities]
		FROM paymentPrediction l
		JOIN actualPayments a on l.city = a.city and l.state = a.state
		WHERE l.seqnum = 1 and a.seqnum = 1
		GROUP BY l.PaymentType, a.paymentType
	)
	/*
	--Classification Matrix
	SELECT 
		[Predicted Payment Type],
		ISNULL([AE],0) AS [AE],
		ISNULL([DB],0) AS [DB],
		ISNULL([MC],0) AS [MC],
		ISNULL([OC],0) AS [OC],
		ISNULL([Other],0) AS [Other],
		ISNULL([VI],0) AS [VI]
	FROM res
	PIVOT
	(
		SUM([Number of Cities])
		FOR [Actual Payment Type] IN (AE, DB, MC, OC, Other, VI)
	) pivot1
	ORDER BY [Predicted Payment Type];
	*/
	-- model accuracy
	SELECT
		[Predicted Payment Type],
		SUM([Number of Cities]) as [Cities],
		SUM(CASE WHEN [Predicted Payment Type] = [Actual Payment Type]
			THEN [Number of Cities] ELSE 0 END)
			AS [Correct],
		SUM(CASE WHEN [Predicted Payment Type] = [Actual Payment Type]
			THEN [Number of Cities] ELSE 0 END) * 100.0
				/
			SUM([Number of Cities]) AS [% Correct]
	FROM res
	GROUP BY [Predicted Payment Type]
	
END;
GO

EXEC A01442859_PaymentProfile @date = '2015-01-01';