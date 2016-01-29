REM $Header: ccminfo.sql 1.0 2010/01/27 17:07:007 dchavez $
REM FILENAME
REM   ccminfo.sql
REM DESCRIPTION
REM   Displays info relevant to Concurrent Managers
REM
REM   Execution:
REM   On the concurrent manager tier navigate to $APPL_TOP and run the 
REM   Oracle Applications Environment script (usually <sid name>_<node name>.env)
REM
REM ******************************************************************************
REM                              NOTE
REM   This is an Internal Information Gathering note and is not supported 
REM            by Oracle Customer Support for Customer use.
REM ******************************************************************************
REM              Created by Dale Chavez
REM Check Note 847839.1 for most current update
REM +======================================================================+
REM
spool ccminfo.lst

Set Pages 1000
Set head on

set head off

Select
'          ************************************************************* 
                          Applications Version
           *************************************************************'
  from Dual;

set head on
select release_name from fnd_product_groups;

set head off

Select
'          ************************************************************* 
                          Database Version
           *************************************************************'
  from Dual;

set head on
select * from v$version;

Column BUG_NUMBER   Format A20
Column CREATION_DATE  Format A20

set head off

Select
'          ************************************************************* 
                          Release 12i RUP Patches
           *************************************************************'
  from Dual;

set head on

select  b.patch, b.description, 
decode(count(a.bug_number),0,'NOT APPLIED','APPLIED')Status, 
a.creation_date applied
from ad_bugs a,
 (      select '5082400' patch, 'RUP1' description from dual
  union select '5484000' patch, 'RUP2' description from dual
  union select '6141000' patch, 'RUP3' description from dual
  union select '6435000' patch, 'RUP4' description from dual
  union select '7282993' patch, 'RUP5' description from dual
  union select '6728000' patch, 'RUP6' description from dual
  union select '6272680' patch, 'R12.ATG_PF.A.DELTA.4' description from dual
  union select '7237006' patch, 'R12.ATG_PF.A.DELTA.6' description from dual 
) b
where a.bug_number (+) = b.patch
group by b.patch, b.description, a.creation_date
order by 1;

set head off

Select
'          ************************************************************* 
                          Release 11i RUP Patches
           *************************************************************'
  from Dual;

set head on
select  b.patch, b.description, 
decode(count(a.bug_number),0,'NOT APPLIED','APPLIED')Status, 
a.creation_date applied
from ad_bugs a,
 (      select '3480000' patch, '11.5.10.2 Maintainance' description from dual
  union select '4334965' patch, 'RUP3' description from dual
  union select '4676589' patch, 'RUP4' description from dual
  union select '5473858' patch, 'RUP5' description from dual
  union select '5903765' patch, 'RUP6' description from dual
  union select '6241631' patch, 'RUP7' description from dual
) b
where a.bug_number (+) = b.patch
group by b.patch, b.description, a.creation_date
order by 1;

Column Q_Name  Format A20
Column Manager  Format A45
Column node  Format A20
Column Running  Format 990
Column Max   Format 999
Column Buf      Format 999
Column D Format A1

set head off
Select
'          ************************************************************* 
           Managers with their defined capacities for the current shift
           *************************************************************'
  from Dual;

set head on
select CONCURRENT_QUEUE_NAME Q_Name, Target_Node Node,Running_Processes Running,
       Max_Processes Max, Cache_Size Buf, Diagnostic_Level D,User_Concurrent_Queue_Name Manager
from fnd_concurrent_queues_vl
order by Running_Processes DESC
;

Column NAME   Format A40
Column LANGUAGE   Format A5
Column VALUE   Format A5
Column LEVEL_SET Format A14


set head off
Select
'          ************************************************************* 
                   Concurrent Manager Profile Settings
           *************************************************************'
  from Dual;
  
