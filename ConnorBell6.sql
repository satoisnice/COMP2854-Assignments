/*
Assignment 6
A01442859
Connor Bell
*/

-- Ex. 1: probability clients use overseas card as payment type by city and state
USE SQLBOOK;
GO
CREATE OR ALTER procedure get_payment_prob
	@paymenttype char(2) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	WITH pmt_counts(orderCount, PaymentType, Probability) AS (
		SELECT
			Count(*) as orderCount,
			PaymentType,
			Count(*) * 1.0 / SUM(Count(*)) OVER () as Probability
		FROM Orders
		GROUP BY PaymentType
	)
	SELECT OrderCount, PaymentType, Probability from pmt_counts WHERE PaymentType = ISNULL(@paymenttype, paymenttype);
END;
GO
EXEC get_payment_prob @paymenttype = 'OC'

-- Ex. 2: Odds of using overseas card as payment type
GO
CREATE TABLE #probabilities (orderCount int, PaymentType char(2), Probability decimal(18,6));

INSERT INTO #probabilities EXEC get_payment_prob @paymenttype = 'OC';

SELECT 
	OrderCount, Paymenttype, Probability,
	CAST(Probability / (1 - Probability) AS DECIMAL(18,6)) as Odds
FROM #probabilities

-- Ex. 3: Probability of customer gender
GO
CREATE OR ALTER PROCEDURE get_cus_gender
	@gender char(1) = NULL -- f or m
AS
BEGIN
	SET NOCOUNT ON;
	SELECT
		Count(*) as PersonCount,
		Gender,
		Count(*) * 1.0 / SUM(COUNT(*)) OVER  () as probability
	FROM customers
	WHERE gender = ISNULL(@gender, gender)
	GROUP BY gender
END
GO
EXEC get_cus_gender;

-- Ex. 4: odds of gender by customers
GO
CREATE TABLE #gender_probabilities (personCount int, Gender char(1), Probability decimal(18,6));

INSERT INTO #gender_probabilities EXEC get_cus_gender

SELECT
	personCount,
	Gender,
	Probability,
	CAST(probability / (1- probability) AS decimal(18,6)) as odds
FROM #gender_probabilities;

-- Ex. 5: Probability of each payment type, ?? conflated to Cash payments
DROP TABLE IF EXISTS #pmt_probs
CREATE TABLE #pmt_probs (orderCount int, PaymentType char(2), Probability decimal(18,6))

INSERT INTO #pmt_probs EXEC get_payment_prob;
UPDATE #PMT_PROBS SET PaymentType = 'CS' -- cash
WHERE PaymentType = '??';

SELECT * from #pmt_probs;

-- Ex. 6: Odds of each payment type
SELECT *,
	cast(probability / (1 - probability) as decimal(18,6)) as odds
FROM #pmt_probs