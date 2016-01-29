prompt MONTHLY EXECS
select trunc(req.actual_completion_date) DAY,
count(*) EXECS
from ood_concurrent_requests req
where req.actual_start_date between to_date('01/04/2012 00:00:00','DD/MM/YYYY HH24:MI:SS') and to_date('28/02/2013 23:59:59','DD/MM/YYYY HH24:MI:SS')
group by trunc(req.actual_completion_date)
order by trunc(req.actual_completion_date);
--set feed on head on pages 50 lines 300
prompt CONCS MAIS EXECUTADOS ULTIMA SEMANA
select substr(prog.user_concurrent_program_name,1,80) USER_CONC_NAME,
count(req.request_id)
from ood_concurrent_requests req,
fnd_concurrent_programs_tl prog
where prog.concurrent_program_id = req.concurrent_program_id
and prog.language = 'US'
--and req.actual_start_date between to_date('03/02/2013 00:00:00','DD/MM/YYYY HH24:MI:SS') and to_date('07/02/2013 23:59:59','DD/MM/YYYY HH24:MI:SS')
and req.actual_start_date > sysdate - 7
group by prog.user_concurrent_program_name
order by 2 desc;
prompt TOP #EXECS MORE THAN 10MINUTES
select * from (
select  b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE) data,
round(max(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) max_MINUTOS,
round(min(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) min_MINUTOS,
round(avg(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) avg_MINUTOS,
round(sum(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) sum_MINUTOS,
count(*)
from apps.ood_Concurrent_requests a,
     apps.fnd_concurrent_programs b,
     apps.ood_Concurrent_queues c,
     apps.fnd_Concurrent_processes d
where a.program_application_id=b.application_id
  and a.concurrent_program_id=b.concurrent_program_id
  and c.application_id=d.queue_application_id
  and c.concurrent_queue_id=d.concurrent_queue_id
  and d.concurrent_process_id=a.controlling_manager
  and a.actual_start_date between to_date('01/04/2012 00:00:00','DD/MM/YYYY HH24:MI:SS') and to_date('28/02/2013 23:59:59','DD/MM/YYYY HH24:MI:SS')
group by b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE)
order by  6, 2 )
where max_MINUTOS > 10;
prompt TOP #EXECS BETWEEN 5 AND 10 MINUTE
select * from (
select  b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE) data,
round(max(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) max_MINUTOS,
round(min(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) min_MINUTOS,
round(avg(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) avg_MINUTOS,
round(sum(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) sum_MINUTOS,
count(*)
from apps.ood_Concurrent_requests a,
     apps.fnd_concurrent_programs b,
     apps.ood_Concurrent_queues c,
     apps.fnd_Concurrent_processes d
where a.program_application_id=b.application_id
  and a.concurrent_program_id=b.concurrent_program_id
  and c.application_id=d.queue_application_id
  and c.concurrent_queue_id=d.concurrent_queue_id
  and d.concurrent_process_id=a.controlling_manager
  and a.actual_start_date between to_date('01/04/2012 00:00:00','DD/MM/YYYY HH24:MI:SS') and to_date('28/02/2013 23:59:59','DD/MM/YYYY HH24:MI:SS')
group by b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE)
order by  6, 2 )
where max_MINUTOS BETWEEN 5 AND 10;
prompt TOP #EXECS 5 MINUTE
select * from (
select  b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE) data,
round(max(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) max_MINUTOS,
round(min(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) min_MINUTOS,
round(avg(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) avg_MINUTOS,
round(sum(TRUNC((a.ACTUAL_COMPLETION_DATE - a.ACTUAL_START_DATE ) * 1440))) sum_MINUTOS,
count(*)
from apps.ood_Concurrent_requests a,
     apps.fnd_concurrent_programs b,
     apps.ood_Concurrent_queues c,
     apps.fnd_Concurrent_processes d
where a.program_application_id=b.application_id
  and a.concurrent_program_id=b.concurrent_program_id
  and c.application_id=d.queue_application_id
  and c.concurrent_queue_id=d.concurrent_queue_id
  and d.concurrent_process_id=a.controlling_manager
  and a.actual_start_date between to_date('01/04/2012 00:00:00','DD/MM/YYYY HH24:MI:SS') and to_date('28/02/2013 23:59:59','DD/MM/YYYY HH24:MI:SS')
group by b.concurrent_program_name, trunc(a.ACTUAL_COMPLETION_DATE)
order by  6, 2 )
where max_MINUTOS < 5;
--set feed on head on pages 50 lines 230
prompt FILAS
select substr(t.USER_CONCURRENT_QUEUE_NAME,1,45) QUEUE_NAME, NODE_NAME, MAX_PROCESSES, RUNNING_PROCESSES, CACHE_SIZE, SLEEP_SECONDS,
((nvl(cache_size,1) + RUNNING_PROCESSES) * 60) / sleep_seconds CAPACITY_PER_MIN,
((((nvl(cache_size,1) + RUNNING_PROCESSES) * 60) / sleep_seconds)*60) CAPACITY_PER_HOUR
from fnd_concurrent_queues q,
fnd_concurrent_queues_tl t
where ENABLED_FLAG = 'Y'
and t.language = 'US'
and q.CONCURRENT_QUEUE_ID = t.CONCURRENT_QUEUE_ID
and q.MAX_PROCESSES > 0
and q.RUNNING_PROCESSES > 0
and q.sleep_seconds != 0
--and q.creation_date >= to_date('01/01/2013 00:00:00','DD/MM/YYYY HH24:MI:SS')
order by q.CONCURRENT_QUEUE_NAME;
prompt QUEUES FULL CAPACITY
select
sum(((nvl(cache_size,1) + RUNNING_PROCESSES) * 60) / sleep_seconds) CAPACITY_PER_MIN,
sum(((((nvl(cache_size,1) + RUNNING_PROCESSES) * 60) / sleep_seconds)*60)) CAPACITY_PER_HOUR
from fnd_concurrent_queues
where ENABLED_FLAG = 'Y'
and MAX_PROCESSES > 0
and RUNNING_PROCESSES > 0
and sleep_seconds != 0
--and creation_date >= to_date('01/01/2013 00:00:00','DD/MM/YYYY HH24:MI:SS')
order by CONCURRENT_QUEUE_NAME;

