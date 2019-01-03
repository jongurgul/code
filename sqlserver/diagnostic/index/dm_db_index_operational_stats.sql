--http://jongurgul.com/blog/sql-index-stats-queries
SELECT 
 SCHEMA_NAME(ao.[schema_id]) [SchemaName]
,ao.[object_id] [ObjectID]
,ao.[name] [ObjectName]
,ao.[is_ms_shipped] [IsSystemObject]
,i.[index_id] [IndexID]
,i.[name] [IndexName]
,ddios.[partition_number] [PartitionNumber]
,i.[type_desc] [IndexType]
,ddios.[leaf_insert_count]--Cumulative count of leaf-level inserts.
,ddios.[leaf_delete_count]--Cumulative count of leaf-level deletes. 
,ddios.[leaf_update_count]--Cumulative count of leaf-level updates. 
,ddios.[leaf_ghost_count]--Cumulative count of leaf-level rows that are marked as deleted, but not yet removed.
--These rows are removed by a cleanup thread at set intervals. This value does not include rows that are retained, because of an outstanding snapshot isolation transaction. 
,ddios.[nonleaf_insert_count] [NonleafInsertCount]--Cumulative count of inserts above the leaf level.
,ddios.[nonleaf_delete_count] [NonleafDeleteCount]--Cumulative count of deletes above the leaf level.
,ddios.[nonleaf_update_count] [NonleafUpdateCount]--Cumulative count of updates above the leaf level.
,ddios.[leaf_allocation_count] [LeafAllocationCount]--Cumulative count of leaf-level page allocations in the index or heap.For an index, a page allocation corresponds to a page split.
,ddios.[nonleaf_allocation_count] [NonLeafAllocationCount]--Cumulative count of page allocations caused by page splits above the leaf level. 
,ddios.[range_scan_count] [RangeScanCount]--Cumulative count of range and table scans started on the index or heap.
,ddios.[singleton_lookup_count] [SingletonLookupCount]--Cumulative count of single row retrievals from the index or heap. 
,ddios.[forwarded_fetch_count] [ForwardedFetchCount]--Count of rows that were fetched through a forwarding record. 
,ddios.[lob_fetch_in_pages] [LobFetchInPages]--Cumulative count of large object (LOB) pages retrieved from the LOB_DATA allocation unit.
,ddios.[row_overflow_fetch_in_pages] [RowOverflowFetchInPages]--Cumulative count of column values for LOB data and row-overflow data that is pushed off-row to make an inserted or updated row fit within a page. 
,ddios.[page_lock_wait_count] [PageLockWaitCount]--Cumulative number of times the Database Engine waited on a page lock.
,ddios.[page_lock_wait_in_ms] [PageLockWaitIn_ms]--Total number of milliseconds the Database Engine waited on a row lock.
,ddios.[row_lock_wait_count] [RowLockWaitCount]--Cumulative number of times the Database Engine waited on a page lock.
,ddios.[row_lock_wait_in_ms] [RowLockWaitIn_ms]--Total number of milliseconds the Database Engine waited on a page lock.
,ddios.[index_lock_promotion_attempt_count] [IndexLockPromotionAttemptCount]--Cumulative number of times the Database Engine tried to escalate locks.
,ddios.[index_lock_promotion_count] [IndexLockPromotionCount]--Cumulative number of times the Database Engine escalated locks.
FROM sys.all_objects ao 
INNER JOIN sys.indexes i ON ao.[object_id] = i.[object_id] 
LEFT OUTER JOIN sys.dm_db_index_operational_stats(DB_ID(),NULL,NULL,NULL) ddios ON i.[object_id] = ddios.[object_id] AND i.[index_id] = ddios.[index_id]
WHERE ao.[is_ms_shipped] = 0