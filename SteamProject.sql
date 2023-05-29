-- Let's make sure all the data imported correctly

SELECT *
FROM dbo.steam$

-- Looks like all the data is there. Most of it is pretty clean and ready to be queried. We're going to drop a few columns of data that won't be relevant to our objective.
-- We're going to drop the columns english and required_age
-- Renamed dbo.steam$ to dbo.steam

ALTER TABLE dbo.steam$
DROP COLUMN english, required_age

Select *
FROM dbo.steam$

-- Next we're going to reformat the release_date column in to a more usable appealing and usable format
-- Were going to use the CAST function to just to quickly remove the 0 time stamp after each invidual date
-- Created a new column as DATE data type to insert newly casted data from release_date. Dropped column release_date as its no longer needed.

SELECT CAST(release_date AS DATE) AS ReleaseDate
FROM dbo.steam$;

ALTER TABLE dbo.steam$
ADD ReleaseDate DATE

UPDATE dbo.steam$
SET ReleaseDate = CAST(release_date AS DATE)

ALTER TABLE dbo.steam$
DROP COLUMN release_date

-- How many unique developers are on this list?

SELECT COUNT(DISTINCT developer)
FROM dbo.steam

SELECT DISTINCT developer
from dbo.steam

-- 17016 unique developers in the table. How many publishers are there?
-- 14214 unique publishers in the table.
-- A lot of the entries with 0-20000 owners have very little to no average playtime at all.
-- For the sake of time we're going to get rid of the games that have either 0 or less than 50 hours of average gameplay time.
-- Make a test table first before deleting a substantial amount of data to make sure you're targeting the correct rows.

SELECT *
INTO TestSteam
FROM dbo.steam
WHERE average_playtime < 50

SELECT *
FROM TestSteam

DELETE FROM dbo.steam
WHERE average_playtime < 50

-- Cut our data down from 22,000 rows to about 5,000 rows. Much easier to work with now.
-- Should I create seperate tables for the categories that have delimiters seperating each value? Or is there a way around this in tableau and SQL?
-- I'm going to have to create a lot of new tables...
-- Let's create two new tables to hold both appid and name and then one to hold the split categories

CREATE TABLE Categories
(gameid INT,
Category VARCHAR(100))

CREATE TABLE Games
(gameid INT,
name VARCHAR(100))

-- Now something completely new. We're going to TRY to create a script to populate those tables without having to do it one by one.

DECLARE @gameid INT;
DECLARE @name VARCHAR(100);
DECLARE @Category VARCHAR(MAX);

-- Cursor to loop through games
DECLARE gameCursor CURSOR FOR
SELECT appid, name, categories
FROM dbo.steam;

OPEN gameCursor;
FETCH NEXT FROM gameCursor INTO @gameid, @name, @Category;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Insert game details into the Games table
    INSERT INTO Games (gameid, name)
    VALUES (@gameid, @name);

    -- Split and insert separated values into the Categories table for the current game
    INSERT INTO Categories (gameid, Category)
    SELECT @gameid, value
    FROM STRING_SPLIT(@Category, ';');

    FETCH NEXT FROM gameCursor INTO @gameid, @name, @Category;
END;

CLOSE gameCursor;
DEALLOCATE gameCursor;

Select * 
from steam

-- Wow. That actually worked. Lets do this for the remainder of the deliminated columns.
-- Next will be the developer column.

CREATE TABLE Developer(
gameid INT,
developer VARCHAR(100))

DECLARE @gameid INT;
DECLARE @developer VARCHAR(MAX);


DECLARE gameCursor CURSOR FOR
SELECT appid, developer
FROM dbo.steam;

OPEN gameCursor;
FETCH NEXT FROM gameCursor INTO @gameid, @developer;

WHILE @@FETCH_STATUS = 0
BEGIN

    INSERT INTO Developer (gameid, developer)
    SELECT @gameid, value
    FROM STRING_SPLIT(@developer, ';');

    FETCH NEXT FROM gameCursor INTO @gameid, @developer;
END;

-- Next is publisher

CREATE TABLE Publisher(
gameid INT,
publisher VARCHAR(100))

DECLARE @gameid INT;
DECLARE @tags VARCHAR(MAX);


DECLARE gameCursor CURSOR FOR
SELECT appid, steamspy_tags
FROM dbo.steam;

OPEN gameCursor;
FETCH NEXT FROM gameCursor INTO @gameid, @tags;

WHILE @@FETCH_STATUS = 0
BEGIN

    INSERT INTO SteamTags (gameid, tags)
    SELECT @gameid, value
    FROM STRING_SPLIT(@tags, ';');

    FETCH NEXT FROM gameCursor INTO @gameid, @tags;
END;

CLOSE gameCursor;
DEALLOCATE gameCursor;

-- To not be as redundant I just went back and replaced the needed values for the script above that created and populated the remaining columns that had delimiters in them.
-- We now have 7 new tables that show categories, developers, games, genres, platforms, publishers, and steamspy_tags seperated by appid

SELECT *
FROM steam

-- Okay that is WAY too much excessive data
-- We have a few options to get around this unnecessarily extensive approach. Lets try to aggregate the genres into their primary categories instead.

SELECT DISTINCT genres
from steam