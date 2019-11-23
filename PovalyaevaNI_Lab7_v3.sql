-- Поваляева Н. И., вариант 3

USE [AdventureWorks2012]
GO

-- Выведите значения полей [BusinessEntityID], [FirstName] и [LastName] из таблицы [Person].[Person] в виде xml,
-- сохраненного в переменную. Формат xml должен соответствовать примеру.
-- Создайте временную таблицу и заполните её данными из переменной, содержащей XML.

CREATE TABLE #Persons(
	BusinessEntityID INT PRIMARY KEY,
	FirstName NVARCHAR(50), 
	LastName NVARCHAR(50)
)

DECLARE @persons XML = (
	SELECT [BusinessEntityID] AS "@ID", [FirstName], [LastName]
	FROM [Person].[Person]
	FOR XML PATH('Person'), ROOT('Persons')
)

INSERT INTO #Persons([BusinessEntityID], [FirstName], [LastName])
SELECT 
	Node.Data.value('@ID', 'INT'), 
	Node.Data.value('FirstName[1]', 'NVARCHAR(15)'),
	Node.Data.value('LastName[1]', 'NVARCHAR(50)')
FROM @persons.nodes('/Persons/Person') AS Node(Data)


SELECT * FROM #Persons;