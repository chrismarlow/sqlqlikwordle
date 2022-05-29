USE Wordle
GO

--Reset letter views
If OBJECT_ID('[dbo].[ResetLetterPositions]') Is Not Null
	DROP PROCEDURE dbo.ResetLetterPositions
	GO

CREATE PROCEDURE dbo.ResetLetterPositions
AS
	
	SET NOCOUNT ON;

	UPDATE LetterPositions SET LetterStatus=1
	UPDATE Letters SET LetterCount=0

	SET NOCOUNT OFF;

GO

--Apply guess/target to the LetterPositions table
If OBJECT_ID('[dbo].[UpdateLetterGrid]') Is Not Null
	DROP PROCEDURE dbo.UpdateLetterGrid
	GO

CREATE PROCEDURE dbo.UpdateLetterGrid
	@guessid int,
	@targetid int
AS

	SET NOCOUNT ON;

	DECLARE @guess char(5) = (SELECT Word FROM Words WHERE WordID=@guessid)
	DECLARE @target char(5) = (SELECT Word FROM Words WHERE WordID=@targetid)

	DECLARE @iter int = 1
	DECLARE @letter char(1)
	DECLARE @letterid int
	DECLARE @inneriter int

	--Mark up all the exact matches
	WHILE @iter<=5
		BEGIN
		SET @letter=SUBSTRING(@guess,@iter,1)
		SET @letterid=(SELECT LetterID FROM Letters WHERE Letter=@letter)
		--Exact matches
		IF @letter=SUBSTRING(@target,@iter,1)
			BEGIN
				--Is this 2 in this position?
				IF (SELECT LP.LetterStatus FROM LetterPositions LP WHERE LP.LetterID=@letterid AND LP.LetterIndex=@iter)=2
					BEGIN
						UPDATE Letters SET LetterCount=LetterCount-1 WHERE Letter=@letter
						IF (SELECT LetterCount FROM Letters L WHERE L.LetterID=@letterid)=0
							BEGIN
								UPDATE LetterPositions SET LetterStatus=1 WHERE LetterStatus=2 AND LetterID=@letterid AND LetterIndex<>@iter
							END
					END
				UPDATE LetterPositions SET LetterStatus=3 WHERE LetterID=@letterid AND LetterIndex=@iter
				UPDATE LetterPositions SET LetterStatus=0 WHERE LetterID<>@letterid AND LetterIndex=@iter
			END
		SET @iter+=1
	END

	--Mark letters not found having excluded matched
	SET @iter=1
	WHILE @iter<=5
		BEGIN
		SET @letter=SUBSTRING(@guess,@iter,1)
		SET @letterid=(SELECT LetterID FROM Letters WHERE Letter=@letter)
		IF (SELECT COUNT(*) FROM Words W
			INNER JOIN WordsLetters WL ON W.WordID=WL.WordID
			LEFT JOIN (SELECT * FROM LetterPositions WHERE LetterStatus=3) LP ON WL.LetterIndex=LP.LetterIndex
			LEFT JOIN Letters L ON WL.LetterID=L.LetterID
			WHERE W.Word=@target AND LP.LetterPositionID Is Null and L.Letter=@letter)=0

			BEGIN
				--NOT A MATCH
				UPDATE LetterPositions SET LetterStatus=0 WHERE LetterID=@letterid AND LetterStatus<>3
				UPDATE Letters SET LetterCount=0 WHERE LetterID=@letterid
			END
		SET @iter+=1
	END

	--Create a table to capture letters guessed in wrong positions
	CREATE TABLE #tempL
	(
		LetterID int,
		GuessCount int,
		TargetCount int,
		LetterIndex int
	)

	INSERT INTO #tempL (LetterID, GuessCount, TargetCount, LetterIndex)
	SELECT G.LetterID, G.GuessCount, T.TargetCount, P.LetterIndex
	FROM
		(SELECT L.LetterID, COUNT(*) AS GuessCount
		FROM Words AWG
		INNER JOIN WordsLetters AWGL ON AWG.WordID=AWGL.WordID
		INNER JOIN LetterPositions LP ON (AWGL.LetterID=LP.LetterID AND AWGL.LetterIndex=LP.LetterIndex)
		INNER JOIN Letters L ON AWGL.LetterID=L.LetterID
		WHERE AWG.Word=@guess
			AND LP.LetterStatus<>3
		GROUP BY L.LetterID) G
	INNER JOIN (
		SELECT L.LetterID, COUNT(*) AS TargetCount
		FROM Words AWG
		INNER JOIN WordsLetters AWGL ON AWG.WordID=AWGL.WordID
		INNER JOIN LetterPositions LP ON (AWGL.LetterID=LP.LetterID AND AWGL.LetterIndex=LP.LetterIndex)
		INNER JOIN Letters L ON AWGL.LetterID=L.LetterID
		WHERE AWG.Word=@target
			AND LP.LetterStatus<>3
		GROUP BY L.LetterID) T ON G.LetterID=T.LetterID
	INNER JOIN (
		SELECT L.LetterID,LP.LetterIndex
		FROM Words AWG
		INNER JOIN WordsLetters AWGL ON AWG.WordID=AWGL.WordID
		INNER JOIN LetterPositions LP ON (AWGL.LetterID=LP.LetterID AND AWGL.LetterIndex=LP.LetterIndex)
		INNER JOIN Letters L ON AWGL.LetterID=L.LetterID
		WHERE AWG.Word=@guess
			AND LP.LetterStatus<>3) P ON G.LetterID=P.LetterID

	--Set 0 for matches
	UPDATE LetterPositions
	SET LetterStatus=0
	FROM LetterPositions LP
	INNER JOIN #tempL L ON (LP.LetterID=L.LetterID AND LP.LetterIndex=L.LetterIndex)

	--Set 2 for letters that appear and are not excluded or definately matched
	UPDATE LetterPositions
	SET LetterStatus=2
	FROM LetterPositions LP
	INNER JOIN #tempL L ON (LP.LetterID=L.LetterID AND LP.LetterIndex<>L.LetterIndex)
	WHERE LP.LetterStatus NOT IN (0,3)

	UPDATE Letters
	SET LetterCount=IIF(GuessCount>TargetCount,TargetCount,GuessCount)
	FROM Letters L INNER JOIN #tempL TL ON (L.LetterID=TL.LetterID)

	DROP TABLE #tempL

	SET NOCOUNT OFF;

