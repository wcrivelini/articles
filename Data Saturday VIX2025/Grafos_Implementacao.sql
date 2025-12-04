--====================================================================
--	Analise de Grafos no Azure SQL DB 
--	por Wagner Crivelini
--	06/dez/2025
--====================================================================

/*
Este script traz o modelo completo de dados apresentado na palestra "Análise de Grafos no Azure SQL DB"

É necessário
1. criar um banco de dados no SQL SERVER (2017 ou superior) ou no AZURE SQL
2. seguir os "blocos" de ativdades apresentados neste script
3. para importar os 2 arquivos CSV fornecidos neste pacote, sugiro usar o assistente de importação do SSMS:
	- abra o SSMS e expanda a guia DATABASES
	- marque a base de dados que foi criada para esta demo
	- clique o botão invertido do mouse e depois clique nos menus TASKS e em seguida IMPORT DATA
	- siga as etapas de configuração para importação dos dados (para mais informações pesquise sobre videos que mostram este assitente)
*/


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
--		carga de dados: use o assistente de importação do SSMS
--====================================================================

--importacao de dados
--	arquivo WorldCup2022_matches.csv
--	arquivo WorldCup2022_players.csv

-- caso seja necessario limpar os dados (elimininar espaços em branco, etc)
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



SELECT * FROM [source].[WorldCup2022_matches]
SELECT * FROM [source].[WorldCup2022_players]
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
	, countryID   CHAR(3)
	, Jersey 	  INTEGER
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
--		carga de dados (source) para o modelo relacional
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

-- adicionando informação sobre continentes (que não existe nos arquivos originais)
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

--verificacao
SELECT TAB = '[relational].[club]', *
FROM [relational].[club]



INSERT INTO [relational].[position] 
VALUES
('GK', 'GOAL KEEPER'),
('DF', 'DEFENSE'),
('MF', 'MID FIELDER'),
('FW', 'FORWARD')

--verificacao
SELECT TAB = '[relational].[position]', *
FROM [relational].position



INSERT INTO [relational].[player] (fullName, firstName, lastName, shirtName, BirhtDate, countryID, Jersey, positionID, clubID, height, appearance, NumGoals)
SELECT DISTINCT PLAYER, P.Name, LastName, [NameOnShirt], [BirhtDate], countryID, [Jersey], [Position], clubID, [HEIGHT],[appearance], [GOALS]
FROM [source].[WorldCup2022_players] P
	INNER JOIN [relational].[country] C ON P.COUNTRY = C.NAME
	INNER JOIN [relational].[club]  CL  ON P.CLUB = CL.NAME

	--verificacao
SELECT TAB = '[relational].[player]', *
FROM [relational].player


	

INSERT INTO [relational].[worldcupgroup]
SELECT DISTINCT ID = CASE WHEN [Group] <> ' ' THEN right([Group], 1)  ELSE 'Z' END  , [Group] = CASE WHEN [Group] <> ' ' THEN [Group] ELSE 'N/A' END
FROM [source].[WorldCup2022_matches]

--verificacao
SELECT TAB = '[relational].[worldcupgroup]', *
FROM [relational].worldcupgroup


INSERT INTO [relational].[worldcuplocation] (name)
SELECT DISTINCT location
FROM [source].[WorldCup2022_matches]

--verificacao
SELECT TAB = '[relational].[worldcuplocation]', *
FROM [relational].worldcuplocation



INSERT INTO [relational].[worldcupround] (name)
SELECT DISTINCT roundnumber
FROM [source].[WorldCup2022_matches]

--verificacao
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

--verificacao
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

--=============================================================
--  nodes 
--  (são as tabelas de entidades ou nós)
--=============================================================
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
-- estas entidades do modelo de grafos estão comentadas
-- porque nao serao usadas no contexto das análises esperadas destes dados
-- de qualquer maneira, não seria difícil adicionar as entidades e relaçoes/bordas correspondentes

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


