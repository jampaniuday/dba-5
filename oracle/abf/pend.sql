select substr(fcw.USER_CONCURRENT_PROGRAM_NAME,1,99) program_name,
substr(fcw.CONCURRENT_PROGRAM_NAME,1,50) short_name,
count(*)
FROM    fnd_concurrent_worker_requests fcw,
fnd_concurrent_queues_vl fcq
WHERE      fcq.concurrent_queue_id = fcw.concurrent_queue_id
AND      fcw.phase_code = 'P'
AND      fcw.hold_flag != 'Y'
AND      fcw.max_processes > 0
AND      fcw.requested_start_date <= SYSDATE
AND     lower(fcq.user_concurrent_queue_name) like '%&program%' 
GROUP BY substr(fcw.USER_CONCURRENT_PROGRAM_NAME,1,99), substr(fcw.CONCURRENT_PROGRAM_NAME,1,50)
order by 3;
