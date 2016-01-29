select s.sid, s.serial#,s.username,  s.machine,to_char(s.logon_time,'dd-mon-yyyy hh24:mi') "logontime", w.event, w.WAIT_time, w.SECONDS_IN_WAIT
 from v$session_wait w, v$session s
 where w.sid=s.sid
 and upper(w.event) not like '%NET%'
 and w.event not in ('pipe get','queue messages','log file sync')
 and s.username is not null
 --and w.event = 'kksfbc child completion'
 order by SECONDS_IN_WAIT;
