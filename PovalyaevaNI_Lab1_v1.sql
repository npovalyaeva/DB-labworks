-- Поваляева Н. И., вариант 3

USE [AdventureWorks2012]
GO

-- Выведите на экран список отделов, названия которых начинаются на букву ‘P’:

SELECT [DepartmentID], [Name]
FROM [HumanResources].[Department]
WHERE [Name] LIKE 'P%'

-- Выведите на экран список сотрудников, у которых осталось больше 10, но меньше 13 часов отпуска (включая эти значения). 
-- Выполните задание, не используя операторы '<', '>', '=':

SELECT [BusinessEntityID], [JobTitle], [Gender], [VacationHours], [SickLeaveHours]
FROM [HumanResources].[Employee]
WHERE [VacationHours] BETWEEN 10 AND 13

-- Выведите на экран сотрудников, которых приняли на работу 1-ого июля (любого года). 
-- Отсортируйте результат по возрастанию BusinessEntityID. 
-- Выведите на экран только 5 строк, пропустив первые 3.

SELECT [BusinessEntityID], [JobTitle], [Gender], [BirthDate], [HireDate]
FROM [HumanResources].[Employee]
WHERE MONTH([HireDate]) = 7 AND DAY([HireDate]) = 1
ORDER BY [BusinessEntityID] ASC
OFFSET (3) ROWS FETCH NEXT (5) ROWS ONLY