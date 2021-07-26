-- Make a transaction log backup frequently
BACKUP LOG [Outbox] TO  DISK = N'F:\bak\outbox.trn' WITH NOFORMAT, NOINIT,  NAME = N'Outbox1-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10;

-- Clear wait statistics
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

-- Empty table to start fresh
TRUNCATE TABLE [dbo].[outbox];

-- Sanity checks WITH(NOLOCK)
SELECT COUNT(*) from [dbo].[outbox] WITH(NOLOCK);
SELECT id FROM [dbo].[outbox] WITH(NOLOCK);
SELECT MIN(id), max(id) FROM [dbo].[outbox] WITH(NOLOCK);

-- Monitor ghost record processing
SELECT SUM(ghost_record_count) total_ghost_records, DB_NAME(database_id) 
FROM sys.dm_db_index_physical_stats (NULL, NULL, NULL, NULL, 'SAMPLED') 
GROUP BY database_id ORDER BY total_ghost_records DESC;

-- Useful scripts while testing: 
-- IO stats delta - https://www.sqlskills.com/blogs/paul/capturing-io-latencies-period-time/
-- Wait stats delta - https://www.sqlskills.com/blogs/paul/capturing-wait-statistics-period-time/
-- Quick checks with Management Studio built-in Performance Dashboard - https://docs.microsoft.com/en-us/sql/relational-databases/performance/performance-dashboard
-- DBCC PAGE and sp_whosisactive - http://whoisactive.com/
