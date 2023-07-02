--====================================================================
--	Analise de Grafos no Azure SQL DB 
--	por Wagner Crivelini
--	06/06/2023
--====================================================================


--====================================================================
--		criacao das tabelas de dados originais
--====================================================================

CREATE SCHEMA source
GO

CREATE TABLE [source].[WorldCup2022_matches](
	  [MatchNumber] [int] NULL
	, [RoundNumber] [varchar](50) NULL
	, [Date] [datetime] NULL
	, [Location] [varchar](200) NULL
	, [HomeTeam] [varchar](50) NULL
	, [AwayTeam] [varchar](50) NULL
	, [Group] [varchar](50) NULL
	, [HomeGoals] [int] NULL
	, [ AwayGoals] [int] NULL
	, [Tie] [varchar](50) NULL
) 
GO

CREATE TABLE [source].[WorldCup2022_players](
	  [Country] [varchar](50) NULL
	, [ShortName] [varchar](50) NULL
	, [Jersey] [int] NULL
	, [Position] [varchar](50) NULL
	, [PLAYER] [varchar](200) NULL
	, [Name] [varchar](200) NULL
	, [LastName] [varchar](200) NULL
	, [NameOnShirt] [varchar](50) NULL
	, [BirhtDate] [date] NULL
	, [CLUB] [varchar](200) NULL
	, [ClubCountry] [varchar](50) NULL
	, [HEIGHT] [int] NULL
	, [appearance] [int] NULL
	, [GOALS] [int] NULL
)
GO


--====================================================================
--		carga de dados
--====================================================================

--importacao de dados
--	arquivo WorldCup2022_matches.csv
--	arquivo WorldCup2022_players.csv

-- limpando dados se necesario
/*
UPDATE source.WorldCup2022_players
SET		COUNTRY  		= TRIM(COUNTRY)
	,	ShortName    	= TRIM(ShortName)
	,	Position    	= TRIM([Position])
	,	PLAYER      	= TRIM(PLAYER)
	,	[Name]      	= TRIM(NAME)
	,	[LastName]  	= TRIM([LastName])
	,	[NameOnShirt]	= TRIM([NameOnShirt])
	,	[CLUB]      	= TRIM([CLUB])
	,	[ClubCountry]	= TRIM([ClubCountry])


UPDATE [source].[WorldCup2022_matches]
SET		[RoundNumber]	= TRIM([RoundNumber])
	,	[Location]  	= TRIM([Location])
	,	[HomeTeam]  	= TRIM([HomeTeam])
	,	[AwayTeam]  	= TRIM([AwayTeam])
	,	[Group]	    	= TRIM([Group])
	,	TIE         	= TRIM(TIE)


*/





--====================================================================
--		criacao do modelo relacional
--====================================================================
CREATE SCHEMA relational
GO 

CREATE TABLE relational.country (
	  countryID   CHAR(3) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
	, continent	  VARCHAR(50)
)
GO

CREATE TABLE relational.club (
	  clubID      INTEGER IDENTITY(1,1) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
	, clubCountry CHAR(3)
)
GO

CREATE TABLE relational.position (
	  positionID  CHAR(2) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
)
GO 

CREATE TABLE relational.player(
	  playerID    INTEGER IDENTITY(1,1) NOT NULL PRIMARY KEY 
	, fullName    VARCHAR(200)
	, firstName   VARCHAR(200)
	, lastName    VARCHAR(200)
	, shirtName   VARCHAR(200)
	, BirhtDate   DATE
	, countryID	CHAR(3)
	, Jersey 	    INTEGER
	, positionID  CHAR(2)
	, clubID      INTEGER
	, height      INTEGER
	, appearance  INTEGER
	, NumGoals    INTEGER -- number of goals in national team
	, player      AS (fullName + ' (' + countryID + ')')

)
GO

CREATE TABLE relational.worldcupgroup (
	  groupID     CHAR(1) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
)
GO 

CREATE TABLE relational.worldcupround (
	  roundID     INTEGER IDENTITY(1,1) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
)
GO 

CREATE TABLE relational.worldcuplocation (
	  locationID  INTEGER IDENTITY(1,1) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
)
GO 


