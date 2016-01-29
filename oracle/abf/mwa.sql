select s.inst_id,
       s.sid,
       s.serial#,
       s.status,
       substr(s.username,1,20) db_user ,
       substr(s.OSUSER,1,20) os_user ,
       substr(p.spid,1,8) spid,
       substr(s.machine,1,20) machine,
       to_char(s.logon_time, 'HH24:MI:SS DD/MM') login,
       substr(s.process,1,8) process,
       substr(s.program,1,18) program,
       substr(s.terminal,1,8) terminal,
       substr(s.module,1,40) module,
       substr(s.action,1,40) action,
       trunc((last_call_et/60)) last_call,
       sw.event,
       sw.seconds_in_wait,
       sw.state,
       s.sql_hash_value,
       s.sql_id
from
gv$session s,
gv$process p,
gv$session_wait sw
where s.paddr=p.addr
and s.inst_id = p.inst_id
and s.sid = sw.sid
and s.inst_id = sw.inst_id
and s.module like ('%MWAJ%');
