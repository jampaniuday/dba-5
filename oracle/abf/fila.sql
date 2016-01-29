prompt FILAS
select substr(t.USER_CONCURRENT_QUEUE_NAME,1,45) QUEUE_NAME, NODE_NAME, MAX_PROCESSES, RUNNING_PROCESSES, CACHE_SIZE, SLEEP_SECONDS,
((nvl(cache_size,0) + RUNNING_PROCESSES) * 60) / sleep_seconds CAPACITY_PER_MIN,
((((nvl(cache_size,0) + RUNNING_PROCESSES) * 60) / sleep_seconds)*60) CAPACITY_PER_HOUR
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
sum(((nvl(cache_size,0) + RUNNING_PROCESSES) * 60) / sleep_seconds) CAPACITY_PER_MIN,
sum(((((nvl(cache_size,0) + RUNNING_PROCESSES) * 60) / sleep_seconds)*60)) CAPACITY_PER_HOUR
from fnd_concurrent_queues
where ENABLED_FLAG = 'Y'
and MAX_PROCESSES > 0
and RUNNING_PROCESSES > 0
and sleep_seconds != 0
--and creation_date >= to_date('01/01/2013 00:00:00','DD/MM/YYYY HH24:MI:SS')
order by CONCURRENT_QUEUE_NAME;