--============================================================= 
--  edges
--  (sao os relacionamentos/bordas que interligam os nós)
--=============================================================
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
--		carga de dados para o modelo de grafos
--====================================================================
-- esta é provavelmente a tarefa mais complicada 
-- para construcao do modelo de grafos
-- a carga para os nós é meio que elementar
-- mas a carga das bordas pode ser um tanto confusa no começo

--nodes
INSERT INTO node.club 
SELECT   clubID , name
FROM relational.club
GO

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

INSERT INTO edge.playerXcountry
SELECT NP.$node_id , NCO.$node_id
FROM node.player NP
	INNER JOIN relational.player RP ON NP.playerID = RP.playerID
	INNER JOIN node.country NCO ON RP.countryID = NCO.countryID


INSERT INTO edge.playerXplayer
SELECT NP1.$node_id , NP2.$node_id, source = 'national team' 
FROM node.player NP1
	INNER JOIN node.player NP2 ON NP1.countryID = NP2.countryID
WHERE NP1.player <> NP2.player


INSERT INTO edge.playerXplayer
SELECT NP1.$node_id , NP2.$node_id, source = 'club' 
FROM node.player NP1
	INNER JOIN node.player NP2 ON NP1.clubID = NP2.clubID
WHERE NP1.player <> NP2.player
EXCEPT (
		SELECT NP1=NP1.$node_id, NP2=NP2.$node_id, source = 'club' --<======== ATENCAO: o registro todo deve ser igual ao da tabela anterior
		FROM node.player NP1
			INNER JOIN node.player NP2 ON NP1.countryID = NP2.countryID
		WHERE NP1.player <> NP2.player
		) 





--====================================================================
--	ANALISANDO DADOS 
--  Comparativo entre modelo relacional com modelo de grafos
--====================================================================


-- EXEMPLO 1
SELECT * FROM node.country



-- EXEMPLO 2
-- lista de jogos com os times mandantes (HOME)
SELECT M.matchID, m.matchDate, m.[group], m.round
	, score = C1.countryID + ' ' + CAST( M.homeGoal AS VARCHAR(2)) + ' x ' + CAST( M.awayGoal AS VARCHAR(2)) + ' "visitante"' 
	, resultado =
		CASE WHEN M.homeGoal >  M.awayGoal 
		THEN 'GANHOU' 
		ELSE 
			CASE WHEN M.homeGoal < M.awayGoal 
			THEN 'PERDEU'
			ELSE 'EMPATOU'
			END
		END
FROM  node.country C1
	, edge.matchXcountry MC1
	, node.worldcupmatch M
WHERE MATCH (M - (MC1)-> C1) 
	AND MC1.teamStatus = 'home'


-- EXEMPLO 3
-- lista de jogos completa (time mandantes e visitantes HOME + AWAY)

--relational
SELECT M.matchID, m.matchDate, G.name AS 'group', R.name AS round, score = M.homeTeam + ' ' + CAST( M.homeGoal AS VARCHAR(2)) + ' x ' + CAST( M.awayGoal AS VARCHAR(2)) + ' ' + M.awayTeam
FROM relational.worldcupmatch M
	INNER JOIN relational.worldcupgroup G ON M.groupID = G.groupID
	INNER JOIN relational.worldcupround R ON M.roundID = R.roundID

