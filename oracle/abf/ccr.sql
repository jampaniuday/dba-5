create or replace PROCEDURE        "OHSCVRD_SCHEDULED_REQUESTS_DS" AS
   CURSOR scheduled_requests (program_id IN NUMBER)
   IS
      SELECT r.request_id, p.user_concurrent_program_name, r.resub_count,
             r.argument_text, r.argument1, r.argument2, r.argument3,
             r.argument4, r.argument5, r.argument6, r.argument7, r.argument8,
             r.argument9, r.argument10, r.argument11, r.argument12,
             r.argument13, r.argument14, r.argument15, r.argument16,
             r.argument17, r.argument18, r.argument19, r.argument20,
             r.argument21, r.argument22, r.argument23, r.argument24,
             r.resubmit_interval_unit_code, r.resubmit_interval
        FROM apps.fnd_concurrent_requests r, apps.fnd_concurrent_programs_tl p
       WHERE p.LANGUAGE = 'US'
         AND p.concurrent_program_id = r.concurrent_program_id
         AND r.concurrent_program_id = program_id
         AND r.phase_code IN ('P', 'R')
         AND r.hold_flag = 'N'
         AND NVL (r.resubmit_end_date, SYSDATE) >= TRUNC (SYSDATE)
         AND r.resubmit_interval IS NOT NULL;

   CURSOR dup_ccr (program_id IN NUMBER)
   IS
      SELECT   r.request_id, r.argument5
          FROM apps.fnd_concurrent_requests r
         WHERE r.concurrent_program_id = program_id
           AND r.phase_code IN ('P', 'R')
           AND r.hold_flag = 'N'
           AND NVL (r.resubmit_end_date, SYSDATE) >= TRUNC (SYSDATE)
           AND r.resubmit_interval IS NOT NULL
      GROUP BY r.request_id, r.argument5
        HAVING COUNT (*) > 1;

   -- incluido por Dantas em 03/06/2008 - Verificacao de profiles e traces ativos
   CURSOR profile  IS
        SELECT
        substr(DECODE(level_id,
                '10001','SITE',
                '10004','USER',
                '10002','APPL',
                '10003','RESP', level_value),1,5) as Nivel
        ,substr(DECODE(level_id,
                '10001','SITE',
                '10004',c.user_name,
                '10002',d.application_name,
                '10003',e.responsibility_name, level_value),1,23) as Valor_Nivel
        ,a.user_profile_option_name as Nome_Perfil
        ,substr(b.profile_option_value,1,5) as Valor_Perfil
        ,to_char(b.last_update_date,'dd/mm/yy hh24:mi')  as data_alteracao
        FROM  fnd_profile_options_vl a
                ,fnd_profile_option_values b
                ,fnd_user c
                ,fnd_application_vl d
                ,fnd_responsibility_vl e
        WHERE a.application_id = b.application_id
        AND level_value = c.user_id(+)
        AND level_value = d.application_id(+)
        AND level_value = e.responsibility_id(+)
        AND a.profile_option_id = b.profile_option_id
        AND a.user_profile_option_name in (select fpo.user_profile_option_name
        from fnd_profile_options_vl fpo, fnd_profile_option_values fpov
        where fpo.application_id = fpov.application_id
        and fpo.profile_option_id = fpov.profile_option_id
        and level_id = 10004)  -- and level_value = 0
        and (((upper(a.user_profile_option_name) like '%DEBUG%' OR upper(a.user_profile_option_name) like '%TRACE%') and b.profile_option_value = 'Y')
              OR (upper(a.user_profile_option_name) like '%DEBUG LEVEL%' AND b.profile_option_value != '0') )
        order by b.last_update_date ;

   -- incluido por Dantas em 03/06/2008 - Verificacao de profiles e traces ativos
   CURSOR trace  IS
        SELECT CONCURRENT_PROGRAM_NAME,
        to_char(LAST_UPDATE_DATE,'dd/mm/yy hh24:mi') LAST_UPDATE_DATE
        FROM fnd_concurrent_programs
        WHERE ENABLE_TRACE = 'Y'
        AND ENABLED_FLAG = 'Y';

   --- Incluido por Vitor Rosas em 06/10/2008
   CURSOR statspack  IS
        select JOB, LOG_USER, WHAT, INSTANCE from dba_jobs
        where LOG_USER='PERFSTAT';

   --- Incluido por Nathan Jacobson em 21/05/2009
   CURSOR sequence  IS
        select sequence_owner, sequence_name, last_number, max_value, (max_value - last_number) AS Faltam, to_char(trunc(( last_number/max_value)*100,1)) AS Porcentagem, increment_by, cycle_flag
        from dba_sequences
        where trunc(( ABS(last_number)/ABS(max_value))*100,1) > 80
        and MAX_VALUE > 0
        and CYCLE_FLAG = 'N'
        ORDER BY 6 DESC;


   v_all              BOOLEAN            := FALSE;
   v_superusuario     BOOLEAN            := FALSE;
   v_sysadmin         BOOLEAN            := FALSE;
   v_sysadmin_com     BOOLEAN            := FALSE;
   v_sysadmin_fin     BOOLEAN            := FALSE;
   v_sysadmin_finap   BOOLEAN            := FALSE;
   v_sysadmin_man     BOOLEAN            := FALSE;
   v_sysadmin_prj     BOOLEAN            := FALSE;
   v_sysadmin_rhf     BOOLEAN            := FALSE;
   v_sysadmin_sup     BOOLEAN            := FALSE;
   v_oce046           BOOLEAN            := FALSE;
   v_temp             BOOLEAN            := FALSE;
   v_perm             BOOLEAN            := FALSE;
   v_apex             BOOLEAN            := FALSE;
   v_createpo             BOOLEAN            := FALSE;
   v_csmtype3             BOOLEAN            := FALSE;
   v_oecogs           BOOLEAN            := FALSE;
   v_cvrdpoap             BOOLEAN            := FALSE;
   v_cvrdpoqd             BOOLEAN            := FALSE;
   v_poapprv          BOOLEAN            := FALSE;
   v_oeoh                         BOOLEAN            := FALSE;
   v_oeol                         BOOLEAN            := FALSE;
   v_poerror          BOOLEAN            := FALSE;
   v_pabudwf          BOOLEAN            := FALSE;
   v_pawfbui              BOOLEAN            := FALSE;
   v_glalloc          BOOLEAN            := FALSE;
   v_ponpblsh             BOOLEAN            := FALSE;
   v_reqapprv             BOOLEAN            := FALSE;
   v_paprowf          BOOLEAN            := FALSE;
   v_wferror              BOOLEAN            := FALSE;
   v_poncompl         BOOLEAN            := FALSE;
   v_stats            BOOLEAN            := FALSE;
   v_count            INTEGER;
   v_dup_rec          dup_ccr%ROWTYPE;
   file_handle        UTL_FILE.file_type;

   -- incluido por Dantas em 30/10/2007 - Purge Obsolete Generic File Manager Data
   v_fnd_lobs         BOOLEAN            := FALSE;

   -- incluido por Vitor Rosas em 08/01/2008 para monitorar requests que alimentam a CVRD_CONC_REQS_DW
   v_ohscvrddw            BOOLEAN            := FALSE;
   v_beacon_critical      BOOLEAN            := FALSE;
   v_beacon_volume        BOOLEAN            := FALSE;
   v_beacon_std           BOOLEAN            := FALSE;
   v_beacon_impact        BOOLEAN            := FALSE;
   v_beacon_fast          BOOLEAN            := FALSE;

   -- incluido por Vitor Rosas em 25/06/2009 para monitorar request do Periodic Alert Scheduler de PCVRDI

   v_periodic_alert          BOOLEAN            := FALSE;

   -- incluido por Dantas em 03/06/2008 - Verificacao de profiles e traces ativos
   v_profile          profile%ROWTYPE;
   v_trace            trace%ROWTYPE;

   -- Incluido por Vitor Rosas em 06/10/2008
   v_statspack          statspack%ROWTYPE;

   -- Incluido por Nathan Jacobson em 21/05/2009
   v_sequence           sequence%ROWTYPE;

   ----------

