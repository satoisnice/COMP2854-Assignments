/*
Assignment 8
A01442859
Connor Bell
*/

/* Customer signature
Identification Cols: firstname, gender
Input Cols: num of orders within time frame, total price of orders, payment type, num of units ordered, days since last order, most purchased product category
Target window: 6 months from cutoff

*/
USE sqlbook;
GO
CREATE OR ALTER PROCEDURE A01442859_CustomerSignature(@CutoffDate DATE)
AS
BEGIN
	DROP FUNCTION IF EXISTS CustomerSignature;
	DECLARE @year INT = YEAR(@CutoffDate);
	DECLARE @years varchar(MAX) = CONCAT('[', @year-2, '],[', @year-1, '],[', @year, ']');
	RETURNS TABLE
	AS
	RETURN
	(
		SELECT
			c.[FirstName],
			c.Gender,
			sum(o.totalprice) AS [Total Spent],
			Count(*) AS [Num of orders],
			DATEDIFF(dd, 
		FROM Customers c
			JOIN Orders o 
				ON c.CustomerId = o.customerid
		WHERE 
			c.firstname = 'JILL' and c.gender = 'F'
		GROUP BY 
			c.firstname, c.gender
	)

SELECT * FROM customers c JOIN orders o ON c.customerid = o.customerid where c.firstname = 'JILL' and c.gender = 'F'

WITH a as (
SELECT 
	ROW_NUMBER() OVER (ORDER BY orderdate DESC) AS row_num, 
	year(orderdate) as orderdate 
FROM orders
)
SELECT * FROM a where row_num = 1;
