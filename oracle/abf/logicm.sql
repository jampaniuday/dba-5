SELECT  fcp.logfile_name
FROM    fnd_concurrent_processes fcp, fnd_concurrent_queues fcq
WHERE   fcp.concurrent_queue_id = fcq.concurrent_queue_id
AND     fcp.queue_application_id = fcq.application_id
AND     fcq.manager_type = '0'
AND     fcp.process_status_code = 'A';
