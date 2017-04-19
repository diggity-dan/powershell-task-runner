-- Extracts last 30 days of Discovery

SET NOCOUNT ON

set transaction isolation level read uncommitted;

    WITH SeparateStats AS (
    SELECT
        CallDate = CONVERT(date,SM.recordedDate),
        TargetMediaSetId = MediaSetMedia.TargetMediaSetId,
        SampledFiles = COUNT(*),
        PendingFiles = SUM(CASE tick.DiscoveryTick WHEN -1 THEN 1 ELSE 0 END),
        ProcessedFiles = SUM(CASE tick.DiscoveryTick WHEN 0 THEN 1 ELSE 0 END),
        FilesWithHits = 0
    FROM dbo.TargetMediaSetSourceMedia AS MediaSetMedia
        INNER JOIN dbo.SourceMediaTick AS tick
            ON MediaSetMedia.SourceMediaId = tick.SourceMediaId and tick.Purpose=1
        INNER JOIN dbo.SourceMedia AS SM
            on tick.SourceMediaId=sm.SourceMediaId
    WHERE sm.RecordedDate >=DATEADD(DAY,-30,CONVERT(date,GETDATE()))
    GROUP BY CONVERT(date,SM.recordedDate),MediaSetMedia.TargetMediaSetId
    UNION
    SELECT
        CallDate = CONVERT(date,SM.recordedDate),
        TargetMediaSetId = MediaSetMedia.TargetMediaSetId,
        SampledFiles = 0,
        PendingFiles = 0,
        ProcessedFiles = 0,
        FilesWithHits = COUNT(DISTINCT MediaSetMedia.SourceMediaId)
    FROM dbo.TargetMediaSetSourceMedia AS MediaSetMedia
        INNER JOIN dbo.SourceMediaPhraseHit AS PhraseHit
            ON MediaSetMedia.SourceMediaId = PhraseHit.SourceMediaId
        INNER JOIN dbo.SourceMedia AS SM
            on MediaSetMedia.SourceMediaId=sm.SourceMediaId
    WHERE sm.RecordedDate >=DATEADD(DAY,-30,CONVERT(date,GETDATE()))
    GROUP BY CONVERT(date,SM.recordedDate),MediaSetMedia.TargetMediaSetId
    )
    SELECT 
        CallDate = SeparateStats.CallDate,
        TargetMediaSetId = SeparateStats.TargetMediaSetId,
        Name= MediaSet.Name,
        SampledFiles = SUM(SeparateStats.SampledFiles),
        PendingFiles = SUM(SeparateStats.PendingFiles),
        ProcessedFiles = SUM(SeparateStats.ProcessedFiles),
        FilesWithHits = SUM(SeparateStats.FilesWithHits)
    FROM SeparateStats AS SeparateStats
        INNER JOIN dbo.TargetMediaSet AS MediaSet
            ON SeparateStats.TargetMediaSetId = MediaSet.TargetMediaSetId
    WHERE MediaSet.TargetMediaSetId = MediaSet.ParentTargetMediaSetId
    AND SeparateStats.CallDate >=DATEADD(DAY,-30,CONVERT(date,GETDATE()))
    GROUP BY  SeparateStats.CallDate,SeparateStats.TargetMediaSetId, MediaSet.Name
    ORDER BY SeparateStats.CallDate,SeparateStats.TargetMediaSetId;