CREATE TABLE relational.worldcupmatch (
	  matchID    INTEGER NOT NULL PRIMARY KEY
	, roundID     INTEGER
	, groupID     CHAR(1)
	, matchDate   DATETIME
	, locationID  INTEGER
	, homeTeam    CHAR(3)
	, awayTeam    CHAR(3)
	, homeGoal    INTEGER
	, awayGoal    INTEGER
	, tie         CHAR(3)
	, winner      AS CASE WHEN homeGoal>awayGoal THEN 'HOME' ELSE CASE WHEN homeGoal<awayGoal THEN 'AWAY' ELSE ISNULL(tie, 'TIE') END END
)
GO 


--====================================================================
--		carga de dados no modelo relacional
--====================================================================



INSERT INTO [relational].[country] (countryID, name)
SELECT DISTINCT trim(P1.ShortName), upper(trim(p1.Country))
FROM [source].[WorldCup2022_players] P1

SELECT DISTINCT p2.clubCountry, CLUB
FROM [source].[WorldCup2022_players] P2
WHERE trim(p2.clubcountry) NOT IN (select countryID FROM [relational].[country])


INSERT INTO [relational].[country] (countryID, name)
VALUES
('AUT', 'AUSTRIA'), 
('CHN', 'CHINA'),  
('COL', 'COLOMBIA'),   
('CYP', 'CYPRUS'),   
('EGY', 'EGYPT'),   
('GRE', 'GREECE'),   
('HUN', 'HUNGARY'),   
('ITA', 'ITALY'),   
('KUW', 'KWAIT'),   
('RUS', 'RUSSIA'),   
('SCO ', 'SCOTLAND'),  
('TUR', 'TURKEY'),   
('UAE', 'UNITED ARAB EMIRATES') 

UPDATE  [relational].[country]
SET continent = 'SOUTH AMERICA'
WHERE countryID IN ('ARG', 'BRA', 'URU', 'PER', 'ECU', 'COL', 'CHI')

UPDATE  [relational].[country]
SET continent = 'NORTH AMERICA'
WHERE countryID IN ('USA', 'MEX', 'CAN', 'CRC' )

UPDATE  [relational].[country]
SET continent = 'OCEANIA'
WHERE countryID IN ('AUS' )

UPDATE  [relational].[country]
SET continent = 'ASIA'
WHERE countryID IN ('CHN', 'IRN', 'JPN' , 'KOR', 'KSA', 'KUW', 'QAT' )

UPDATE  [relational].[country]
SET continent = 'AFRICA'
WHERE countryID IN ('CMR', 'EGY', 'GHA' , 'MAR', 'SEN', 'TUN', 'UAE' )

UPDATE  [relational].[country]
SET continent = 'EUROPE'
WHERE continent IS NULL

SELECT TAB = '[relational].[country]', *
FROM [relational].[country]




INSERT INTO [relational].[club] ([name], [clubCountry])
SELECT DISTINCT CLUB,  p2.clubCountry
FROM [source].[WorldCup2022_players] P2 

SELECT TAB = '[relational].[club]', *
FROM [relational].[club]



INSERT INTO [relational].[position] 
VALUES
('GK', 'GOAL KEEPER'),
('DF', 'DEFENSE'),
('MF', 'MID FIELDER'),
('FW', 'FORWARD')

SELECT TAB = '[relational].[position]', *
FROM [relational].position



INSERT INTO [relational].[player] (fullName, firstName, lastName, shirtName, BirhtDate, countryID, Jersey, positionID, clubID, height, appearance, NumGoals)
SELECT DISTINCT PLAYER, P.Name, LastName, [NameOnShirt], [BirhtDate], countryID, [Jersey], [Position], clubID, [HEIGHT],[appearance], [GOALS]
FROM [source].[WorldCup2022_players] P
	INNER JOIN [relational].[country] C ON P.COUNTRY = C.NAME
	INNER JOIN [relational].[club]  CL  ON P.CLUB = CL.NAME

SELECT TAB = '[relational].[player]', *
FROM [relational].player


	

INSERT INTO [relational].[worldcupgroup]
SELECT DISTINCT ID = CASE WHEN [Group] <> ' ' THEN right([Group], 1)  ELSE 'Z' END  , [Group] = CASE WHEN [Group] <> ' ' THEN [Group] ELSE 'N/A' END
FROM [source].[WorldCup2022_matches]

