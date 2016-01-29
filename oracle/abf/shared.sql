set echo off 
spool pool_est 
/* 
********************************************************* 
*                                                       * 
* TITLE        : Shared Pool Estimation                 * 
* CATEGORY     : Information, Utility                   * 
* SUBJECT AREA : Shared Pool                            * 
* DESCRIPTION  : Estimates shared pool utilization      * 
*  based on current database usage. This should be      * 
*  run during peak operation, after all stored          * 
*  objects i.e. packages, views have been loaded.       * 
* NOTE:  Modified to work with later versions 4/11/06   * 
*                                                       * 
********************************************************/ 
Rem If running MTS uncomment the mts calculation and output 
Rem commands. 
 
set serveroutput on; 
 
declare 
        object_mem number; 
        shared_sql number; 
        cursor_ovh number;
        cursor_mem number; 
        mts_mem number; 
        used_pool_size number; 
        free_mem number; 
        pool_size varchar2(512); -- same as V$PARAMETER.VALUE 
begin 
 
-- Stored objects (packages, views) 
select sum(sharable_mem) into object_mem from v$db_object_cache
where type = 'CURSOR';
 
-- Shared SQL -- need to have additional memory if dynamic SQL used 
select sum(sharable_mem) into shared_sql from v$sqlarea; 
 
-- User Cursor Usage -- run this during peak usage. 
--  assumes 250 bytes per open cursor, for each concurrent user. 
select sum(250*users_opening) into cursor_ovh from v$sqlarea; 

select sum(sharable_mem) into cursor_mem from v$db_object_cache
WHERE type='CURSOR';
 
-- For a test system -- get usage for one user, multiply by # users 
-- select (250 * value) bytes_per_user 
-- from v$sesstat s, v$statname n 
-- where s.statistic# = n.statistic# 
-- and n.name = 'opened cursors current' 
-- and s.sid = 25;  -- where 25 is the sid of the process 
 
-- MTS memory needed to hold session information for shared server users 
-- This query computes a total for all currently logged on users (run 
--  during peak period). Alternatively calculate for a single user and 
--  multiply by # users. 
select sum(value) into mts_mem from v$sesstat s, v$statname n 
       where s.statistic#=n.statistic# 
       and n.name='session uga memory max'; 
 
-- Free (unused) memory in the SGA: gives an indication of how much memory 
-- is being wasted out of the total allocated. 
-- For pre-9i issue
-- select bytes into free_mem from v$sgastat 
--        where name = 'free memory';

-- with 9i and newer releases issue
select bytes into free_mem from v$sgastat 
        where name = 'free memory'
        and pool = 'shared pool';

 
-- For non-MTS add up object, shared sql, cursors and 20% overhead.
-- Not including cursor_mem because this is included in shared_sql 
used_pool_size := round(1.2*(object_mem+shared_sql)); 
 
-- For MTS mts contribution needs to be included (comment out previous line) 
-- used_pool_size := round(1.2*(object_mem+shared_sql+mts_mem)); 

-- Pre-9i or if using manual SGA management, issue 
-- select value into pool_size from v$parameter where name='shared_pool_size'; 

-- With 9i and 10g and and automatic SGA management, issue
select  c.ksppstvl into pool_size from x$ksppi a, x$ksppcv b, x$ksppsv c
     where a.indx = b.indx and a.indx = c.indx
       and a.ksppinm = '__shared_pool_size';
 
-- Display results 
dbms_output.put_line ('Obj mem:  '||to_char (object_mem) || ' bytes ' || '('
|| to_char(round(object_mem/1024/1024,2)) || 'MB)'); 
dbms_output.put_line ('Shared sql:  '||to_char (shared_sql) || ' bytes ' || '('
|| to_char(round(shared_sql/1024/1024,2)) || 'MB)'); 
dbms_output.put_line ('Cursors:  '||to_char (cursor_mem+cursor_ovh) || ' bytes '
|| '('|| to_char(round((cursor_mem+cursor_ovh)/1024/1024,2)) || 'MB)'); 
-- dbms_output.put_line ('MTS session: '||to_char (mts_mem) || ' bytes'); 
dbms_output.put_line ('Free memory: '||to_char (free_mem) || ' bytes ' || '(' 
|| to_char(round(free_mem/1024/1024,2)) || 'MB)'); 
dbms_output.put_line ('Shared pool utilization (total):  '|| 
to_char(used_pool_size) || ' bytes ' || '(' || 
to_char(round(used_pool_size/1024/1024,2)) || 'MB)'); 
dbms_output.put_line ('Shared pool allocation (actual):  '|| pool_size ||
'bytes ' || '(' || to_char(round(pool_size/1024/1024,2)) || 'MB)'); 
dbms_output.put_line ('Percentage Utilized:  '||to_char 
(round(((pool_size-free_mem) / pool_size)*100)) || '%'); 
end; 
/ 
 
spool off
