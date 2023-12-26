--	Scripts SQL e Tabelas de Sistema - Parte 2: Índices 
--	por Wagner Crivelini
--	data:Jan/2023




-- selecao de objetos afetados
DROP TABLE IF EXISTS #tempIndices 
GO

DECLARE @SourceDataType VARCHAR(20)
DECLARE @TargetDataType VARCHAR(20)

SET @SourceDataType = 'NVARCHAR'
SET @TargetDataType = 'VARCHAR' 

;
WITH cte AS 
   (
  SELECT DISTINCT O.object_id, I.index_id, ESQ = OBJECT_SCHEMA_NAME (O.object_id)
     , TAB = O.name, IND = I.name  
   FROM sys.objects                O
      INNER JOIN sys.columns       C ON O.object_id    = C.object_id
      INNER JOIN sys.types         T ON C.user_type_id = T.user_type_id
	  INNER JOIN sys.indexes       I ON O.object_id    = I.object_id
	  INNER JOIN sys.index_columns X ON I.object_id    = X.object_id    AND I.index_id = X.index_id AND C.column_id = X.column_id
   WHERE  O.type_desc = 'USER_TABLE'
      AND I.type_desc = 'NONCLUSTERED'
	  AND T.name      = @SourceDataType
	)
SELECT T.ESQ, T.TAB, T.IND
   , I.*
   , ICO = C.name, X.index_column_id, X.column_id, X.key_ordinal
   , X.partition_ordinal, X.is_descending_key, X.is_included_column
INTO #tempIndices
FROM cte                          T
   INNER JOIN sys.indexes         I ON I.object_id = T.object_id AND I.index_id  = T.index_id
   INNER JOIN sys.index_columns   X ON I.object_id = X.object_id AND I.index_id  = X.index_id 
   INNER JOIN sys.columns         C ON X.object_id = C.object_id AND X.column_id = C.column_id




--exclusao de indices
;
WITH cte AS (
	SELECT DISTINCT T.object_id, T.ESQ, T.TAB, T.IND
	FROM #tempIndices T
	)
SELECT DECLARACAO =
        'DROP INDEX IF EXISTS [' + T.IND 
      + '] ON [' + T.ESQ +'].[' + T.TAB + '] ;' 
      + CHAR(10) +  CHAR(10)
FROM  cte T
ORDER BY T.ESQ, T.TAB, T.IND




--criação de índices
;
WITH
--  passo 1 : ordenar as colunas do indice 
cteColIndex AS (
	SELECT
		  T.object_id
		, T.index_id
		, STRING_AGG( '[' + T.ICO + '] ' + CASE WHEN T.is_descending_key = 0 THEN ' ASC' ELSE ' DESC' END, ', ') AS COLUNAAGREG
	FROM #tempIndices	T
	WHERE T.is_included_column = 0
	GROUP BY 
		  T.object_id
		, T.index_id	
	)
,
--	passo 2 : agrupar colunas da clausula INCLUDE
cteColInclude AS (
	SELECT
		  T.object_id
		, T.index_id
		, STRING_AGG( '[' + T.ICO + ']', ', ') AS COLUNAINCLUDE
	FROM #tempIndices	T
	WHERE T.is_included_column = 1
	GROUP BY 
		  T.object_id
		, T.index_id	
	)
,
-- passo 3 : agrupar nomes de indices
cteIndex AS (
	SELECT DISTINCT T.object_id, T.index_id, T.ESQ, T.TAB, T.IND 
		, T.is_unique 
	FROM #tempIndices	T
	)
--	gerando script
SELECT  DECLARACAO =
	  'CREATE ' + CASE WHEN IX.is_unique = 1 THEN 'UNIQUE ' ELSE '' END + 'NONCLUSTERED INDEX [' + IX.IND  + ']'
	+ ' ON [' + IX.ESQ + '].[' + IX.TAB + '] (' + CIX.COLUNAAGREG + ')'
	+ CASE WHEN CINC.COLUNAINCLUDE IS NOT NULL THEN ' INCLUDE (' + CINC.COLUNAINCLUDE + '); ' ELSE ';' END
FROM cteIndex           	IX
	LEFT JOIN cteColIndex	CIX		ON IX.object_id = CIX.object_id  AND IX.index_id = CIX.index_id
	LEFT JOIN cteColInclude CINC	ON IX.object_id = CINC.object_id AND IX.index_id = CINC.index_id
ORDER BY IX.ESQ , IX.TAB , IX.IND


-- execução imediata do script gerado (bloco 1)
declare @sql nvarchar(max) = ''
;
WITH cte AS (
	SELECT DISTINCT T.object_id, T.ESQ, T.TAB, T.IND
	FROM #tempIndices T
	)
SELECT @sql = @sql + 
        'DROP INDEX IF EXISTS [' + T.IND 
      + '] ON [' + T.ESQ +'].[' + T.TAB + '] ;' 
      + CHAR(10) +  CHAR(10)
FROM  cte T
ORDER BY T.ESQ, T.TAB, T.IND

print @sql 
exec (@sql)