SELECT TAB = '[relational].[worldcupgroup]', *
FROM [relational].worldcupgroup


INSERT INTO [relational].[worldcuplocation] (name)
SELECT DISTINCT location
FROM [source].[WorldCup2022_matches]

SELECT TAB = '[relational].[worldcuplocation]', *
FROM [relational].worldcuplocation



INSERT INTO [relational].[worldcupround] (name)
SELECT DISTINCT roundnumber
FROM [source].[WorldCup2022_matches]

SELECT TAB = '[relational].[worldcupround]', *
FROM [relational].worldcupround




INSERT INTO [relational].[worldcupmatch] (matchID, roundID, groupID, matchDate, locationID, homeTeam, awayTeam, homeGoal, awayGoal, tie)
SELECT [MatchNumber], R.roundID, COALESCE(G.groupID, 'Z'), [Date], L.locationID, HO.countryID, AW.countryID,  [HomeGoals], [ AwayGoals], [Tie]
FROM [source].[WorldCup2022_matches]    		M
	INNER JOIN [relational].[worldcuplocation]	L  ON M.LOCATION	= L.NAME
	INNER JOIN [relational].[worldcupround] 	R  ON M.ROUNDNUMBER	= R.NAME
	INNER JOIN [relational].[country]       	HO ON M.HOMETEAM	= HO.NAME
	INNER JOIN [relational].[country]       	AW ON M.AWAYTEAM	= AW.NAME
	LEFT JOIN [relational].[worldcupgroup]		G  ON M.[GROUP]  	= G.NAME


SELECT TAB = '[relational].[worldcupmatch]', *
FROM [relational].[worldcupmatch]
GO




 
--====================================================================
--		criacao do modelo de grafos
--====================================================================

CREATE SCHEMA node
GO

CREATE SCHEMA edge
GO

--  nodes
CREATE TABLE node.club (
	  clubID INTEGER NOT NULL PRIMARY KEY
	, club VARCHAR(100)
) AS NODE
GO

CREATE TABLE node.country (
	  countryID   CHAR(3) NOT NULL PRIMARY KEY
	, country        VARCHAR(200)
	, continent	  VARCHAR (50)
)  AS NODE
GO


CREATE TABLE node.player(
	  playerID    INTEGER NOT NULL PRIMARY KEY
	, fullName    VARCHAR(200)
	, firstName   VARCHAR(200)
	, lastName    VARCHAR(200)
	, shirtName   VARCHAR(200)
	, birhtDate   DATE
	, position 	  CHAR(2)
	, jersey      INTEGER
	, height      INTEGER
	, appearance  INTEGER
	, numGoals    INTEGER -- number of goals in national team
	, countryID   CHAR(3)
	, clubID      INTEGER
	, player      AS (fullName + ' (' + countryID + ')')
) AS NODE 
GO

/*

CREATE TABLE node.position (
	  positionID  CHAR(2) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
)
GO

CREATE TABLE node.worldcupgroup (
	  groupID     CHAR(1) NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
) AS NODE
GO 

CREATE TABLE node.worldcupround (
	  roundID     INTEGER NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
) AS NODE
GO 
*/


CREATE TABLE node.worldcuplocation (
	  locationID  INTEGER NOT NULL PRIMARY KEY
	, name        VARCHAR(200)
) AS NODE 
GO


CREATE TABLE node.worldcupmatch (
	  matchID     INTEGER NOT NULL PRIMARY KEY  
	, matchDate   DATETIME
  	, [group] 	  VARCHAR(50) 
	, round 	  VARCHAR(50)
	, homeGoal    INTEGER
	, awayGoal    INTEGER
	, tie         VARCHAR(3)
	, winner      AS CASE WHEN homeGoal>awayGoal THEN 'HOME' ELSE CASE WHEN homeGoal<awayGoal THEN 'AWAY' ELSE ISNULL(tie, 'TIE') END END
) AS NODE
GO


 
--  edges
CREATE TABLE edge.matchXcountry
	(
	  teamStatus VARCHAR(4)
	)
