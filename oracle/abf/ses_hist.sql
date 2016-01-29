select count(*), session_id, session_serial#, sql_id, event, session_state, blocking_session_status, blocking_session
, program, module, action, client_id, sum(time_waited)
from dba_hist_active_sess_history
where sample_time > trunc(sysdate) +16/24
and program like 'frmweb@auohsedab35%'
group by session_id, session_serial#, sql_id, event, session_state, blocking_session_status, blocking_session, program, module, action, client_id
order by 13 desc, session_id, session_serial#;
