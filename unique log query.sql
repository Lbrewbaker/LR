USE LogRhythm_LogMart 
GO 
SELECT COUNT(*) AS [UniqueLog_Count] FROM UniqueLog 
SELECT COUNT(*) AS [UniqueLogStats_Count] FROM UniqueLogStats 
EXEC LogRhythm_Partitions_Query @TableName='UniqueLogStats' 
SELECT MC.FullName AS [Classification], COUNT(U.MsgClassID) AS [Record Count] 
FROM LogRhythm_LogMart.dbo.UniqueLog U INNER JOIN 
LogRhythmEMDB.dbo.MsgClass MC ON U.MsgClassID=MC.MsgClassID 
GROUP BY MC.FullName 
ORDER BY COUNT(U.MsgClassID) DESC  
