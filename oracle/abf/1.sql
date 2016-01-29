COLUMN "Queue Time" format a15
COLUMN "Concurrent Manager" format a20
COLUMN "Program" format a60 heading "Concurrent Program"
set linesize 2000
set echo off
BREAK on "Queue Time" SKIP 1 ON "Concurrent Manager"
SELECT
TO_CHAR (actual_start_date, 'DD-MON-YY : HH24') "Queue Time",
fcqtl.user_concurrent_queue_name "Concurrent Manager",
fcptl.user_concurrent_program_name "Program",
ROUND
( SUM (GREATEST (actual_completion_date - actual_start_date, 0))
* 60
* 24,
2
) "Total Duration (min)",
ROUND
( AVG (GREATEST (actual_completion_date - actual_start_date, 0))
* 60
* 24,
2
) "Avg Duration (min)",
ROUND
( MIN (GREATEST (actual_completion_date - actual_start_date, 0))
* 60
* 24,
2
) "Min Duration (min)",
ROUND
( MAX (GREATEST (actual_completion_date - actual_start_date, 0))
* 60
* 24,
2
) "Max Duration (min)",
COUNT (*) "Times Run", fcq.target_processes "Total Processes"
FROM fnd_concurrent_programs fcp,
fnd_concurrent_programs_tl fcptl,
fnd_concurrent_processes fcproc,
fnd_concurrent_queues_tl fcqtl,
fnd_concurrent_queues fcq,
fnd_concurrent_requests fcr
WHERE fcr.phase_code = 'C'
AND fcr.actual_completion_date IS NOT NULL
AND actual_start_date IS NOT NULL
AND fcq.concurrent_queue_id = fcproc.concurrent_queue_id
AND fcq.application_id = fcproc.queue_application_id
AND fcq.manager_type = 1
AND fcr.controlling_manager = fcproc.concurrent_process_id
AND fcr.program_application_id = fcp.application_id
AND fcr.concurrent_program_id = fcp.concurrent_program_id
AND fcp.concurrent_program_name NOT IN
('ACTIVATE', 'ABORT', 'DEACTIVATE', 'VERIFY')
AND fcr.concurrent_program_id = fcptl.concurrent_program_id
AND fcr.program_application_id = fcptl.application_id
AND fcptl.LANGUAGE = 'US'
AND fcproc.queue_application_id = fcqtl.application_id
AND fcproc.concurrent_queue_id = fcqtl.concurrent_queue_id
AND fcqtl.LANGUAGE = 'US'
GROUP BY TO_CHAR (actual_start_date, 'DD-MON-YY : HH24'),
fcqtl.user_concurrent_queue_name,
fcptl.user_concurrent_program_name,
fcq.target_processes
ORDER BY "Queue Time" ASC,
"Concurrent Manager" ASC,
"Times Run" DESC,
"Max Duration (min)" DESC,
"Total Duration (min)" DESC;
