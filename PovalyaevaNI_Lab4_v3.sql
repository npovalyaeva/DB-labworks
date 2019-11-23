-- Поваляева Н. И., вариант 3

USE [AdventureWorks2012]
GO

-- Создайте таблицу Production.WorkOrderHst, которая будет хранить информацию об изменениях в таблице Production.WorkOrder.
-- Обязательные поля, которые должны присутствовать в таблице: 
--	ID — первичный ключ IDENTITY(1,1); 
--	Action — совершенное действие (insert, update или delete); 
--	ModifiedDate — дата и время, когда была совершена операция; 
--	SourceID — первичный ключ исходной таблицы; 
--	UserName — имя пользователя, совершившего операцию. 
-- Создайте другие поля, если считаете их нужными.

CREATE TABLE [Production].[WorkOrderHst](
	[ActionID] [int] IDENTITY(1,1) PRIMARY KEY NOT NULL,
	[Action] [nvarchar](7) NOT NULL CHECK
		([Action] IN ('insert', 'update', 'delete')),
	[ModifiedDate] [datetime] NOT NULL,
	[SourceID] [int] NOT NULL,
	[UserName] [nvarchar](100) NOT NULL
)

-- Создайте один AFTER триггер для трех операций INSERT, UPDATE, DELETE для таблицы Production.WorkOrder. 
-- Триггер должен заполнять таблицу Production.WorkOrderHst с указанием типа операции в поле Action в зависимости от оператора, вызвавшего триггер.

CREATE TRIGGER IUD_Production_WorkOrder_ActionCreation
ON [Production].[WorkOrder]
AFTER
	INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @action varchar(7);
    DECLARE @sourceID int;

    IF EXISTS (SELECT * FROM inserted)
        BEGIN
            IF EXISTS(SELECT * FROM deleted)
                SELECT @action = 'update';
            ELSE
                SELECT @action = 'insert';
			SELECT @sourceID = [WorkOrderID]
            FROM inserted;
        END;
    ELSE
        BEGIN 
            SELECT @action = 'delete';
            SELECT @sourceID = [WorkOrderID]
            FROM deleted;
        END;

    INSERT INTO [Production].[WorkOrderHst]
		([Action], [ModifiedDate], [SourceID], [UserName])
    VALUES (@action, GETDATE(), @sourceID, USER_NAME());
END

-- Создайте представление VIEW, отображающее все поля таблицы Production.WorkOrder.

CREATE VIEW WorkOrders AS
	SELECT *
	FROM [Production].[WorkOrder]

-- Вставьте новую строку в Production.WorkOrder через представление. 
-- Обновите вставленную строку. Удалите вставленную строку. 
-- Убедитесь, что все три операции отображены в Production.WorkOrderHst.

INSERT INTO [Production].[WorkOrder]
	(ProductID, OrderQty, ScrappedQty, StartDate, DueDate, ModifiedDate)
	VALUES (1, 1, 1, '1968-07-07 00:00:00.000', GETDATE(), GETDATE())

UPDATE [Production].[WorkOrder]
SET [StartDate] = '1940-11-06 00:00:00.000'
WHERE [StartDate] = '1968-07-07 00:00:00.000'

DELETE
FROM [Production].[WorkOrder]
WHERE [StartDate] = '1940-11-06 00:00:00.000'

SELECT *
FROM [Production].[WorkOrderHst]

-- --------------------------------------------------------------------------------------------------------------------------------------------

USE [AdventureWorks2012]
GO

-- Создайте представление VIEW, отображающее данные из таблиц Production.WorkOrder и Production.ScrapReason, 
-- а также Name из таблицы Production.Product. Сделайте невозможным просмотр исходного кода представления.
-- Создайте уникальный кластерный индекс в представлении по полю WorkOrderID.

CREATE VIEW ExtendedWorkOrders
    WITH SCHEMABINDING
	AS
	SELECT [wo].[WorkOrderID], [wo].[OrderQty], [wo].[StockedQty], [wo].[ScrappedQty], 
		[wo].[StartDate], [wo].[EndDate], [wo].[DueDate], [wo].[ModifiedDate],
		[sr].[ScrapReasonID], [sr].[Name] AS [ScrapReasonName], [sr].[ModifiedDate] AS [ScrapReasonModifiedDate],
		[p].[ProductID], [p].[Name] AS [ProductName]
	FROM [Production].[WorkOrder] AS wo
	INNER JOIN [Production].[ScrapReason] as sr
		ON [wo].[ScrapReasonID] = [sr].[ScrapReasonID]
	INNER JOIN [Production].[Product] AS p
		ON [wo].[ProductID] = [p].[ProductID];

