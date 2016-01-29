col reqid    format 9999999999 heading 'RequestID';
col mins_exec format 999.99 heading 'Mins Exec';
col paren    format a10 heading 'Parent';
col phase    format a10 heading 'Phase code';
col status   format a14 heading 'Status code';
col short_name format a15 heading 'Short Name';
SELECT A.REQUEST_ID AS "reqid",
       nvl(to_char(trunc(parent_request_id)),'No Parent') as "paren",
                 DECODE (A.PHASE_CODE,'C','COMPLETED','I','INACTIVE','P','PENDING','R','RUNNING',A.PHASE_CODE) AS "PHASE",
                 DECODE (A.STATUS_CODE,'A','WAITING','B','RESUMING','C','NORMAL','D','CANCELLED','E','ERRORED','F','SCHEDULED',
                 'G','WARNING','H','ONHOLD','I','NORMAL','M','NO MANAGER','Q','STANDBY','R','NORMAL','S','SUSPENDED','T','TERMINATING',
                 'U','DISABLED','W','PAUSED','X','TERMINATED','Z','WAITING',A.STATUS_CODE) AS "STATUS",
         substr(c.CONCURRENT_PROGRAM_NAME,1,15) AS "SHORT_NAME",
	 TO_CHAR (A.ACTUAL_start_DATE, 'DD/MM/YYYY HH24:MI:SS') AS "Start Time",
	 TO_CHAR(TRUNC((NVL(A.ACTUAL_COMPLETION_DATE,SYSDATE)-A.ACTUAL_START_DATE)*1440,2)) AS "mins_exec"
   FROM APPS.FND_CONCURRENT_REQUESTS A,
        APPS.FND_CONCURRENT_PROGRAMS_TL B,
        apps.fnd_concurrent_programs c,
        apps.fnd_user d,
        apps.fnd_responsibility_tl resp
   WHERE a.concurrent_program_id = c.concurrent_program_id
     and A.concurrent_program_id = B.CONCURRENT_PROGRAM_id
     AND A.PROGRAM_APPLICATION_ID = B.APPLICATION_ID
     and a.program_application_id = c.application_id
     and a.requested_by = d.user_id
     and a.responsibility_id = resp.responsibility_id
     AND A.PHASE_CODE = 'R'
     and a.hold_flag = 'N'
     and b.language = 'US'
     and resp.language = 'US'
     and to_number(TO_CHAR(TRUNC((NVL(A.ACTUAL_COMPLETION_DATE,SYSDATE)-A.ACTUAL_START_DATE)*1440,2))) > 1
ORDER BY (TO_CHAR(TRUNC((NVL(A.ACTUAL_COMPLETION_DATE,SYSDATE)-A.ACTUAL_START_DATE)*1440,2)))DESC;
