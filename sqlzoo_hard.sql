
-- HARD LEVEL DIFFICULTY -- 

/* #11: For every customer with a 'Main Office' in Dallas show AddressLine1 of the 'Main Office' and AddressLine1 of the 'Shipping' address - if there is no shipping address leave it blank. Use one row per customer. */

SELECT 
	C.CompanyName,
	MAX(CASE WHEN CA.AddressType = 'Main Office' then A.AddressLine1 ELSE '' END) as MainOfficeAddress,
	MAX(CASE WHEN CA.AddressType = 'Shipping' then A.AddressLine1 ELSE '' END) AS ShippingAddress
FROM CustomerAddress AS CA
LEFT JOIN Address AS A 
  ON CA.AddressID = A.AddressID 
LEFT JOIN Customer AS C 
  ON CA.CustomerID = C.CustomerID
WHERE A.City ='Dallas'
GROUP BY C.CompanyName

/* #12: For each order show the SalesOrderID and SubTotal calculated three ways:
--A) From the SalesOrderHeader
--B) Sum of OrderQty*UnitPrice
--C) Sum of OrderQty*ListPrice 

	Using an inner join in this case because there is an order where no qty is specified, let's look at only 
    orders where a qty exists for method B & C to work */
	
SELECT 
	SOH.SalesOrderID,
	SOH.SubTotal AS 'Method A',
	SUM(SOD.OrderQty * SOD.UnitPrice) AS 'Method B',
	SUM(SOD.OrderQty * P.ListPrice) AS 'Method C'
FROM SalesOrderHeader AS SOH
INNER JOIN SalesOrderDetail AS SOD 
   ON SOH.SalesOrderID = SOD.SalesOrderID
INNER JOIN Product AS P 
   ON SOD.ProductID = P.ProductID 
GROUP BY SOH.SalesOrderID, SOH.SubTotal

/* #13: Show the best selling item by value. 
   Value is subjective, in this case we will consider the best selling to be determined by order qty * list price */

SELECT 
	SOD.ProductID,
	P.Name,
	P.ListPrice,
	SUM(SOD.OrderQty) AS 'Total Sold',
	SUM(SOD.OrderQty * P.ListPrice) AS 'Order Value'
FROM SalesOrderDetail AS SOD 
LEFT JOIN Product AS P 
  ON SOD.ProductID = P.ProductID
GROUP BY SOD.ProductID, P.Name, P.listPrice
ORDER BY SUM(SOD.OrderQty * P.ListPrice) DESC
LIMIT 1 


/* #14: Show how many orders are in the following ranges (in $):

    RANGE      Num Orders      Total Value
    0-  99
  100- 999
 1000-9999
10000-

 Again, value is subjective. This time we'll sum the subtotal + tax amount to get a total $. 

*/

SELECT 
R.Range, 
COUNT(R.SalesOrderId) AS 'Num Orders',
SUM(TotalValue) AS 'Total Value'
FROM 
( 
	SELECT 
	SOH.SalesOrderId,
	CASE 
		WHEN (SUM(SubTotal + TaxAmt) BETWEEN 0 AND 99) then '0-99' 
		WHEN (SUM(SubTotal + TaxAmt) BETWEEN 100 AND 999) then '100-999'
		WHEN (SUM(SubTotal + TaxAmt) BETWEEN 1000 AND 9999) then '1000-9999'
		ELSE '10000'
	END AS 'Range',
	SUM(SubTotal + TaxAmt) AS 'TotalValue'

	FROM SalesOrderHeader AS SOH
	LEFT JOIN SalesOrderDetail AS SOD 
	  ON SOH.SalesOrderID = SOD.SalesOrderID
	GROUP BY SOH.SalesOrderId
) R
GROUP BY R.Range


/* #15: Identify the three most important cities. Show the break down of top level product category against city.
   Interpreting "top level product category" as the product categories with the most in $ sales, by city. */

WITH CTE_InitData AS 
(--initial data
	SELECT 
		PC.Name,
		A.City,
		SUM(OrderQty * ListPrice) AS 'OrderValue',
		ROW_NUMBER () OVER (PARTITION BY A.City ORDER BY OrderValue) AS 'RN'

	FROM SalesOrderDetail AS SOD
	LEFT JOIN SalesOrderHeader AS SOH 
	  ON SOD.SalesOrderID = SOH.SalesOrderID 
	LEFT JOIN Product AS P 
	  ON SOD.ProductID = P.ProductID 
	LEFT JOIN ProductCategory AS PC 
	  ON P.ProductCategoryID = PC.ProductCategoryID
	LEFT JOIN Address AS A 
	  ON SOH.ShipToAddressID = A.AddressID

	GROUP BY PC.Name, A.City
	ORDER BY SUM(OrderQty * ListPrice) DESC
), 

CTE_TopCities AS 
(--gathering the top 3 cities by ordervalue 
	SELECT 
		City, 
		OrderValue
	FROM CTE_InitData 
	ORDER BY OrderValue DESC
	LIMIT 3
),

CTE_MaxPriceCity AS 
(--gathering the max ordervalue amount by city 
	SELECT 
		City, 
		MAX(OrderValue) AS MaxOrderValue 
	FROM CTE_InitData 
	GROUP BY City 
) 

 SELECT 
	 MP.City, 
	 Name AS ProductCat, 
	 MaxOrderValue
 FROM CTE_TopCities AS TC 
 INNER JOIN CTE_MaxPriceCity AS MP 
    ON TC.City = MP.City
 INNER JOIN CTE_InitData AS ID 
    ON TC.City = ID.City
 WHERE ID.OrderValue= MaxOrderValue --want to make sure the sum/total ordervalue for the city is the same as the max ordervalue we calculated 