col TRACE_INFO for a100
SELECT 'Trace id: '||proc.spid ||chr(10)||
			 chr(9)||'Trace Name: '||dest.value||'/'||lower(dbnm.value)||'_ora_'||proc.spid||'.trc' ||chr(10)||
			 chr(9)||'INSTANCIA, SID e Serial: '||ses.inst_id||','||ses.sid||','|| ses.serial# ||chr(10)||
       chr(9)||'Module : '||ses.module TRACE_INFO
from gv$session ses, gv$process proc, gv$parameter dest, gv$parameter dbnm
where ses.sid = &sid
and ses.inst_id = &inst_id
and proc.addr = ses.paddr(+)
and proc.INST_ID = ses.INST_ID
and dest.inst_id = ses.inst_id
and dbnm.inst_id = ses.inst_id
and dest.name='user_dump_dest' 
and dbnm.name='instance_name';
