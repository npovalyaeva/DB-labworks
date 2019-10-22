-- Поваляева Н. И., вариант 3

USE [AdventureWorks2012]
GO

-- Добавьте в таблицу dbo.Address поле AddressType типа nvarchar и размерностью 50 символов:

ALTER TABLE [dbo].[Address] 
	ADD [AddressType] NVARCHAR(50)
GO

-- Объявите табличную переменную с такой же структурой как dbo.Address и заполните ее данными из dbo.Address. 
-- Заполните поле AddressType значениями из Person.AddressType поля Name:

DECLARE @AddressTable TABLE (
	[AddressID] [int] NOT NULL,
	[AddressLine1] [nvarchar](60) NOT NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[City] [nvarchar](20) NOT NULL,
	[StateProvinceID] [int] NOT NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[AddressType] [nvarchar](50) NOT NULL
);
INSERT INTO @AddressTable
	([AddressID], [AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [ModifiedDate], [AddressType])
	(SELECT [a].[AddressID], [a].[AddressLine1], [a].[AddressLine2], [a].[City], [a].[StateProvinceID], [a].[PostalCode], [a].[ModifiedDate], [atype].[Name]
	FROM [dbo].[Address] AS a
	INNER JOIN [Person].[BusinessEntityAddress] as bea
	ON [a].[AddressID] = [bea].[AddressID]
	INNER JOIN [Person].[AddressType] as atype
	ON [bea].[AddressTypeID] = [atype].[AddressTypeID])

-- Обновите поле AddressType в dbo.Address данными из табличной переменной. 
-- Также обновите AddressLine2, если значением в поле является NULL — обновите поле данными из AddressLine1:

UPDATE [dbo].[Address]
SET [AddressType] = [atable].[AddressType]
FROM @AddressTable AS atable
WHERE [Address].[StateProvinceID] = [atable].[StateProvinceID]
	AND [Address].[PostalCode] = [atable].[PostalCode]

UPDATE [dbo].[Address]
SET [AddressLine2] = [AddressLine1]
WHERE [AddressLine2] IS NULL

-- Удалите данные из dbo.Address, оставив только по одной строке для каждого AddressType с максимальным AddressID:

DELETE
FROM [dbo].[Address]
WHERE [AddressID] NOT IN (
	SELECT [a].[AddressID] 
	FROM (
		SELECT TOP(1) WITH TIES *
		FROM [dbo].[Address]
		ORDER BY ROW_NUMBER() OVER (PARTITION BY [AddressType] ORDER BY [AddressID] DESC)
	) as a
)

-- Удалите поле AddressType из таблицы, удалите все созданные ограничения и значения по умолчанию;
-- Имена ограничений вы можете найти в метаданных.
-- Имена значений по умолчанию найдите самостоятельно, приведите код, которым пользовались для поиска:

SELECT [name]
FROM [sys].[default_constraints]
WHERE ([parent_object_id] = object_id('[dbo].[Address]') 
	AND [type] = 'D');

ALTER TABLE [dbo].[Address]
	DROP COLUMN [AddressType],
		CONSTRAINT CHK_Address_PostalCode, DF_PostalCode

-- Удалите таблицу dbo.Address:

DROP TABLE [dbo].[Address]

-- --------------------------------------------------------------------------------------------------------------------------------------------

USE [AdventureWorks2012]
GO

-- Выполните код, созданный во втором задании второй лабораторной работы. 
-- Добавьте в таблицу dbo.Address поля CountryRegionCode NVARCHAR(3) и TaxRate SMALLMONEY. 
-- Также создайте в таблице вычисляемое поле DiffMin, считающее разницу между значением в поле TaxRate и минимальной налоговой ставкой 5.00:

ALTER TABLE [dbo].[Address] 
	ADD [CountryRegionCode] NVARCHAR(3), [TaxRate] SMALLMONEY,
		[DiffMin] AS ([TaxRate] - 5.00)
GO

-- Создайте временную таблицу #Address с первичным ключом по полю AddressID. 
-- Временная таблица должна включать все поля таблицы dbo.Address за исключением поля DiffMin:

CREATE TABLE #Address (
	[AddressID] [int] NOT NULL PRIMARY KEY,
	[AddressLine1] [nvarchar](60) NOT NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[City] [nvarchar](20) NOT NULL,
	[StateProvinceID] [int] NOT NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,
	[CountryRegionCode] NVARCHAR(3) NOT NULL,
	[TaxRate] SMALLMONEY NOT NULL
);

-- DROP TABLE #Address

-- Заполните временную таблицу данными из dbo.Address. 
-- Поле CountryRegionCode заполните значениями из таблицы Person.StateProvince.
-- Поле TaxRate заполните значениями из таблицы Sales.SalesTaxRate. 
-- Выберите только те записи, где TaxRate > 5.
-- Выборку данных для вставки в табличную переменную осуществите в Common Table Expression (CTE):

WITH TaxRate_CTE([StateProvinceID], [TaxRate]) AS (
	SELECT [StateProvinceID], [TaxRate]
	FROM [Sales].[SalesTaxRate]
	WHERE [TaxRate] > 5
)
INSERT INTO #Address
	([AddressID], [AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [ModifiedDate],
		[CountryRegionCode], [TaxRate])
	(SELECT [a].[AddressID], [a].[AddressLine1], [a].[AddressLine2], [a].[City], [a].[StateProvinceID], [a].[PostalCode], [a].[ModifiedDate], 
		[sp].[CountryRegionCode], [cte].[TaxRate]
	FROM [dbo].[Address] AS a
	INNER JOIN [Person].[StateProvince] as sp
	ON [a].[StateProvinceID] = [sp].[StateProvinceID]
	INNER JOIN TaxRate_CTE AS cte
	ON [a].[StateProvinceID] = [cte].[StateProvinceID])

-- Удалите из таблицы dbo.Address одну строку (где StateProvinceID = 36):

SET ROWCOUNT 1
DELETE
FROM [dbo].[Address]
WHERE [StateProvinceID] = 36;
SET ROWCOUNT 0

-- Напишите merge-выражение, использующее dbo.Address как target, а временную таблицу как source. 
-- Для связи target и source используйте AddressID. 
-- Обновите поля CountryRegionCode и TaxRate, если запись присутствует в source и target. 
-- Если строка присутствует во временной таблице, но не существует в target, - добавьте строку в dbo.Address. 
-- Если в dbo.Address присутствует такая строка, которой не существует во временной таблице, - удалите строку из dbo.Address.

SET IDENTITY_INSERT [dbo].[Address] ON
MERGE [dbo].[Address] AS target using #Address AS source
ON [target].[AddressID] = [source].[AddressID]
WHEN MATCHED THEN
	UPDATE SET [target].[CountryRegionCode] = [source].[CountryRegionCode], 
		[target].[TaxRate] = [source].[TaxRate]
WHEN NOT MATCHED THEN
	INSERT ([AddressID], [AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [ModifiedDate], [CountryRegionCode], [TaxRate])
	VALUES ([source].[AddressID], [source].[AddressLine1], [source].[AddressLine2], [source].[City], [source].[StateProvinceID], [source].[PostalCode], [source].[ModifiedDate], [source].[CountryRegionCode], [source].[TaxRate])
WHEN NOT MATCHED BY SOURCE THEN
	DELETE;
SET IDENTITY_INSERT [dbo].[Address] OFF