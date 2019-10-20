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

-- Удалите поле AddressType из таблицы, удалите все созданные ограничения и значения по умолчанию:

ALTER TABLE [dbo].[Address]
	DROP CONSTRAINT CHK_Address_PostalCode, DF_PostalCode,
    COLUMN [AddressType]

-- Удалите таблицу dbo.Address:

DROP TABLE [dbo].[Address]


USE [AdventureWorks2012]
GO

-- Выполните код, созданный во втором задании второй лабораторной работы. 
-- Добавьте в таблицу dbo.Address поля CountryRegionCode NVARCHAR(3) и TaxRate SMALLMONEY. 
-- Также создайте в таблице вычисляемое поле DiffMin, считающее разницу между значением в поле TaxRate и минимальной налоговой ставкой 5.00:



-- Создайте временную таблицу #Address с первичным ключом по полю AddressID. 
-- Временная таблица должна включать все поля таблицы dbo.Address за исключением поля DiffMin:



-- Заполните временную таблицу данными из dbo.Address. 
-- Поле CountryRegionCode заполните значениями из таблицы Person.StateProvince.
-- Поле TaxRate заполните значениями из таблицы Sales.SalesTaxRate. 
-- Выберите только те записи, где TaxRate > 5.
-- Выборку данных для вставки в табличную переменную осуществите в Common Table Expression (CTE):



-- Удалите из таблицы dbo.Address одну строку (где StateProvinceID = 36):



-- Напишите Merge-выражение, использующее dbo.Address как target, а временную таблицу как source. 
-- Для связи target и source используйте AddressID. 
-- Обновите поля CountryRegionCode и TaxRate, если запись присутствует в source и target. 
-- Если строка присутствует во временной таблице, но не существует в target, - добавьте строку в dbo.Address. 
-- Если в dbo.Address присутствует такая строка, которой не существует во временной таблице, - удалите строку из dbo.Address.