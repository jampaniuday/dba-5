SELECT TO_CHAR(A.REQUEST_ID) AS "REQ_ID",
                 DECODE (A.PHASE_CODE,'C','COMPLETED','I','INACTIVE','P','PENDING','R','RUNNING',A.PHASE_CODE) AS "PHASE",
                 DECODE (A.STATUS_CODE,'A','WAITING','B','RESUMING','C','NORMAL','D','CANCELLED','E','ERRORED','F','SCHEDULED',
                 'G','WARNING','H','ONHOLD','I','NORMAL','M','NO MANAGER','Q','STANDBY','R','NORMAL','S','SUSPENDED','T','TERMINATING',
                 'U','DISABLED','W','PAUSED','X','TERMINATED','Z','WAITING',A.STATUS_CODE) AS "STATUS",
         resp.responsibility_name,
				 c.CONCURRENT_PROGRAM_NAME AS " PROGRAM SHORT NAME",
				 b.USER_CONCURRENT_PROGRAM_NAME AS "PROGRAM NAME",
         d.user_name,
         d.description COMPLETE_NAME,
         d.email_address,
				 A.ARGUMENT_TEXT,
         a.description CONC_PROGRAM_DESCRIPTION,
         a.completion_text,
         to_char(request_date,'DD/MM/YYYY HH24:MI:SS') REQUEST_TIME,
         to_char(requested_start_date,'DD/MM/YYYY HH24:MI:SS') REQUESTED_START_TIME,
         TO_CHAR(TRUNC((NVL(A.ACTUAL_START_DATE,SYSDATE)-A.REQUEST_DATE)*1440,2)) AS "DELAY MINS TO START",
         TO_CHAR (A.ACTUAL_start_DATE, 'DD/MM/YYYY HH24:MI:SS') AS "START TIME",
				 TO_CHAR (A.ACTUAL_completion_DATE, 'DD/MM/YYYY HH24:MI:SS') AS "COMPLETION TIME",
				 TO_CHAR(TRUNC((NVL(A.ACTUAL_COMPLETION_DATE,SYSDATE)-A.ACTUAL_START_DATE)*1440,2)) AS "MINS EXECUTION"
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
     --and trunc(a.requested_start_date) between to_date('31/12/2010','DD/MM/YYYY') and sysdate
     --AND A.PHASE_CODE = 'P'
     --AND A.STATUS_CODE in ('F')
     and b.language = 'US'
     and resp.language = 'US'
     --and c.concurrent_program_name like ('B2W_B2B_TITULOS_APLIC_SAL%')
     --and a.argument2 like '%RA_CUSTOMER_TRX_ALL%'
     --and d.user_name = 'L38954'
     and a.request_id in (&request)
     --and rownum < 17)
ORDER BY a.request_date DESC;
