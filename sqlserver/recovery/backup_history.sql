--http://jongurgul.com/blog/backup-history/
SELECT
 bus.[database_name] [DatabaseName]
,bus.[type] [Type]
,bus.[backup_start_date] [BackupStartDate]
,bus.[backup_finish_date] [BackupFinishDate]

,CONVERT(DECIMAL(15,3),(bus.[backup_size]/1048576)) [Size_MiB]
,CONVERT(DECIMAL(15,3),(bus.[compressed_backup_size]/1048576)) [CompressedSize_MiB] --SQL2008
,LTRIM(STR((bus.[backup_size])/(bus.[compressed_backup_size]),38,3))+':1' [CompressionRatio] --SQL2008

,DATEDIFF(SECOND,bus.[backup_start_date],bus.[backup_finish_date]) [Duration_S]
,CONVERT(DECIMAL(15,3),(bus.[backup_size]/COALESCE(NULLIF(DATEDIFF(SECOND,bus.[backup_start_date],bus.[backup_finish_date]),0),1))/1048576) [Backup_MiB_S]
,bumf.[physical_device_name]

,bus.[first_lsn] [FirstLSN]
,bus.[last_lsn] [LastLSN]
,bus.[checkpoint_lsn] [CheckpointLSN]
,bus.[database_backup_lsn] [DatabaseBackupLSN]
,bus.[is_copy_only] [IsCopyOnly]
,bus.[differential_base_guid] [DifferentialBaseGUID]
,bus.[differential_base_lsn] [DifferentialBaseLSN]
,bus.[first_recovery_fork_guid] [FirstRecoveryForkID]
,bus.[last_recovery_fork_guid] [LastRecoveryForkID]
,bus.[fork_point_lsn] [ForkPointLSN]

,bus.[user_name] [UserName]
,bus.[compatibility_level] [CompatibilityLevel]
,bus.[database_version] [DatabaseVersion]
,bus.[collation_name] [CollationName]
--SELECT *
FROM [msdb].[dbo].[backupset] bus
INNER JOIN [msdb].[dbo].[backupmediafamily] bumf 
ON bus.[media_set_id] = bumf .[media_set_id]
ORDER BY bus.[backup_start_date] DESC