set head on
select n.user_profile_option_name NAME, v.profile_option_value VALUE,
         decode(v.level_id, 
		10001, 'Site', 
		10002, 'Application',
		10003, 'Responsibility',
		10004, 'User',
		10005, 'Server',
		10007, 'SERVRESP',
	'UnDef') LEVEL_SET
  from fnd_profile_options p, 
     fnd_profile_option_values v, 
     fnd_profile_options_tl n,
     fnd_user usr,
     fnd_application app,
     fnd_responsibility rsp,
     fnd_nodes svr,
     hr_operating_units org
  where p.profile_option_id = v.profile_option_id (+)
  and p.profile_option_name = n.profile_option_name
  and upper(n.user_profile_option_name) like upper('Concurrent%')
  and    usr.user_id (+) = v.level_value
  and    rsp.application_id (+) = v.level_value_application_id
  and    rsp.responsibility_id (+) = v.level_value
  and    app.application_id (+) = v.level_value
  and    svr.node_id (+) = v.level_value
  and    org.organization_id (+) = v.level_value
  and    v.level_id in (10001, 10005, 10007)
  and n.language='US'
  order by n.user_profile_option_name;
  
  Column NODE_NAME   Format A30
  Column NODE_MODE   Format A1
  Column PLATFORM_CODE Format A5
  
set head off
Select
'          ************************************************************* 
                                Node Names and Functions
           *************************************************************'
  from Dual;
  
set head on
   select
     NODE_NAME,
     decode(STATUS,'Y','ACTIVE','INACTIVE') Status,
     decode(SUPPORT_CP,'Y', 'ConcMgr','No') ConcMgr,
     decode(SUPPORT_FORMS,'Y','Forms', 'No') Forms,
     decode(SUPPORT_WEB,'Y','Web', 'No') WebServer,
     decode(SUPPORT_ADMIN, 'Y','Admin', 'No') Admin,
     decode(SUPPORT_DB, 'Y','Rdbms', 'No') Database
   from fnd_nodes
   where node_name != 'AUTHENTICATION';
   
set head off

set head on
Column fnd_concurrent_queues.CONCURRENT_QUEUE_NAME   Format A15
Column fnd_concurrent_queues_tl.USER_CONCURRENT_QUEUE_NAME   Format A25
Column fnd_concurrent_queues.NODE_NAME   Format A15
Column fnd_concurrent_queues.NODE_NAME2   Format A15
set head off

Select
'          ************************************************************* 
                 Primary and Secondary Node Names for Managers
           *************************************************************'
from Dual;


set head on
select fnd_concurrent_queues.node_name Primary, fnd_concurrent_queues.node_name2 Secondary,
fnd_concurrent_queues.concurrent_queue_name Mgr, fnd_concurrent_queues_tl.user_concurrent_queue_name Manager
from fnd_concurrent_queues, fnd_concurrent_queues_tl 
where fnd_concurrent_queues_tl.concurrent_queue_id=fnd_concurrent_queues.concurrent_queue_id and fnd_concurrent_queues.enabled_flag = 'Y' and language='US'
order by fnd_concurrent_queues_tl.user_concurrent_queue_name;
  
set head off
Select
'          ************************************************************* 
                Number of rows in FND_CONCURRENT_REQUEST table
           *************************************************************'
  from Dual;
  
set head on

select  count(*) from fnd_concurrent_requests;

set head off
Select
'          ************************************************************* 
                 Number of rows in FND_CONCURRENT_PROCESSES table
           *************************************************************'
  from Dual;
  
set head on

select  count(*) from fnd_concurrent_processes;

set head off

set head on
Column fnd_concurrent_queues.CONCURRENT_QUEUE_NAME   Format A15
Column fnd_concurrent_queues.running_processes   Format A15
Column fnd_concurrent_queues.max_processes   Format A15
set head off

Select
'          ************************************************************* 
                 Running and Max Processes for Managers
           *************************************************************'
from Dual;


