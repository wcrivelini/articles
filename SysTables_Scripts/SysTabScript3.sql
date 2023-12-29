--	Scripts SQL e Tabelas de Sistema - Parte  3: Arquivos de Log
--	por Wagner Crivelini
--	data:Jan/2023


USE master
GO

DECLARE @TargetSizeGB  INTEGER
DECLARE @InitialSizeGB INTEGER

SET @TargetSizeGB  = 10 -- GB
SET @InitialSizeGB = 40 -- GB

; WITH cte AS 
	(
	SELECT 
	     DB       = d.name
	   , Recover  = d.recovery_model_desc
	   , DBstate  = f.state_desc
	   , FileID   = f.file_id   
	   , LogiName = f.name
	   , SizeGB   = CEILING(1.0/128 *(f.size))
	FROM sys.databases d
	   INNER JOIN sys.master_files f ON d.database_id = f.database_id
	WHERE  f.Type       = 1 --LOG
	   AND f.state_desc = 'ONLINE'
	   AND d.database_id > 4  -- exclui bases de sistema
	)
SELECT	DECLARACAO = CHAR(10) + CHAR(10)
	+ 'USE ' + DB + CHAR(10) + 'GO' + CHAR(10) + CHAR(10) 
	+ 'DBCC SHRINKFILE(' + CAST(LogiName AS VARCHAR(100) ) + ', ' 
	+ CAST(@TargetSizeGB AS VARCHAR(10) ) + ');'
FROM cte
WHERE SizeGB >= @InitialSizeGB
ORDER BY DECLARACAO


-- alternativa de esvaziar complementamente o arquivo de log
--dbcc shrinkfile ('Summarize3_data5', emptyfile)