AS EDGE
GO

	
CREATE TABLE edge.matchXlocation
AS EDGE
GO


	
CREATE TABLE edge.playerXclub
	(
	  status VARCHAR(10) DEFAULT 'CURRENT'
	)
AS EDGE
GO


CREATE TABLE edge.playerXcountry
AS EDGE
GO


CREATE TABLE edge.clubXcountry
AS EDGE
GO


CREATE TABLE edge.playerXplayer
	(
	  source VARCHAR(50) -- 'NATIONAL TEAM' or 'CLUB' 
	)
AS EDGE
GO



--====================================================================
--		carga de dados no modelo de grafos
--====================================================================
--nodes
INSERT INTO node.club 
SELECT   clubID , name
FROM relational.club
GO

SELECT TOP 5 * FROM node.club where club like 'B%'

INSERT INTO node.country
SELECT   countryID , name, continent
FROM relational.country
GO

INSERT INTO node.player(playerID , fullName, firstName, lastName, shirtName, birhtDate, position, jersey, height, appearance, numGoals, countryID, clubID)
SELECT   playerID , fullName, firstName, lastName, shirtName, birhtDate, positionID, jersey, height, appearance, numGoals, countryID, clubID
FROM relational.player
GO

INSERT INTO node.worldcuplocation
SELECT  locationID , name
FROM relational.worldcuplocation
GO

INSERT INTO node.worldcupmatch
SELECT  matchID , matchDate, G.name, R.name, homeGoal, awayGoal, tie 
FROM relational.worldcupmatch M
	INNER JOIN relational.worldcupgroup G ON M.groupID = G.groupID
	INNER JOIN relational.worldcupround R ON M.roundID = R.roundID
GO


--edges
INSERT INTO edge.clubXcountry
SELECT NCL.$node_id , NCO.$node_id
FROM node.club NCL
	INNER JOIN relational.club RC 	ON NCL.clubID = RC.clubID
	INNER JOIN node.country NCO 	ON NCO.countryID = RC.clubCountry
GO

INSERT INTO edge.matchXcountry
SELECT NM.$node_id , NCO.$node_id, 'home' AS teamStatus
FROM node.worldcupmatch NM
	INNER JOIN relational.worldcupmatch M ON NM.matchID = M.matchID
	INNER JOIN node.country NCO 	ON NCO.countryID = M.homeTeam
UNION
SELECT NM.$node_id , NCO.$node_id, 'away' AS teamStatus
FROM node.worldcupmatch NM
	INNER JOIN relational.worldcupmatch M ON NM.matchID = M.matchID
	INNER JOIN node.country NCO 	ON NCO.countryID = M.awayTeam
GO


INSERT INTO edge.matchXlocation
SELECT NM.$node_id , NL.$node_id
FROM node.worldcupmatch NM
	INNER JOIN relational.worldcupmatch M ON NM.matchID = M.matchID
	INNER JOIN node.worldcuplocation NL ON M.locationID = NL.locationID

INSERT INTO  edge.playerXclub
SELECT NP.$node_id , NCL.$node_id, status = 'CURRENT' 
FROM node.player NP
	INNER JOIN relational.player RP ON NP.playerID = RP.playerID
	INNER JOIN node.club NCL ON RP.clubID = NCL.clubID

SELECT TOP 5 * FROM edge.playerXclub

INSERT INTO edge.playerXcountry
SELECT NP.$node_id , NCO.$node_id
FROM node.player NP
	INNER JOIN relational.player RP ON NP.playerID = RP.playerID
	INNER JOIN node.country NCO ON RP.countryID = NCO.countryID


;
WITH ctePlayerNationalTeam AS 
	(
	SELECT P1 = NP1.$node_id , P2 = NP2.$node_id, source = 'national team' 
	FROM node.player NP1
		INNER JOIN node.player NP2 ON NP1.countryID = NP2.countryID
	WHERE NP1.player <> NP2.player
	)

INSERT INTO edge.playerXplayer
SELECT * 
FROM ctePlayerNationalTeam
UNION
SELECT NP1.$node_id , NP2.$node_id, source = 'club' 
FROM node.player NP1
	INNER JOIN node.player NP2 ON NP1.clubID = NP2.clubID