BEGIN
   file_handle :=
      UTL_FILE.fopen ('/pdilgi/applcsf/',
                      'ohs_scheduled_ccr_ds.txt',
                      'W'
                     );
   UTL_FILE.put_line (file_handle, 'OMCS Scheduled Tasks PDILGI Monitoring    ');
   UTL_FILE.put_line (file_handle, '====================================');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'Critical Tables - Count');
   UTL_FILE.put_line (file_handle, '--------------------------');

-- Count FND_CONCURRENT_REQUESTS
   SELECT /*+ PARALLEL (FCR, 4) */
          COUNT (*)
     INTO v_count
     FROM apps.fnd_concurrent_requests fcr;

   UTL_FILE.put_line (file_handle,
                      'Number of rows in FND_CONCURRENT_REQUESTS table: ' || v_count
                     );

-- Count WF_ITEM_ACTIVITY_STATUSES
   SELECT /*+ PARALLEL (WF, 8) */
          COUNT (*)
     INTO v_count
     FROM apps.wf_item_activity_statuses wf;

   UTL_FILE.put_line (file_handle,
                      'Number of rows in WF_ITEM_ACTIVITY_STATUSES table: ' || v_count
                     );

-- Count WSH_EXCEPTIONS
   SELECT /*+ PARALLEL (WSH, 8) */
          COUNT (*)
     INTO v_count
    FROM apps.WSH_EXCEPTIONS wsh;

   UTL_FILE.put_line (file_handle,
                      'NUmber of rows in WSH_EXCEPTIONS table: ' || v_count
                     );

