Problem:

we had a problem!  Whether it was hardware failure, corruption, a bad query, or a benign migration, database recovery is something you’ll certainly run into multiple times throughout a modest BI/DBA career.  Often, it’s difficult giving end-users and supervisors accurate completion estimates on when the database will be live again.  
The average DBA may feel as though they’re staring into a black box just waiting and refreshing until the database finishes recovery.  There has to be an easier way!

Solution:

Did you know that SQL Server’s ERRORLOG actually calculates its own estimates to completion? 
Log entries can sometimes be overwhelming and overly-detailed, so we’ll instead use this simple SQL query to produce easy-to-read and surprisingly accurate estimation results.

We’ll start with the following query.  Please be sure to set the database to “master,” and replace the variable in the first line, “@DBName,” with the database you wish to investigate.  You can also modify this query to include more than the top result, if desired (e.g. “SELECT TOP 10”).

/*****************Query to retrieve the status of the database when it is in recovery mode**************************/

DECLARE @DBName VARCHAR(64) = 'Database Name'

DECLARE @ErrorLog AS TABLE([LogDate] CHAR(24), [ProcessInfo] VARCHAR(64), [TEXT] VARCHAR(MAX))

INSERT INTO @ErrorLog
EXEC master..sp_readerrorlog 0, 1, 'Recovery of database', @DBName

INSERT INTO @ErrorLog
EXEC master..sp_readerrorlog 0, 1, 'Recovery completed', @DBName

SELECT TOP 1
    @DBName AS [DBName]
   ,[LogDate]
   ,CASE
      WHEN SUBSTRING([TEXT],10,1) = 'c'
      THEN '100%'
      ELSE SUBSTRING([TEXT], CHARINDEX(') is ', [TEXT]) + 4,CHARINDEX(' complete (', [TEXT]) - CHARINDEX(') is ', [TEXT]) - 4)
      END AS PercentComplete
   ,CASE
      WHEN SUBSTRING([TEXT],10,1) = 'c'
      THEN 0
      ELSE CAST(SUBSTRING([TEXT], CHARINDEX('approximately', [TEXT]) + 13,CHARINDEX(' seconds remain', [TEXT]) - CHARINDEX('approximately', [TEXT]) - 13) AS FLOAT)/60.0
      END AS MinutesRemaining
   ,CASE
      WHEN SUBSTRING([TEXT],10,1) = 'c'
      THEN 0
      ELSE CAST(SUBSTRING([TEXT], CHARINDEX('approximately', [TEXT]) + 13,CHARINDEX(' seconds remain', [TEXT]) - CHARINDEX('approximately', [TEXT]) - 13) AS FLOAT)/60.0/60.0
      END AS HoursRemaining
   ,[TEXT]
FROM @ErrorLog ORDER BY CAST([LogDate] as datetime) DESC, [MinutesRemaining]

/*********************************************************************************************************************/