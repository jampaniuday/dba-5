column traceid format a8
column tracename format a80
column user_concurrent_program_name format a40
column execname format a15
column enable_trace format a12
set lines 80
set pages 22
set head off

SELECT 'Request id: '||request_id ,
'Trace id: '||oracle_Process_id,
'Trace Flag: '||req.enable_trace,
'Trace Name:
'||dest.value||'/'||lower(dbnm.value)||'_ora_'||oracle_process_id||'.trc',
'Prog. Name: '||prog.user_concurrent_program_name,
'File Name: '||execname.execution_file_name|| execname.subroutine_name ,
'Status : '||decode(phase_code,'R','Running')
||'-'||decode(status_code,'R','Normal'),
'INST SID Serial: '|| ses.inst_id || ' - ' || ses.sid ||','|| ses.serial#,
'Module : '||ses.module
from fnd_concurrent_requests req, gv$session ses, gv$process proc,
gv$parameter dest, gv$parameter dbnm, fnd_concurrent_programs_vl prog,
fnd_executables execname
where req.request_id = &request
and req.oracle_process_id=proc.spid(+)
and proc.addr = ses.paddr(+)
and proc.INST_ID = ses.INST_ID
and dest.inst_id = ses.inst_id
and dbnm.inst_id = ses.inst_id
and dest.name='user_dump_dest'
and dbnm.name='instance_name'
and req.concurrent_program_id = prog.concurrent_program_id
and req.program_application_id = prog.application_id
and prog.application_id = execname.application_id
and prog.executable_id=execname.executable_id;