set head on
select concurrent_queue_name, running_processes, max_processes from fnd_concurrent_queues
order by running_processes desc;
set head off
Select
'          ************************************************************* 
                 FND_CONCURRENT_PROCESSES.PROCESS_STATUS_CODE Counts
			A	Active	
			C	Connecting	Connecting to Database
			D	Deactiviating	
			G	Awaiting Discovery	Process has spawned externally and is not yet controlled
			K	Terminated	
			M	Migrating	Process is shutting down to migrate to the primary node
			P	Suspended	
			R	Running	
			S	Deactivated	
			T	Terminating	
			U	Unreachable	Process is not reachable over the network
			Z	Initializing	
           *************************************************************'
  from Dual;
  
set head on

select process_status_code, count(*) as "count" from fnd_concurrent_processes
group by process_status_code;


Column OWNER   Format A5
Column OBJECT_TYPE FORMAT A15
Column STATUS FORMAT A8
Column OBJECT_NAME FORMAT A35

set head off
Select
'          ************************************************************* 
                             "FND_%" Invalid Objects
           *************************************************************'
  from Dual;
  
set head on

 select OWNER, OBJECT_TYPE TYPE, STATUS,OBJECT_NAME
 from all_objects
 where object_name like 'FND_%'
 and status='INVALID';
 
 set head off
Select
'          ************************************************************* 
                 Number of Pending Requests
           *************************************************************'
  from Dual;
  
set head on
select count(*) from fnd_concurrent_requests
where status_code='P';

Column concurrent_queue_name   Format A10
Column language   Format A7
Column type_application_id   Format A4
Column type_code   Format A4
Column USER_CONCURRENT_PROGRAM_NAME   Format A40
Column include_flag   Format A4

set head off
Select
'          ************************************************************* 
                 Included or Exclude requests in Managers
           *************************************************************'
  from Dual;
  
set head on

select cql.concurrent_queue_name queue_name, qc.include_flag flag ,cql.language mgr_lang ,
qc.type_application_id App, qc.type_code type, cp.USER_CONCURRENT_PROGRAM_NAME NAME, cp.LANGUAGE PG_LANG
from FND_CONCURRENT_QUEUE_CONTENT QC, fnd_concurrent_programs_tl cp, FND_CONCURRENT_QUEUES_TL cql
where qc.concurrent_queue_id = cql.concurrent_queue_id
and qc.TYPE_ID=cp.CONCURRENT_PROGRAM_ID
and cql.concurrent_queue_name='STANDARD'
order by cql.language, cql.concurrent_queue_name;


set head off
Select
'          ************************************************************* 
                               Log Files
           *************************************************************'
  from Dual;
  
set head on
SELECT  fcq.concurrent_queue_name,'LOG_NAME=' || fcp.logfile_name log
FROM    fnd_concurrent_processes fcp, fnd_concurrent_queues fcq
WHERE   fcp.concurrent_queue_id = fcq.concurrent_queue_id
AND     fcp.queue_application_id = fcq.application_id
AND     (fcq.concurrent_queue_name = 'FNDICM' or fcq.concurrent_queue_name LIKE 'FNDSM%'
or fcq.concurrent_queue_name = 'STANDARD')
AND     fcp.process_status_code = 'A';


Column NAME  Format A25
Column TEXT  Format A40

set head off
Select
'          ************************************************************* 
                                FND API
           *************************************************************'
  from Dual;

select name, text from all_source
where text like '%Header%' and
name like 'FND%'
order by name;

set head off
Select
'          ************************************************************* 
                 Current Environment
           *************************************************************'
  from Dual;
  
set head on

HOST env


set head off
Select
'          ************************************************************* 
                 Current Node
           *************************************************************'
  from Dual;
  
set head on

HOST uname -a

set head off
Select
'          ************************************************************* 
                 Database Paraeters
           *************************************************************'
  from Dual;
  
set head on

SELECT name,value  FROM v$parameter order by name;


spool off

exit;