-- graph
SELECT M.matchID, m.matchDate, m.[group], m.round
	, score = C1.countryID + ' ' + CAST( M.homeGoal AS VARCHAR(2)) + ' x ' + CAST( M.awayGoal AS VARCHAR(2)) + ' ' + C2.countryID 
	, resultado =
		CASE WHEN M.homeGoal >  M.awayGoal 
		THEN 'GANHOU' 
		ELSE 
			CASE WHEN M.homeGoal < M.awayGoal 
			THEN 'PERDEU'
			ELSE 'EMPATOU'
			END
		END
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
--	QUANDO O MODELO DE GRAFOS FAZ A DIFERENCA
-- ===================================================================
--
--  Algumas consultas mais complexas podem ser feitas muito mais simples
--  quando se usa o modelo de grafos
--  No modelo relacional é muito fácil analisar as relações entre tabelas.
--  A entidade no modelo relacional É UMA TABELA
--
--  O modelo de grafo foca nos ELEMENTOS DA TABELA: cada pessoa, produto, fornecedor,etc
--  A entidade no modelo grafos É UM "INDIVIDUO", ou seja, cada elemento da tabela relacional
--
--
--  SITUAÇAO 1:  CONSIDERE OS DADOS REFERENTES A COPA DO MUNDO DE 2022 (dados que foram importados)
--			     CLASSIFIQUE O RELACIONAMENTO ENTRE 1 JOGADOR QUALQUER E OS DEMAIS ATLETAS DO EVENTO
--	Exemplo de relacionamentos
--	1 GRAU : Jogadores que estão na COPA E são companheiros de SELEÇÃO ou de CLUBE do jogador @player
--  2 GRAU : Jogadores que estão na COPA E jogam em seleção ou clube com alguém que joga com algum atleta do nível 1
--	etc
--====================================================================
DECLARE @player VARCHAR(200) = 'MESSI'
-- testar duplicidade com 'NEYMAR JR'
;
WITH 
  -- jogador selecionado no NIVEL 0
  cteP0 AS
	(
	SELECT Player0 = P0.fullName + ' (' + P0.countryID + ')', clubID, countryID
	FROM relational.player P0
	WHERE P0.shirtName = @player
	)
-- ======================================================================================================
--	1 GRAU : Jogadores que estão na COPA E são companheiros de SELEÇÃO ou de CLUBE do jogador @player
-- ======================================================================================================
, cteP1country AS
	(
	-- jogam com @player na seleção
	SELECT Player1 = P1.fullName + ' (' + P1.countryID + ')'
		, GRAU      	= 1
		, PathTo    	= P0.Player0 + '==>' + P1.fullName + ' (' + P1.countryID + ')' 
		, fullName1		= P1.fullName
		, countryID1	= P1.countryID
		, clubID1		= P1.clubID
	FROM cteP0 P0 
		INNER JOIN relational.player P1 ON P1.countryID = P0.countryID
		INNER JOIN relational.country CO1 ON P1.countryID = CO1.countryID
	WHERE P1.shirtName <> @player
	)
, cteP1club AS
	(
	-- jogam com @player em clube
	SELECT Player1 = P1.fullName + ' (' + P1.countryID + ')'
		, GRAU      	= 1
		, PathTo    	= P0.Player0 + '==>' + P1.fullName + ' (' + P1.countryID + ')' 
		, fullName1		= P1.fullName
		, countryID1	= P1.countryID
		, clubID1		= P1.clubID
	FROM cteP0 P0 
		INNER JOIN relational.player P1 ON P1.clubID = P0.clubID
		INNER JOIN relational.country CO1 ON P1.countryID = CO1.countryID
	WHERE P1.shirtName <> @player
	)
, cteP1 AS
	(
	SELECT * FROM cteP1country
	UNION  -- tem que ser UNION pra evitar duplicidade
	SELECT * FROM cteP1club
	)
-- ======================================================================================================
--  2 GRAU : Jogadores que estão na COPA e jogam com algum atleta do nível 1 
-- ======================================================================================================
, cteP2country AS
	(
		-- jogam com algum jogador do nivel 1 em seleção
		SELECT DISTINCT Player2	= P2.fullName + ' (' + P2.countryID + ')'
			, GRAU  	= 2
			, PathTo	= CP1.PathTo + '==>' + P2.fullName + ' (' + P2.countryID + ')'
		FROM cteP1 CP1
			INNER JOIN relational.player P2 ON CP1.countryID1 = P2.countryID
		WHERE P2.shirtName <> @player
			AND P2.fullName + ' (' + P2.countryID + ')' NOT IN (SELECT Player1 FROM cteP1)
	)
, cteP2club AS
	(
		-- jogam com algum jogador do nivel 1 em club
		SELECT DISTINCT Player2	= P2.fullName + ' (' + P2.countryID + ')'
			, GRAU  	= 2
			, PathTo	= CP1.PathTo + '==>' + P2.fullName + ' (' + P2.countryID + ')'
		FROM cteP1 CP1
			INNER JOIN relational.player P2 ON CP1.clubID1 = P2.clubID
		WHERE P2.shirtName <> @player
			AND P2.fullName + ' (' + P2.countryID + ')' NOT IN (SELECT Player1 FROM cteP1)
			AND P2.fullName + ' (' + P2.countryID + ')' NOT IN (SELECT Player2 FROM cteP2country)
	)