CREATE UNIQUE CLUSTERED INDEX WORK_ORDER_INDEX
ON ExtendedWorkOrders (WorkOrderID);

-- Создайте три INSTEAD OF триггера для представления на операции INSERT, UPDATE, DELETE. 
-- Каждый триггер должен выполнять соответствующие операции в таблицах Production.WorkOrder и Production.ScrapReason 
-- для указанного Product Name. Обновление и удаление строк производите только в таблицах Production.WorkOrder и 
-- Production.ScrapReason, но не в Production.Product. 
-- В UPDATE-триггере не указывайте обновление поля OrderQty для таблицы Production.WorkOrder.

CREATE TRIGGER I_Task_4_2
ON [dbo].[ExtendedWorkOrders]
INSTEAD OF 
	INSERT AS
BEGIN 
	INSERT INTO [Production].[WorkOrder]
		([ProductID], [OrderQty], [ScrappedQty], [StartDate], [EndDate], [DueDate], [ScrapReasonID], [ModifiedDate])
	SELECT [p].[ProductID], [OrderQty], [ScrappedQty], [StartDate], [EndDate], [DueDate], [sr].[ScrapReasonID], [sr].[ModifiedDate]
	FROM inserted
		INNER JOIN [Production].[Product] AS p
			ON inserted.[ProductName] = [p].[Name]
		INNER JOIN [Production].[ScrapReason] AS sr 
			ON inserted.[ScrapReasonModifiedDate]  = [sr].[ModifiedDate];

	INSERT INTO [Production].[ScrapReason] ([Name], [ModifiedDate])
	SELECT [ScrapReasonName],  [ScrapReasonModifiedDate] 
	FROM inserted;
END;
GO

CREATE TRIGGER U_Task_4_2
ON [dbo].[ExtendedWorkOrders]
INSTEAD OF 
	UPDATE AS
BEGIN
	UPDATE [Production].[WorkOrder]
	SET 
		[ScrappedQty] = inserted.[ScrappedQty],
		[StartDate] = inserted.[StartDate],
		[EndDate] = inserted.[EndDate],
		[DueDate] = inserted.[DueDate],
		[ModifiedDate] = inserted.[ModifiedDate]	
	FROM inserted
	WHERE inserted.[ProductID] = [Production].[WorkOrder].[ProductID];

	UPDATE [Production].[ScrapReason]
	SET 
		[Name] = inserted.[ScrapReasonName],
		[ModifiedDate] = inserted.[ScrapReasonModifiedDate]
	FROM inserted
	WHERE inserted.[ScrapReasonID] = [Production].[ScrapReason].[ScrapReasonID] 
END;
GO

CREATE TRIGGER D_Task_4_2
ON [dbo].[ExtendedWorkOrders]
INSTEAD OF 
	DELETE	AS
BEGIN
	DELETE [wo] FROM [Production].[WorkOrder] AS wo
	INNER JOIN deleted 
		ON [wo].[ScrapReasonID] = deleted.[ScrapReasonID]
	INNER JOIN [Production].[Product] AS p 
		ON deleted.[ProductName] = [p].[Name]
	WHERE [wo].[ProductID] = [p].[ProductID];

	DELETE [sr] FROM [Production].[ScrapReason] AS sr
	INNER JOIN deleted	
		ON deleted.[ScrapReasonID] = [sr].[ScrapReasonID]
END;
GO

-- Вставьте новую строку в представление, указав новые данные для WorkOrder и ScrapReason, 
-- но для существующего Product (например для ‘Adjustable Race’). 
-- Триггер должен добавить новые строки в таблицы Production.WorkOrder и Production.ScrapReason для указанного Product Name. 
-- Обновите вставленные строки через представление. Удалите строки.

INSERT INTO [dbo].[ExtendedWorkOrders]
	([WorkOrderID], [OrderQty], [ScrappedQty], [ProductName], [StartDate], [EndDate], [DueDate], [ModifiedDate], [ScrapReasonName], [ScrapReasonModifiedDate]) 
VALUES 
	(1, 1, 0, 'Adjustable Race', GETDATE(), GETDATE(), GETDATE(), GETDATE(),  'Oh no!', GETDATE());

UPDATE [dbo].[ExtendedWorkOrders]
SET [OrderQty] = 0
WHERE [ProductName] = 'Adjustable Race';

DELETE [dbo].[ExtendedWorkOrders]
WHERE [ProductName] = 'Adjustable Race';