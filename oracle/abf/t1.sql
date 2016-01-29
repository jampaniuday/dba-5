set lines 200;
col instance format a8;
col username format a12;
col server   format a14;
col sid      format 99999;
col serial#  format 99999;
col "Pct %" for a5;
break on instance;
set feed off;
select     tep.instance_name                   as Instance
          ,tep.alocado                         as "Alocado TEMP(Mb)"
          ,tep.usado                           as "Usado TEMP(Mb)"
          ,to_char(tep.pct,'999.99')||'%'     as "Pct Usado"
from
            (select   texp.inst_id
                   ,ins.instance_name
                   ,texp.tablespace_name
                   ,trunc(sum(BYTES_USED/1024/1024)) as usado
                   ,trunc(sum(BYTES_CACHED/1024/1024)) as alocado
                   ,trunc(100 - ((  trunc(sum(BYTES_CACHED/1024/1024)) - trunc(sum(BYTES_USED/1024/1024))
                          )
                            /trunc(sum(BYTES_CACHED/1024/1024))
                                   ) *100,1
                     ) as pct
             from gv$temp_extent_pool texp,
                  gv$instance ins
               where tablespace_name='TEMP'
                 and texp.inst_id=ins.inst_id
              group by texp.inst_id
                      ,ins.instance_name
                      ,texp.tablespace_name
                       order by tablespace_name desc,
                                inst_id) tep
order by tep.pct desc;
prompt;
prompt  ********* Dados das sessoes que mais consomem TEMP ;

select     instance_name||':'                                                                             as instance
           ,username                                                                                 as username
           ,sid
           ,serial#
           ,machine                                                                                  as  Server
           ,trunc(tmp.sess_used,2)                                                                   as "Used(Mb)"
           ,lpad(trunc( 100 - (((tep.alocado - tmp.sess_used)/tep.alocado)*100),1),4.1,' ')||'%' as "Pct %"
from
        (select   texp.inst_id
                  ,ins.instance_name
                  ,texp.tablespace_name
                  ,trunc(sum(BYTES_USED/1024/1024)) as usado
                  ,trunc(sum(BYTES_CACHED/1024/1024)) as alocado
                  ,trunc(100 - ((  trunc(sum(BYTES_CACHED/1024/1024)) - trunc(sum(BYTES_USED/1024/1024))
                         )
                           /trunc(sum(BYTES_CACHED/1024/1024))
                                  ) *100,1
                    ) as pct
            from gv$temp_extent_pool texp,
                 gv$instance ins
              where tablespace_name='TEMP'
                and texp.inst_id=ins.inst_id
             group by texp.inst_id
                     ,ins.instance_name
                     ,texp.tablespace_name ) tep,
        (select sum(sess_used) as sess_used,
                inst_id,
                tablespace,
                session_Addr
                    from (select sou.session_addr
                                 ,sou.inst_id
                                 ,tablespace
                                 ,(blocks * (select block_size from dba_tablespaces where tablespace_name='TEMP'))/1024/1024 as sess_used
                                 ,row_number() over (partition by inst_id,tablespace order by blocks desc) as rn
                             from gv$sort_usage sou
                              where tablespace='TEMP'
                        )
            where rn<=2
            group by inst_id,
                     tablespace,
                     session_Addr
         ) tmp,
           gv$session  sess
where sess.saddr      = tmp.session_Addr
  and   sess.inst_id  = tmp.inst_id
  and   tep.inst_id   = sess.inst_id
order by tmp.inst_id,
         tmp.sess_used desc;