, cteP2 AS
	(
	SELECT * FROM cteP2country
	UNION  -- tem que ser UNION pra evitar duplicidade
	SELECT * FROM cteP2club
	)
SELECT @player AS Player0, GRAU, Player1 AS Player, PathTo
FROM cteP1
UNION 
SELECT @player AS Player0, GRAU, Player2 AS Player,PathTo
FROM cteP2
ORDER BY GRAU, Player
go




-- mesma consulta usando GRAFOS
DECLARE @player VARCHAR(200) = 'MESSI'
SELECT 	  Player        = NP1.player
		, GRAU      	= COUNT(NP2.Player)                      WITHIN GROUP (GRAPH PATH)
		, Player2		= LAST_VALUE(NP2.Player)                 WITHIN GROUP (GRAPH PATH) 
		, PathTo    	= NP1.player + ' ==> ' + STRING_AGG(NP2.Player, ' ==> ')  WITHIN GROUP (GRAPH PATH)	
FROM  node.player NP1
	, edge.playerXplayer FOR PATH AS EPP
	, node.player        FOR PATH AS NP2
WHERE MATCH(SHORTEST_PATH(NP1(-(EPP)->NP2)+))
	AND NP1.shirtName = @player




-- ===================================================================
--  SITUAÇAO 2: CRIE UMA CONSULTA PARA MOSTRAR NO POWER BI 
--              OS RELACIONAMENTOS ENTRE TODOS OS ATLETAS DESSA COPA
-- ===================================================================

-- esta consulta gera um relatório para todas as relações entre os 835 atletas que participaram da COPA 2022
-- sao quase 700 mil registros
SELECT 	  Player1       = NP1.player
		, Player2		= LAST_VALUE(NP2.Player)                 WITHIN GROUP (GRAPH PATH) 
		, GRAU      	= COUNT(NP2.Player)                      WITHIN GROUP (GRAPH PATH) 
		, PESO       	= 4 / COUNT(NP2.Player)                  WITHIN GROUP (GRAPH PATH)-- no power bi, o "peso" vai ser pelo inverso do grau: quanto menor, mais importante a relação
		, Country2      = LAST_VALUE(NP2.countryID)              WITHIN GROUP (GRAPH PATH)
FROM  node.player NP1
	, edge.playerXplayer FOR PATH AS EPP
	, node.player        FOR PATH AS NP2
WHERE MATCH(SHORTEST_PATH(NP1(-(EPP)->NP2)+))



-- ===================================================================
--  SITUAÇAO 3: ALTERE A CONSULTA ANTERIOR PARA ADICIONAR
--              UM FILTRO POR "CONTINENTE"
-- ===================================================================

-- esta consulta gera um relatório para todas as relações entre os 835 atletas que participaram da COPA 2022
-- sao quase 700 mil registros
WITH cteGrafo AS
	(
	SELECT 	  Player1       = NP1.player
			, Player2		= LAST_VALUE(NP2.Player)                 WITHIN GROUP (GRAPH PATH) 
			, GRAU      	= COUNT(NP2.Player)                      WITHIN GROUP (GRAPH PATH) 
			, PESO       	= 4 / COUNT(NP2.Player)                  WITHIN GROUP (GRAPH PATH)-- no power bi, o "peso" vai ser pelo inverso do grau: quanto menor, mais importante a relação
			, Country2      = LAST_VALUE(NP2.countryID)              WITHIN GROUP (GRAPH PATH)
	FROM  node.player NP1
		, edge.playerXplayer FOR PATH AS EPP
		, node.player        FOR PATH AS NP2
	WHERE MATCH(SHORTEST_PATH(NP1(-(EPP)->NP2)+))
	)
SELECT g.*, c.Continent
FROM cteGrafo g
	INNER JOIN relational.Country c ON g.Country2 = c.countryID


	