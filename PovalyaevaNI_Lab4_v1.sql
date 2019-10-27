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
	FROM [Production].[WorkOrder];
GO

-- Вставьте новую строку в Production.WorkOrder через представление. 
-- Обновите вставленную строку. Удалите вставленную строку. 
-- Убедитесь, что все три операции отображены в Production.WorkOrderHst.

INSERT INTO [Production].[WorkOrder]
	(ProductID, OrderQty, ScrappedQty, StartDate, DueDate, ModifiedDate)
	VALUES (1, 1, 1, '1968-07-07 00:00:00.000', GETDATE(), GETDATE())

UPDATE [Production].[WorkOrder]
SET [StartDate] = '1941-11-06 00:00:00.000'
WHERE [StartDate] = '1968-07-07 00:00:00.000'

DELETE
FROM [Production].[WorkOrder]
WHERE [StartDate] = '1941-11-06 00:00:00.000'

SELECT *
FROM [Production].[WorkOrderHst]

-- --------------------------------------------------------------------------------------------------------------------------------------------