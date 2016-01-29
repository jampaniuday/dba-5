col sql_text for a80;
col Gets_p_exec for 999,999,999,999;

spool bad_sql.log
select * 
  from (select 	hash_value, 
		substr(sql_text,1,80) sql_text, 
		executions, 
		buffer_gets, 
		buffer_gets/decode(executions,0,1,executions) Gets_p_exec,
		username,
		FIRST_LOAD_TIME,
                rows_processed/decode(executions,0,1,executions) Rows_per_exec
	   from v$sqlarea a , dba_users b
          where a.PARSING_USER_ID = b.user_id        
          order by 5 desc)
 where rownum <= &top_n
/


spool off;
