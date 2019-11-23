-- Поваляева Н. И., вариант 3

USE [AdventureWorks2012]
GO

-- Создайте хранимую процедуру, которая будет возвращать сводную таблицу (оператор PIVOT), 
-- отображающую данные о средней цене (Production.Product.ListPrice) продукта 
-- в каждой подкатегории (Production.ProductSubcategory) по определенному классу (Production.Product.Class).
-- Список классов передайте в процедуру через входной параметр.
-- Таким образом, вызов процедуры будет выглядеть следующим образом:
-- EXECUTE dbo.SubCategoriesByClass '[H],[L],[M]'

CREATE PROCEDURE [dbo].[SubCategoriesByClass] @classes NVARCHAR(MAX)
AS
BEGIN
    DECLARE @query AS NVARCHAR(MAX);
    SET @query =
        'SELECT * FROM(
			SELECT [ps].[Name], [p].[ListPrice], [p].[Class]
			FROM [Production].[Product] AS p
			JOIN [Production].[ProductSubcategory] AS ps
				ON [p].[ProductSubcategoryID] = [ps].[ProductSubcategoryID]
		) AS idontknowhowtonameit
		PIVOT(
			AVG([ListPrice])
			FOR [Class] IN (' + @classes + ') 		
		) AS ohohohhappynewyear';
    EXECUTE (@query)
END

EXECUTE [dbo].[SubCategoriesByClass] '[H],[L],[M]'