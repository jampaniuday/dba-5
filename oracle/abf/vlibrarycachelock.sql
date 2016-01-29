Prompt ************************************ Locks Library Cache ***************************************
set pages 50
 select a.INST_ID,
        a.SID,
        a.SEQ#,
        a.WAIT_TIME,
        a.SECONDS_IN_WAIT,
        a.STATE,
        b.action,
        b.module
  from gv$session_wait a,
       gv$session b
     where a.event ='library cache lock'
     and   a.sid=b.sid
     and   a.inst_id=b.inst_id;
set pages 0
prompt
prompt
set feed off
select 'Sysdate: '||sysdate from dual;
set feed on
prompt
prompt 
prompt 
prompt
set pages 50