GO

--Return the next guess based on updated positions table
If OBJECT_ID('[dbo].[ReturnNextGuess]') Is Not Null
	DROP PROCEDURE dbo.ReturnNextGuess
	GO

CREATE PROCEDURE dbo.ReturnNextGuess
	@modelid int,
	@guessnumber int,
	@nextguessid int OUTPUT
AS

	DECLARE @initialguessid int = 0

	--Only use model initial guesses while we have not guessed all letters (either exact place or in wrong place) 
	IF (SELECT (SELECT COUNT(*) FROM LetterPositions WHERE LetterStatus=3)+(SELECT SUM(LetterCount) FROM dbo.Letters))<5

		SELECT @initialguessid=WordID FROM [dbo].[ModelInitialGuesses] WHERE ModelID=@modelid AND GuessNumber=@guessnumber

	--If we don't find an initial guess use scoring model to return guess
	IF @initialguessid<>0

		SET @nextguessid=@initialguessid

	ELSE

		BEGIN

		--Create a temporary table to store next guess
		CREATE TABLE #tempNG
		(
			nextguessid int,
			modelscore DECIMAL(8,7)
		)

		--If we have any letters that we have guessed but in wrong position, and not subsequently guessed right, we need different query
		IF (SELECT COUNT(*) FROM Letters WHERE LetterCount>0)=0

			INSERT INTO #tempNG
			SELECT TOP 1 AW.WordID, WMS.ModelScore
			FROM LetterPositions LP
			INNER JOIN WordsLetters AWL ON (LP.LetterID=AWL.LetterID AND LP.LetterIndex=AWL.LetterIndex)
			INNER JOIN Words AW ON (AWL.WordID=AW.WordID)
			INNER JOIN WordModelScores WMS ON (AW.WordID=WMS.WordID)
			INNER JOIN Models M ON (WMS.[ScoringModelID]=M.ScoringModelID)
			WHERE LP.LetterStatus<>0 AND [ModelID]=@modelid
			GROUP BY AW.WordID, WMS.ModelScore
			HAVING COUNT(*)=5
			ORDER BY WMS.ModelScore DESC

		ELSE
		
			INSERT INTO #tempNG
			SELECT TOP 1 AW.WordID, WMS.ModelScore
			FROM LetterPositions LP
			INNER JOIN WordsLetters AWL ON (LP.LetterID=AWL.LetterID AND LP.LetterIndex=AWL.LetterIndex)
			INNER JOIN Words AW ON (AWL.WordID=AW.WordID)
			INNER JOIN WordModelScores WMS ON (AW.WordID=WMS.WordID)
			INNER JOIN Models M ON (WMS.[ScoringModelID]=M.ScoringModelID)
			INNER JOIN (
				SELECT AW.WordID, COUNT(DISTINCT AWL.LetterID) AS C
				FROM LetterPositions LP
				INNER JOIN WordsLetters AWL ON (LP.LetterID=AWL.LetterID AND LP.LetterIndex=AWL.LetterIndex)
				INNER JOIN Words AW ON (AWL.WordID=AW.WordID)
				WHERE LP.LetterStatus=2
				GROUP BY AW.WordID
				HAVING COUNT(DISTINCT AWL.LetterID)>=(SELECT COUNT(*) FROM Letters WHERE LetterCount>0)) P ON AW.WordID=P.WordID
			WHERE LP.LetterStatus<>0 AND [ModelID]=@modelid
			GROUP BY AW.WordID, WMS.ModelScore
			HAVING COUNT(*)=5
			ORDER BY WMS.ModelScore DESC

		--Return the guess
		SELECT @nextguessid=nextguessid FROM #tempNG

		END

	RETURN;

