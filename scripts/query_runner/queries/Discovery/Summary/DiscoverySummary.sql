--Extracts the files processed for the past 10 days
SET NOCOUNT ON

set transaction isolation level read uncommitted;
SELECT CONVERT(date,recordeddate) as "Recorded Date",COUNT(0) as "Files Processed",SUM(CONVERT(BIGINT,DurationInMs))/1000/60/60 as "Duration" FROM SourceMedia WITH (NOLOCK)
WHERE CONVERT(date,recordeddate)>=DATEADD(day,-10,convert(date,getdate())) and TranscriptCreationDateTimeUtc is not null 
group by CONVERT(date,recordeddate)

