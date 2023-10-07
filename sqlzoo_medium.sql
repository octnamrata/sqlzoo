-- MEDIUM LEVEL DIFFICULTY -- 

/*  #6: A "Single Item Order" is a customer order where only one item is ordered. Show the SalesOrderID and the UnitPrice for every Single Item Order.

We want to see the order ID and unit price for orders that contain only one item. 
Some orders contain multiple items with ranging order qty.
An approach could be to simply filter on OrderQty = 1 and leave it at that, but to me the data shows for one OrderID, we can have multiple products & multiple quantities. 
In this case I will choose to find orders where there's only one ProductID per order, with an Order Qty of 1. 
*/

WITH CTE_QtyPerOrder AS 
(
	SELECT 
		SalesOrderID,
		UnitPrice,
		OrderQty,
		COUNT(ProductID) OVER (PARTITION BY SalesOrderID) AS Count
	FROM SalesOrderDetail
)
SELECT
	SalesOrderID,
	UnitPrice
FROM CTE_QtyPerOrder
WHERE Count = 1 
  AND OrderQty = 1
GROUP BY SalesOrderID , UnitPrice, OrderQty, Count
ORDER BY SalesOrderID


/* #7: Where did the racing socks go? List the product name and the CompanyName for all Customers who ordered ProductModel 'Racing Socks'.
Segment into two parts, first getting the customer CompanyName, then the correct joins to find ProductModel = Racing Socks */

SELECT 
	P.Name,
	C.CompanyName 
FROM SalesOrderDetail AS SOD
LEFT JOIN SalesOrderHeader AS SOH 
  ON SOD.SalesOrderID = SOH.SalesOrderID
LEFT JOIN Customer AS C 
  ON SOH.CustomerID = C.CustomerID
LEFT JOIN Product AS P 
  ON SOD.ProductID = P.ProductID
LEFT JOIN ProductModel AS PM 
  ON P.ProductModelID = PM.ProductModelID
WHERE PM.Name = 'Racing Socks'


/* #8: Show the product description for culture 'fr' for product with ProductID 736. */

SELECT 
	PD.Description 
FROM ProductDescription AS  PD 
LEFT JOIN ProductModelProductDescription PMD 
  ON PD.ProductDescriptionID = PMD.ProductDescriptionID
LEFT JOIN Product P 
  ON PMD.ProductModelId = P.ProductModelID
WHERE P.ProductId = 736
  AND PMD.Culture = 'fr'

/* #9: Use the SubTotal value in SaleOrderHeader to list orders from the largest to the smallest. For each order show the CompanyName and the SubTotal and the total weight of the order.*/

SELECT 
	C.CompanyName,
	SOH.SubTotal,
	SUM(SOD.OrderQty * P.Weight) as TotalWeight
FROM SalesOrderHeader AS SOH
LEFT JOIN SalesOrderDetail AS SOD 
  ON SOH.SalesOrderID = SOD.SalesOrderID 
LEFT JOIN Customer AS C 
  ON SOH.CustomerID = C.CustomerID 
LEFT JOIN Product AS P 
  ON SOD.ProductID = P.ProductID
GROUP BY C.CompanyName, SOH.SubTotal


/* #10: How many products in ProductCategory 'Cranksets' have been sold to an address in 'London'? */

SELECT 
	SUM(SOD.OrderQty) AS CranksetsSoldinLondon
FROM ProductCategory PC 
LEFT JOIN Product P 
  ON PC.ProductCategoryID = P.ProductCategoryID
LEFT JOIN SalesOrderDetail AS SOD 
  ON P.ProductID = SOD.ProductID
LEFT JOIN SalesOrderHeader AS SOH 
  ON SOD.SalesOrderID = SOH.SalesOrderID 
LEFT JOIN Customer AS C 
  ON SOH.CustomerID = C.CustomerID 
LEFT JOIN CustomerAddress AS CA 
  ON C.CustomerID = CA.CustomerID 
LEFT JOIN Address AS A 
  ON CA.AddressID = A.AddressID
WHERE PC.Name = 'Cranksets'
AND A.City = 'London'
