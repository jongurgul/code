--http://jongurgul.com/blog/policy-based-management-execution-mode/
SELECT
 f.[name] [FacetName]
,ISNULL(p.d,'') [On change: prevent]
,ISNULL(l.d,'') [On change: log only]
,ISNULL(ds.d,'') [On demand / On schedule]
FROM msdb..syspolicy_management_facets f
LEFT OUTER JOIN (SELECT 'x' d,1 n) p ON f.execution_mode & p.n = p.n
LEFT OUTER JOIN (SELECT 'x' d,2 n) l ON f.execution_mode & l.n = l.n
LEFT OUTER JOIN (SELECT 'x' d,4 n) ds ON f.execution_mode & ds.n = ds.n
ORDER BY f.[name]