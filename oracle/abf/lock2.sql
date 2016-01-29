SELECT s.sid, s.serial#, s.username, s.osuser, s.program
,s.action, p.spid
,to_char(s.logon_time,'dd-mon-yyyy hh24:mi') "logontime"
, l.blocking_others, l.lock_type, l.mode_held
FROM DBA_LOCK l, v$session s, v$process p
where s.sid = l.session_id
and s.paddr=p.addr
and l.blocking_others <> 'Not Blocking'
order by s.logon_time;
