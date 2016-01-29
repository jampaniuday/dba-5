select substr(fcw.USER_CONCURRENT_PROGRAM_NAME,1,50) program_name,
substr(fcq.USER_CONCURRENT_QUEUE_NAME,1,50) manager,
count(*)
FROM    fnd_concurrent_worker_requests fcw,
fnd_concurrent_queues_vl fcq
WHERE      fcq.concurrent_queue_id = fcw.concurrent_queue_id
AND      fcw.phase_code = 'P'
AND      fcw.hold_flag != 'Y'
AND      fcw.max_processes > 0
AND      fcw.requested_start_date <= SYSDATE
AND     lower(fcq.user_concurrent_queue_name) like '%&fila%' 
GROUP BY substr(fcw.USER_CONCURRENT_PROGRAM_NAME,1,50), substr(fcq.USER_CONCURRENT_QUEUE_NAME,1,50)
order by 3;
