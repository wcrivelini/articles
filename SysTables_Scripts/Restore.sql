-- ARTIGO 1 

-- ATTENTION TO DATA & LOG FOLDER PERMISSIONS
-- https://stackoverflow.com/questions/64027947/unable-to-open-the-physical-file-operating-system-error-5-5access-is-denied

RESTORE FILELISTONLY 
   FROM DISK ='C:\DB\Bak\AdventureWorksDW2012.bak'


RESTORE DATABASE AdventureWorksDW2012
   FROM DISK = 'C:\DB\Bak\AdventureWorksDW2012.bak'
   WITH RECOVERY,
   MOVE 'AdventureWorksDW2012'		TO 'C:\temp\DB\Data\AdventureWorksDW2012.mdf',
   MOVE 'AdventureWorksDW2012_log'	TO 'C:\temp\DB\LOG\AdventureWorksDW2012_log.ldf' 
GO



-- ARTIGO 2
-- https://stackoverflow.com/questions/64027947/unable-to-open-the-physical-file-operating-system-error-5-5access-is-denied

RESTORE FILELISTONLY 
   FROM DISK ='C:\DB\Bak\AdventureWorks2022.bak'


RESTORE DATABASE AdventureWorks
   FROM DISK = 'C:\DB\Bak\AdventureWorks2022.bak'
   WITH RECOVERY,
   MOVE 'AdventureWorks2022'		TO 'C:\temp\DB\Data\AdventureWorks2022.mdf',
   MOVE 'AdventureWorks2022_log'	TO 'C:\temp\DB\LOG\AdventureWorks2022_log.ldf' 
GO




-- ARTIGO 4
-- https://learn.microsoft.com/pt-br/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms
-- https://learn.microsoft.com/en-us/sql/relational-databases/security/ledger/ledger-how-to-append-only-ledger-tables?view=sql-server-ver16
-- https://learn.microsoft.com/en-us/sql/relational-databases/security/ledger/ledger-how-to-updatable-ledger-tables?view=sql-server-ver16


RESTORE FILELISTONLY 
   FROM DISK ='C:\DB\Bak\AdventureWorks2022.bak'


RESTORE DATABASE AdventureWorks2022
   FROM DISK = 'C:\DB\Bak\AdventureWorks2022.bak'
   WITH RECOVERY,
   MOVE 'AdventureWorks2022'		TO 'C:\temp\DB\Data\AdventureWorks2022.mdf',
   MOVE 'AdventureWorks2022_log'	TO 'C:\temp\DB\LOG\AdventureWorks2022_log.ldf' 
GO



RESTORE FILELISTONLY 
   FROM DISK ='C:\DB\Bak\AdventureWorksDW2022.bak'


RESTORE DATABASE AdventureWorksDW2022
   FROM DISK = 'C:\DB\Bak\AdventureWorksDW2022.bak'
   WITH RECOVERY,
   MOVE 'AdventureWorksDW2022'		TO 'C:\temp\DB\Data\AdventureWorksDW2022.mdf',
   MOVE 'AdventureWorksDW2022_log'	TO 'C:\temp\DB\LOG\AdventureWorksDW2022_log.ldf' 
GO




-- CRIANDO TABELAS LEDGER
USE tempX
GO

CREATE SCHEMA [AccessControl];
GO
CREATE TABLE [AccessControl].[KeyCardEvents]
   (
      [EmployeeID] INT NOT NULL,
      [AccessOperationDescription] NVARCHAR (1024) NOT NULL,
      [Timestamp] Datetime2 NOT NULL
   )
   WITH (LEDGER = ON (APPEND_ONLY = ON));


INSERT INTO [AccessControl].[KeyCardEvents]
VALUES ('43869', 'Building42', '2020-05-02T19:58:47.1234567');



CREATE SCHEMA [Account];
GO  
CREATE TABLE [Account].[Balance]
(
    [CustomerID] INT NOT NULL PRIMARY KEY CLUSTERED,
    [LastName] VARCHAR (50) NOT NULL,
    [FirstName] VARCHAR (50) NOT NULL,
    [Balance] DECIMAL (10,2) NOT NULL
)
WITH 
(
 SYSTEM_VERSIONING = ON (HISTORY_TABLE = [Account].[BalanceHistory]),
 LEDGER = ON
);


INSERT INTO [Account].[Balance]
VALUES (1, 'Jones', 'Nick', 50);


INSERT INTO [Account].[Balance]
VALUES (2, 'Smith', 'John', 500),
(3, 'Smith', 'Joe', 30),
(4, 'Michaels', 'Mary', 200);



UPDATE [Account].[Balance] SET [Balance] = 100
WHERE [CustomerID] = 1;


