col sql_text format a300
select
        TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') AS "SYSDATE",
        x.sql_text as "SQL TEXT"
from
        gv$session s,
        gv$sqltext x
where
        s.sql_address=x.address
        and s.sid = &sid_conc
        and s.inst_id = &inst_id
order by sid, piece asc;
select sql_text from gv$sql s, gv$session ss
where s.sql_id = ss.sql_id
and s.inst_id = ss.inst_id
and ss.sid = $sid_conc
and ss.inst_id = &inst_id

