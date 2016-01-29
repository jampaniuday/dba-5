set pagesize 100
SELECT 'alter system disconnect session '''||sid||','|| serial# ||''' immediate;'
FROM GV$SESSION S
WHERE
S.ACTION LIKE 'FRM%'
AND STATUS = 'INACTIVE'
AND S.LAST_CALL_ET > 7200
or
S.ACTION LIKE 'FRM%'
AND STATUS = 'ACTIVE'
AND S.LAST_CALL_ET > 3600;
