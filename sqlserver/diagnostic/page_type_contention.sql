--http://jongurgul.com/blog/sql-server-page-types/

SELECT *, 
CASE
WHEN [page_id] = 0 THEN 'File Header Page m_type 15'
WHEN [page_id] = 1 OR [page_id] % 8088 = 0 THEN 'PFS m_type 11'
WHEN [page_id] = 2 OR [page_id] % 511232 = 0 THEN 'GAM m_type 8'
WHEN [page_id] = 3 OR ([page_id] - 1) % 511232 = 0 THEN 'SGAM m_type 9'
WHEN [page_id] = 6 OR ([page_id] - 6) % 511232 = 0 THEN 'DCM m_type 16'
WHEN [page_id] = 7 OR ([page_id] - 7) % 511232 = 0 THEN 'BCM m_type 17'
WHEN [page_id] = 9 AND [file_id] = 1 THEN 'Boot Page m_type 13' --DBCC DBINFO WITH TABLERESULTS 
WHEN [page_id] = 10 AND DB_ID() = 1 THEN 'config page - sp_configure settings only present in master m_type 14'
ELSE 'Other'
END [Description], 
'DBCC PAGE('''+DB_NAME()+''','+LTRIM(STR(x.[file_id]))+','+LTRIM(STR(x.[page_id]))+',3) WITH TABLERESULTS' [Page] 
FROM
( 
SELECT 0 [page_id],1 [file_id] UNION ALL -- A File Header Page 
SELECT 1 [page_id],1 [file_id] UNION ALL -- A PFS Page 
 --SELECT 8088 [page_id],1 [file_id] UNION ALL -- A PFS Page 
 --SELECT 16176 [page_id],1 [file_id] UNION ALL -- A PFS Page 
SELECT 2 [page_id],1 [file_id] UNION ALL -- A GAM Page 
 --SELECT 511232 [page_id],1 [file_id] UNION ALL -- A GAM Page 
SELECT 3 [page_id],1 [file_id] UNION ALL -- A SGAM page 
 --SELECT 511233 [page_id],1 [file_id] UNION ALL -- A SGAM page 
SELECT 6 [page_id],1 [file_id] UNION ALL -- A DCM page 
 --SELECT 511238 [page_id],1 [file_id] UNION ALL -- A DCM page 
SELECT 7 [page_id],1 [file_id] UNION ALL -- A BCM page 
 --SELECT 511239 [page_id],1 [file_id] UNION ALL -- A BCM page 
SELECT 9 [page_id],1 [file_id] UNION ALL -- The Boot Page 
SELECT [page_id],[file_id] FROM msdb.dbo.suspect_pages 

UNION ALL
 SELECT      
 PARSENAME(REPLACE([resource_description],':','.'),1) [page_id]
,PARSENAME(REPLACE([resource_description],':','.'),2) [file_id]
--,PARSENAME(REPLACE([resource_description],':','.'),3) [database_id]
--,[resource_description]
--,[wait_type]
--,SUBSTRING([resource_description], 0, CHARINDEX(':', [resource_description])) [DatabaseID]
FROM sys.dm_os_waiting_tasks
WHERE [resource_description] IS NOT NULL
AND [wait_type] LIKE '%IOLATCH%' 

) x