-- Purge Concurrent Request and/or Manager Data
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle,
                      'Purge Concurrent Request and/or Manager Data'
                     );
   UTL_FILE.put_line (file_handle,
                      '--------------------------------------------'
                     );

   FOR v_dup IN dup_ccr (32263)
   LOOP
      IF dup_ccr%FOUND
      THEN
         UTL_FILE.put_line
            (file_handle,
             'Problem with Purge Concurrent Request and/or Manager Data scheduled program.'
            );
         UTL_FILE.put_line (file_handle,
                               'There is more than one purge program scheduled for user: '
                            || v_dup.argument5
                           );
      END IF;
   END LOOP;

   FOR sch_req IN scheduled_requests (32263)
   LOOP
      -- ALL, Age, 5
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 5)
         AND (sch_req.argument5 IS NULL)
      THEN
         v_all := TRUE;
      END IF;

      -- OCE046, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'OCE046')
      THEN
         v_oce046 := TRUE;
      END IF;

      -- SUPERUSUARIO, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SUPERUSUARIO')
      THEN
         v_superusuario := TRUE;
      END IF;

      -- SYSADMIN, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SYSADMIN')
      THEN
         v_sysadmin := TRUE;
      END IF;

      -- SYSADMIN_COM, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SYSADMIN_COM')
      THEN
         v_sysadmin_com := TRUE;
      END IF;

      -- SYSADMIN_FIN, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SYSADMIN_FIN')
      THEN
         v_sysadmin_fin := TRUE;
      END IF;

      -- SYSADMIN_FINAP, Age, 2
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 2)
         AND (sch_req.argument5 = 'SYSADMIN_FINAP')
      THEN
         v_sysadmin_finap := TRUE;
      END IF;

      -- SYSADMIN_MAN, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SYSADMIN_MAN')
      THEN
         v_sysadmin_man := TRUE;
      END IF;

      -- SYSADMIN_PRJ, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SYSADMIN_PRJ')
      THEN
         v_sysadmin_prj := TRUE;
      END IF;

      -- SYSADMIN_RHF, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SYSADMIN_RHF')
      THEN
         v_sysadmin_rhf := TRUE;
      END IF;

      -- SYSADMIN_SUP, Age, 1
      IF     (sch_req.argument2 = 'Age')
         AND (sch_req.argument3 = 1)
         AND (sch_req.argument5 = 'SYSADMIN_SUP')
      THEN
         v_sysadmin_sup := TRUE;
      END IF;

   END LOOP;

--------------------------
   -- Purge Obsolete Generic File Manager Data (purge da FND_LOBS)
   -- Incluido esta verificacao por Dantas em 30/10/2007
   FOR sch_req IN scheduled_requests (39947)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'Purge Obsolete Generic File Manager Data')
         AND (sch_req.argument1 = 'Y')
         AND (sch_req.resubmit_interval = 7)
      THEN
         v_fnd_lobs := TRUE;
      END IF;

   END LOOP;

--------------------------
   -- Monitoracao do Concurrent OHSCVRD Coleta CVRD_CONCURRENT_REQUESTS_DW
   -- Incluido esta verificacao por Vitor Rosas em 08/01/2008

   FOR sch_req IN scheduled_requests (47046)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'OHSCVRD Coleta CVRD_CONCURRENT_REQUESTS_DW')

      THEN
         v_ohscvrddw := TRUE;
      END IF;

   END LOOP;
--------------------------
   -- Monitoracao do Concurrent CVRD - Beacon Business Critical
   -- Incluido esta verificacao por Vitor Rosas em 08/01/2008

   FOR sch_req IN scheduled_requests (46003)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'CVRD - Beacon Business Critical')

      THEN
         v_beacon_critical := TRUE;
      END IF;

   END LOOP;
--------------------------
   -- Monitoracao do Concurrent CVRD - Beacon High Volume
   -- Incluido esta verificacao por Vitor Rosas em 08/01/2008

   FOR sch_req IN scheduled_requests (46002)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'CVRD - Beacon High Volume')

      THEN
         v_beacon_volume := TRUE;
      END IF;

   END LOOP;
--------------------------
   -- Monitoracao do Concurrent CVRD - Beacon Fast
   -- Incluido esta verificacao por Vitor Rosas em 08/01/2008

   FOR sch_req IN scheduled_requests (46001)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'CVRD - Beacon Fast')

      THEN
         v_beacon_fast := TRUE;
      END IF;

   END LOOP;
--------------------------
   -- Monitoracao do Concurrent CVRD - Beacon Standard
   -- Incluido esta verificacao por Vitor Rosas em 08/01/2008

   FOR sch_req IN scheduled_requests (46005)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'CVRD - Beacon Standard')

      THEN
         v_beacon_std := TRUE;
      END IF;

   END LOOP;
--------------------------
   -- Monitoracao do Concurrent CVRD - Beacon High Impact
   -- Incluido esta verificacao por Vitor Rosas em 08/01/2008

   FOR sch_req IN scheduled_requests (46004)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'CVRD - Beacon High Impact')

      THEN
         v_beacon_impact := TRUE;
      END IF;

   END LOOP;
--------------------------

   -- Monitoracao do Concurrent Periodic Alert Scheduler
   -- Incluido esta verificacao por Vitor Rosas em 25/06/2009

   FOR sch_req IN scheduled_requests (20394)
   LOOP

      IF     (sch_req.user_concurrent_program_name = 'Periodic Alert Scheduler')

      THEN
         v_periodic_alert := TRUE;
      END IF;

   END LOOP;
--------------------------

   IF NOT v_all
   THEN
      UTL_FILE.put_line (file_handle, 'Problems in purge ALL, Age, 5');
   ELSE
      UTL_FILE.put_line (file_handle,
                         'Purge Concurrent Requests Schedule ALL OK'
                        );
   END IF;

   IF NOT v_oce046
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge OCE046, Count, 100');
   ELSE
      UTL_FILE.put_line (file_handle,
                         'Purge Concurrent Requests Schedule OCE046 OK'
                        );
   END IF;

   IF NOT v_superusuario
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge SUPERUSUARIO, Age, 1'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Concurrent Requests Schedule SUPERUSUARIO OK'
                  );
   END IF;

   IF NOT v_sysadmin
   THEN
      UTL_FILE.put_line (file_handle, 'Problemas in purge SYSADMIN, Age, 1');
   ELSE
      UTL_FILE.put_line
                      (file_handle,
                       'Purge Concurrent Requests Schedule SYSADMIN OK'
                      );
   END IF;

   IF NOT v_sysadmin_com
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problemas in purge SYSADMIN_COM, Age, 1'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Concurrent Requests Schedule SYSADMIN_COM OK'
                  );
   END IF;

   IF NOT v_sysadmin_fin
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge SYSADMIN_FIN, Age, 1'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Concurrent Requests Schedule SYSADMIN_FIN OK'
                  );
   END IF;

   IF NOT v_sysadmin_finap
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge SYSADMIN_FINAP, Age, 2'
                        );
   ELSE
      UTL_FILE.put_line
                (file_handle,
                 'Purge Concurrent Requests Schedule SYSADMIN_FINAP OK'
                );
   END IF;

   IF NOT v_sysadmin_man
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge SYSADMIN_MAN, Age, 1'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Concurrent Requests Schedule SYSADMIN_MAN OK'
                  );
   END IF;

   IF NOT v_sysadmin_prj
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge SYSADMIN_PRJ, Age, 1'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Concurrent Requests Schedule SYSADMIN_PRJ OK'
                  );
   END IF;

   IF NOT v_sysadmin_rhf
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge SYSADMIN_RHF, Age, 1'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Concurrent Requests Schedule SYSADMIN_RHF OK'
                  );
   END IF;

   IF NOT v_sysadmin_sup
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in purge SYSADMIN_SUP, Age, 1'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Concurrent Requests Schedule SYSADMIN_SUP OK'
                  );
   END IF;


   -- Purge Obsolete Generic File Manager Data (purge da FND_LOBS)
   -- Incluido esta verificacao por Dantas em 30/10/2007
   IF NOT v_fnd_lobs
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in Purge Obsolete Generic File Manager Data [-SEMANAL-]'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Purge Obsolete Generic File Manager Data [-SEMANAL-] : Schedule OK'
                  );
   END IF;

   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle,
                      'CVRD_CONCURRENT_REQUESTS_DW table - Monitoring populate program'
                     );
   UTL_FILE.put_line (file_handle,
                      '---------------------------------------------------------------'
                     );

   -- OHSCVRD Coleta CVRD_CONCURRENT_REQUESTS_DW
   IF NOT v_ohscvrddw
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in OHSCVRD Coleta CVRD_CONCURRENT_REQUESTS_DW'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'OHSCVRD Coleta CVRD_CONCURRENT_REQUESTS_DW scheduled program OK'
                  );
   END IF;

UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle,
                      'Monitoring Requests of BEACON Governance'
                     );
   UTL_FILE.put_line (file_handle,
                      '--------------------------------------------'
                     );

   -- CVRD - Beacon Business Critical
   IF NOT v_beacon_critical
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in CVRD - Beacon Business Critical'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'CVRD - Beacon Business Critical scheduled program OK'
                  );
   END IF;

   -- CVRD - Beacon High Volume
   IF NOT v_beacon_volume
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in CVRD - Beacon High Volume'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'CVRD - Beacon High Volume scheduled program OK'
                  );
   END IF;

   -- CVRD - Beacon Fast
   IF NOT v_beacon_fast
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in CVRD - Beacon Fast'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'CVRD - Beacon Fast scheduled program OK'
                  );
   END IF;

   -- CVRD - Beacon Standard
   IF NOT v_beacon_std
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in CVRD - Beacon Standard'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'CVRD - Beacon Standard scheduled program OK'
                  );
   END IF;

   -- CVRD - Beacon High Impact
   IF NOT v_beacon_impact
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in CVRD - Beacon High Impact'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'CVRD - Beacon High Impact scheduled program OK'
                  );
   END IF;

UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle,
                      'Periodic Alert Scheduler Monitoring Request'
                     );
   UTL_FILE.put_line (file_handle,
                      '-------------------------------------------'
                     );

   -- Periodic Alert Scheduler
   IF NOT v_beacon_critical
   THEN
      UTL_FILE.put_line (file_handle,
                         'Problems in Periodic Alert Scheduler'
                        );
   ELSE
      UTL_FILE.put_line
                  (file_handle,
                   'Periodic Alert Scheduler scheduled program OK'
                  );
   END IF;

