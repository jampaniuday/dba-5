prompt CONCS POR DIA
select trunc(actual_completion_date) DIA, 
count(*) CONCS
from fnd_concurrent_requests 
group by trunc(actual_completion_date) 
order by trunc(actual_completion_date);
--set feed on head on pages 50 lines 300
prompt CONCS MAIS EXECUTADOS ULTIMA SEMANA
select substr(prog.user_concurrent_program_name,1,80) USER_CONC_NAME,
count(req.request_id)
from fnd_concurrent_requests req,
fnd_concurrent_programs_tl prog
where prog.concurrent_program_id = req.concurrent_program_id
and prog.language = 'US'
and trunc(actual_completion_date) > trunc(sysdate - 7)
group by prog.user_concurrent_program_name
order by 2 desc;
select * from (
select  b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE) data,
round(max(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) max_MINUTOS, 
round(min(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) min_MINUTOS, 
round(avg(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) avg_MINUTOS,
round(sum(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) sum_MINUTOS,
count(*)
from apps.fnd_Concurrent_requests a,
     apps.fnd_concurrent_programs b,
     apps.fnd_Concurrent_queues c,
     apps.fnd_Concurrent_processes d
where a.program_application_id=b.application_id
  and a.concurrent_program_id=b.concurrent_program_id
  and c.application_id=d.queue_application_id
  and c.concurrent_queue_id=d.concurrent_queue_id
  and d.concurrent_process_id=a.controlling_manager 
  and a.ACTUAL_START_DATE > trunc(sysdate)-7 
group by b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE)
order by  1, 2 )
where max_MINUTOS > 10;
--set feed on head on pages 50 lines 230
prompt CONCS TEMPO MAIOR 10MIN
SELECT 
   fcr.request_id request_id,
   TRUNC(((fcr.actual_completion_date-fcr.actual_start_date)/(1/24))*60) exec_time,
   to_char(fcr.actual_start_date,'DD/MM/YYYY HH24:MI:SS') start_date,
   to_char(fcr.actual_completion_date,'DD/MM/YYYY HH24:MI:SS') comp_date,
   substr(fcp.concurrent_program_name,1,40) SHORT_NAME,
   substr(fcpt.user_concurrent_program_name,1,80) USER_CONC_NAME,
   substr(fcr.description,1,50) description
FROM
  fnd_concurrent_programs fcp,
  fnd_concurrent_programs_tl fcpt,
  fnd_concurrent_requests fcr
WHERE TRUNC(((fcr.actual_completion_date-fcr.actual_start_date)/(1/24))*60) > 10
and fcr.actual_start_date > sysdate - 7
and fcr.concurrent_program_id = fcp.concurrent_program_id
and fcr.program_application_id = fcp.application_id
and fcr.concurrent_program_id = fcpt.concurrent_program_id
and fcr.program_application_id = fcpt.application_id
and fcpt.language = 'US'
ORDER BY TRUNC(((fcr.actual_completion_date-fcr.actual_start_date)/(1/24))*60) desc;
--set feed on head on pages 50 lines 200
prompt PROGRAMAS QUE CADA FILA EXECUTA
select substr(q.concurrent_queue_name,1,30) QUEUE_NAME,
substr(tl.user_concurrent_program_name,1,80) PROG_NAME,
substr(p.concurrent_program_name,1,30) SHORT_NAME
from fnd_concurrent_queues q,
fnd_concurrent_queue_content c,
fnd_concurrent_programs p,
fnd_concurrent_programs_tl tl
where c.QUEUE_APPLICATION_ID = q.APPLICATION_ID
and q.CONCURRENT_QUEUE_ID = c.CONCURRENT_QUEUE_ID
and p. APPLICATION_ID = c.TYPE_APPLICATION_ID
and p.CONCURRENT_PROGRAM_ID = c.type_id
and tl.concurrent_program_id = p.concurrent_program_id
and tl.language = 'US'
and c.include_flag = 'I';
prompt USER POR FILA
select substr(q.concurrent_queue_name,1,30) QUEUE_NAME,
u.user_name
from fnd_concurrent_queues q,
fnd_concurrent_queue_content c,
fnd_user u
where c.QUEUE_APPLICATION_ID = q.APPLICATION_ID
and q.CONCURRENT_QUEUE_ID = c.CONCURRENT_QUEUE_ID
and u.user_id = c.type_id
and c.include_flag = 'I';
prompt REQUEST CLASS POR FILA
select substr(q.concurrent_queue_name,1,30) QUEUE_NAME,
class.REQUEST_CLASS_NAME
from fnd_concurrent_queues q,
fnd_concurrent_queue_content c,
fnd_concurrent_request_class class
where c.QUEUE_APPLICATION_ID = q.APPLICATION_ID
and q.CONCURRENT_QUEUE_ID = c.CONCURRENT_QUEUE_ID
and class. APPLICATION_ID = c.TYPE_APPLICATION_ID
and class.REQUEST_CLASS_ID = c.type_id
and c.include_flag = 'I';
prompt MODULOS POR FILA
select substr(q.concurrent_queue_name,1,30) QUEUE_NAME,
u.oracle_username
from fnd_concurrent_queues q,
fnd_concurrent_queue_content c,
FND_ORACLE_USERID u
where c.QUEUE_APPLICATION_ID = q.APPLICATION_ID
and q.CONCURRENT_QUEUE_ID = c.CONCURRENT_QUEUE_ID
and u.oracle_id = c.type_id
and c.include_flag = 'I';
prompt RULES POR FILA
select substr(q.concurrent_queue_name,1,30) QUEUE_NAME,
rule.COMPLEX_RULE_NAME,
substr(DESCRIPTION,1,80) description
from fnd_concurrent_queues q,
fnd_concurrent_queue_content c,
FND_CONCURRENT_COMPLEX_RULES rule
where c.QUEUE_APPLICATION_ID = q.APPLICATION_ID
and q.CONCURRENT_QUEUE_ID = c.CONCURRENT_QUEUE_ID
and rule.APPLICATION_ID = c.TYPE_APPLICATION_ID
and rule.COMPLEX_RULE_ID = c.type_id
and c.include_flag = 'I';
prompt FILAS
select CONCURRENT_QUEUE_NAME, NODE_NAME, MAX_PROCESSES, RUNNING_PROCESSES, CACHE_SIZE, SLEEP_SECONDS, 
((nvl(cache_size,1) + RUNNING_PROCESSES) * 60) / sleep_seconds CAPACITY
from fnd_concurrent_queues
where ENABLED_FLAG = 'Y'
and MAX_PROCESSES > 0
and RUNNING_PROCESSES > 0
and sleep_seconds != 0
order by CONCURRENT_QUEUE_NAME;

