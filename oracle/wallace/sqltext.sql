break on hash_value
break on sqlId_HashValue
column sqlId_HashValue for a25
set pagesize 1000
set long 2000000
select sql_text
from v$sqltext
where hash_value in
        (select sql_hash_value from
                v$session where sid = &sid)
order by piece
/
