/*

5/9/18
Written by Luke Brewbaker, SQA @ LogRhythm.  
Used to delete only specific classifications from LogMart instead of a full purge

*/

DELETE cla
FROM LogRhythm_LogMart.dbo.UniqueLog cla
INNER JOIN LogRhythmEMDB.dbo.MsgClass emdb ON cla.MsgClassID=emdb.MsgClassID
WHERE FullName ='Ops/Network Allow' -- Set this to the actual name from the Unique Log Query that you want to delete