--	Scripts SQL e Tabelas de Sistema - Parte 1: Colunas 
--	por Wagner Crivelini
--	data:Jan/2023

DECLARE @SourceDataType VARCHAR(20)
DECLARE @TargetDataType VARCHAR(20)

SET @SourceDataType = 'TEXT'
SET @TargetDataType = 'VARCHAR(MAX)' 

;
WITH cte AS 
	(
	SELECT O.object_id, ESQ = OBJECT_SCHEMA_NAME (O.object_id), TAB = O.name, COL = C.name, TIPO = T.name, TAMANHO = C.max_length, NULO = C.is_nullable
	FROM sys.objects           O
		INNER JOIN sys.columns C ON O.object_id    = C.object_id
		INNER JOIN sys.types   T ON C.user_type_id = T.user_type_id
	WHERE	O.type_desc = 'USER_TABLE'
		AND	T.name  = @SourceDataType
	)
SELECT declaracaoSQL = 'USE ' + DB_NAME() + ' ;'
UNION ALL
SELECT declaracaoSQL =
	'ALTER TABLE [' + C.ESQ + '].[' + C.TAB + ']    '
	+ 'ALTER COLUMN [' + C.COL + ']   ' + @TargetDataType  + '   ' 
	+ CASE WHEN C.NULO = 0 THEN 'NULL' ELSE 'NOT NULL' END
	+ ' ;'
FROM cte C
GO
