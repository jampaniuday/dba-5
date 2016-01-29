select substr(fcq.USER_CONCURRENT_QUEUE_NAME,1,50) queue_name,
count(*)
FROM    fnd_concurrent_worker_requests fcw,
fnd_concurrent_queues_vl fcq
WHERE      fcq.concurrent_queue_id = fcw.concurrent_queue_id
AND      fcw.phase_code = 'P'
AND      fcw.hold_flag != 'Y'
AND      fcw.max_processes > 0
AND      fcw.requested_start_date <= SYSDATE
AND     lower(fcq.user_concurrent_queue_name) like '%&fila%' 
GROUP BY substr(fcq.USER_CONCURRENT_QUEUE_NAME,1,50)
order by 2;
