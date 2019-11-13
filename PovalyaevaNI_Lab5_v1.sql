-- Поваляева Н. И., вариант 3

USE [AdventureWorks2012]
GO

-- Создайте scalar-valued функцию, которая будет принимать в качестве входного параметра id заказа 
-- (Purchasing.PurchaseOrderHeader.PurchaseOrderID) и возвращать сумму по заказу из детализированного списка заказов 
-- (Purchasing.PurchaseOrderDetail.LineTotal).

CREATE FUNCTION [dbo].[GetTotalPrice] (@purchaseOrderID int)  
RETURNS money
WITH EXECUTE AS CALLER  
AS  
BEGIN  
     RETURN (SELECT SUM([LineTotal]) FROM [Purchasing].[PurchaseOrderDetail]
		WHERE [PurchaseOrderID] = @purchaseOrderID);  
END;  
GO

SELECT [dbo].[GetTotalPrice](1) AS [TotalPrice]

-- Создайте inline table-valued функцию, которая будет принимать в качестве входных параметров id заказчика 
-- (Sales.Customer.CustomerID) и количество строк, которые необходимо вывести.
-- Функция должна возвращать определенное количество самых прибыльных заказов (по TotalDue) из Sales.SalesOrderHeader для каждого заказчика.

CREATE FUNCTION [dbo].[GetLucrativeOrders] (@customerId int, @rowsCount int)  
RETURNS TABLE  
AS  
RETURN   
(  
    SELECT [CustomerID], [TotalDue]
	FROM [Sales].[SalesOrderHeader]
	WHERE [CustomerID] = @customerId
	ORDER BY [TotalDue] DESC
	OFFSET (0) ROWS FETCH NEXT (@rowsCount) ROWS ONLY
);  
GO 

SELECT * FROM [dbo].[GetLucrativeOrders](29672, 4)

-- Вызовите функцию для каждого заказчика, применив оператор CROSS APPLY. 

SELECT [glo].*
FROM [Sales].[Customer] as c
CROSS APPLY (
	SELECT * FROM [dbo].[GetLucrativeOrders]([c].[CustomerID], 5)
) as glo
-- ORDER BY [CustomerID] ASC
GO

-- Вызовите функцию для каждого заказчика, применив оператор OUTER APPLY.

SELECT [glo].*
FROM [Sales].[Customer] as c
OUTER APPLY (
	SELECT * FROM [dbo].[GetLucrativeOrders]([c].[CustomerID], 5)
) as glo
-- ORDER BY [CustomerID] DESC
GO

-- Измените созданную inline table-valued функцию, сделав ее multistatement table-valued.

CREATE FUNCTION [dbo].[MULTIGetLucrativeOrders] (@customerId int, @rowsCount int) 
RETURNS @lucrativeOrders TABLE (
	CustomerID int,
	TotalDue money
)
AS
BEGIN
	INSERT INTO @lucrativeOrders
		SELECT [CustomerID], [TotalDue]
		FROM [Sales].[SalesOrderHeader]
		WHERE [CustomerID] = @customerId
		ORDER BY [TotalDue] DESC
		OFFSET (0) ROWS FETCH NEXT (@rowsCount) ROWS ONLY
	RETURN;
END
GO

SELECT * FROM [dbo].[MULTIGetLucrativeOrders](29672, 4)