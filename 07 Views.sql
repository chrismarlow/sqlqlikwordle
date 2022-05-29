USE WordleTest
GO

--View for Qlik Sense application

If OBJECT_ID('[dbo].[WordleGuesses]') Is Not Null
	DROP VIEW [dbo].[WordleGuesses]
GO

CREATE VIEW [dbo].[WordleGuesses]
AS
SELECT dbo.WordGuesses.ModelID, dbo.WordGuesses.TargetWordID, dbo.Words.Word AS TargetWord, Words_1.Word AS GuessWord, dbo.WordGuesses.GuessNumber
FROM   dbo.Words INNER JOIN
             dbo.WordGuesses ON dbo.Words.WordID = dbo.WordGuesses.TargetWordID INNER JOIN
             dbo.Words AS Words_1 ON dbo.WordGuesses.GuessWordID = Words_1.WordID
GO
