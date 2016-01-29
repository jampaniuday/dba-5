col sid_serial format a10
set lines 999
col wait_file_name format a50
col username format a15

 select s.sid || ',' || s.serial# sid_serial,
        substr(s.username,1,15) username, substr(s.osuser,1,10) osuser,
        substr(w.event,1,50) event,
        w.seconds_in_wait secswait,
        w.p1, w.p2, w.p3, dtf.name wait_file_name
 from v$session_wait w,
      v$session s,
      v$datafile dtf
 where s.sid = w.sid
 and   w.p1 = dtf.file# (+)
 and ((w.event not like '%SQL*Net%'
       and w.event not like '%timer%'
       and w.event not like '%ipc%') or
      (w.event like '%dblink%'))
 order by w.seconds_in_wait
/