GO

--Guess word by running iteratively through ReturnNextGuess/UpdateLetterGrid
If OBJECT_ID('[dbo].[GuessWord]') Is Not Null
	DROP PROCEDURE dbo.GuessWord
	GO

CREATE PROCEDURE dbo.GuessWord
	@target int,
	@modelid int
AS
	
	DECLARE @iter int=1
	DECLARE @nextguess int=0

	--Reset to all letters in a all positions possible
	EXEC ResetLetterPositions

	--Stop when we get the word
	WHILE @nextguess<>@target
		BEGIN
			--Get the next guess
			EXEC ReturnNextGuess @modelid, @iter, @nextguess OUTPUT
			INSERT INTO WordGuesses ([ModelID], [TargetWordID], [GuessWordID], [GuessNumber]) VALUES (@modelid, @target ,@nextguess, @iter)
			--Update the letter positions to reflect the guess made
			EXEC UpdateLetterGrid @nextguess,@target
			SET @iter+=1
		END

GO

--Guess word by running iteratively through
If OBJECT_ID('[dbo].[ExecuteModel]') Is Not Null
	DROP PROCEDURE dbo.ExecuteModel
	GO

CREATE PROCEDURE dbo.ExecuteModel
	@modelid int
AS

	DECLARE @wordid int

	DELETE FROM WordGuesses WHERE ModelID=@modelid

	--This gives list of companies to create new hierarchy for
	DECLARE word_cursor CURSOR FOR  
		SELECT WW.WordID FROM Words WW WHERE WW.WordleWord=1
	OPEN word_cursor;  
  
	-- Perform the first fetch.  
	FETCH NEXT FROM word_cursor INTO @wordid;  
  
	-- Check @@FETCH_STATUS to see if there are any more rows to fetch.  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		EXEC GuessWord @wordid, @modelid
		FETCH NEXT FROM word_cursor INTO @wordid;
	END  
  
	CLOSE word_cursor;  
	DEALLOCATE word_cursor; 

GO
