-- ��������� �. �., ������� 3

USE [AdventureWorks2012]
GO

-- �������� � ������� dbo.Address ���� AddressType ���� nvarchar � ������������ 50 ��������:

ALTER TABLE [dbo].[Address] 
	ADD [AddressType] NVARCHAR(50)
GO

-- �������� ��������� ���������� � ����� �� ���������� ��� dbo.Address � ��������� �� ������� �� dbo.Address. 
-- ��������� ���� AddressType ���������� �� Person.AddressType ���� Name:

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

-- �������� ���� AddressType � dbo.Address ������� �� ��������� ����������. 
-- ����� �������� AddressLine2, ���� ��������� � ���� �������� NULL � �������� ���� ������� �� AddressLine1:

UPDATE [dbo].[Address]
SET [AddressType] = [atable].[AddressType]
FROM @AddressTable AS atable
WHERE [Address].[StateProvinceID] = [atable].[StateProvinceID]
	AND [Address].[PostalCode] = [atable].[PostalCode]

UPDATE [dbo].[Address]
SET [AddressLine2] = [AddressLine1]
WHERE [AddressLine2] IS NULL

-- ������� ������ �� dbo.Address, ������� ������ �� ����� ������ ��� ������� AddressType � ������������ AddressID:

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

-- ������� ���� AddressType �� �������, ������� ��� ��������� ����������� � �������� �� ���������;
-- ����� ����������� �� ������ ����� � ����������.
-- ����� �������� �� ��������� ������� ��������������, ��������� ���, ������� ������������ ��� ������:

SELECT [name]
FROM [sys].[default_constraints]
WHERE ([parent_object_id] = object_id('[dbo].[Address]') 
	AND [type] = 'D');

ALTER TABLE [dbo].[Address]
	DROP COLUMN [AddressType],
		CONSTRAINT CHK_Address_PostalCode, DF_PostalCode

-- ������� ������� dbo.Address:

DROP TABLE [dbo].[Address]

-- --------------------------------------------------------------------------------------------------------------------------------------------

USE [AdventureWorks2012]
GO

-- ��������� ���, ��������� �� ������ ������� ������ ������������ ������. 
-- �������� � ������� dbo.Address ���� CountryRegionCode NVARCHAR(3) � TaxRate SMALLMONEY. 
-- ����� �������� � ������� ����������� ���� DiffMin, ��������� ������� ����� ��������� � ���� TaxRate � ����������� ��������� ������� 5.00:

ALTER TABLE [dbo].[Address] 
	ADD [CountryRegionCode] NVARCHAR(3), [TaxRate] SMALLMONEY,
		[DiffMin] AS ([TaxRate] - 5.00)
GO

-- �������� ��������� ������� #Address � ��������� ������ �� ���� AddressID. 
-- ��������� ������� ������ �������� ��� ���� ������� dbo.Address �� ����������� ���� DiffMin:

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

-- ��������� ��������� ������� ������� �� dbo.Address. 
-- ���� CountryRegionCode ��������� ���������� �� ������� Person.StateProvince.
-- ���� TaxRate ��������� ���������� �� ������� Sales.SalesTaxRate. 
-- �������� ������ �� ������, ��� TaxRate > 5.
-- ������� ������ ��� ������� � ��������� ���������� ����������� � Common Table Expression (CTE):

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

-- ������� �� ������� dbo.Address ���� ������ (��� StateProvinceID = 36):

SET ROWCOUNT 1
DELETE
FROM [dbo].[Address]
WHERE [StateProvinceID] = 36;
SET ROWCOUNT 0

-- �������� merge-���������, ������������ dbo.Address ��� target, � ��������� ������� ��� source. 
-- ��� ����� target � source ����������� AddressID. 
-- �������� ���� CountryRegionCode � TaxRate, ���� ������ ������������ � source � target. 
-- ���� ������ ������������ �� ��������� �������, �� �� ���������� � target, - �������� ������ � dbo.Address. 
-- ���� � dbo.Address ������������ ����� ������, ������� �� ���������� �� ��������� �������, - ������� ������ �� dbo.Address.

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