--	Scripts SQL e Tabelas de Sistema - Parte 4: Atuando em Toda Instância 
--	por Wagner Crivelini
--	data:Jan/2023


-- dependendo da versão do SQL, algumas dessas opções não estarão ativadas 
-- e a consulta vai gerar erro
-- comente as linhas que falharem
SELECT DB  = DB_NAME()
	, TAB  = S.name + '.' + T.name
	, TIPO = CASE
				WHEN T.temporal_type        	= 2 THEN 'TABELA TEMPORAL (PRINCIPAL)'
				WHEN T.temporal_type        	= 1 THEN 'TABELA TEMPORAL (HISTÓRICA)'
				WHEN T.is_replicated        	= 1 THEN 'TABELA REPLICADA'
				WHEN T.is_memory_optimized   	= 1 THEN 'TABELA EM MEMORIA'
				WHEN T.is_external          	= 1 THEN 'TABELA EXTERNA'
				WHEN T.is_node              	= 1 THEN 'TABELA DE GRAFOS (NÓS)'
				WHEN T.is_edge              	= 1 THEN 'TABELA DE GRAFOS (BORDAS)'
				WHEN T.ledger_type          	= 1 THEN 'TABELA DE LEDGER (HISTÓRICA)'
				WHEN T.ledger_type          	= 2 THEN 'TABELA DE LEDGER (UPDATABLE)'
				WHEN T.ledger_type           	= 3 THEN 'TABELA DE LEDGER (APPEND_ONLY)'
				WHEN T.is_dropped_ledger_table 	= 1 THEN 'TABELA DE LEDGER EXCLUÍDA'
				ELSE 'COMUM'
				END
FROM sys.tables T
	INNER JOIN sys.schemas S ON T.schema_id = S.schema_id




-- GERANDO A DECLARAÇÃO COM A VARREDURA DAS BASES DE DADOS DE USUÁRIO
USE master
GO

-- alternativa para o uso de variável de tabela (definido no fim do script)
--DROP TABLE IF EXISTS #tmpTables
--GO

--CREATE TABLE #tmpTables (
--	  DB	VARCHAR(200)
--	, TAB 	VARCHAR(200)
--	, TIPO	VARCHAR(50)
--);

DECLARE @sql NVARCHAR(MAX) = ''

SELECT
   @sql = @sql 
	    + ' SELECT DB  = ''' + D.name + ''' '
	    + ', TAB  = S.name + ''.'' + T.name '
		+ ', TIPO = CASE '
				+ ' WHEN T.temporal_type        	= 2 THEN ''TABELA TEMPORAL (PRINCIPAL)'' '
				+ ' WHEN T.temporal_type        	= 1 THEN ''TABELA TEMPORAL (HISTÓRICA)'' '
				+ ' WHEN T.is_replicated        	= 1 THEN ''TABELA REPLICADA'' '
				+ ' WHEN T.is_memory_optimized   	= 1 THEN ''TABELA EM MEMORIA'' '
				+ ' WHEN T.is_external          	= 1 THEN ''TABELA EXTERNA'' '
				+ ' WHEN T.is_node              	= 1 THEN ''TABELA DE GRAFOS (NÓS)'' '
				+ ' WHEN T.is_edge              	= 1 THEN ''TABELA DE GRAFOS (BORDAS)'' '
				+ ' WHEN T.ledger_type          	= 1 THEN ''TABELA DE LEDGER (HISTÓRICA)'' '
				+ ' WHEN T.ledger_type          	= 2 THEN ''TABELA DE LEDGER (UPDATABLE)'' '
				+ ' WHEN T.ledger_type           	= 3 THEN ''TABELA DE LEDGER (APPEND_ONLY)'' '
				+ ' WHEN T.is_dropped_ledger_table 	= 1 THEN ''TABELA DE LEDGER EXCLUÍDA'' '
				+ ' ELSE ''COMUM'' '
				+ ' END '
	    + ' FROM ' +  D.name  + '.sys.tables T '
	    + ' INNER JOIN ' +  D.name  + '.sys.schemas S ON T.schema_id = S.schema_id '
        + ' UNION '
FROM sys.databases D
WHERE database_id > 4 -- exclui as bases de dados de sistema

print @sql


DECLARE @varTables TABLE (
	  DB	VARCHAR(200)
	, TAB 	VARCHAR(200)
	, TIPO	VARCHAR(50)
)

SELECT @sql = LEFT(@sql, LEN(@sql) - 6)

INSERT INTO @varTables
EXEC sp_executesql @sql

SELECT * FROM @varTables


SELECT DB = CASE WHEN GROUPING(T.DB)  = 0 THEN T.DB   ELSE '_TOTAL' END 
	,TIPO = CASE WHEN GROUPING(T.TIPO)= 0 THEN T.TIPO ELSE '_TOTAL' END 
	, CNT = COUNT(*)
FROM @varTables T
GROUP BY DB, TIPO WITH ROLLUP


