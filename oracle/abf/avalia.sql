set lines 500
COLUMN Operation FORMAT A95
COLUMN sid FORMAT 99999
COLUMN serial# FORMAT 9999999
COLUMN machine FORMAT A10
COLUMN progress_pct FORMAT 99999999.00
COLUMN elapsed FORMAT A8
COLUMN remaining FORMAT A10
SELECT sl.message "Operation",
       s.sid,
       s.serial#,
       s.machine,
       TRUNC(sl.elapsed_seconds/60) || ':' || MOD(sl.elapsed_seconds,60) elapsed,
       TRUNC(sl.time_remaining/60) || ':' || MOD(sl.time_remaining,60) remaining,
       ROUND(sl.sofar/sl.totalwork*100, 2) progress_pct
FROM   gv$session s,
       gv$session_longops sl
WHERE  s.sid     = sl.sid
AND    s.serial# = sl.serial#
AND    s.sid = &sid
AND    s.inst_id = &inst_id
AND    sl.totalwork <> 0;
