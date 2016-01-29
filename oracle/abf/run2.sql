SELECT TO_CHAR(fcr.REQUEST_ID) AS "REQ_ID",
                 DECODE (fcr.PHASE_CODE,'C','COMPLETED','I','INACTIVE','P','PENDING','R','RUNNING',fcr.PHASE_CODE) AS "PHASE",
                 DECODE (fcr.STATUS_CODE,'A','WAITING','B','RESUMING','C','NORMAL','D','CANCELLED','E','ERRORED','F','SCHEDULED',
                 'G','WARNING','H','ONHOLD','I','NORMAL','M','NO MANAGER','Q','STANDBY','R','NORMAL','S','SUSPENDED','T','TERMINATING',
                 'U','DISABLED','W','PAUSED','X','TERMINATED','Z','WAITING',fcr.STATUS_CODE) AS "STATUS",
fcp.enable_trace AS "TRACE",
fcp.CONCURRENT_PROGRAM_NAME AS "SHORT NAME",
fcq.concurrent_queue_name AS "QUEUE NAME",
ses.inst_id || ' - ' || ses.SID || ',' || ses.serial# AS "INST - SID,SERIAL", 
ses.status AS "STATUS SID",
sesw.event "SESSION EVENT",
TO_CHAR (fcr.actual_start_date,'DD/MM/YYYY HH24:MI:SS') AS "START DATE",
TO_CHAR (  TRUNC (((86400 * (SYSDATE - fcr.actual_start_date)) / 60) / 60, 2) -   24 
* (TRUNC (  (  (  (86400 * (SYSDATE - fcr.actual_start_date))/ 60)/ 60)/ 24))) AS "TIME"
FROM 
	fnd_concurrent_queues fcq,
	fnd_concurrent_requests fcr,
	fnd_concurrent_programs fcp,
	fnd_concurrent_processes fpro,
  fnd_user fu,
	gv$session ses,
  gv$session_wait sesw,
	gv$process proc
WHERE
phase_code = 'R'
AND fcr.oracle_process_id=proc.spid(+)
AND proc.addr = ses.paddr(+)
and ses.sid = sesw.sid
and ses.inst_id = sesw.inst_id
AND fcr.controlling_manager = concurrent_process_id
AND (fcq.concurrent_queue_id = fpro.concurrent_queue_id AND fcq.application_id = fpro.queue_application_id)
AND (fcr.concurrent_program_id = fcp.concurrent_program_id AND fcr.program_application_id = fcp.application_id)
AND fcr.requested_by = fu.user_id
order by actual_start_date desc;
