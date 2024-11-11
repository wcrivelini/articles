USE [WideWorldImporters]
GO


CREATE TABLE [Warehouse].[ColdRoomTemperatures2]
(
	[ColdRoomTemperatureID] [bigint] IDENTITY(1,1) NOT NULL,
	[ColdRoomSensorNumber] [int] NOT NULL,
	[RecordedWhen] [datetime2](7) NOT NULL,
	[Temperature] [decimal](10, 2) NOT NULL,
	[ValidFrom] [datetime2](7) NOT NULL,
	[ValidTo] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Warehouse_ColdRoomTemperatures2]  PRIMARY KEY NONCLUSTERED ([ColdRoomTemperatureID] ASC)
)
GO



SET IDENTITY_INSERT [Warehouse].[ColdRoomTemperatures2] ON


INSERT INTO [Warehouse].[ColdRoomTemperatures2]
	(
	 ColdRoomTemperatureID
	,ColdRoomSensorNumber
	,RecordedWhen
	,Temperature
	,ValidFrom
	,ValidTo
	)
SELECT * 
FROM [Warehouse].[ColdRoomTemperatures_Archive]


SET IDENTITY_INSERT [Warehouse].[ColdRoomTemperatures2] OFF
GO



CREATE NONCLUSTERED INDEX ix1_ColdRoom ON [Warehouse].[ColdRoomTemperatures2] (ValidFrom, ValidTo)
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX ix2_ColdRoom ON [Warehouse].[ColdRoomTemperatures2] (ValidFrom, ValidTo)
GO

-- Tamanho dos índices em Megabytes
SELECT i.name AS IDX_NOME, i.type_desc AS IDX_TIPO, SUM(ps.used_page_count) * 8/1024 IDX_Megabytes
FROM sys.indexes i
	INNER JOIN  sys.dm_db_partition_stats ps ON i.object_id = ps.object_id
WHERE i.name IN ('ix1_ColdRoom','ix2_ColdRoom')
GROUP BY i.name, i.type_desc




--Planos de execução da mesma consulta com cada um dos índices
SELECT *
FROM [Warehouse].[ColdRoomTemperatures2] T WITH (index(ix1_ColdRoom))
WHERE T.ValidFrom = '2016-05-31 23:57:49.0000000' AND T.ValidTo = '2016-05-31 23:58:03.0000000'

SELECT *
FROM [Warehouse].[ColdRoomTemperatures2] T WITH (index(ix2_ColdRoom))
WHERE T.ValidFrom = '2016-05-31 23:57:49.0000000' AND T.ValidTo = '2016-05-31 23:58:03.0000000'