-- Purge Obsolete Workflow Runtime Data
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'Purge Obsolete Workflow Runtime Data');
   UTL_FILE.put_line (file_handle, '------------------------------------');

   FOR sch_req IN scheduled_requests (38089)
   LOOP
      -- NULL, NULL, 0, PERM, 500, N
      IF     (sch_req.argument1 IS NULL)
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'PERM')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')
      THEN
         v_perm := TRUE;
      END IF;

      -- NULL, NULL, 0, TEMP, 500, N
      IF     (sch_req.argument1 IS NULL)
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         --AND (sch_req.argument7 = 'N')

      THEN
         v_temp := TRUE;
      END IF;

                        -- APEXP, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'APEXP')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_apex := TRUE;
      END IF;

      -- CREATEPO, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'CREATEPO')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_createpo := TRUE;
      END IF;

      -- CSMTYPE3, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'CSMTYPE3')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_csmtype3 := TRUE;
      END IF;

      -- OECOGS, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'OECOGS')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_oecogs := TRUE;
      END IF;

      -- CVRDPOAP, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'CVRDPOAP')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_cvrdpoap := TRUE;
      END IF;

      -- CVRDPOQD, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'CVRDPOQD')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_cvrdpoqd := TRUE;
      END IF;

          -- POAPPRV, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'POAPPRV')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_poapprv := TRUE;
      END IF;

      -- OEOH, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'OEOH')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_oeoh := TRUE;
      END IF;

      -- OEOL, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'OEOL')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_oeol := TRUE;
      END IF;

      -- POERROR, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'POERROR')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_poerror := TRUE;
      END IF;

          -- PABUDWF, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'PABUDWF')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_pabudwf := TRUE;
      END IF;

      -- PAWFBUI, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'PAWFBUI')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_pawfbui := TRUE;
      END IF;

      -- GLALLOC, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'GLALLOC')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_glalloc := TRUE;
      END IF;

      -- PONPBLSH, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'PONPBLSH')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_ponpblsh := TRUE;
      END IF;

      -- REQAPPRV, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'REQAPPRV')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_reqapprv := TRUE;
      END IF;

          -- PAPROWF, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'PAPROWF')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_paprowf := TRUE;
      END IF;

      -- WFERROR, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'WFERROR')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_wferror := TRUE;
      END IF;

      -- PONCOMPL, , 0, TEMP, N, 500, N
      IF     (sch_req.argument1 = 'PONCOMPL')
         AND (sch_req.argument2 IS NULL)
         AND (sch_req.argument3 = 0)
         AND (sch_req.argument4 = 'TEMP')
         AND (sch_req.argument5 = 'N')
         AND (sch_req.argument6 = '500')
         AND (sch_req.argument7 = 'N')

      THEN
         v_poncompl := TRUE;
      END IF;

   END LOOP;

   IF NOT v_perm
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data NULL, NULL, 0, PERM, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data NULL, NULL, 0, PERM, N    OK'
         );
   END IF;

   IF NOT v_apex
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data APEXP, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data APEXP, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_createpo
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data CREATEPO, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data CREATEPO, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_csmtype3
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data CSMTYPE3, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data CSMTYPE3, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_oecogs
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data OECOGS, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data OECOGS, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_cvrdpoap
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data CVRDPOAP, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data CVRDPOAP, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_cvrdpoqd
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data CVRDPOQD, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data CVRDPOQD, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_poapprv
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data POAPPRV, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data POAPPRV, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_oeoh
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data OEOH, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data OEOH, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_oeol
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data OEOL, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data OEOL, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_poerror
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data POERROR, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data POERROR, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_pabudwf
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data PABUDWF, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data PABUDWF, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_pawfbui
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data PAWFBUI, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data PAWFBUI, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_glalloc
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data GLALLOC, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data GLALLOC, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_ponpblsh
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data PONPBLSH, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data PONPBLSH, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_reqapprv
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data REQAPPRV, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data REQAPPRV, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_paprowf
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data PAPROWF, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data PAPROWF, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_wferror
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data WFERROR, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data WFERROR, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_poncompl
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data PONCOMPL, , 0, TEMP, N, 500, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data PONCOMPL, , 0, TEMP, N, 500, N    OK'
         );
   END IF;

   IF NOT v_temp
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems in Purge Obsolete Workflow Runtime Data NULL, NULL, 0, TEMP, N'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Purge Obsolete Workflow Runtime Data NULL, NULL, 0, TEMP, N, 500, N    OK'
         );
   END IF;


