set feed off head on lines 300 pages 20
cl scr
select count(*) REQUESTS_RUNNING from fnd_concurrent_requests where phase_code = 'R';
select count(*) REQUESTES_PENDING from fnd_concurrent_worker_requests where phase_code = 'P' and status_code = 'I' and requested_start_date <= SYSDATE;
select count(sid) INACTIVE_FORMS_SESSIONS from v$session where lower(module) like '%frm%' and program like 'frmweb%' and status = 'INACTIVE' and machine = 'auohsedab35';
select count(sid) ACTIVE_FORMS_SESSIONS from v$session where lower(module) like '%frm%' and program like 'frmweb%' and status = 'ACTIVE' and machine = 'auohsedab35';
select count(*) ACTIVE_JDBC_CONNECTIONS from v$session where program like '%JDBC%' and status = 'ACTIVE';
select count(*) INACTIVE_JDBC_CONNECTIONS from v$session where program like '%JDBC%' and status = 'INACTIVE';
prompt PURGES
select DECODE (r.PHASE_CODE,'C','COMPLETED','I','INACTIVE','P','PENDING','R','RUNNING',r.PHASE_CODE) AS "PHASE",
DECODE(r.STATUS_CODE,'A','WAITING','B','RESUMING','C','NORMAL','D','CANCELLED','E','ERRORED','F','SCHEDULED','G','WARNING','H','ONHOLD','I','NORMAL','M','NO MANAGER','Q','STANDBY','R','NORMAL','S','SUSPENDED','T','TERMINATING','U','DISABLED','W','PAUSED','X','TERMINATED','Z','WAITING',r.STATUS_CODE) AS "STATUS",
substr(p.user_concurrent_program_name,1,60) concurrent_program_name, to_char(r.actual_completion_date,'DD/MM/YYYY HH24:MI:SS') COMPLETION_DATE
from fnd_concurrent_requests r, fnd_concurrent_programs_tl p
where r.concurrent_program_id = p.concurrent_program_id
and p.language = 'US'
and r.concurrent_program_id in (32263,43871,43588,44421,50698,38089,44408,32592,46781,43593,46798,46796,46797)
and trunc(r.actual_start_date) = trunc(sysdate);
set feed on pages 50
