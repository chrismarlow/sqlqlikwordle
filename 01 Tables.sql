USE WordleTest
GO

--Tables

--All Words
If OBJECT_ID('[dbo].[Words]') Is Not Null
	DROP TABLE dbo.Words
	GO

CREATE TABLE [dbo].Words(
	[WordID] [int] IDENTITY(1,1) NOT NULL,
	[Word] [char](5) NOT NULL,
	[WordleWord] bit,
	CONSTRAINT [PK_WordID] PRIMARY KEY CLUSTERED 
		(
			[WordID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Letters by position for all words
If OBJECT_ID('[dbo].[WordsLetters]') Is Not Null
	DROP TABLE dbo.WordsLetters
	GO

CREATE TABLE [dbo].WordsLetters(
	[WordLetterID] [int] IDENTITY(1,1) NOT NULL,
	[WordID] [int] NOT NULL,
	[LetterIndex] smallint NOT NULL,
	[LetterID] smallint NOT NULL,
	CONSTRAINT [PK_WordLetterID] PRIMARY KEY CLUSTERED 
		(
			[WordLetterID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Wordle scoring models
If OBJECT_ID('[dbo].[ScoringModels]') Is Not Null
	DROP TABLE dbo.ScoringModels
	GO

CREATE TABLE [dbo].ScoringModels(
	[ScoringModelID] [int] IDENTITY(1,1) NOT NULL,
	[ScoringModel] [varchar](255) NOT NULL
	CONSTRAINT [PK_ScoringModelID] PRIMARY KEY CLUSTERED 
		(
			[ScoringModelID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Wordle models
If OBJECT_ID('[dbo].[Models]') Is Not Null
	DROP TABLE dbo.Models
	GO

CREATE TABLE [dbo].Models(
	[ModelID] [int] IDENTITY(1,1) NOT NULL,
	[Model] [varchar](255) NOT NULL,
	[ScoringModelID] int NOT NULL,
	CONSTRAINT [PK_ModelID] PRIMARY KEY CLUSTERED 
		(
			[ModelID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Word model scores
If OBJECT_ID('[dbo].[WordModelScores]') Is Not Null
	DROP TABLE dbo.WordModelScores
	GO

CREATE TABLE [dbo].WordModelScores(
	[WordModelScoreID] [int] IDENTITY(1,1) NOT NULL,
	[WordID] int NOT NULL,	
	[ScoringModelID] int NOT NULL,
	[ModelScore] DECIMAL(8,7) NOT NULL,
	CONSTRAINT [PK_WordModelScoreID] PRIMARY KEY CLUSTERED 
		(
			[WordModelScoreID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


--Record the guesses
If OBJECT_ID('[dbo].[WordGuesses]') Is Not Null
	DROP TABLE dbo.WordGuesses
	GO

CREATE TABLE [dbo].WordGuesses(
	[WordGuessID] [int] IDENTITY(1,1) NOT NULL,
	[ModelID] [int] NOT NULL,
	[TargetWordID] [int] NOT NULL,
	[GuessWordID] [int] NOT NULL,
	[GuessNumber] smallint NOT NULL
	CONSTRAINT [PK_WordGuessID] PRIMARY KEY CLUSTERED 
		(
			[WordGuessID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Letters
If OBJECT_ID('[dbo].[Letters]') Is Not Null
	DROP TABLE dbo.Letters
	GO

CREATE TABLE [dbo].Letters(
	[LetterID] [int] IDENTITY(1,1) NOT NULL,
	[Letter] [char](1) NOT NULL,
	[LetterCount] smallint NULL
	CONSTRAINT [PK_LetterID] PRIMARY KEY CLUSTERED 
		(
			[LetterID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Letter positions grid
If OBJECT_ID('[dbo].[LetterPositions]') Is Not Null
	DROP TABLE dbo.LetterPositions
	GO

CREATE TABLE [dbo].LetterPositions(
	[LetterPositionID] [int] IDENTITY(1,1) NOT NULL,
	[LetterID] [int] NOT NULL,
	[LetterIndex] smallint NULL,
	[LetterStatus] smallint NULL,
	CONSTRAINT [PK_LetterPositionID] PRIMARY KEY CLUSTERED 
		(
			[LetterPositionID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Store initial guesses for models
If OBJECT_ID('[dbo].[ModelInitialGuesses]') Is Not Null
	DROP TABLE dbo.ModelInitialGuesses
	GO

CREATE TABLE [dbo].ModelInitialGuesses(
	[ModelInitialGuessesID] [int] IDENTITY(1,1) NOT NULL,
	[ModelID] [int] NOT NULL,
	[GuessNumber] smallint NULL,
	[WordID] smallint NULL,
	CONSTRAINT [PK_ModelInitialGuessesID] PRIMARY KEY CLUSTERED 
		(
			[ModelInitialGuessesID] ASC
		) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

--Indexes

--Index IDX_WordModelScores_WordID
If OBJECT_ID('[dbo].[IDX_LetterPositions_LetterID]') Is Not Null
	DROP INDEX [IDX_LetterPositions_LetterID] ON [dbo].[LetterPositions]
GO

CREATE NONCLUSTERED INDEX [IDX_LetterPositions_LetterID] ON [dbo].[LetterPositions]
(
	[LetterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

--Index IDX_WordModelScores_WordID
If OBJECT_ID('[dbo].[IDX_WordModelScores_WordID]') Is Not Null
	DROP INDEX [IDX_WordModelScores_WordID] ON [dbo].[WordModelScores]
GO

CREATE NONCLUSTERED INDEX [IDX_WordModelScores_WordID] ON [dbo].[WordModelScores]
(
	[WordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

--Index IDX_WordModelScores_ScoringModelID
If OBJECT_ID('[dbo].[IDX_WordModelScores_ScoringModelID]') Is Not Null
	DROP INDEX [IDX_WordModelScores_ScoringModelID] ON [dbo].[WordModelScores]
GO

CREATE NONCLUSTERED INDEX [IDX_WordModelScores_ScoringModelID] ON [dbo].[WordModelScores]
(
	[ScoringModelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

--Index IDX_WordsLetters_LetterID
If OBJECT_ID('[dbo].[IDX_WordsLetters_LetterID]') Is Not Null
	DROP INDEX [IDX_WordsLetters_LetterID] ON [dbo].[WordsLetters]
GO

CREATE NONCLUSTERED INDEX [IDX_WordsLetters_LetterID] ON [dbo].[WordsLetters]
(
	[LetterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

--Index IDX_WordsLetters_WordID
If OBJECT_ID('[dbo].[IDX_WordsLetters_WordID]') Is Not Null
	DROP INDEX [IDX_WordsLetters_WordID] ON [dbo].[WordsLetters]
GO

CREATE NONCLUSTERED INDEX [IDX_WordsLetters_WordID] ON [dbo].[WordsLetters]
(
	[WordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO









