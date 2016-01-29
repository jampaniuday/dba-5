exec dbms_application_info.set_module(' GATHER_STATS_APPS ',' LARGE_TABLES ');
select to_Char(sysdate,'DD/MM/YYYY HH24:MI:SS') from dual;
exec fnd_stats.GATHER_TABLE_STATS(OWNNAME=>'APPS',TABNAME=>'B2W_APLICACAO_RECEBIMENTOS',PERCENT=>20,degree=>5);
exec fnd_stats.GATHER_TABLE_STATS(OWNNAME=>'APPS',TABNAME=>'B2W_LOG_EXECUCAO',PERCENT=>20,degree=>5);
select to_Char(sysdate,'DD/MM/YYYY HH24:MI:SS') from dual;
