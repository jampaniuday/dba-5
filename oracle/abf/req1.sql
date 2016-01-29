column traceid format a8
column tracename format a80
column user_concurrent_program_name format a40
column execname format a15
column enable_trace format a12
column status format a10
column login format a24
column spid format a8
column process format a8
column machine format a14
column module format a50
column program format a50
column action format a50
column last_call format a10
column wait_event format a50
column secs_wait format a10
column state format a20
set lines 80
set pages 0 
set heading off
set feed off

SELECT '----------------------------------------------------------------',
'                                                                       ',
'SYSDATE: '||to_char(sysdate,'HH24:MI:SS DD/MM/YYYY'),
'                                                                       ',
'----------------------------------------------------------------',
'Request id: '||request_id ,
'Trace id: '||oracle_Process_id,
'Trace Flag: '||req.enable_trace,
'Trace Name:
'||dest.value||'/'||lower(dbnm.value)||'_ora_'||oracle_process_id||'.trc',
'Prog. Name: '||prog.user_concurrent_program_name,
'File Name: '||execname.execution_file_name|| execname.subroutine_name ,
'Status : '||decode(phase_code,'R','Running')
||'-'||decode(status_code,'R','Normal'),
'INST SID Serial: '|| ses.inst_id || ' - ' || ses.sid ||','|| ses.serial#,
'Status: '||ses.status||'                 ',
'Login: '||to_char(ses.logon_time, 'HH24:MI:SS DD/MM/YYYY')||'                            ',
'SPID: '|| proc.spid,
'Process: '|| ses.process||'                   ',
'Machine: '|| ses.machine,
'Module: '||ses.module,
'Program: '||ses.program,
'Action: '||ses.action,
'Last Call: '||to_char(trunc((ses.last_call_et/60))),
'Wait Event: '||sw.event,
'Secs Wait: '||to_char(sw.seconds_in_wait),
'State: '||sw.state||'                                                ',
'Hash: '||ses.sql_hash_value||'                                                    ',
'SQL_ID: '||ses.sql_id,
'----------------------------------------------------------------'
from fnd_concurrent_requests req, gv$session ses, gv$process proc, gv$session_wait sw,
gv$parameter dest, gv$parameter dbnm, fnd_concurrent_programs_vl prog,
fnd_executables execname
where req.request_id = &request
and req.oracle_process_id=proc.spid(+)
and proc.addr = ses.paddr(+)
and ses.sid = sw.sid
and ses.inst_id = sw.inst_id
and proc.INST_ID = ses.INST_ID
and dest.inst_id = ses.inst_id
and dbnm.inst_id = ses.inst_id
and dest.name='user_dump_dest'
and dbnm.name='instance_name'
and req.concurrent_program_id = prog.concurrent_program_id
and req.program_application_id = prog.application_id
and prog.application_id = execname.application_id
and prog.executable_id=execname.executable_id;