-- Gather Statistics(APPS and NON-APPS) and Histograms

   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'Gather Statistics(APPS and NON-APPS) and Histograms (Report Set)');
   UTL_FILE.put_line (file_handle, '----------------------------------------------------------------');

   FOR sch_req IN scheduled_requests (31659)
   LOOP
      -- NULL, NULL, NULL, Y, N, N
      IF     (sch_req.argument_text = '80005, 1764')

      THEN
         v_stats := TRUE;
      END IF;

   END LOOP;

   IF NOT v_stats
   THEN
      UTL_FILE.put_line
         (file_handle,
          'Problems with Gather Statistics(APPS and NON-APPS) and Histograms scheduled program'
         );
   ELSE
      UTL_FILE.put_line
         (file_handle,
          'Gather Statistics(APPS and NON-APPS) and Histograms (Report Set)  schedule OK'
         );
   END IF;

   -- incluido por Dantas em 03/06/2008 - Verificacao de profiles  ativas
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'List of all profiles enabled in PCVRDI');
   UTL_FILE.put_line (file_handle, '--------------------------------------');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'LEVEL      VALUE_LEVEL    PERFIL_NAME                                            VALUE    DATE of CHANGE    ');
   UTL_FILE.put_line (file_handle, '------     ------------   -------------------------------------------------      ------   ------------------');

   for v_profile in profile
   loop
       if profile%FOUND
       then

       UTL_FILE.put_line (file_handle,
           rpad(v_profile.nivel,12,'.')||rpad(v_profile.valor_nivel,19,'.')||rpad(v_profile.nome_perfil,54,'.')||rpad(v_profile.valor_Perfil,9,'.')||v_profile.DATA_ALTERACAO
                         );
       end if;
    end loop;  -- profile

   -- incluido por Dantas em 03/06/2008 - Verificacao de traces ativos
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'List of traces enabled in PCVRDI ');
   UTL_FILE.put_line (file_handle, '---------------------------------');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'CONCURRENT                                                          DATE of CHANGE   ');
   UTL_FILE.put_line (file_handle, '----------------------------------------------------------------    -----------------');

   for v_trace in trace
   loop
       if trace%FOUND
       then

       UTL_FILE.put_line (file_handle,
           rpad(v_trace.CONCURRENT_PROGRAM_NAME,70,'.')||v_trace.LAST_UPDATE_DATE
                         );
       end if;
    end loop;  -- trace

   -- incluido por Vitor Rosas em 06/10/2008 - Verificacao dos JOBS do StatsPack

   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'List of StatsPack Jobs in PCVRDI');
   UTL_FILE.put_line (file_handle, '----------------------------------------------------------------');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'JOB LOG_USER  WHAT                 INSTANCE');
   UTL_FILE.put_line (file_handle, '-------------------------------------------');

   for v_statspack in statspack
   loop
       if statspack%FOUND
       then
       UTL_FILE.put_line (file_handle,
           rpad(v_statspack.JOB,8,'.')||rpad(v_statspack.LOG_USER,14,'.')||rpad(v_statspack.WHAT,25,'.')||v_statspack.INSTANCE
                         );
       end if;
    end loop;  -- statspack


   -- incluido por Nathan Jacobson em 21/05/2009 - Verificacao das Sequences com mais de 80% de utilizacao

   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'List of sequences with more than 80% of utilization in PCVRDI   ');
   UTL_FILE.put_line (file_handle, '----------------------------------------------------------------');
   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, 'OWNER     SEQUENCE                 LAST#       MAX_VALUE   FALTAM      %     INC CYCLE');
   UTL_FILE.put_line (file_handle, '--------- ------------------------ ----------- ----------- ----------- ----- --- -----');

   for v_sequence in sequence
   loop
       if sequence%FOUND
       then
       UTL_FILE.put_line (file_handle,
           rpad(v_sequence.sequence_owner,10,'.')||rpad(v_sequence.sequence_name,25,'.')||rpad(v_sequence.last_number,12,'.')||rpad(v_sequence.max_value,12,'.')||rpad(v_sequence.faltam,12,'.')||rpad(v_sequence.porcentagem,6,'.')||rpad(v_sequence.increment_by,4,'.')||rpad(v_sequence.cycle_flag,2,'.')
                         );
       end if;
    end loop;  -- sequence

   UTL_FILE.put_line (file_handle, '');
   UTL_FILE.put_line (file_handle, '');

   UTL_FILE.fclose (file_handle);
END;
