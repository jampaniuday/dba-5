select s.inst_id, 
       s.sid, 
       s.serial#, 
       s.status, 
       substr(s.username,1,10) db_user ,
       substr(p.spid,1,8) spid, 
       substr(s.machine,1,10) machine, 
       to_char(s.logon_time, 'HH24:MI:SS DD/MM') login, 
       substr(s.process,1,8) process, 
       substr(s.module,1,30) module, 
       substr(s.action,1,30) action, 
       trunc((last_call_et/60)) last_call, 
       substr(sw.event,1,30)
from 
gv$session s,
gv$process p,
gv$session_wait sw
where s.paddr=p.addr
and s.inst_id = p.inst_id
and s.sid = sw.sid
and s.inst_id = sw.inst_id
and lower(s.module) like ('%&module%')
--and trunc(s.logon_time) < to_date('14/01/2011','DD/MM/YYYY')
order by s.logon_time desc;