WHERE NP1.player <> NP2.player
EXCEPT (
	SELECT NP1=C.P1, NP2=C.P2, source = 'club' 
	FROM ctePlayerNationalTeam c
	)







--====================================================================
--	EXEMPLOS DE CONSULTAS
--====================================================================


-- EXEMPLO 1
-- identificar quem era o time mandante de cada partida e quantos gols ele marcou
--relational
SELECT m.matchID, m.matchDate, G.name AS [group], R.name [round], m.homeTeam, m.homeGoal
FROM relational.worldcupmatch M
	INNER JOIN relational.country		C ON M.homeTeam = C.countryID
	INNER JOIN relational.worldcupgroup	G ON M.groupID  = G.groupID
	INNER JOIN relational.worldcupround	R ON M.roundID  = R.roundID

--graph
SELECT m.matchID, m.matchDate, m.[group], m.round, C1.country , M.homeGoal 
FROM node.country C1
	, edge.matchXcountry MC1
	, node.worldcupmatch M
WHERE MATCH (M - (MC1)-> C1) 
	AND MC1.teamStatus = 'home'


-- EXEMPLO 2
-- lista de jogos completa (time mandantes e visitantes HOME + AWAY)

--relational
SELECT M.matchID, m.matchDate, G.name AS 'group', R.name AS round, score = M.homeTeam + ' ' + CAST( M.homeGoal AS VARCHAR(2)) + ' x ' + CAST( M.awayGoal AS VARCHAR(2)) + ' ' + M.awayTeam
FROM relational.worldcupmatch M
	INNER JOIN relational.worldcupgroup G ON M.groupID = G.groupID
	INNER JOIN relational.worldcupround R ON M.roundID = R.roundID

-- graph
SELECT M.matchID, m.matchDate, m.[group], m.round, score = C1.country + ' ' + CAST( M.homeGoal AS VARCHAR(2)) + ' x ' + CAST( M.awayGoal AS VARCHAR(2)) + ' ' + C2.country 
FROM  node.country C1
	, edge.matchXcountry MC1
	, node.worldcupmatch M
	, node.country C2
	, edge.matchXcountry MC2
WHERE MATCH (C1 <- (MC1)- M - (MC2) -> C2) 
	AND MC1.teamStatus = 'home'
	AND MC2.teamStatus = 'away'



-- EXEMPLO 4
-- qtd de clubes diferentes por seleção
SELECT Country = P.countryID, CNT_CLUB = COUNT(DISTINCT clubID), CNT_PLAYER = COUNT(*)
FROM [relational].[player] P
GROUP BY P.countryID
ORDER BY CNT_CLUB DESC


SELECT Country = NCO.country, CNT_CLUB = COUNT(DISTINCT NCL.club), CNT_PLAYER = COUNT(NP.playerID)
FROM  [node].[player]          	NP
	, [node].[club]	        	NCL
	, [node].[country]			NCO
	, [edge].[playerXclub]		EPCL
	, [edge].[playerXcountry]	EPCO
WHERE MATCH (NCO <- (EPCO) - NP - (EPCL) -> NCL) 
GROUP BY Country
ORDER BY CNT_CLUB DESC




--====================================================================
--	TESTE 1 
--  CLASSIFICAR RELACIONAMENTO ENTRE 1 JOGADOR E DEMAIS ATLETAS 
--	BASEADO NOS CLUBES EM QUE JOGAM
--	Exemplo de relacionamentos
--	1 GRAU : Companheiros de clube do jogador @player
--  2 GRAU : Jogadores que jogam com alguém que joga com Messi
--	3 GRAU : Jogadores que Jogam com alguém q joga com outro alguém que joga com Messi
--	etc
--====================================================================
-- 1o GRAU
DECLARE @player VARCHAR(200) = 'MESSI'
;
WITH 
  cteP0 AS
	(
	SELECT Player0 = P0.fullName + ' (' + P0.countryID + ')'
	FROM relational.player P0
	WHERE P0.shirtName = @player
	)
