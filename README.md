# Outbox message queue examples
This repository has some sample scripts of leveraging an Outbox pattern with SQL Server.
Can be used to find the right balance between concurrent read and write operations on the message box table. 

1. 1_clustered.sql - Table with a primary key and clustered index on the pk. 
2. 2_clustered_optimized.sql - Table with a primary key and clustered index on the pk with SQL Server 2019 feature optimize_for_sequential_key. 
3. 3_partitioned.sql - Table with a primary key on the identity and clustered index on id, hash. Depending on the amount of records that will be deallocated when reading from the queue, evaluate if a non-clustered index is needed on the primary key (optimize for seeking and limit the amount of logical reads). 
4. 4_partitioned_optimized.sql - Table with a primary on the identity, clustered index on id, hash and Optimize for optimize_for_sequential_key.
5. 5_LMax_disruptor.sql - Inspired by Chris Adkin: https://chrisadkin.io/2016/01/02/super-scaling-queues-using-the-lmax-disruptor-pattern/
6. 5_LMax_disruptor_inmemory.sql - Inspired by Chris Adkin: https://chrisadkin.io/2016/01/18/super-scaling-queues-using-the-lmax-disruptor-pattern-and-the-in-memory-oltp-engine/

When evaluating a message box or queue pattern, the following articles and points can be used for inspiration: 
* An article describing the fundamentals of 'tables as queues' by Remus Rusanu. - https://rusanu.com/2010/03/26/using-tables-as-queues/
* With inserting data at a high rate you might hit into the first boundary; last-page contention and is discussed here - https://docs.microsoft.com/en-US/troubleshoot/sql/performance/resolve-pagelatch-ex-contention
* You want to have deallocation-select queries on the message table as fast and small as possible. One way is using a watermark to make sure your limiting the possibility of triggering index scans and also blocking the ghost cleanup process. - https://forrestmcdaniel.com/2021/06/30/fixing-queues-with-watermarks/
* Test different approaches with real data, thread usage and also concurrency of any other processes to the SQL Server. A great tool for performance testing is SQLQueryStress - https://github.com/ErikEJ/SqlQueryStress
* Changing database setting AUTO_UPDATE_STATISTICS_ASYNC to ON can be considered when testing and optimizing for performance - https://docs.microsoft.com/en-us/sql/t-sql/statements/alter-database-transact-sql-set-options?view=sql-server-ver15#auto_update_statistics_async
* Changing database setting DELAYED_DURABILITY to FORCED can be considered - https://docs.microsoft.com/en-us/sql/relational-databases/logs/control-transaction-durability?view=sql-server-ver15#when-to-use-delayed-transaction-durability
* Make sure that database files (MDF/NDF, LDF) are properly scaled before testing/using in production. Give them enough space to not hit into any performance overhead of growing the transaction log (blocking operation).  
*	Use an environment that has optimal disk sub-system (ssd/nvme) to support this pattern, optimize the transaction log location and make sure you make transaction log backups often. 
* Availability Groups with synchronize replication will have noticeable performance overhead. Be sure to test what the overhead will be in an environment that’s under concurrent load.
