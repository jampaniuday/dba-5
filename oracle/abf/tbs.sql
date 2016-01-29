exec dbms_application_info.set_module('TBS.SQL','TBS');
COL tbs FORMAT a25
COL total(mb) FORMAT 999,999,990.00
COL livre(mb) FORMAT 999,999,990.00
COL livre(%) FORMAT 990.00
select instance_name,host_name,to_char(sysdate,'dd/mm/yy hh24:mi') from v$instance;
SELECT DISTINCT d.tablespace_name "NOME DA TABLESPACE",t.total "TOTAL(MB)", NVL(f.livre,0) "LIVRE(MB)", (NVL(f.livre,0)*100/t.total) "LIVRE(%)"
FROM dba_data_files d,
     (SELECT tablespace_name ,sum(bytes)/1024/1024 total FROM dba_data_files GROUP BY tablespace_name) t, 
     (SELECT tablespace_name ,sum(bytes)/1024/1024 livre FROM dba_free_space GROUP BY  tablespace_name) f
WHERE d.tablespace_name =t.tablespace_name
AND   d.tablespace_name = f.tablespace_name(+)
ORDER BY 4 DESC;
select instance_name,host_name,to_char(sysdate,'dd/mm/yy hh24:mi') from v$instance;