, cteP1 AS
	(
	SELECT Player = P1.fullName + ' (' + P1.countryID + ')'
		, GRAU      	= 1
		, PathTo    	= P0.Player0 + '==>' + P1.fullName + ' (' + P1.countryID + ')' 
		, fullName1		= P1.fullName
		, countryID1	= P1.countryID
		, clubID1		= P1.clubID
	FROM cteP0 P0, 
		relational.player P1
		INNER JOIN relational.country CO1 ON P1.countryID = CO1.countryID
	WHERE P1.countryID = (SELECT countryID FROM relational.player WHERE shirtName = @player)
		AND P1.shirtName <> @player
	UNION
	SELECT Player   	= P1.fullName + ' (' + P1.countryID + ')'
		, GRAU      	= 1
		, PathTo    	= P0.Player0 + '==>' + P1.fullName + ' (' + P1.countryID + ')' 
		, fullName1		= P1.fullName
		, countryID1	= P1.countryID
		, clubID1		= P1.clubID
	FROM cteP0 P0, 
		relational.player P1
		INNER JOIN relational.club CL1 ON P1.clubID = CL1.clubID
	WHERE P1.clubID = (SELECT clubID FROM relational.player WHERE shirtName = @player)
		AND P1.shirtName <> @player	
		AND P1.countryID <> (SELECT countryID FROM relational.player WHERE shirtName = @player)
	)

-- 2o GRAU: necessário excluir jogadores que já foram classificados como '1o GRAU'
, cteP2 AS
	(
		-- 1o select: contato de 1o grau na seleção nacional, contato de 2o grau no clube
		SELECT Player	= P2.fullName + ' (' + P2.countryID + ')'
			, GRAU  	= 2
			, PathTo	= P0.Player0 + '==>' + CP1.fullName1 + ' (' + CP1.countryID1 + ')' + '==>' + P2.fullName + ' (' + P2.countryID + ')'
		FROM cteP0 P0, 
			cteP1 CP1
			INNER JOIN relational.player P2 ON CP1.clubID1 = P2.clubID  
		WHERE P2.shirtName <> @player
			AND P2.fullName NOT IN (SELECT fullName1 FROM cteP1)
		UNION
		-- 2o select: contato de 1o grau na clube, contato de 2o grau no clube
		SELECT Player	= P2.fullName + ' (' + P2.countryID + ')'
			, GRAU  	= 2
			, PathTo	= P0.Player0 + '==>' + CP1.fullName1 + ' (' + CP1.countryID1 + ')' + '==>' + P2.fullName + ' (' + P2.countryID + ')'
		FROM cteP0 P0, 
			cteP1 CP1
			INNER JOIN relational.player P2 ON CP1.clubID1 = P2.clubID 
		WHERE P2.shirtName <> @player
			AND P2.fullName NOT IN (SELECT fullName1 FROM cteP1)
	)
SELECT GRAU, Player, PathTo
FROM cteP1
UNION 
SELECT GRAU, Player,PathTo
FROM cteP2
go




-- mesma consulta usando GRAFOS
DECLARE @player VARCHAR(200) = 'MESSI'
SELECT 	  Player        = NP1.player
		, GRAU      	= COUNT(NP2.Player)                      WITHIN GROUP (GRAPH PATH)
		, PathTo    	= NP1.player + ' ==> ' + STRING_AGG(NP2.Player, ' ==> ')  WITHIN GROUP (GRAPH PATH)
		, Player2		= LAST_VALUE(NP2.Player)                 WITHIN GROUP (GRAPH PATH) 
FROM  node.player NP1
	, edge.playerXplayer FOR PATH AS EPP
	, node.player        FOR PATH AS NP2
WHERE MATCH(SHORTEST_PATH(NP1(-(EPP)->NP2)+))
	AND NP1.shirtName = @player



--EXPORTING TO VIEW DATA IN POWER BI
SELECT 	  Player1        = NP1.player
		, Player2		= LAST_VALUE(NP2.Player)                 WITHIN GROUP (GRAPH PATH) 
		, GRAU      	= -COUNT(NP2.Player)                     WITHIN GROUP (GRAPH PATH)
FROM  node.player NP1
	, edge.playerXplayer FOR PATH AS EPP
	, node.player        FOR PATH AS NP2
WHERE MATCH(SHORTEST_PATH(NP1(-(EPP)->NP2)+))
