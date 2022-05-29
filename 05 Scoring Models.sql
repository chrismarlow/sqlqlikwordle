USE Wordle
GO

--Sample simple scoring models using the whole word set
--These do not rescore after guesses

--Letter frequency (1)
INSERT INTO dbo.WordModelScores (WordID, ScoringModelID, ModelScore)
SELECT AW.WordID, 1, SUM((CAST(LT.LetterTotal AS DECIMAL))/64855)
FROM dbo.Words AW
INNER JOIN dbo.WordsLetters AWL ON (AW.WordID=AWL.WordID)
INNER JOIN 
	(SELECT LetterID, COUNT(*) AS LetterTotal
	FROM dbo.WordsLetters
	GROUP BY LetterID) LT ON (AWL.LetterID=LT.LetterID)
GROUP BY AW.WordID

--Letter frequency with position (2)
INSERT INTO dbo.WordModelScores (WordID, ScoringModelID, ModelScore)
SELECT AW.WordID, 2, SUM((CAST(LT.LetterTotal AS DECIMAL)+(5*CAST(LPT.LetterPositionTotal AS DECIMAL)))/64855)
FROM dbo.Words AW
INNER JOIN dbo.WordsLetters AWL ON (AW.WordID=AWL.WordID)
INNER JOIN 
	(SELECT LetterID, COUNT(*) AS LetterTotal
	FROM dbo.WordsLetters
	GROUP BY LetterID) LT ON (AWL.LetterID=LT.LetterID)
INNER JOIN 
	(SELECT LetterID, LetterIndex, COUNT(*) AS LetterPositionTotal
	FROM dbo.WordsLetters
	GROUP BY LetterID, LetterIndex) LPT ON (AWL.LetterID=LPT.LetterID AND AWL.LetterIndex=LPT.LetterIndex)
GROUP BY AW.WordID

--Letter frequency with position (duplicates) (3)
INSERT INTO dbo.WordModelScores (WordID, ScoringModelID, ModelScore)
SELECT AW.WordID, 3, SUM(((CAST(LT.LetterTotal AS DECIMAL))+(5*CAST(LPT.LetterPositionTotal AS DECIMAL)/CAST(WLC.WordLetterCount AS DECIMAL)))/64855)
FROM dbo.Words AW
INNER JOIN dbo.WordsLetters AWL ON (AW.WordID=AWL.WordID)
INNER JOIN 
	(SELECT LetterID, COUNT(*) AS LetterTotal
	FROM dbo.WordsLetters
	GROUP BY LetterID) LT ON (AWL.LetterID=LT.LetterID)
INNER JOIN 
	(SELECT LetterID, LetterIndex, COUNT(*) AS LetterPositionTotal
	FROM dbo.WordsLetters
	GROUP BY LetterID, LetterIndex) LPT ON (AWL.LetterID=LPT.LetterID AND AWL.LetterIndex=LPT.LetterIndex)
INNER JOIN 
	(SELECT WordID, LetterID, COUNT(*) AS WordLetterCount
	FROM dbo.WordsLetters
	GROUP BY WordID, LetterID) WLC ON (AWL.WordID=WLC.WordID AND AWL.LetterID=WLC.LetterID)
GROUP BY AW.WordID

--Letter frequency with position (duplicates root) (4)
INSERT INTO dbo.WordModelScores (WordID, ScoringModelID, ModelScore)
SELECT AW.WordID, 4, SUM(((CAST(LT.LetterTotal AS DECIMAL))+(5*CAST(LPT.LetterPositionTotal AS DECIMAL)/SQRT(CAST(WLC.WordLetterCount AS DECIMAL))))/64855)
FROM dbo.Words AW
INNER JOIN dbo.WordsLetters AWL ON (AW.WordID=AWL.WordID)
INNER JOIN 
	(SELECT LetterID, COUNT(*) AS LetterTotal
	FROM dbo.WordsLetters
	GROUP BY LetterID) LT ON (AWL.LetterID=LT.LetterID)
INNER JOIN 
	(SELECT LetterID, LetterIndex, COUNT(*) AS LetterPositionTotal
	FROM dbo.WordsLetters
	GROUP BY LetterID, LetterIndex) LPT ON (AWL.LetterID=LPT.LetterID AND AWL.LetterIndex=LPT.LetterIndex)
INNER JOIN 
	(SELECT WordID, LetterID, COUNT(*) AS WordLetterCount
	FROM dbo.WordsLetters
	GROUP BY WordID, LetterID) WLC ON (AWL.WordID=WLC.WordID AND AWL.LetterID=WLC.LetterID)
GROUP BY AW.WordID
