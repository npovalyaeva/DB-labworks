-- Поваляева Н. И., вариант 3

USE [AdventureWorks2012]
GO

-- Выведите на экран название отдела, где работает каждый сотрудник в настоящий момент:

SELECT [Employee].[BusinessEntityID], [Employee].[JobTitle],
	[Department].[DepartmentID], [Department].[Name]
FROM [HumanResources].[Employee]
INNER JOIN [HumanResources].[EmployeeDepartmentHistory]
ON [Employee].[BusinessEntityID] = [EmployeeDepartmentHistory].[BusinessEntityID]
INNER JOIN [HumanResources].[Department]
ON [EmployeeDepartmentHistory].[DepartmentID] = [Department].[DepartmentID]

-- Выведите на экран количество сотрудников в каждом отделе:

SELECT [Department].[DepartmentID], [Department].[Name], COUNT(*) AS EmpCount
FROM [HumanResources].[EmployeeDepartmentHistory]
INNER JOIN [HumanResources].[Department]
ON [EmployeeDepartmentHistory].[DepartmentID] = [Department].[DepartmentID]
GROUP BY [Department].[DepartmentID], [Department].[Name]

-- Выведите на экран отчет истории изменения почасовых ставок, как показано в примере:

SELECT [Employee].[JobTitle], [EmployeePayHistory].[Rate], [EmployeePayHistory].[RateChangeDate],
	CONCAT('The rate for ', [Employee].[JobTitle], ' was set to ', [EmployeePayHistory].[Rate], ' at ', FORMAT([EmployeePayHistory].[RateChangeDate], 'dd MMM yyyy')) AS 'Report'
FROM [HumanResources].[Employee]
INNER JOIN [HumanResources].[EmployeePayHistory]
ON [Employee].[BusinessEntityID] = [EmployeePayHistory].[BusinessEntityID]


USE [AdventureWorks2012]
GO

-- Создайте таблицу dbo.Address с такой же структурой, как Person.Address, кроме полей geography, uniqueidentifier, 
-- не включая индексы, ограничения и триггеры:

CREATE TABLE [dbo].[Address](
	[AddressID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[AddressLine1] [nvarchar](60) NOT NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[City] [nvarchar](30) NOT NULL,
	[StateProvinceID] [int] NOT NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
)

-- Используя инструкцию ALTER TABLE, создайте для таблицы dbo.Address составной первичный ключ из полей StateProvinceID и PostalCode:

ALTER TABLE [dbo].[Address]
	ADD  PRIMARY KEY ([StateProvinceID], [PostalCode])
GO

-- Используя инструкцию ALTER TABLE, создайте для таблицы dbo.Address ограничение для поля PostalCode, запрещающее заполнение этого поля буквами:

ALTER TABLE [dbo].[Address]
	ADD CONSTRAINT [CHK_Address_PostalCode] 
	CHECK ([PostalCode] NOT LIKE '%[A-Za-z]%');
GO

-- Используя инструкцию ALTER TABLE, создайте для таблицы dbo.Address ограничение DEFAULT для поля ModifiedDate, задайте значением по умолчанию текущую дату и время:

ALTER TABLE [dbo].[Address]
	ADD CONSTRAINT [DF_PostalCode] DEFAULT (GetUtcDate()) FOR [PostalCode];
GO

-- Заполните новую таблицу данными из Person.Address. 
-- Выберите для вставки только те адреса, где значение поля CountryRegionCode = US из таблицы StateProvince. 
-- Также исключите данные, где PostalCode содержит буквы. 
-- Для группы данных из полей StateProvinceID и PostalCode выберите только строки с максимальным AddressID 
-- (это можно осуществить с помощью оконных функций):

SET IDENTITY_INSERT [dbo].[Address] ON
INSERT INTO [dbo].[Address] 
	([AddressID], [AddressLine1], [AddressLine2], [City], [StateProvinceID], [PostalCode], [ModifiedDate])
	(SELECT [a].[AddressID], [a].[AddressLine1], [a].[AddressLine2], [a].[City], [a].[StateProvinceID], [a].[PostalCode], [a].[ModifiedDate]
	FROM (
		SELECT TOP(1) WITH TIES *
		FROM [Person].[Address]
		ORDER BY ROW_NUMBER() OVER (PARTITION BY [StateProvinceID], [PostalCode] ORDER BY [AddressID] DESC)
	) AS a
	INNER JOIN [Person].[StateProvince] AS st
	ON [a].[StateProvinceID] = [st].[StateProvinceID] 
		AND [st].[CountryRegionCode] = 'US'
		AND [a].[PostalCode] NOT LIKE '%[A-Za-z]%')
SET IDENTITY_INSERT [dbo].[Address] OFF 

-- Уменьшите размер поля City на NVARCHAR(20):

ALTER TABLE [dbo].[Address]
	ALTER COLUMN [City] NVARCHAR(20) NOT NULL