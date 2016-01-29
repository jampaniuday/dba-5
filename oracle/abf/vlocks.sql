set pages 0;
set lines 350;
col sid format 9999999;
alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';
Prompt
Prompt *********************************** Locks de Transacao ***********************************
select sid "Locks gerados"
 from (
  select distinct
            decode (request,0,'===> Sessao '||a.sid||' da inst '||a.inst_id||' ('||module||' '||
      decode (action,'Concurrent Request',' - Concurrent '||(select distinct request_id from apps.fnd_concurrent_requests fcr,
                                                                                        gv$session gs
                                                                  where-- fcr.os_process_id=gs.process
                                                                     fcr.oracle_session_id=gs.audsid
                                                                  and   gs.sid=c.sid
                                                                  and   gs.inst_id=c.inst_id
                                                                  and   fcr.phase_code='R'
                                                                  and   fcr.status_code='R'
                                                                  -- and   rownum=1
                                                                  ),
                        null)||') está bloqueando ',
      lpad(' ',9)||'Sessao '||a.sid||' da inst '||a.inst_id||' executando: '||
      decode (action,'Concurrent Request','Concurrent '||(select distinct request_id||' '||user_concurrent_program_name
                                                                              ||' wainting: '||sw.seconds_in_wait||' segs.'
                                                                                        from apps.fnd_concurrent_requests fcr,
                                                                                             apps.FND_CONCURRENT_PROGRAMS_TL fcp,
                                                                                             gv$session gs
                                                                 where-- fcr.os_process_id=gs.process
                                                                     fcr.oracle_session_id=gs.audsid
                                                                  and   fcp.concurrent_program_id=fcr.concurrent_program_id
                                                                  and   gs.sid=c.sid
                                                                  and   gs.inst_id=c.inst_id
                                                                  and   fcr.phase_code='R'
                                                                  and   fcr.status_code='R'
                                                                  and   fcp.language='US'
                                                                  -- and   rownum=1
                                                                  )||' LOCK-TYPE=>('||a.type||')',
            module||' waiting: '||sw.seconds_in_wait||' segs. '||'LOCK-TYPE=>('||a.type||')')) as SID,
            LMODE,
            REQUEST,
            trunc(id1/power(2,16)) as RBS,
            BITAND(id1,TO_NUMBER('FFFF','XXXX'))+0 as SLOT,
            decode(id2,0,id1,id2) SEQ
            -- ob.name
            -- ID1 Object
   from
     gv$lock a,
     gv$session c,
     gv$session_wait sw,
     -- sys.obj$ ob,
     (select  sid,inst_id,
              trunc(p2/power(2,16)) as RBS,
              BITAND(p2,TO_NUMBER('FFFF','XXXX'))+0 as SLOT,
              P3 as SEQ
      from gv$session_wait
        where event like 'enq%'
         and seconds_in_wait > 3) B
     where trunc(a.id1/power(2,16))=b.RBS
     and   BITAND(a.id1,TO_NUMBER('FFFF','XXXX'))+0=b.SLOT
     and   a.id2=b.SEQ
     and   c.sid=a.sid
     and   c.inst_id=a.inst_id
     and   c.sid=sw.sid
     and   c.inst_id=sw.inst_id
    -- and   ob.obj#=a.id1
     order by trunc(id1/power(2,16)),
              BITAND(id1,TO_NUMBER('FFFF','XXXX'))+0,
            --  decode(id2,0,id1,id2),
              lmode desc ,
              request
              );

prompt
prompt 
@@vlibrarycachelock.sql
