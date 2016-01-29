set pagesize 50
col queue_name  format a14
col node        format a12
col phase       format a15
col status      format a15
col run         format 999
col act         format 999
col tgt         format 999
col pend        format 99999
col cs          format 99
col slp         format 999
col stby        format 9999
col capacity    format 9999
col running     format a10

select fcwr.CONCURRENT_QUEUE_NAME  queue_name,
       fcq.node_name node,
       fcwr.cache_size * fcwr.RUNNING_PROCESSES * 60 / fcq.sleep_seconds capacity,
       fcq.sleep_seconds SLP,
       fcwr.cache_size CS,
       fcwr.RUNNING_PROCESSES TGT,
       nvl(fcrun.run,0)   run  ,
       nvl(fcpend.PEND,0) pend ,
       nvl(fcstby.stby,0) stby ,
       to_char( sysdate, 'HH:MI:SS' ) time
  from fnd_concurrent_queues fcq,
       fnd_concurrent_worker_requests fcwr,
       (select  fcwr1.QUEUE_APPLICATION_ID,
                fcwr1.CONCURRENT_QUEUE_ID,count(*) run
                from fnd_concurrent_worker_requests fcwr1
                where fcwr1.phase_code='R'
                and fcwr1.requested_start_date  < sysdate
                and fcwr1.hold_flag='N'
                and fcwr1.status_code='R'
                group by fcwr1.QUEUE_APPLICATION_ID,
                        fcwr1.CONCURRENT_QUEUE_ID) fcrun,
       (select  fcwr1.QUEUE_APPLICATION_ID,
                fcwr1.CONCURRENT_QUEUE_ID,count(*) stby
                from fnd_concurrent_worker_requests fcwr1
                where fcwr1.phase_code='P'
                and fcwr1.requested_start_date  < sysdate
                and fcwr1.hold_flag='N'
                and fcwr1.status_code='Q'
                group by fcwr1.QUEUE_APPLICATION_ID,
                        fcwr1.CONCURRENT_QUEUE_ID) fcstby,
       (select  fcwr1.QUEUE_APPLICATION_ID,
                fcwr1.CONCURRENT_QUEUE_ID,count(*) pend
                from fnd_concurrent_worker_requests fcwr1
                where fcwr1.phase_code='P'
                and fcwr1.requested_start_date  < sysdate
                and fcwr1.hold_flag='N'
                and fcwr1.status_code != 'Q'
                group by fcwr1.QUEUE_APPLICATION_ID,
                        fcwr1.CONCURRENT_QUEUE_ID) fcpend
  where fcwr.requested_start_date  < sysdate
        and fcwr.phase_code != 'C'
        and fcwr.hold_flag = 'N'
        and fcwr.QUEUE_APPLICATION_ID =fcq.APPLICATION_ID
        and fcwr.CONCURRENT_QUEUE_ID  =fcq.CONCURRENT_QUEUE_ID
        and fcwr.QUEUE_APPLICATION_ID =fcrun.QUEUE_APPLICATION_ID(+)
        and fcwr.CONCURRENT_QUEUE_ID  =fcrun.CONCURRENT_QUEUE_ID(+)
        and fcwr.QUEUE_APPLICATION_ID =fcpend.QUEUE_APPLICATION_ID(+)
        and fcwr.CONCURRENT_QUEUE_ID  =fcpend.CONCURRENT_QUEUE_ID(+)
        and fcwr.QUEUE_APPLICATION_ID =fcstby.QUEUE_APPLICATION_ID(+)
        and fcwr.CONCURRENT_QUEUE_ID  =fcstby.CONCURRENT_QUEUE_ID(+)
        and fcwr.CONCURRENT_QUEUE_NAME not in ('XBOL_HIGHWKLD', 'ZIPQM', 'CEMLIQM')
group by fcwr.CONCURRENT_QUEUE_NAME
        , fcq.sleep_seconds
        , fcwr.RUNNING_PROCESSES
        , fcwr.cache_size
        , fcq.node_name
        , nvl(fcrun.run,0) ,
        nvl(fcpend.PEND,0)  ,
        nvl(fcstby.stby,0)
order by fcwr.CONCURRENT_QUEUE_NAME, capacity
/  
