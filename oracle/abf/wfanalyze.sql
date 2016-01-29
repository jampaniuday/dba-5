REM HEADER
REM   $Header: workflow_analyzer.sql v4.06 BBURBAGE $
REM   
REM MODIFICATION LOG:
REM	
REM	BBURBAGE 
REM	
REM	Consolidated script to diagnose the current status and footprint of workflow on an environment.
REM     This script can be run on 11.5.x or higher.
REM
REM   workflow_analyzer.sql
REM     
REM   	This script was created to collect all the required information to understand what impact workflow
REM   	embedded in Oracle Applications has on an EBS instance.
REM
REM
REM   How to run it?
REM   
REM   	sqlplus apps/<password>	@workflow_analyzer.sql
REM
REM   
REM   Output file 
REM   
REM	wf_analyzer_<SID>_<HOST_NAME>.html
REM
REM
REM     Created: May 16th, 2011
REM     Last Updated: July 10th, 2012
REM
REM
REM  CHANGE HISTORY:
REM   1.00  16-MAY-2011 bburbage Creation from design
REM   1.01  04-JUN-2011 bburbage Adjustments to include more queries
REM   3.00  11-JUN-2011 bburbage Change output to html
REM   3.01  16-JUN-2011 bburbage Adding patches, adding more recommendations
REM   3.02  08-JUL-2011 bburbage Adding WF_ADMIN_ROLE search and enhancements
REM   3.03  21-JUL-2011 bburbage Added Profiles check, and database parameter settings
REM                              aq_tm_processes and job_queue_processes
REM   3.06  07-JUL-2011 bburbage Enhanced Java Mailer to loop thru custom mailer if exist
REM                              Modified the Concurrent Requests test to include scheduled requests
REM				 as well as requests that have run.
REM   4.00  19-SEP-2011 bburbage Prepare script for initial external release
REM   4.01  06-DEC-2011 bburbage Adding Feedback Section
REM				 Adding Change History
REM   4.02  07-DEC-2011 bburbage Corrected some miscellaneous verbage and color coding
REM   4.03  28-DEC-2011 bburbage Created table for TOC.
REM				 Added SQL Script buttons to display queries
REM                              Added exception logic for no rows found in large historical activities
REM   4.04  12-JAN-2012 bburbage Added logic to stablize Footprint graph code
REM				 Added SYSADMIN User Setup Analysis	
REM   4.05  28-FEB-2012 bburbage Miscellaneous syntax corrections
REM   				 Added Note 1425053.1 on How To schedule WF_Analyzer as Concurrent Request.
REM                              to the script output and to the Note 1369938.1
REM                              Added R12.2 to WF Patch Checklist
REM				 Modified the WF Footprint graph and Runtime Tables
REM				 Added graph for WF Error Notifications
REM				 Removed the spool naming format to allow for Concurrent Request Functionality
REM				 Added spool naming instructions in Note 1369938.1 for running script manually
REM   4.06  21-APR-2012 bburbage Miscellaneous syntax corrections
REM         18-JUN-2012 bburbage Fine tuned the compile date and time to run calculations
REM

set arraysize 1
set heading off
set feedback off  
set echo off
set verify off
SET CONCAT ON
SET CONCAT .
SET ESCAPE OFF
SET ESCAPE '\'

set lines 120
set pages 9999
set serveroutput on size 100000

variable st_time 	varchar2(100);
variable et_time 	varchar2(100);

begin
select to_char(sysdate,'hh24:mi:ss') into :st_time from dual;
end;
/

REM COLUMN host_name NOPRINT NEW_VALUE hostname
REM SELECT host_name from v$instance;
REM COLUMN instance_name NOPRINT NEW_VALUE instancename
REM SELECT instance_name from v$instance;
REM COLUMN sysdate NOPRINT NEW_VALUE when
REM select to_char(sysdate, 'YYYY-Mon-DD') "sysdate" from dual;
REM SPOOL wf_analyzer_&&hostname._&&instancename._&&when..html

VARIABLE TEST		VARCHAR2(240);
VARIABLE WFCMTPHY	NUMBER;
VARIABLE WFDIGPHY	NUMBER;
VARIABLE WFITMPHY	NUMBER;
VARIABLE WIASPHY	NUMBER;
VARIABLE WIASHPHY	NUMBER;
VARIABLE WFATTRPHY	NUMBER;
VARIABLE WFNTFPHY	NUMBER;
VARIABLE WFCMTPHY2	NUMBER;
VARIABLE WFDIGPHY2	NUMBER;
VARIABLE WFITMPHY2	NUMBER;
VARIABLE WIASPHY2	NUMBER;
VARIABLE WIASHPHY2	NUMBER;
VARIABLE WFATTRPHY2	NUMBER;
VARIABLE WFNTFPHY2	NUMBER;
VARIABLE ERRORNTFCNT    NUMBER;
VARIABLE NTFERR_CNT	NUMBER;
VARIABLE ECXERR_CNT	NUMBER;
VARIABLE OMERR_CNT	NUMBER;
VARIABLE POERR_CNT	NUMBER;
VARIABLE WFERR_CNT	NUMBER;
VARIABLE ECXRATE	NUMBER;
VARIABLE OMRATE		NUMBER;
VARIABLE PORATE		NUMBER;
VARIABLE WFRATE		NUMBER;
VARIABLE ADMIN_EMAIL    VARCHAR2(40);
VARIABLE NTF_PREF       VARCHAR2(10);
VARIABLE GSM		VARCHAR2(1);
VARIABLE WF_ADMIN_ROLE	VARCHAR2(320);
VARIABLE ITEM_CNT    	NUMBER;
VARIABLE ITEM_OPEN   	NUMBER;
VARIABLE OLDEST_ITEM 	NUMBER;
VARIABLE SID         	VARCHAR2(20);
VARIABLE HOST        	VARCHAR2(30);
VARIABLE APPS_REL    	VARCHAR2(10);
VARIABLE WF_ADMIN_DISPLAY VARCHAR2(360);
VARIABLE EMAIL       	VARCHAR2(320);
VARIABLE EMAIL_OVERRIDE	VARCHAR2(320);
VARIABLE NTF_PREF    	VARCHAR2(8);
VARIABLE MAILER_ENABLED	VARCHAR2(10);
VARIABLE MAILER_STATUS	VARCHAR2(30);
VARIABLE CORRID    	VARCHAR2(240);
VARIABLE COMPONENT_NAME VARCHAR2(80);
VARIABLE CONTAINER_NAME VARCHAR2(240);
VARIABLE STARTUP_MODE   VARCHAR2(30);
VARIABLE TOTAL_ERROR  	NUMBER;
VARIABLE OPEN_ERROR   	NUMBER;
VARIABLE CLOSED_ERROR 	NUMBER;
VARIABLE LOGICAL_TOTALS VARCHAR2(22);
VARIABLE PHYSICAL_TOTALS VARCHAR2(22);
VARIABLE DIFF_TOTALS    VARCHAR2(22);
VARIABLE NINETY_TOTALS	VARCHAR2(22);
VARIABLE RATE		NUMBER;
VARIABLE NINETY_CNT	NUMBER;
VARIABLE HIST_CNT	NUMBER;
VARIABLE HIST_DAYS	NUMBER;
VARIABLE HIST_DAILY	NUMBER;
VARIABLE MAILER_CNT	NUMBER;
VARIABLE HIST_END	VARCHAR2(22);
VARIABLE HIST_BEGIN	VARCHAR2(22);
VARIABLE SYSDATE	VARCHAR2(22);
VARIABLE HIST_RECENT	VARCHAR2(22);
VARIABLE HASROWS	NUMBER;
VARIABLE HIST_ITEM	VARCHAR2(8);
VARIABLE HIST_KEY	VARCHAR2(240);
VARIABLE WFADMIN_NAME	VARCHAR2(320);
VARIABLE WFADMIN_DISPLAY_NAME	VARCHAR2(360);
VARIABLE WFADMIN_ORIG_SYSTEM	VARCHAR2(30);
VARIABLE WFADMIN_STATUS VARCHAR2(8);
VARIABLE WF_ADMINS_CNT  NUMBER; 
VARIABLE QMON		NUMBER;
VARIABLE DB_VER    	VARCHAR2(10);

declare

	test			varchar2(240);
	wfcmtphy		number;
	wfdigphy		number;
	wfitmphy		number;
	wiasphy			number;
	wiashphy		number;
	wfattrphy		number;
	wfntfphy		number;
	wfcmtphy2		number;
	wfdigphy2		number;
	wfitmphy2		number;
	wiasphy2		number;
	wiashphy2		number;
	wfattrphy2		number;
	wfntfphy2		number;
	errorntfcnt		number;
	ntferr_cnt		number;
	ecxerr_cnt		number;	
	omerr_cnt		number;	
	poerr_cnt		number;	
	wferr_cnt		number;	
	ecxrate			number;	
	omrate			number;	
	porate			number;	
	wfrate			number;
	admin_email             varchar2(40);
        ntf_pref                varchar2(10);
	gsm         		varchar2(1);
	item_cnt    		number;
	item_open   		number;
	oldest_item 		number;
	sid         		varchar2(20);
	host        		varchar2(30);
	apps_rel    		varchar2(10);
	wf_admin_display 	varchar2(360);
	email       		varchar2(320);
	email_override 		varchar2(320);	
	ntf_pref    		varchar2(8);
	mailer_enabled 		varchar2(10);
	mailer_status 		varchar2(30);
	corrid	 		varchar2(240);
	component_name  	varchar2(80);
	container_name  	varchar2(240);
	startup_mode    	varchar2(30);
	total_error  		number;
	open_error   		number;
	closed_error 		number;
	wf_admin_role 		varchar2(320);
        logical_totals		varchar2(22);
        physical_totals 	varchar2(22);
        diff_totals 		varchar2(22);
        ninety_totals 		varchar2(22);
	rate			number;
	ninety_cnt		number;
	hist_cnt   		number;
	hist_days 		number;
	hist_daily		number;
	mailer_cnt		number;
	hist_end		varchar2(22);
	hist_begin		varchar2(22);
	hist_recent		varchar2(22);
	sysdate			varchar2(22);
	hasrows			number;
	hist_item      		varchar2(8);
	hist_key       		varchar2(240);
	wf_admins_cnt		number;
	wfadmin_name		varchar2(320);                                                                                                     
	wfadmin_display_name	varchar2(360);                                                                                           
	wfadmin_orig_system	varchar2(30);
	wfadmin_status		varchar2(8);
	qmon			number;
	mycheck			number;
	db_ver			varchar2(10); 

			 				 
begin

  select wf_core.translate('WF_ADMIN_ROLE') into :wf_admin_role from dual;
   
end;
/

alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

prompt <HTML>
prompt <HEAD>
prompt <TITLE>Workflow Analyzer</TITLE>
prompt <STYLE TYPE="text/css">
prompt <!-- TD {font-size: 10pt; font-family: calibri; font-style: normal} -->
prompt </STYLE>
prompt </HEAD>
prompt <BODY>

prompt <TABLE border="1" cellspacing="0" cellpadding="10">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF"><TD bordercolor="#DEE6EF"><font face="Calibri">
prompt <B><font size="+2">Workflow Analyzer for 
select UPPER(instance_name) from v$instance;
prompt <B><font size="+2"> on 
select UPPER(host_name) from v$instance;
prompt </font></B></TD></TR>
prompt </TABLE><BR>

prompt <img width="758" height="81" title="Support URL" src="https://support.oracle.com/oip/faces/secure/km/DownloadAttachment.jspx?attachid=432.1:BANNER2" /></a>
prompt <br>

prompt <font size="-1"><i><b>WF Analyzer v4.06 compiled on : 
select to_char(sysdate, 'Dy Month DD, YYYY') from dual;
prompt at 
select to_char(sysdate, ' hh24:mi:ss') from dual;
prompt </b></i></font><BR><BR>

prompt This Workflow Analyzer script reviews the current Workflow Footprint, analyzes runtime tables, profiles, settings, 
prompt and configurations for the overall workflow environment, providing helpful feedback and recommendations on Best Practices for any areas for concern on your system.
prompt <BR>

prompt ________________________________________________________________________________________________<BR>

prompt <table width="95%" border="0">
prompt   <tr> 
prompt     <td colspan="2" height="46"> 
prompt       <p><a name="top"><b><font size="+2">Table of Contents</font></b></a> </p>
prompt     </td>
prompt   </tr>
prompt   <tr> 
prompt     <td width="50%"> 
prompt       <p><a href="#section1"><b><font size="+1">Workflow Analzyer Overview</font></b></a> 
prompt         <br>
prompt       <blockquote> <a href="#wfadv111"> - E-Business Suite Version</a><br>
prompt         <a href="#wfadv112"> - Workflow Database Parameter Settings</a></blockquote>
prompt       <a href="#section2"><b><font size="+1">Workflow Administration</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#wfadv121"> - Verify the Workflow Administrator Role</a><br>
prompt         <a href="#sysadmin"> - SYSADMIN User Setup for Error Notifications</a><br>
prompt         <a href="#wfadv122"> - SYSADMIN WorkList Access</a><br>
prompt         <a href="#wfrouting"> - SYSADMIN Notification Routing Rules</a><br>
prompt         <a href="#wfadv123"> - Verify AutoClose_FYI Setting</a><br>
prompt         <a href="#ebsprofile"> - E-Business Suite Profile Settings</a><br>
prompt         <a href="#wfprofile"> - Workflow Profile Settings</a><br>
prompt         <a href="#wfadv124"> - Verify Error Messages</a><br>
prompt         <a href="#wfstuck"> - Verify #STUCK Activities</a><br>
prompt         <a href="#wfadv125"> - Totals for Notification Preferences</a><br>
prompt         <a href="#wfadv126"> - Check the Status of Workflow Services</a><br>
prompt       </blockquote>
prompt       <a href="#section3"><b><font size="+1">Workflow Footprint</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#wfadv131"> - Volume of Workflow Runtime Data Tables</a><br>
prompt         <a href="#wfadv132"> - Verify Closed and Purgeable TEMP Items</a><br>
prompt         <a href="#wfsummry"> - SUMMARY Of Workflow Processes By Item Type</a><br>
prompt         <a href="#wfadv133"> - Check the Volume of Open and Closed Items Annually</a><br>
prompt         <a href="#wfadv134"> - Average Volume of Opened Items in the past 6 Months, 
prompt         Monthly, and Daily</a><br>
prompt         <a href="#wfadv135"> - Total OPEN Items Started Over 90 Days Ago</a><br>
prompt         <a href="#wfadv136"> - Check Top 30 Large Item Activity Status History 
prompt         Items</a></blockquote>
prompt     </td>
prompt     <td width="50%"><a href="#section4"><b><font size="+1">Workflow Concurrent 
prompt       Programs</font></b></a> <br>
prompt       <blockquote> <a href="#wfadv141"> - Verify Concurrent Programs Scheduled 
prompt         to Run</a><br>
prompt         <a href="#wfadv142"> - Verify Workflow Background Processes that ran</a><br>
prompt         <a href="#wfadv143"> - Verify Status of the Workflow Background Engine 
prompt         Deferred Queue Table</a><br>
prompt         <a href="#wfadv144"> - Verify Workflow Purge Concurrent Programs</a><br>
prompt         <a href="#wfadv145"> - Verify Workflow Control Queue Cleanup Programs</a></blockquote>
prompt       <a href="#section5"><b><font size="+1">Workflow Notification Mailer</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#wfadv151"> - Check the status of the Workflow Services</a><br>
prompt         <a href="#wfadv152"> - Check the status of the Workflow Notification Mailer(s)</a><br>
prompt         <a href="#wfadv153"> - Check Status of WF_NOTIFICATIONS Table</a><br>
prompt         <a href="#wfadv154"> - Check Status of WF_NOTIFICATION_OUT Table</a><br>
prompt         <a href="#wfadv155"> - Check for Orphaned Notifications</a></blockquote>
prompt       <a href="#section6"><b><font size="+1">Workflow Patch Levels</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#wfadv161"> - Applied ATG Patches</a><br>
prompt         <a href="#atgrups"> - Known 1-Off Patches on top of ATG Rollups</a><br>
prompt         <a href="#wfadv162"> - Verify Status of Workflow Log Levels</a><br>
prompt         <a href="#wfadv163"> - Verify Workflow Services Log Locations</a><br>
prompt       </blockquote>
prompt       <a href="#section7"><b><font size="+1">References</font></b></a> 
prompt       <blockquote></blockquote>
prompt     </td>
prompt   </tr>
prompt </table>

prompt ________________________________________________________________________________________________<BR><BR>


REM **************************************************************************************** 
REM *******                   Section 1 : Workflow Analyzer Overview                 *******
REM ****************************************************************************************

prompt <a name="section1"></a><B><font size="+2">Workflow Analyzer Overview</font></B><BR><BR>

begin

select upper(instance_name) into :sid from v$instance;

select host_name into :host from fnd_product_groups, v$instance;

select release_name into :apps_rel from fnd_product_groups, v$instance;


select e.status into :mailer_enabled
from wf_events e, WF_EVENT_SUBSCRIPTIONS s
where  e.GUID=s.EVENT_FILTER_GUID
and s.DESCRIPTION like '%WF_NOTIFICATION_OUT%'
and e.name = 'oracle.apps.wf.notification.send.group';

select count(notification_id) into :total_error
from WF_NOTIFICATIONS
where message_type like '%ERROR%';

select count(notification_id) into :open_error
from WF_NOTIFICATIONS
where message_type like '%ERROR%'
and end_date is null;

select count(notification_id) into :closed_error
from WF_NOTIFICATIONS
where message_type like '%ERROR%'
and end_date is not null;

select count(item_key) into :item_cnt from wf_items;

select count(item_key) into :item_open from wf_items where end_date is null;

select round(sysdate-(min(begin_date)),0) into :oldest_item from wf_items;

       
if (:oldest_item > 1095) THEN

  dbms_output.put_line('<b>Workflow Runtime Data Table Gauge</b><BR>');
  dbms_output.put('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put('\&chxt=y');
  dbms_output.put('\&chs=300x150');
  dbms_output.put('\&cht=gm');
  dbms_output.put('\&chd=t:10');
  dbms_output.put('\&chl=Excessive" width="300" height="150" alt="" />');
  dbms_output.put_line('<BR><BR>');
  
    dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">Your overall Workflow HealthCheck Status is in need of Immediate Review!</font><BR> ');
    dbms_output.put_line('        The WF_ITEMS Table has obsolete workflow runtime data that is older than 3 years.<BR><BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');

  else   if (:oldest_item > 365) THEN

  dbms_output.put_line('<b>Workflow Runtime Data Table Gauge</b><BR>');
  dbms_output.put('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put('\&chxt=y');
  dbms_output.put('\&chs=300x150');
  dbms_output.put('\&cht=gm');
  dbms_output.put('\&chd=t:50');
  dbms_output.put('\&chl=Poor" width="300" height="150" alt="" />');
  dbms_output.put_line('<BR><BR>');
  
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">Your overall Workflow HealthCheck Status is in need of Review!</font><BR> ');
    dbms_output.put_line('        The WF_ITEMS Table has obsolete workflow runtime data that is older than 1 year but less than 3 years.<BR><BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
  else

  dbms_output.put_line('<b>Workflow Runtime Data Table Gauge</b><BR>');
  dbms_output.put('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put('\&chxt=y');
  dbms_output.put('\&chs=300x150');
  dbms_output.put('\&cht=gm');
  dbms_output.put('\&chd=t:90');
  dbms_output.put('\&chl=Healthy" width="300" height="150" alt="" />');
  dbms_output.put_line('<BR><BR>');
  
    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#666600" bgcolor="#99FF99" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">Your overall Workflow HealthCheck Status is Healthy!</font><BR> ');
    dbms_output.put_line('        The WF_ITEMS Table has workflow runtime data that is less than 1 year old.<BR><BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
  end if;
end if;

    
  if (:item_cnt > 100) THEN
   
    dbms_output.put_line('We reviewed all ' || to_char(:item_cnt,'999,999,999,999') || ' rows in WF_ITEMS Table for Oracle Applications Release ' || :apps_rel || ' instance called ' || :sid || ' on ' || :host || '<BR>');
    dbms_output.put_line('Currently ' || (round(:item_open/:item_cnt, 2)*100) || '% (' || to_char(:item_open,'999,999,999,999') || ') of WF_ITEMS are OPEN, while ' || (round((:item_cnt-:item_open)/:item_cnt, 2)*100) || '% (' || to_char((:item_cnt-:item_open),'999,999,999,999') || ') are CLOSED items but still exist in the runtime tables.<BR><BR>');

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> Once a Workflow is closed, its runtime data that is stored in Workflow Runtime Tables (WF_*) becomes obsolete.<BR>');
    dbms_output.put_line('All the pertinent data is stored in the functional tables (FND_*, PO_*, AP_*, HR_*, OE_*, etc), like who approved what, for how much, for who, etc...)<br>');
    dbms_output.put_line('Remember that each row in WF_ITEMS is associated to 100s or 1000s of rows in the other WF runtime tables, ');
    dbms_output.put_line('so it is important to purge this obsolete runtime data regularly.</p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

  else

    dbms_output.put_line('There are less than 100 items in the WF_ITEMS table.<BR><BR>');

  end if;

end;
/

REM
REM ******* Ebusiness Suite Version *******
REM

prompt <script type="text/javascript">    function displayRows1sql1(){var row = document.getElementById("s1sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv111"></a>
prompt     <B>E-Business Suite Version</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="60">
prompt       <blockquote><p align="left">
prompt          select vi.instance_name, fpg.release_name, vi.host_name, vi.startup_time, vi.version <br>
prompt          from fnd_product_groups fpg, v$instance vi<br>
prompt          where fpg.APPLICATIONS_SYSTEM_NAME = vi.INSTANCE_NAME;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RELEASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>HOSTNAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATABASE</B></TD>
select  
'<TR><TD>'||instance_name||'</TD>'||chr(10)|| 
'<TD>'||release_name||'</TD>'||chr(10)|| 
'<TD>'||host_name||'</TD>'||chr(10)|| 
'<TD>'||startup_time||'</TD>'||chr(10)|| 
'<TD>'||version||'</TD></TR>'
from fnd_product_groups, v$instance
where APPLICATIONS_SYSTEM_NAME = INSTANCE_NAME;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Workflow Database Parameter Settings *******
REM

prompt <script type="text/javascript">    function displayRows1sql2(){var row = document.getElementById("s1sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv112"></a>
prompt     <B>Workflow Database Parameter Settings</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="45">
prompt       <blockquote><p align="left">
prompt          select name, value<br>
prompt          from v$parameter<br>
prompt          where upper(name) in ('AQ_TM_PROCESSES','JOB_QUEUE_PROCESSES','JOB_QUEUE_INTERVAL',<br>
prompt                                'UTL_FILE_DIR','NLS_LANGUAGE', 'NLS_TERRITORY', 'CPU_COUNT',<br>
prompt                                'PARALLEL_THREADS_PER_CPU');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
select  
'<TR><TD>'||name||'</TD>'||chr(10)|| 
'<TD>'||value||'</TD></TR>'
from v$parameter
where upper(name) in ('AQ_TM_PROCESSES','JOB_QUEUE_PROCESSES','JOB_QUEUE_INTERVAL','UTL_FILE_DIR','NLS_LANGUAGE', 'NLS_TERRITORY', 'CPU_COUNT','PARALLEL_THREADS_PER_CPU');
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

begin

select version into :db_ver from v$instance;

if (:db_ver like '8.%') or (:db_ver like '9.%') then 

    :db_ver := '0'||:db_ver;

end if;

if (:db_ver < '11.1') then

    select value into :qmon from v$parameter where upper(name) = 'AQ_TM_PROCESSES';

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: JOB_QUEUE_PROCESSES for pre-11gR1 (11.1) databases:</B><BR>');
    dbms_output.put_line('Oracle Workflow requires job queue processes to handle propagation of Business Event System event messages by AQs.<BR>');
    dbms_output.put_line('<B>The recommended minimum number of JOB_QUEUE_PROCESSES for Oracle Workflow is 10.<BR> ');
    dbms_output.put_line('The maximum number of JOB_QUEUE_PROCESSES is :<BR> -    36 in Oracle8i<BR> - 1,000 in Oracle9i Database and higher, so set the value of JOB_QUEUE_PROCESSES accordingly.</B><BR>');
    dbms_output.put_line('The ideal setting for JOB_QUEUE_PROCESSES should be set to the maximum number of jobs that would ever be run concurrently on a system PLUS a few more.</B><BR><BR>');

    dbms_output.put_line('To determine the proper amount of JOB_QUEUE_PROCESSES for Oracle Workflow, follow the queries outlined in<BR> ');
    dbms_output.put_line('<a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=578831.1" target="_blank">Note 578831.1</a>');
    dbms_output.put_line('- How to determine the correct setting for JOB_QUEUE_PROCESSES.<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');
	
  elsif (:db_ver >= '11.1') then

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: Significance of the JOB_QUEUE_PROCESSES for 11gR1+ (11.1) databases:</B><BR><BR>');
    dbms_output.put_line('Starting from 11gR1, The init.ora parameter job_queue_processes does NOT need to be set for AQ propagations.');
    dbms_output.put_line('AQ propagation is now likewise handled by DBMS_SCHEDULER jobs rather than DBMS_JOBS. ');
    dbms_output.put_line('Reason: propagation takes advantage of the event based scheduling features of DBMS_SCHEDULER for better scalability. ');
    dbms_output.put_line('If the value of the JOB_QUEUE_PROCESSES database initialization parameter is zero, then that parameter does not influence ');
    dbms_output.put_line('the number of Oracle Scheduler jobs that can run concurrently. ');
    dbms_output.put_line('However, if the value is non-zero, it effectively becomes the maximum number of Scheduler jobs and job queue jobs than can run concurrently. ');
    dbms_output.put_line('If a non-zero value is set, it should be large enough to accommodate a Scheduler job for each Messaging Gateway agent to be started.<BR><BR>');    
    
    dbms_output.put_line('<B>Oracle Workflow recommends to UNSET the JOB_QUEUE_PROCESSES parameter as per DB recommendations to enable the scheduling features of DBMS_SCHEDULER for better scalability.</B><BR><BR>');      
    
    dbms_output.put_line('To update the JOB_QUEUE_PROCESSES database parameter file (init.ora) file:<BR><BR>');
    dbms_output.put_line('<i>job_queue_processes=10</i><BR><BR>');
    dbms_output.put_line('or set dynamically via<BR><BR>');
    dbms_output.put_line('<i>alter system set job_queue_processes=10;</i><BR><BR>Remember that after bouncing the DB, dynamic changes are lost, and the DB parameter file settings are used.<BR>');    
    dbms_output.put_line('To determine the proper setting of JOB_QUEUE_PROCESSES for Oracle Workflow, follow the queries outlined in <BR>');
    dbms_output.put_line('<a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=578831.1" target="_blank">Note 578831.1</a>');
    dbms_output.put_line('- How to determine the correct setting for JOB_QUEUE_PROCESSES.<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');
  
  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: To determine the proper amount of JOB_QUEUE_PROCESSES for Oracle Workflow</B><BR>');
    dbms_output.put_line('Follow the queries outlined in ');
    dbms_output.put_line('<a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=578831.1" target="_blank">Note 578831.1</a>');
    dbms_output.put_line('- How to determine the correct setting for JOB_QUEUE_PROCESSES.<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

end if;

  
end;
/


begin

select version into :db_ver from v$instance;

if (:db_ver like '8.%') or (:db_ver like '9.%') then 

    :db_ver := '0'||:db_ver;

end if;

if (:db_ver < '10.1') then

    select value into :qmon from v$parameter where upper(name) = 'AQ_TM_PROCESSES';

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: AQ_TM_PROCESSES for pre-10gR1 (10.1) databases:</B><BR>');
    dbms_output.put_line('The Oracle Streams AQ time manager process is called the Queue MONitor (QMON), a background process controlled by parameter AQ_TM_PROCESSES.<BR>');
    dbms_output.put_line('QMON processes are associated with the mechanisms for message expiration, retry, delay, maintaining queue statistics, removing PROCESSED messages ');
    dbms_output.put_line('from a queue table and updating the dequeue IOT as necessary.  QMON plays a part in both permanent and buffered message processing.<BR>');
    dbms_output.put_line('If a qmon process should fail, this should not cause the instance to fail. This is also the case with job queue processes.<BR>');
    dbms_output.put_line('QMON itself operates on queues but does not use a database queue for its own processing of tasks and time based operations, so it can ');
    dbms_output.put_line('be envisaged as a number of discrete tasks which are run by Queue Monitor processes or servers.');

    dbms_output.put_line('The AQ_TM_PROCESSES parameter is set in the (init.ora) database parameter file, and by default is set to 1.<br>');
    dbms_output.put_line('This value allows Advanced Queuing to start 1 AQ background process for Queue Monitoring, which is  ');
    dbms_output.put_line('usually sufficient for simple E-Business Suite instances.  <BR><B>However, this setting can be increased (dynamically) to improve queue maintenance performance.</B></p>');
    
    dbms_output.put_line('If this parameter is set to a non-zero value X, Oracle creates that number of QMNX processes starting from ora_qmn0_SID (where SID is the identifier of the database) ');
    dbms_output.put_line('up to ora_qmnX_SID ; if the parameter is not specified or is set to 0, then the QMON processes are not created. ');
    dbms_output.put_line('There can be a maximum of 10 QMON processes running on a single instance. For example the parameter can be set in the init.ora as follows :<BR><BR>');
    dbms_output.put_line('<i>aq_tm_processes=3</i><BR><BR>');
    dbms_output.put_line('or set dynamically via<BR><BR>');
    dbms_output.put_line('<i>alter system set aq_tm_processes=3;</i><BR><BR>Remember that after bouncing the DB, dynamic changes are lost, and the DB parameter file settings are used.<BR>'); 
    
    dbms_output.put_line('It is recommended to NOT DISABLE the Queue Monitor processes by setting aq_tm_processes=0 on a permanent basis. As can be seen above, ');
    dbms_output.put_line('disabling will stop all related processing in relation to tasks outlined. This will likely have a significant affect on operation of queues - PROCESSED ');
    dbms_output.put_line('messages will not be removed and any time related, TM actions will not succeed, AQ objects will grow in size.<BR><BR>');
    dbms_output.put_line('To update the AQ_TM_PROCESSES database parameter, follow the steps outlined in <BR>');
    dbms_output.put_line('<a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=305662.1#aref1" target="_blank">Note 305662.1</a>');
    dbms_output.put_line('- Master Note for AQ Queue Monitor Process (QMON).<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

  elsif (:db_ver >= '10.1') then

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: Significance of the AQ_TM_PROCESSES for 10gR1+ (10.1) databases:</B><BR><BR>');
    dbms_output.put_line('Starting from 10gR1, Queue Monitoring can utilize a feature called "auto-tune".<br>');
    dbms_output.put_line('That means Queue Monitoring does not need AQ_TM_PROCESSES to be defined,');
    dbms_output.put_line('it is instead able to adapt to the number of AQ background processes to the system load.<br>');
    dbms_output.put_line('However, if you do specify a value, then that value is taken into account but the number of processes can still be auto-tuned and so the number of ');
    dbms_output.put_line('running qXXX processes can be different from what was specified by AQ_TM_PROCESSES.<BR><BR>');    
    
    dbms_output.put_line('<B>Oracle Workflow recommends to UNSET the AQ_TM_PROCESSES parameter as per DB recommendations to enable auto-tune feature.</B><BR><BR>');      
    
    dbms_output.put_line('Note: For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=746313.1" target="_blank">Note 746313.1</a>');
    dbms_output.put_line('- What should be the Correct Setting for Parameter AQ_TM_PROCESSES in E-Business Suite Instance?<br></p>');

    dbms_output.put_line('It should be noted that if AQ_TM_PROCESSES is explicitly specified then the process(es) started will only maintain persistent messages. ');
    dbms_output.put_line('For example if aq_tm_processes=1 then at least one queue monitor slave process will be dedicated to maintaining persistent messages. ');
    dbms_output.put_line('Other process can still be automatically started to maintain buffered messages. Up to and including version 11.1 if you explicitly set aq_tm_processes = 10 ');
    dbms_output.put_line('then there will be no processes available to maintain buffered messages. This should be borne in mind in environments which use Streams replication ');
    dbms_output.put_line('and from 10.2 onwards user enqueued buffered messages.<BR><BR>');

    dbms_output.put_line('It is also recommended to NOT DISABLE the Queue Monitor processes by setting aq_tm_processes=0 on a permanent basis. As can be seen above, ');
    dbms_output.put_line('disabling will stop all related processing in relation to tasks outlined. This will likely have a significant affect on operation of queues - PROCESSED ');
    dbms_output.put_line('messages will not be removed and any time related, TM actions will not succeed, AQ objects will grow in size.<BR>');

    dbms_output.put_line('<p><B>Note: There is a known issue viewing the true value of AQ_TM_PROCESSES for 10gR2+ (10.2) from the v$parameters table.</B><BR>');
    dbms_output.put_line('Review the details in <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=428441.1" target="_blank">Note 428441.1</a>');
    dbms_output.put_line('- Warning: Aq_tm_processes Is Set To 0" Message in Alert Log After Upgrade to 10.2.0.3 or Higher.</p>');
    
    dbms_output.put_line('To check whether AQ_TM_PROCESSES Auto-Tuning is enabled, follow the steps outlined in<BR> ');
    dbms_output.put_line('<a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=305662.1#aref7" target="_blank">Note 305662.1</a>');
    dbms_output.put_line('- Master Note for AQ Queue Monitor Process (QMON) under Section : Significance of the AQ_TM_PROCESSES Parameter in 10.1 onwards<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');
  
  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=746313.1" target="_blank">Note 746313.1</a>');
    dbms_output.put_line('- What should be the Correct Setting for Parameter AQ_TM_PROCESSES in E-Business Suite Instance?<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

end if;

  
end;
/


REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=453137.1" target="_blank">
prompt Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

REM **************************************************************************************** 
REM *******                   Section 2 : Workflow Administration                    *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><font size="+2">Workflow Administration</font></B><BR><BR>

REM
REM ******* Verify the Workflow Administrator Role *******
REM

declare

	wfadminUsers          varchar2(320);

cursor wf_adminIDs IS
	select name
	from wf_roles 
	where name in (select user_name from WF_USER_ROLE_ASSIGNMENTS where role_name = (select wf_core.translate('WF_ADMIN_ROLE') from dual));

begin

	select wf_core.translate('WF_ADMIN_ROLE') into :wf_admin_role from dual;

	select nvl(max(rownum), 0) into :wf_admins_cnt
	from wf_roles 
	where name in (select user_name from WF_USER_ROLE_ASSIGNMENTS where role_name = (select wf_core.translate('WF_ADMIN_ROLE') from dual));

if ((:wf_admin_role like 'FND_RESP%') and (:wf_admins_cnt = 0)) then

       dbms_output.put_line('<a name="wfadv121"></a><B><U>Workflow Administrator Role</B></U><BR>');
       dbms_output.put_line('There are no Users assigned to this Responsibility, so noone has Workflow Administrator Role permissions on this instance.<BR>');
       dbms_output.put_line('Please assign someone this responsibility.<BR><BR> ');
       

  elsif ((:wf_admin_role like 'FND_RESP%') and (:wf_admins_cnt = 1)) then
 
       dbms_output.put_line('<a name="wfadv121"></a><B><U>Workflow Administrator Role</B></U><BR>');
       dbms_output.put_line('There is only one User assigned to this Responsibility, so they alone have Workflow Administrator Role permissions on this instance.<BR>');
       dbms_output.put_line('Please assign more people to this responsibility.<BR><BR> ');
  
  elsif ((:wf_admin_role like 'FND_RESP%') and (:wf_admins_cnt > 1)) then

	select r.display_name into :wf_admin_display 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ;

	select notification_preference into :ntf_pref 
	from wf_local_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ; 

	select decode(email_address, '','No Email Specified', email_address) into :email 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ;  

       dbms_output.put_line('<a name="wfadv121"></a><B><U>Workflow Administrator Role</B></U><BR>');
       dbms_output.put_line('The Workflow Administrator role (WF_ADMIN_ROLE) for ' || :sid || ' is set to a Responsibility (' || :wf_admin_role || ') also known as ' || :wf_admin_display || '.<BR>' );
       dbms_output.put_line('This role ' || :wf_admin_role || ' has a Notification Preference of ' || :ntf_pref || ', and email address is set to ' || :email || '.<BR>');
       dbms_output.put_line('There are mutiple Users assigned to this Responsibility, all having Workflow Administrator Role permissions on this instance.<BR>');
       dbms_output.put_line('Please verify this list of users assigned this responsibility is accurate.<BR><BR>');
 
       dbms_output.put_line('<TABLE border="1" cellspacing="0" cellpadding="2">');
       dbms_output.put_line('<TR bgcolor="#DEE6EF" bordercolor="#DEE6EF"><TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">');
       dbms_output.put_line('<a name="wfadmins"></a><B>Roles with Workflow Administrator Role Permissions</B></font></TD></TR>');
       dbms_output.put_line('<TR>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></font></TD>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></font></TD>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ORIG_SYSTEM</B></font></TD>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></font></TD>');
 

	OPEN wf_adminIDs;
	LOOP

	    Fetch wf_adminIDs INTO wfadminUsers;

	    EXIT WHEN wf_adminIDs%NOTFOUND;

		select name into :wfadmin_name
		from wf_roles 
		where name = wfadminUsers;

		select display_name into :wfadmin_display_name
		from wf_roles 
		where name = wfadminUsers;

		select orig_system into :wfadmin_orig_system
		from wf_roles 
		where name = wfadminUsers;

		select status into :wfadmin_status 
		from wf_roles 
		where name = wfadminUsers;

		dbms_output.put_line('<TR><TD>'||:wfadmin_name||'</TD>');                                                                                                     
		dbms_output.put_line('<TD>'||:wfadmin_display_name||'</TD>');                                                                                              
		dbms_output.put_line('<TD>'||:wfadmin_orig_system||'</TD>');                                                                                                             
		dbms_output.put_line('<TD>'||:wfadmin_status||'</TD></TR>');                                                                                                     

	END LOOP;

	CLOSE wf_adminIDs;


        dbms_output.put_line('</TABLE><P><P>');
        dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');

  elsif (:wf_admin_role = '*') then

	:wf_admin_display := 'Asterisk';
	:ntf_pref := 'not set';
	:email := 'not set when Asterisk';

    dbms_output.put_line('<a name="wfadv121"></a><B><U>Workflow Administrator Role</B></U><BR>');
    dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Warning:</B>The Workflow Administrator role (WF_ADMIN_ROLE) for ' || :sid || ' is set to an Asterisk which allows EVERYONE access to Workflow Administrator Role permissions.<BR>');
    dbms_output.put_line('This is not recommended for Production instances, but may be ok for Testing.  <BR>Remember that the Workflow Administrator Role has permissions to full access of all workflows and notifications.<BR><BR>');
    dbms_output.put_line('      <p><B>Note:</B> For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=453137.1" target="_blank">Note 453137.1</a>');
    dbms_output.put_line('- Oracle Workflow Best Practices Release 12 and Release 11i<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

  else 

	select r.display_name into :wf_admin_display 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ;

	select notification_preference into :ntf_pref 
	from wf_local_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ; 

	select decode(email_address, '','No Email Specified', email_address) into :email 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ; 
	
    dbms_output.put_line('<a name="wfadv121"></a><B><U>Workflow Administrator Role</B></U><BR>');
    dbms_output.put_line('The Workflow Administrator role (WF_ADMIN_ROLE) for ' || :sid || ' is set to a single Applications Username or role (' || :wf_admin_role || ') also known as ' || :wf_admin_display || '.<BR>' );
    dbms_output.put_line('This role ' || :wf_admin_role || ' has a Notification Preference of ' || :ntf_pref || ', and email address is set to ' || :email || '.<BR>' );
    dbms_output.put_line('On this instance, you must log into Oracle Applications as ' || :wf_admin_role || ' to utilize the Workflow Administrator Role permissions and control any and all workflows.<BR><BR>');
    dbms_output.put_line('<B>Note:</B> For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=453137.1" target="_blank">Note 453137.1</a>');
    dbms_output.put_line('- Oracle Workflow Best Practices Release 12 and Release 11i<br><br>');



  end if;
 
end;
/



prompt <a name="sysadmin"></a><B><U>SYSADMIN User Setup for Error Notifications</B></U><BR>
        
begin

 select notification_preference into :ntf_pref 
   from wf_roles
  where name = 'SYSADMIN';

 select nvl(email_address,'NOTSET') into :admin_email 
   from wf_roles
  where name = 'SYSADMIN';

 select count(notification_id) into :errorntfcnt
   from wf_notifications
  where recipient_role = 'SYSADMIN'
    and message_type like '%ERROR%';

end;
/

begin

if (:ntf_pref = 'DISABLED') then

    dbms_output.put_line('<table border="1" name="Error" cellpadding="10" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Error<BR>');
    dbms_output.put_line('The SYSADMIN User e-mail is DISABLED!</B><BR>');
    dbms_output.put_line('The SYSADMIN User is the default recipient for several types of notifications such as Workflow error notifications.<br>  ');
    dbms_output.put_line('Currently there are '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications assigned to the SYSADMIN user. <br><br>');
    dbms_output.put_line('<B>Action</B><BR>');
    dbms_output.put_line('Please specify how you want to receive these notifications by defining the notification preference and e-mail address for the SYSADMIN User.<BR>');
    dbms_output.put_line('First correct the SYSADMIN User e-mail_address and change the notification_preference from DISABLED to a valid setting.<BR><BR>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for information on how to change these settings.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
  elsif (:ntf_pref = 'QUERY') then

    dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Warning</B><BR>');
    dbms_output.put_line('The SYSADMIN User appears to be setup to <b>not receive</b> email notifications!<br>');
    dbms_output.put_line('<br>This is fine.<br>');
    dbms_output.put_line('<B>However</b>, this means SYSADMIN can only access notifications through the Oracle Workflow Worklist Web page. <br>');
    dbms_output.put_line('Please verify that the SYSADMIN User is actively processing the '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications that are currently assigned to this user. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for information on how to change these settings if needed.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

    
  elsif ((:admin_email = 'NOTSET') and (:ntf_pref <> 'QUERY')) then

    dbms_output.put_line('<table border="1" name="Error" cellpadding="10" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Error<BR>');
    dbms_output.put_line('The SYSADMIN User has not been setup correctly.  SYSADMIN e-mail address is not set, but the notification preference is set to send emails.</B><BR>');
    dbms_output.put_line('Currently there are '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications assigned to the SYSADMIN user. <br><br>');
    dbms_output.put_line('<B>Action</B><BR>');
    dbms_output.put_line('In Oracle Applications, you must particularly check the notification preference and e-mail address for the SYSADMIN User. <BR>');
    dbms_output.put_line('The SYSADMIN User is the default recipient for several types of notifications such as Workflow error notifications.  ');
    dbms_output.put_line('You need to specify how you want to receive these notifications by defining the notification preference and e-mail address for the User: SYSADMIN.<BR>');
    dbms_output.put_line('By default, the SYSADMIN User has a notification preference to receive e-mail notifications. <BR>To enable Oracle Workflow to send e-mail to this user, ');
    dbms_output.put_line('navigate to the Users window in Oracle Applications and assign SYSADMIN an e-mail address that is fully qualified with a valid domain.<br> ');
    dbms_output.put_line('However, if you want to access notifications only through the Oracle Workflow Worklist Web page, ');
    dbms_output.put_line('then you should change the notification preference for SYSADMIN to "Do not send me mail" in the Preferences page. In this case you do not need to define an e-mail address. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  elsif ((:admin_email <> 'NOTSET') and (:ntf_pref <> 'QUERY')) then 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> The SYSADMIN User appears to be setup to receive email notifications.<br>');
    dbms_output.put_line('Please verify that the email_address ('||:admin_email||') is a valid email address and can recieve emails successully.<br>');
    dbms_output.put_line('Also, please verify that the SYSADMIN User is actively processing the '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications that are currently assigned to this user. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');  
    
  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> It is unclear what the SYSADMIN User e-mail address is set to.<br>');
    dbms_output.put_line('Please verify that the SYSADMIN User is actively processing the '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications that are currently assigned to this user. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for information on how to setup these tasks.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');  
    
end if;
 
end;
/

begin

	select nvl(max(rownum), 0) into :ntferr_cnt
	from wf_notifications n
	where n.message_type like '%ERROR%';

	select nvl(max(rownum), 0) into :ecxerr_cnt
	from wf_notifications n
	where n.message_type = 'ECXERROR';

	select nvl(max(rownum), 0) into :omerr_cnt
	from wf_notifications n
	where n.message_type = 'OMERROR';

	select nvl(max(rownum), 0) into :poerr_cnt
	from wf_notifications n
	where n.message_type = 'POERROR';

	select nvl(max(rownum), 0) into :wferr_cnt
	from wf_notifications n
	where n.message_type = 'WFERROR';	

	select round(:ecxerr_cnt/:ntferr_cnt,2)*100 into :ecxrate from dual;	
	select round(:omerr_cnt/:ntferr_cnt,2)*100 into :omrate from dual;
	select round(:poerr_cnt/:ntferr_cnt,2)*100 into :porate from dual;
	select round(:wferr_cnt/:ntferr_cnt,2)*100 into :wfrate from dual;

dbms_output.put_line('<BR><B><U>Show the status of the Workflow Error Notifications for this instance</B></U><BR>');


  if (:ntferr_cnt = 0) then

       dbms_output.put_line('There are no Notification Error Messages for this instance.<BR>');
       dbms_output.put_line('You deserve a whole cake.<BR><BR> ');

    elsif (:ntferr_cnt < 100) then
 
       dbms_output.put_line('There are less that 100 Error Notifications found on this instance.<BR>');
       dbms_output.put_line('Keep up the good work.... You deserve a piece of pie. <BR><BR> ');
  
    else 
        
	dbms_output.put('<blockquote><img src="https://chart.googleapis.com/chart?');
	dbms_output.put('chs=500x200');
	dbms_output.put('\&chd=t:'||:wfrate||','||:porate||','||:omrate||','||:ecxrate||'\&cht=p3');
	dbms_output.put('\&chtt=Workflow+Error+Notifications+by+Type');
	dbms_output.put('\&chl=WFERROR|POERROR|OMERROR|ECXERROR');
	dbms_output.put('\&chdl='||:wferr_cnt||'|'||:poerr_cnt||'|'||:omerr_cnt||'|'||:ecxerr_cnt||'"><BR>');
	dbms_output.put_line('Item Types</blockquote>');
	
  	dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
  	dbms_output.put_line('<tbody><tr><td> ');
  	dbms_output.put_line('<B>Attention</B><BR>');
  	dbms_output.put_line('There are '||to_char(:ntferr_cnt,'999,999,999,999')||' Error Notifications of type (ECXERROR,OMERROR,POERROR,WFERROR) found on this instance.<BR>');
  	dbms_output.put_line('Please review the following table to better understand the volume and status for these Error Notifications. <BR><BR>');
  	dbms_output.put_line('Also review : <br><a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1448095.1" target="_blank">');
  	dbms_output.put_line('Note 1448095.1</a> - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN.<br>');
  	dbms_output.put_line('<a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=760386.1" target="_blank">');
  	dbms_output.put_line('Note 760386.1</a> - How to enable Bulk Notification Response Processing for Workflow in 11i and R12, for more details on ways to do this.');
  	dbms_output.put_line('</p></td></tr></tbody></table><BR>');       
       
  end if;
end;
/



prompt <script type="text/javascript">    function displayRows2sql3(){var row = document.getElementById("s2sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=7 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Summary of Error Message Recipients (WFERROR, POERROR, OMERROR, ECXERROR)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="8" height="85">
prompt       <blockquote><p align="left">
prompt          select r.name, r.display_name, r.status, r.notification_preference, r.email_address, n.message_type,<br>
prompt          count(n.notification_id) COUNT, decode(to_char(n.end_date), null, 'OPEN', 'CLOSED') OPEN<br>
prompt          from wf_roles r, wf_notifications n<br>
prompt          where r.name in (select distinct n.recipient_role from wf_notifications where n.message_type like '%ERROR')<br>
prompt          and r.name = n.recipient_role<br>
prompt          group by r.name, r.display_name, r.status, r.notification_preference, r.email_address, n.message_type, decode(to_char(n.end_date), null, 'OPEN', 'CLOSED')<br>
prompt          order by count(n.notification_id) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PREFERENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EMAIL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OPEN</B></TD>
select  
'<TR><TD>'||r.name||'</TD>'||chr(10)|| 
'<TD>'||r.display_name||'</TD>'||chr(10)||
'<TD>'||r.status||'</TD>'||chr(10)||
'<TD>'||r.notification_preference||'</TD>'||chr(10)||
'<TD>'||r.email_address||'</TD>'||chr(10)||
'<TD>'||n.message_type||'</TD>'||chr(10)|| 
'<TD>'||to_char(count(n.notification_id),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD><div align="center">'||decode(to_char(n.end_date), null, 'OPEN', 'CLOSED')||'</div></TD></TR>'
from wf_roles r, wf_notifications n
where r.name in (select distinct n.recipient_role from wf_notifications where n.message_type like '%ERROR')
and r.name = n.recipient_role
group by r.name, r.display_name, r.status, r.notification_preference, r.email_address, n.message_type, decode(to_char(n.end_date), null, 'OPEN', 'CLOSED')
order by count(n.notification_id) desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <a name="wfadv122"></a><B><U>Worklist Access</B></U><BR>
prompt The Oracle Workflow Advanced Worklist allows you to grant access to your worklist to another user. <BR>
prompt That user can then act as your proxy to handle the notifications in your list on your behalf. 
prompt You can either grant a user access for a specific period or allow the user.s access to continue indefinitely.
prompt The worklist access feature lets you allow another user to handle your notifications 
prompt without giving that user access to any other privileges or responsibilities that you have in Oracle Applications.<BR>
prompt <BR>
prompt To access other worklists granted to you, simply switch the Advanced Worklist to display the user.s notifications instead of your own.<BR> 
prompt When viewing another user.s worklist, you can perform the following actions:<BR>
prompt - View the details of the user.s notifications.<BR>
prompt - Respond to notifications that require a response.<BR>
prompt - Close notifications that do not require a response.<BR>
prompt - Reassign notifications to a different user.<BR><BR>
prompt Below we verify who has been granted WorkList Access to the SYSADMIN Role in order to respond to error notifications.
prompt <BR><BR>

REM
REM ******* WorkList Access for SYSADMIN *******
REM

prompt <script type="text/javascript">    function displayRows2sql2(){var row = document.getElementById("s2sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SYSADMIN WorkList Access</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="85">
prompt       <blockquote><p align="left">
prompt          select parameter1, grantee_key, start_date,<br>
prompt          end_date, parameter2, instance_pk1_value<br>
prompt          FROM fnd_grants<br>
prompt          WHERE program_name = 'WORKFLOW_UI'<br>
prompt          AND parameter1 = 'SYSADMIN';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>GRANTOR</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>GRANTEE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>START DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>END DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACCESSIBLE ITEMS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE</B></TD>
select  
'<TR><TD>'||parameter1||'</TD>'||chr(10)|| 
'<TD>'||grantee_key||'</TD>'||chr(10)|| 
'<TD>'||start_date||'</TD>'||chr(10)|| 
'<TD>'||end_date||'</TD>'||chr(10)|| 
'<TD>'||parameter2||'</TD>'||chr(10)|| 
'<TD>'||instance_pk1_value||'</TD></TR>'
FROM fnd_grants
WHERE program_name = 'WORKFLOW_UI'
AND parameter1 = 'SYSADMIN';
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Routing Rules for SYSADMIN *******
REM

prompt <a name="wfrouting"></a><B><U>SYSADMIN Notification Routing Rules</B></U><BR>
prompt The Oracle Workflow Advanced Worklist allows you to grant access to your worklist to another user. <BR>
prompt That user can then act as your proxy to handle the notifications in your list on your behalf. 
prompt You can either grant a user access for a specific period or allow the user.s access to continue indefinitely.
prompt The worklist access feature lets you allow another user to handle your notifications 
prompt without giving that user access to any other privileges or responsibilities that you have in Oracle Applications.<BR>
prompt <BR>
prompt To access other worklists granted to you, simply switch the Advanced Worklist to display the user.s notifications instead of your own.<BR> 
prompt When viewing another user.s worklist, you can perform the following actions:<BR>
prompt - View the details of the user.s notifications.<BR>
prompt - Respond to notifications that require a response.<BR>
prompt - Close notifications that do not require a response.<BR>
prompt - Reassign notifications to a different user.<BR><BR>
prompt Below we verify who has been granted WorkList Access to the SYSADMIN Role in order to respond to error notifications.
prompt <BR><BR>

prompt <script type="text/javascript">    function displayRows2sql2a(){var row = document.getElementById("s2sql2a");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SYSADMIN Notification Routing Rules</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql2a()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql2a" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="85">
prompt       <blockquote><p align="left">
prompt          SELECT wrr.RULE_ID, wrr.ROLE, r.DESCRIPTION, wrr.ACTION, <br>
prompt          wrr.ACTION_ARGUMENT "TO", wrr.MESSAGE_TYPE, wrr.MESSAGE_NAME, <br>
prompt          wrr.BEGIN_DATE, wrr.END_DATE, wrr.RULE_COMMENT<br>
prompt          FROM WF_ROUTING_RULES wrr, wf_roles r<br>
prompt          WHERE wrr.ROLE = r.NAME<br>
prompt          and wrr.role = 'SYSADMIN';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RULE_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ROLE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TO</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BEGIN_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>END_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RULE_COMMENT</B></TD>
select  
'<TR><TD>'||wrr.RULE_ID||'</TD>'||chr(10)|| 
'<TD>'||wrr.ROLE||'</TD>'||chr(10)|| 
'<TD>'||r.DESCRIPTION||'</TD>'||chr(10)|| 
'<TD>'||wrr.ACTION||'</TD>'||chr(10)|| 
'<TD>'||wrr.ACTION_ARGUMENT||'</TD>'||chr(10)|| 
'<TD>'||wrr.MESSAGE_TYPE||'</TD>'||chr(10)|| 
'<TD>'||wrr.MESSAGE_NAME||'</TD>'||chr(10)|| 
'<TD>'||wrr.BEGIN_DATE||'</TD>'||chr(10)|| 
'<TD>'||wrr.END_DATE||'</TD>'||chr(10)||
'<TD>'||wrr.RULE_COMMENT||'</TD></TR>'
FROM WF_ROUTING_RULES wrr, wf_roles r
WHERE wrr.ROLE = r.NAME
and wrr.role = 'SYSADMIN';
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Verify AutoClose_FYI Setting *******
REM

prompt <script type="text/javascript">    function displayRows2sql3(){var row = document.getElementById("s2sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv123"></a>
prompt     <B>Verify AutoClose_FYI Setting</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="85">
prompt       <blockquote><p align="left">
prompt          select SC.COMPONENT_NAME, v.PARAMETER_DISPLAY_NAME, v.PARAMETER_VALUE<br>
prompt          from FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC<br>
prompt          where v.COMPONENT_ID=sc.COMPONENT_ID <br>
prompt          and v.parameter_name = 'AUTOCLOSE_FYI'<br>
prompt          order by sc.COMPONENT_ID;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARAMETER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
select  
'<TR><TD>'||SC.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD>'||v.PARAMETER_DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD><div align="center">'||v.PARAMETER_VALUE||'</div></TD></TR>'
from FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC
where v.COMPONENT_ID=sc.COMPONENT_ID 
and v.parameter_name = 'AUTOCLOSE_FYI'
order by sc.COMPONENT_ID;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* E-Business Suite Profile Settings *******
REM

prompt <script type="text/javascript">    function displayRows2sql4(){var row = document.getElementById("s2sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="ebsprofile"></a>
prompt     <B>E-Business Suite Profile Settings</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="125">
prompt       <blockquote><p align="left">
prompt          select t.PROFILE_OPTION_ID, t.PROFILE_OPTION_NAME, z.USER_PROFILE_OPTION_NAME,<br>
prompt          v.PROFILE_OPTION_VALUE, z.DESCRIPTION<br>
prompt          from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z<br>
prompt          where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)<br>
prompt          and (v.level_id = 10001)<br>
prompt          and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)<br>
prompt          and (t.PROFILE_OPTION_NAME in ('CONC_GSM_ENABLED','WF_VALIDATE_NTF_ACCESS','GUEST_USER_PWD',<br>
prompt          'AFLOG_ENABLED','AFLOG_FILENAME','AFLOG_LEVEL','AFLOG_BUFFER_MODE','AFLOG_MODULE','FND_FWK_COMPATIBILITY_MODE',<br>
prompt          'FND_VALIDATION_LEVEL','FND_MIGRATED_TO_JRAD','AMPOOL_ENABLED',<br>
prompt          'FND_NTF_REASSIGN_MODE','WF_ROUTE_RULE_ALLOW_ALL'))<br>
prompt          order by z.USER_PROFILE_OPTION_NAME;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE_OPTION_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION</B></TD>
select  
'<TR><TD>'||t.PROFILE_OPTION_ID||'</TD>'||chr(10)|| 
'<TD>'||t.PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||z.USER_PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||v.PROFILE_OPTION_VALUE||'</TD>'||chr(10)|| 
'<TD>'||z.DESCRIPTION||'</TD></TR>'
from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z
where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)
and (v.level_id = 10001)
and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)
and (t.PROFILE_OPTION_NAME in ('CONC_GSM_ENABLED','WF_VALIDATE_NTF_ACCESS','GUEST_USER_PWD','AFLOG_ENABLED','AFLOG_FILENAME','AFLOG_LEVEL','AFLOG_BUFFER_MODE','AFLOG_MODULE','FND_FWK_COMPATIBILITY_MODE',
'FND_VALIDATION_LEVEL','FND_MIGRATED_TO_JRAD','AMPOOL_ENABLED',
'FND_NTF_REASSIGN_MODE','WF_ROUTE_RULE_ALLOW_ALL'))
order by z.USER_PROFILE_OPTION_NAME;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

begin

 select v.PROFILE_OPTION_VALUE into :gsm 
   from fnd_profile_option_values v, fnd_profile_options p
  where v.PROFILE_OPTION_ID = p.PROFILE_OPTION_ID
    and p.PROFILE_OPTION_NAME = 'CONC_GSM_ENABLED'
    and sysdate BETWEEN p.start_date_active 
    and NVL(p.end_date_active, sysdate);

if (:gsm = 'Y') then

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: Profile "Concurrent:GSM Enabled" is enabled as expected.</B><BR>');
    dbms_output.put_line('The profile "Concurrent:GSM Enabled" is currently set to Y to allow GSM to enable running workflows.<BR>'); 
    dbms_output.put_line('This is expected as GSM must be enabled in order to process workflow.<BR>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 1191400.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	
  elsif (:gsm = 'N') then

    dbms_output.put_line('<table border="1" name="Error" cellpadding="10" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Error<BR>');
    dbms_output.put_line('The EBS profile "Concurrent:GSM Enabled" is not enabled.</B><BR>');
    dbms_output.put_line('<B>Action</B><BR>');
    dbms_output.put_line('Please enable profile "Concurrent:GSM Enabled" to Y to allow GSM to enable running workflows.<BR>'); 
    dbms_output.put_line('GSM must be enabled to process workflow.<BR>');
    dbms_output.put_line('Once GSM has started, verify Workflow Services started via OAM.<BR>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 1191400.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> It is unclear what EBS profile "Concurrent:GSM Enabled" is set to.');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 1191400.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

end if;
 
end;
/

REM
REM ******* Workflow Profile Settings *******
REM

prompt <script type="text/javascript">    function displayRows2sql5(){var row = document.getElementById("s2sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfprofile"></a>
prompt     <B>Workflow Profile Settings</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="85">
prompt       <blockquote><p align="left">
prompt          select t.PROFILE_OPTION_ID, t.PROFILE_OPTION_NAME, z.USER_PROFILE_OPTION_NAME,<br>
prompt          nvl(v.PROFILE_OPTION_VALUE,'NOT SET - Replace with specific Web Server URL (non-virtual) if using load balancers')<br>
prompt          from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z<br>
prompt          where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)<br>
prompt          and ((v.level_id = 10001) or (v.level_id is null))<br>
prompt          and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)<br>                
prompt          and (t.PROFILE_OPTION_NAME in ('APPS_FRAMEWORK_AGENT','WF_MAIL_WEB_AGENT'));</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE_OPTION_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
select  
'<TR><TD>'||t.PROFILE_OPTION_ID||'</TD>'||chr(10)|| 
'<TD>'||t.PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||z.USER_PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||nvl(v.PROFILE_OPTION_VALUE,'NOT SET - Replace with specific Web Server URL (non-virtual) if using load balancers')||'</TD></TR>'
from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z
where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)
and ((v.level_id = 10001) or (v.level_id is null))
and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)
and (t.PROFILE_OPTION_NAME in ('APPS_FRAMEWORK_AGENT','WF_MAIL_WEB_AGENT'));
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Verify Error Messages *******
REM

prompt <script type="text/javascript">    function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv124"></a>
prompt     <B>Verify Error Messages</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="165">
prompt       <blockquote><p align="left">
prompt          select n.message_type, n.MESSAGE_NAME, nvl(to_char(n.end_date, 'YYYY'),'OPEN') OPENED,<br>
prompt          -- nvl(to_char(n.end_date, 'YYYY-MM'),'OPEN') OPENED, <br>
prompt          n.STATUS, n.recipient_role, r.STATUS, r.ORIG_SYSTEM, r.notification_preference NTF_PREF,<br>
prompt          r.email_address, count(n.notification_id) COUNT<br>
prompt          from wf_notifications n, wf_roles r<br>
prompt          where n.recipient_role = r.name<br>
prompt          and n.message_type like '%ERROR%'<br>
prompt          group by n.message_type, n.MESSAGE_NAME, nvl(to_char(n.end_date, 'YYYY'),'OPEN'), n.STATUS,<br> 
prompt          n.recipient_role, r.STATUS, r.ORIG_SYSTEM, r.notification_preference, r.email_address<br>
prompt          order by nvl(to_char(n.end_date, 'YYYY'),'OPEN'), count(n.notification_id) desc, n.recipient_role;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NTF_STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RECIPIENT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ORIG_SYSTEM</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EMAIL PREF</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EMAIL ADDRESS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||n.message_type||'</TD>'||chr(10)|| 
'<TD>'||n.MESSAGE_NAME||'</TD>'||chr(10)||
'<TD>'||nvl(to_char(n.end_date, 'YYYY'),'OPEN')||'</TD>'||chr(10)|| 
'<TD>'||n.STATUS||'</TD>'||chr(10)||
'<TD>'||n.recipient_role||'</TD>'||chr(10)|| 
'<TD>'||r.STATUS||'</TD>'||chr(10)||
'<TD>'||r.ORIG_SYSTEM||'</TD>'||chr(10)||
'<TD>'||r.notification_preference||'</TD>'||chr(10)|| 
'<TD>'||r.email_address||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(n.notification_id),'999,999,999,999')||'</div></TD></TR>'
from wf_notifications n, wf_roles r
where n.recipient_role = r.name
and n.message_type like '%ERROR%'
group by n.message_type, n.MESSAGE_NAME, nvl(to_char(n.end_date, 'YYYY'),'OPEN'), n.STATUS, 
n.recipient_role, r.STATUS, r.ORIG_SYSTEM, r.notification_preference, r.email_address
order by nvl(to_char(n.end_date, 'YYYY'),'OPEN'), count(n.notification_id) desc, n.recipient_role;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

begin

       dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning</B><BR>');
       dbms_output.put_line('There are ' || to_char(:total_error,'999,999,999,999') || ' Error Notifications, ');
       dbms_output.put_line('where ' || to_char(:open_error,'999,999,999,999') || ' (' || (round(:open_error/:total_error,2)*100) || '%) are still OPEN, and '|| to_char(:closed_error,'999,999,999,999') || ' are closed.<BR><BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR><BR>');

end;
/


REM
REM ******* Verify #STUCK Activities *******
REM

prompt <script type="text/javascript">    function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfstuck"></a>
prompt     <B>Verify #STUCK Activities</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="85">
prompt       <blockquote><p align="left">
prompt          SELECT p.PROCESS_ITEM_TYPE, p.ACTIVITY_NAME, s.ACTIVITY_STATUS,<br>
prompt                 s.ACTIVITY_RESULT_CODE, count(s.ITEM_KEY)<br>
prompt            FROM wf_item_activity_statuses s,wf_process_activities p<br>
prompt           WHERE p.instance_id = s.process_activity<br>
prompt             AND activity_status = 'ERROR'<br>
prompt             AND activity_result_code = '#STUCK'<br>
prompt           GROUP BY p.PROCESS_ITEM_TYPE, p.ACTIVITY_NAME, s.ACTIVITY_STATUS, s.ACTIVITY_RESULT_CODE<br>
prompt           ORDER BY p.PROCESS_ITEM_TYPE, count(s.ITEM_KEY) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_RESULT_CODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||p.PROCESS_ITEM_TYPE||'</TD>'||chr(10)|| 
'<TD>'||p.ACTIVITY_NAME||'</TD>'||chr(10)|| 
'<TD>'||s.ACTIVITY_STATUS||'</TD>'||chr(10)|| 
'<TD>'||s.ACTIVITY_RESULT_CODE||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(s.ITEM_KEY),'999,999,999,999')||'</div></TD></TR>'
  FROM wf_item_activity_statuses s,wf_process_activities p
WHERE p.instance_id = s.process_activity
   and activity_status = 'ERROR'
   AND activity_result_code = '#STUCK'
 group by p.PROCESS_ITEM_TYPE, p.ACTIVITY_NAME, s.ACTIVITY_STATUS, s.ACTIVITY_RESULT_CODE
 order by p.PROCESS_ITEM_TYPE, count(s.ITEM_KEY) desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td>
prompt <B>Note: Clarification on STUCK Activities:</B><BR><BR>
prompt A process is identified as stuck when it has a status of ACTIVE, but cannot progress any further. 
prompt Stuck activities do not have a clear pattern as cause but mainly they are caused by flaws in the WF definition like improper transition definitions.
prompt For example, a process could become stuck in the following situations:<BR>
prompt - A thread within a process leads to an activity that is not defined as an End activity
prompt but has no other activity modeled after it, and no other activity is active.<BR>
prompt - A process with only one thread loops back, but the pivot activity of the loop has
prompt the On Revisit property set to Ignore.<BR>
prompt - An activity returns a result for which no eligible transition exists. <BR>
prompt For instance, if the function for a function activity returns an unexpected result value, and no default transition is modeled after that activity, the process cannot continue.  
prompt <BR><BR>
prompt <B>COMMON MISCONCEPTION :</B> Running the Worklfow Background Process for STUCK activities fixes STUCK workflows.<BR>Not true.<BR>
prompt Running the concurrent request "Workflow Background Process" with Stuck=Yes only identifies these activities that cannot progress.
prompt The workflow engine changes the status of a stuck process to ERROR:#STUCK and executes the error process defined for it.
prompt This error process sends a notification to SYSADMIN to alert them of this issue, which they need to resolve.
prompt The query to determine these activities is very expensive as it joins 3 WF runtime tables and one WF design table. 
prompt This is why the Workflow Background Engine should run seperately when load is not high and only once a week or month.<BR> 
prompt <p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=453137.1" 
prompt target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>
prompt </td></tr></tbody></table><BR><BR>



REM
REM ******* Totals for Notification Preferences *******
REM

prompt <script type="text/javascript">    function displayRows2sql8a(){var row = document.getElementById("s2sql8a");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv125"></a>
prompt     <B>Totals for Notification Preferences</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql8a()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql8a" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="50">
prompt       <blockquote><p align="left">
prompt          select notification_preference, count(name)<br>
prompt          from wf_local_roles<br>
prompt          group by notification_preference;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NOTIFICATION PREFERENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||notification_preference||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(name),'999,999,999,999')||'</div></TD></TR>'
from wf_local_roles
group by notification_preference;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Totals for Notification Preferences *******
REM

prompt <script type="text/javascript">    function displayRows2sql8b(){var row = document.getElementById("s2sql8b");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv125"></a>
prompt     <B>Totals for User Notification Preferences</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql8b()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql8b" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="50">
prompt       <blockquote><p align="left">
prompt          select notification_preference, count(name)<br>
prompt          from wf_local_roles<br>
prompt          where name not like 'FND_RESP%'<br>
prompt          group by notification_preference;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NOTIFICATION PREFERENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||notification_preference||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(name),'999,999,999,999')||'</div></TD></TR>'
from wf_local_roles
where name not like 'FND_RESP%'
group by notification_preference;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Check the Status of Workflow Services *******
REM

prompt <script type="text/javascript">    function displayRows2sql9(){var row = document.getElementById("s2sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv126"></a>
prompt     <B>Check the Status of Workflow Services</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql9" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="11" height="130">
prompt       <blockquote><p align="left">
prompt          select fcq.USER_CONCURRENT_QUEUE_NAME, fsc.COMPONENT_NAME,<br>
prompt          DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID), fcq.MAX_PROCESSES,<br>
prompt          fcq.RUNNING_PROCESSES, v.PARAMETER_VALUE, fcq.ENABLED_FLAG, fsc.COMPONENT_ID,<br>
prompt          fsc.CORRELATION_ID, fsc.STARTUP_MODE, fsc.COMPONENT_STATUS<br>
prompt          from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, <br>
prompt          APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v<br>
prompt          where v.COMPONENT_ID=fsc.COMPONENT_ID<br>
prompt          and fcq.MANAGER_TYPE = fcs.SERVICE_ID <br>
prompt          and fcs.SERVICE_HANDLE = 'FNDCPGSC' <br>
prompt          and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)<br>
prompt          and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+)<br> 
prompt          and fcq.application_id = fcp.queue_application_id(+) <br>
prompt          and fcp.process_status_code(+) = 'A'<br>
prompt          and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'<br>
prompt          order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONTAINER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROCID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TARGET</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTUAL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>#THREADS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ENABLED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CORRELATION_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTUP_MODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
select  
'<TR><TD>'||fcq.USER_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID)||'</TD>'||chr(10)|| 
'<TD>'||fcq.MAX_PROCESSES||'</TD>'||chr(10)|| 
'<TD>'||fcq.RUNNING_PROCESSES||'</TD>'||chr(10)|| 
'<TD>'||v.PARAMETER_VALUE||'</TD>'||chr(10)|| 
'<TD>'||fcq.ENABLED_FLAG||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.CORRELATION_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.STARTUP_MODE||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_STATUS||'</TD></TR>'
from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
where v.COMPONENT_ID=fsc.COMPONENT_ID
and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
and fcq.application_id = fcp.queue_application_id(+) 
and fcp.process_status_code(+) = 'A'
and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>Note: For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=760386.1" target="_blank">
prompt Note 760386.1</a> - How to enable Bulk Notification Response Processing for Workflow in 11i and R12<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>



REM **************************************************************************************** 
REM *******                   Section 3 : Workflow Footprint                         *******
REM ****************************************************************************************

prompt <a name="section3"></a><B><font size="+2">Workflow Footprint</font></B><BR><BR>



REM
REM ******* Check the Actual Table Size for Workflow  *******
REM

begin

	select round((blocks*8192/1024/1024),2) into :wfcmtphy
	from dba_tables 
	where table_name = 'WF_COMMENTS'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfdigphy
	from dba_tables 
	where table_name = 'WF_DIG_SIGS'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfitmphy
	from dba_tables 
	where table_name = 'WF_ITEMS'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wiasphy
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wiashphy
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES_H'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfattrphy
	from dba_tables 
	where table_name = 'WF_ITEM_ATTRIBUTE_VALUES'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfntfphy
	from dba_tables 
	where table_name = 'WF_NOTIFICATIONS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfcmtphy2
	from dba_tables 
	where table_name = 'WF_COMMENTS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfdigphy2
	from dba_tables 
	where table_name = 'WF_DIG_SIGS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfitmphy2
	from dba_tables 
	where table_name = 'WF_ITEMS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wiasphy2
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wiashphy2
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES_H'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfattrphy2
	from dba_tables 
	where table_name = 'WF_ITEM_ATTRIBUTE_VALUES'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfntfphy2
	from dba_tables 
	where table_name = 'WF_NOTIFICATIONS'
	and owner = 'APPLSYS';

end;
/

prompt <img src="http://chart.apis.google.com/chart?chxl=0:|WF_NOTIFICATIONS|WF_ITEM_ATTRIBUTE_VALUES|WF_ITEM_ACTIVITY_STATUSES_H|WF_ITEM_ACTIVITY_STATUSES|WF_ITEMS|WF_DIG_SIGS|WF_COMMENTS\&chdl=Physical_Data|Logical_Data\&chxs=0,676767,11.5,0,lt,676767\&chxtc=0,5\&chxt=y,x\&chds=a\&chs=600x425\&chma=0,0,0,5\&chbh=20,5,10\&cht=bhg
begin
  select '\&chd=t:'||:wfcmtphy||','||:wfdigphy||','||:wfitmphy||','||:wiasphy||','||:wiashphy||','||:wfattrphy||','||:wfntfphy||'\|'||:wfdigphy2||','||:wfitmphy2||','||:wiasphy2||','||:wiashphy2||','||:wfattrphy2||','||:wfntfphy2 into :test from dual;
  dbms_output.put('\&chco=A2C180,3D7930');
  dbms_output.put(''||:test||'');
  dbms_output.put('\&chtt=Workflow+Runtime+Data+Tables" />');
  dbms_output.put_line('<br><br>');
end;
/

begin

select sum(LOGICAL_TOTAL) into :logical_totals  from (
select   round(blocks*8192/1024/1024) as "LOGICAL_TOTAL"
		from dba_tables 
                where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
                and owner = 'APPLSYS' );

select sum(PHYSICAL_TOTAL) into :physical_totals  from ( 
select round((num_rows*AVG_ROW_LEN)/1024/1024) as "PHYSICAL_TOTAL"
		from dba_tables 
                where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
                and owner = 'APPLSYS' );

select sum(TOTAL_DIFF) into :diff_totals  from ( 
select round((blocks*8192/1024/1024)-(num_rows*AVG_ROW_LEN)/1024/1024) as "TOTAL_DIFF" 
		from dba_tables 
                where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
                and owner = 'APPLSYS' ); 

select ROUND(:diff_totals/:logical_totals,2)*100 into :rate from dual;
              
select sum(COUNT) into :ninety_totals from ( 
select  
to_char(wi.begin_date, 'YYYY') BEGAN,
to_char(count(wi.item_key)) COUNT
from wf_items wi, wf_item_types wit, wf_item_types_tl witt  
where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  
and wit.NAME=witt.NAME and witt.LANGUAGE = 'US' and wi.begin_date < sysdate-90  
group by to_char(wi.begin_date, 'YYYY') 
order by to_char(wi.begin_date, 'YYYY'));

    if (:rate>29) then

        dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	dbms_output.put_line('<tbody><tr><td> ');
	dbms_output.put_line('<B>Warning</B><BR>');
        dbms_output.put_line('The Workflow Runtime Tables logical space which is used for all full-table scans is ' || :rate || '% greater than the physical or actual tablespace being used.<BR>');
        dbms_output.put_line('It is recommended to have a DBA resize these tables to reset the HighWater Mark.<BR>');
        dbms_output.put_line('There are several ways to coalesce, drop, recreate these workflow runtime tables.<BR><BR> ');
	dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=388672.1" target="_blank">Note 388672.1</a> - How to Reorganize Workflow Tables, for more details on ways to do this.');
	dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    else

	dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
	dbms_output.put_line('<tbody><tr><td> ');
	dbms_output.put_line('<B>Attention</B><BR>');
	dbms_output.put_line('The Workflow Runtime Tables logical space which is used for all full-table scans is only at ' || :rate || '% greater than the physical or actual tablespace being used.<BR>');
        dbms_output.put_line('It is recommended at levels above 30% to resize these tables to maintain or reset the table HighWater Mark for optimum performance.<br>  Please have a DBA monitor these tables going forward to ensure they are being maintained at optimal levels.<BR><BR>');
        dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=388672.1" target="_blank">Note 388672.1</a> - How to Reorganize Workflow Tables, on how to manage workflow runtime tablespaces for optimal performance.<BR>');
	dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	
    end if;
end;
/

prompt <script type="text/javascript">    function displayRows3sql1(){var row = document.getElementById("s3sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Volume of Workflow Runtime Data Tables (in MegaBytes)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="130">
prompt       <blockquote><p align="left">
prompt          select table_name, <br>
prompt                   round(blocks*8192/1024/1024) "MB Logical", <br>
prompt                   round((num_rows*AVG_ROW_LEN)/1024/1024) "MB Physical", <br>
prompt                   round((blocks*8192/1024/1024)  - <br>
prompt                  (num_rows*AVG_ROW_LEN)/1024/1024) "MB Difference"<br>
prompt          from dba_tables <br>
prompt          where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES',<br>
prompt               'WF_ITEM_ACTIVITY_STATUSES_H','WF_ITEM_ATTRIBUTE_VALUES',<br>
prompt               'WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')<br>
prompt          and owner = 'APPLSYS'<br>
prompt          order by table_name;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Workflow Table Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Logical Table Size</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Physical Table Data</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Difference</B></TD></TR>
select  
'<TR><TD>'||table_name||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(round(blocks*8192/1024/1024),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(round((num_rows*AVG_ROW_LEN)/1024/1024),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(round((blocks*8192/1024/1024)-(num_rows*AVG_ROW_LEN)/1024/1024),'999,999,999,999')||'</div></TD></TR>'
from dba_tables
where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                     'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
and owner='APPLSYS'
order by table_name;
prompt <TR><TD BGCOLOR=#DEE6EF align="right"><font face="Calibri"><B>TOTALS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :logical_totals
prompt </TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :physical_totals
prompt </TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :diff_totals
prompt </TD></TD></TR>
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Verify Closed and Purgeable TEMP Items *******
REM


prompt <script type="text/javascript">    function displayRows3sql2(){var row = document.getElementById("s3sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv132"></a>
prompt     <B>Verify Closed and Purgeable TEMP Items</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt          select COUNT(A.ITEM_KEY), WF_PURGE.GETPURGEABLECOUNT(A.ITEM_TYPE),<br>
prompt          A.ITEM_TYPE, b.DISPLAY_NAME, b.PERSISTENCE_DAYS<br>
prompt          FROM  WF_ITEMS A, WF_ITEM_TYPES_VL B<br>
prompt          WHERE  A.ITEM_TYPE = B.NAME<br>
prompt          and b.PERSISTENCE_TYPE = 'TEMP'<br>
prompt          and a.END_DATE is not null<br>
prompt          GROUP BY A.ITEM_TYPE, b.DISPLAY_NAME, b.PERSISTENCE_DAYS<br>
prompt          order by 1 desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED ITEMS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PURGEABLE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE DAYS</B></TD>
select  
'<TR><TD><div align="right">'||to_char(COUNT(A.ITEM_KEY),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD><div align="left">'||to_char(WF_PURGE.GETPURGEABLECOUNT(A.ITEM_TYPE),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD>'||A.ITEM_TYPE||'</TD>'||chr(10)|| 
'<TD>'||b.DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD>'||b.PERSISTENCE_DAYS||'</TD></TR>'
FROM  WF_ITEMS A, WF_ITEM_TYPES_VL B       
WHERE  A.ITEM_TYPE = B.NAME       
and b.PERSISTENCE_TYPE = 'TEMP' 
and a.END_DATE is not null       
GROUP BY A.ITEM_TYPE, b.DISPLAY_NAME, b.PERSISTENCE_DAYS     
order by 1 desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td> 
prompt If there are closed items that are not purgeable, then it may be because an associated child process is still open.<BR>
prompt To verify all the workflow processes (item_keys) that are associated to a single workflow, run the bde_wf_process_tree.sql<BR>
prompt script found in <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1378954.1" target="_blank">Document 1378954.1</a> - bde_wf_process_tree.sql - For analyzing the Root Parent, Children, Grandchildren Associations of a Single Workflow Process<BR>
prompt </p></td></tr></tbody></table><BR>

prompt <table border="1" name="Notebox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td> 
prompt Post 11i.ATG.rup4+ are 3 new Concurrent Programs designed to gather Workflow Statistics that is displayed in Oracle Manager Workflow Metrics screens.<BR>
prompt These Concurrent Programs are set to run automatically every 24 hrs by default to refresh these workflow runtime table statistics.<BR>
prompt <B> - Workflow Agent Activity Statistics (FNDWFAASTATCC)</B> - Gathers statistics for the Agent Activity graph in the Workflow System status page and for the agent activity list in the Agent Activity page.<BR>
prompt <B> - Workflow Mailer Statistics (FNDWFMLRSTATCC)</B> - Gathers statistics for the throughput graph in the Notification Mailer Throughput page.<BR>
prompt <B> - Workflow Work Items Statistics (FNDWFWITSTATCC)</B> - Gathers statistics for the Work Items graph in the Workflow System status page, for 
prompt the Completed Work Items list in the Workflow Purge page, and for the work item lists in the Active Work Items, Deferred Work Items, Suspended Work Items, and Errored Work Items pages.<BR>
prompt If the list above does not match the list below, then please run these Workflow Statistics requests again.<BR>
prompt </p></td></tr></tbody></table><BR><BR>


REM
REM ******* WF_ITEM_TYPES *******
REM

prompt <script type="text/javascript">    function displayRows3sql3(){var row = document.getElementById("s3sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfsummry"></a>
prompt     <B>SUMMARY Of Workflow Processes By Item Type</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="150">
prompt       <blockquote><p align="left">
prompt          select NUM_ACTIVE, NUM_COMPLETE, NUM_PURGEABLE, WIT.NAME, DISPLAY_NAME, <br>
prompt          PERSISTENCE_TYPE, PERSISTENCE_DAYS, NUM_ERROR, NUM_DEFER, NUM_SUSPEND<br>
prompt          from wf_item_types wit, wf_item_types_tl wtl<br>
prompt          where wit.name like ('%')<br>
prompt          AND wtl.name = wit.name<br>
prompt          AND wtl.language = userenv('LANG')<br>
prompt          AND wit.NUM_ACTIVE is not NULL<br>
prompt          AND wit.NUM_ACTIVE <>0 <br>
prompt          order by PERSISTENCE_TYPE, NUM_COMPLETE desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PURGEABLE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_DAYS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ERRORED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DEFERRED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SUSPENDED</B></TD>
select  
'<TR><TD><div align="right">'||to_char(NUM_ACTIVE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_COMPLETE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||to_char(NUM_PURGEABLE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||WIT.NAME||'</div></TD>'||chr(10)||
'<TD><div align="left">'||DISPLAY_NAME||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_TYPE||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_DAYS||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_ERROR,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_DEFER,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_SUSPEND,'999,999,999,999')||'</div></TD></TR>'
from wf_item_types wit, wf_item_types_tl wtl
where wit.name like ('%')
AND wtl.name = wit.name
AND wtl.language = userenv('LANG')
AND wit.NUM_ACTIVE is not NULL
AND wit.NUM_ACTIVE <>0 
order by PERSISTENCE_TYPE, NUM_COMPLETE desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Check the Volume of Open and Closed Items Annually *******
REM

prompt <script type="text/javascript">    function displayRows3sql4(){var row = document.getElementById("s3sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv133"></a>
prompt     <B>Check the Volume of Open and Closed Items Annually</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="135">
prompt       <blockquote><p align="left">
prompt          select wi.item_type, witt.DISPLAY_NAME, wit.PERSISTENCE_TYPE,<br>
prompt          nvl(wit.PERSISTENCE_DAYS,0), nvl(to_char(wi.end_date, 'YYYY'),'OPEN'), count(wi.item_key)<br>
prompt          from wf_items wi, wf_item_types wit, wf_item_types_tl witt where wi.ITEM_TYPE=wit.NAME <br>
prompt          and wit.NAME=witt.NAME and witt.LANGUAGE = 'US'<br>
prompt          group by wi.item_type, witt.DISPLAY_NAME, wit.PERSISTENCE_TYPE, <br>
prompt          wit.PERSISTENCE_DAYS, to_char(wi.end_date, 'YYYY')<br>
prompt          order by wit.PERSISTENCE_TYPE asc, nvl(to_char(wi.end_date, 'YYYY'),'OPEN') asc, count(wi.item_key) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>P_DAYS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
select  
'<TR><TD>'||wi.item_type||'</TD>'||chr(10)|| 
'<TD>'||witt.DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD>'||wit.PERSISTENCE_TYPE||'</TD>'||chr(10)|| 
'<TD>'||nvl(wit.PERSISTENCE_DAYS,0)||'</TD>'||chr(10)||
'<TD>'||nvl(to_char(wi.end_date, 'YYYY'),'OPEN')||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(wi.item_key),'999,999,999,999')||'</div></TD></TR>'
from wf_items wi, wf_item_types wit, wf_item_types_tl witt where wi.ITEM_TYPE=wit.NAME and wit.NAME=witt.NAME and witt.LANGUAGE = 'US'
group by wi.item_type, witt.DISPLAY_NAME, wit.PERSISTENCE_TYPE, 
wit.PERSISTENCE_DAYS, to_char(wi.end_date, 'YYYY')
order by wit.PERSISTENCE_TYPE asc, nvl(to_char(wi.end_date, 'YYYY'),'OPEN') asc, count(wi.item_key) desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Average Volume of Opened Items in the past 6 Months, Monthly, & Daily *******
REM

prompt <script type="text/javascript">    function displayRows3sql5(){var row = document.getElementById("s3sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv134"></a>
prompt     <B>Average Volume of Opened Items in the past 6 Months, Monthly, and Daily</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="85">
prompt       <blockquote><p align="left">
prompt          select item_type, count(item_key), <br>
prompt          to_char(round(count(item_key)/6,0),'999,999,999,999'), to_char(round(count(item_key)/180,0),'999,999,999,999')<br>
prompt          from wf_items<br>
prompt          where begin_date > sysdate-180<br>
prompt          group by item_type<br>
prompt          order by count(item_key) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>6_MONTHS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MONTHLY</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DAILY</B></TD> 
select  
'<TR><TD>'||item_type||'</TD>'||chr(10)|| 
'<TD>'||to_char(count(item_key),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD>'||to_char(round(count(item_key)/6,0),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD>'||to_char(round(count(item_key)/180,0),'999,999,999,999')||'</TD></TR>'
from wf_items
where begin_date > sysdate-180
group by item_type
order by count(item_key) desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Opened Over 90 Days Ago *******
REM

prompt <script type="text/javascript">    function displayRows3sql6(){var row = document.getElementById("s3sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv135"></a>
prompt     <B>Total OPEN Items Started Over 90 Days Ago</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="55">
prompt       <blockquote><p align="left">
prompt          select to_char(wi.begin_date, 'YYYY'), count(wi.item_key)<br>
prompt          from wf_items wi, wf_item_types wit, wf_item_types_tl witt<br>  
prompt          where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  <br>
prompt          and wit.NAME=witt.NAME and witt.LANGUAGE = 'US' and wi.begin_date < sysdate-90  <br>
prompt          group by to_char(wi.begin_date, 'YYYY') <br>
prompt          order by to_char(wi.begin_date, 'YYYY');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OPENED</B></font></TD> 
prompt <TD BGCOLOR=#DEE6EF><div align="right"><font face="Calibri"><B>COUNT</B></font></div></TD>
select  
'<TR><TD>'||to_char(wi.begin_date, 'YYYY')||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(wi.item_key),'999,999,999,999')||'</div></TD></TR>'
from wf_items wi, wf_item_types wit, wf_item_types_tl witt  
where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  
and wit.NAME=witt.NAME and witt.LANGUAGE = 'US' and wi.begin_date < sysdate-90  
group by to_char(wi.begin_date, 'YYYY') 
order by to_char(wi.begin_date, 'YYYY');
prompt <TR><TD BGCOLOR=#DEE6EF align="right"><font face="Calibri"><B>TOTALS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :ninety_totals
prompt </TD></TR>
prompt </TABLE><P><P> 

begin

select sum(COUNT) into :ninety_cnt from (  
select to_char(wi.begin_date, 'YYYY') TOTAL_OPENED, count(wi.item_key) COUNT  
from wf_items wi, wf_item_types wit, wf_item_types_tl witt  
where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  
and wit.NAME=witt.NAME and witt.LANGUAGE = 'US' and wi.begin_date < (sysdate-90)
group by to_char(wi.begin_date, 'YYYY') );

    if (:ninety_cnt = 0) then

       dbms_output.put_line('There are no OPEN items that were started over 90 days ago.<BR>');
      
      else if (:ninety_cnt > 0) then

       dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning</B><BR>');
       dbms_output.put_line('There are ' || to_char(:ninety_cnt,'999,999,999,999') || ' OPEN item_types in WF_ITEMS table that were started over 90 days ago.<BR>');
       dbms_output.put_line('Remember that once a Workflow is closed, its runtime data which is stored in Workflow Runtime Tables (WF_*) becomes obsolete.<BR>');
       dbms_output.put_line('All pertinent information is stored in the functional tables (FND_*, PO_*, AP_*, HR_*, OE_*, etc), like who approved what, for how much, for whom, etc...)');
       dbms_output.put_line('and that each single row in WF_ITEMS can represent 100s or 1000s of rows in the subsequent Workflow Runtime tables, ');
       dbms_output.put_line('so it is important to close these open workflows once completed so they can be purged.<BR>');
       dbms_output.put_line('<B>Action</B><BR>');
       dbms_output.put_line('Ask the Question: How long should these workflows take to complete?<BR>');
       dbms_output.put_line('30 Days... 60 Days... 6 months... 1 Year?<BR>');
       dbms_output.put_line('There may be valid business reasons why these OPEN items still exist after 90 days so that should be taken into consideration.<BR>');
       dbms_output.put_line('However, if this is not the case, then once a workflow item is closed then all the runtime data associated to completing this workflow is now obsolete and should be purged to make room for new workflows.<BR>');
       dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=144806.1" target="_blank">Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data ');
       dbms_output.put_line('for details on how to drill down to discover the reason why these OLD items are still open, and ways to close them so they can be purged.');
       dbms_output.put_line('</p></td></tr></tbody></table><BR><BR>');
 
      end if;   
    end if;  
end;
/

prompt <table border="1" name="Notebox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td> 
prompt It is normal for Workflow to use WAITS and other looping acitivities to process delayed responses and other criteria.<BR>
prompt Each revisit of a node replaces the previous data with the current activities status and stores the old activity information into a activities history table.<BR>
prompt Looking at this history table (WF_ITEM_ACTIVITY_STATUSES_H) can help to identify possible long running workflows that appear to be stuck in a loop over a long time, or a poorly designed workflow that is looping excessively and can cause performance issues.<BR>
prompt </p></td></tr></tbody></table><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Check Top 30 Large Item Activity Status History Items *******
REM

prompt <script type="text/javascript">    function displayRows3sql7(){var row = document.getElementById("s3sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv136"></a>
prompt     <B>Check Top 30 Large Item Activity Status History Items</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="125">
prompt       <blockquote><p align="left">
prompt          SELECT sta.item_type, sta.item_key, COUNT(*),<br>
prompt          TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD'), wfi.user_key<br>
prompt          FROM wf_item_activity_statuses_h sta, <br>
prompt          wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' <br>
prompt          GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), <br>
prompt          TO_CHAR(wfi.end_date, 'YYYY-MM-DD') <br>
prompt          HAVING COUNT(*) > 500 <br>
prompt          ORDER BY COUNT(*) DESC);</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_KEY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">BEGIN_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">END_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">DESCRIPTION</B></TD>
SELECT * FROM (SELECT  
'<TR><TD>'||sta.item_type||'</TD>'||chr(10)|| 
'<TD>'||sta.item_key||'</TD>'||chr(10)|| 
'<TD>'||to_char(COUNT(*),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.begin_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.end_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||wfi.user_key||'</TD></TR>'
FROM wf_item_activity_statuses_h sta, 
wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 500 
ORDER BY COUNT(*) DESC) 
WHERE ROWNUM < 31;
prompt</TABLE><P><P>


begin

SELECT count(*) into :hasrows FROM (SELECT sta.item_type 
FROM wf_item_activity_statuses_h sta, 
wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 500 
ORDER BY COUNT(*) DESC);

if (:hasrows>0) then

	dbms_output.put_line('<table border="1" name="Success" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	dbms_output.put_line('<tbody><tr><td> ');
	dbms_output.put_line('Rows are found in the HISTORY table');
	dbms_output.put_line('</p></td></tr></tbody></table><BR>');     

	SELECT * into :hist_item FROM (SELECT sta.item_type 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	select * into :hist_key from (SELECT sta.item_key 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_end  
	FROM (SELECT end_date from wf_items where item_type = :hist_item and item_key = :hist_key);

	SELECT * into :hist_cnt FROM (SELECT count(sta.item_key) 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_begin
	FROM (SELECT to_char(begin_date, 'Mon DD, YYYY') from  wf_items where item_type = :hist_item and item_key = :hist_key);

	select * into :hist_recent 
	FROM (SELECT to_char(max(begin_date),'Mon DD, YYYY') from wf_item_activity_statuses_h
	where item_type = :hist_item and item_key = :hist_key);

	select sysdate into :sysdate from dual;

	select * into :hist_days
	from (select round(sysdate-begin_date,0) from wf_items where item_type = :hist_item and item_key = :hist_key);

	select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;

	    if (:hist_end is null) then 

	       dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('Currently, the largest single activity found in the history table is for <br>     item_type : ' || :hist_item || '<br>     item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started back on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');       

	   else

	       dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single activity found in the history table is for Item_Type ' || :hist_item || ' and item_key ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || '.<BR>');

	    end if;       

	       dbms_output.put_line('So far this one activity for item_type ' || :hist_item || ' and item_key ' || :hist_key || ' has looped ' || to_char(:hist_cnt,'999,999,999,999') || ' times since it started in ' || :hist_begin || '.<BR>');
	       dbms_output.put_line('<B>Action</B><BR>');
	       dbms_output.put_line('This is a good place to start, as this single activity has been looping for ' || to_char(:hist_days,'999,999') || ' days, which is about ' || to_char(:hist_daily,'999,999') || ' times a day.<BR>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=144806.1" target="_blank">');
	       dbms_output.put_line('Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data on how to drill down and discover how to purge this workflow data.<br>');
	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');


elsif (:hasrows=0) then 

       dbms_output.put_line('<table border="1" name="GoodJob" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Well Done !!</B><BR><BR>');
       dbms_output.put_line('There are NO ROWS found in the HISTORY table (wf_item_activity_statuses_h) that have over 500 rows associated to the same item_key.<BR>');
       dbms_output.put_line('This is a good result, which means there is no major looping issues at this time.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

end if;
end;
/


prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM *******                   Section 4 : Workflow Concurrent Programs               *******
REM ****************************************************************************************

prompt <a name="section4"></a><B><font size="+2">Workflow Concurrent Programs</font></B><BR><BR>

REM
REM ******* Verify Concurrent Programs Scheduled to Run *******
REM

prompt <p>Oracle Workflow requires several Concurrent Programs to be run to process, progress, cleanup, and purge workflow related information.<BR>
prompt    This section verifies these required Workflow Concurrent Programs are scheduled as recommended.  <BR>
prompt    Note: This section is only looking at the scheduled jobs in FND_CONCURRENT_REQUESTS table.  <BR>
prompt    Jobs scheduled using other tools (DBMS_JOBS, CONSUB, or PL/SQL, etc) are not reflected here, so keep this in mind.<br>
prompt    The following table displays Concurrent requests that HAVE run, regardless of how they were scheduled (DBMS_JOBS, CONSUB, or PL/SQL, etc)<BR>
prompt    Keep in mind how often the Concurrent Requests Data is being purged.</p>

prompt <script type="text/javascript">    function displayRows4sql1(){var row = document.getElementById("s4sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv141"></a>
prompt     <B>Verify Workflow Concurrent Programs Scheduled to Run</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="185">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, r.PHASE_CODE, r.ACTUAL_START_DATE,<br>
prompt          c.CONCURRENT_PROGRAM_NAME, p.USER_CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT, <br>
prompt          r.RESUBMIT_INTERVAL, r.RESUBMIT_INTERVAL_UNIT_CODE, r.RESUBMIT_END_DATE<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME in ('FNDWFBG','FNDWFPR','FNDWFRET','JTFRSWSN','FNDWFSYNCUR','FNDWFLSC', <br>
prompt          'FNDWFLIC','FNDWFDSURV','FNDCPPUR','FNDWFBES_CONTROL_QUEUE_CLEANUP','FNDWFAASTATCC','FNDWFMLRSTATCC','FNDWFWITSTATCC') <br>
prompt          AND p.LANGUAGE = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')<br>
prompt          order by c.CONCURRENT_PROGRAM_NAME;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUESTED_BY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>INTERNAL NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EVERY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SO_OFTEN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESUBMIT_END_DATE</B></TD>
select  
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)|| 
'<TD>'||r.PHASE_CODE||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||c.CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)||
'<TD>'||r.ARGUMENT_TEXT||'</TD>'||chr(10)|| 
'<TD>'||r.RESUBMIT_INTERVAL||'</TD>'||chr(10)||  
'<TD>'||r.RESUBMIT_INTERVAL_UNIT_CODE||'</TD>'||chr(10)||
'<TD>'||r.RESUBMIT_END_DATE||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME in ('FNDWFBG','FNDWFPR','FNDWFRET','JTFRSWSN','FNDWFSYNCUR','FNDWFLSC', 
'FNDWFLIC','FNDWFDSURV','FNDCPPUR','FNDWFBES_CONTROL_QUEUE_CLEANUP','FNDWFAASTATCC','FNDWFMLRSTATCC','FNDWFWITSTATCC') 
AND p.LANGUAGE = 'US' 
and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')
order by c.CONCURRENT_PROGRAM_NAME;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Verify Workflow Background Processes Scheduled to Run *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>The Workflow Administrator's Guide requires that there is at least one background engine that can process deferred activities, check for timed out activities, and identify stuck processes.<BR> 
prompt          At a minimum, there needs to be at least one background process that can handle both deferred and timed out activities in order to progress workflows.<BR>
prompt          However, for performance reasons Oracle recommends running three separate background engines at different intervals.<BR>
prompt          - Run a Background Process to handle only DEFERRED activities every 5 to 60 minutes.<BR>
prompt          - Run a Background Process to handle only TIMED OUT activities every 1 to 24 hours as needed.<BR>
prompt          - Run a Background Process to identify STUCK processes once a week to once a month, when the load on the system is low.<BR><BR>
prompt          Please see <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=186361.1" target="_blank">Note 186361.1</a> - Workflow Background Process Performance Troubleshooting Guide for more information</p>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>
    

prompt <script type="text/javascript">    function displayRows4sql2(){var row = document.getElementById("s4sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv142"></a>
prompt     <B>Verify Workflow Background Processes that ran</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="350">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, p.USER_CONCURRENT_PROGRAM_NAME,<br>
prompt          DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',<br>
prompt          'D','D=Cancelled','E','E=Error','G','G=Warning',<br>
prompt          'H','H=On Hold','I','I=Normal','M','M=No Manager',<br>
prompt          'P','P=Scheduled','Q','Q=Standby','R','R=Normal',<br>
prompt          'S','S=Suspended','T','T=Terminating','U','U=Disabled',<br>
prompt          'W','W=Paused','X','X=Terminated','Z','Z=Waiting'),<br>
prompt          DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running'),<br>
prompt          r.ACTUAL_START_DATE,r.ACTUAL_COMPLETION_DATE,<br>
prompt          ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2),<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||<br>
prompt          FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||<br>
prompt          ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-<br>
prompt          (FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs', <br>
prompt          r.ARGUMENT_TEXT<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME = 'FNDWFBG' <br>
prompt          AND p.LANGUAGE = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')<br>
prompt          order by r.ACTUAL_START_DATE;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_MINS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TIME_TO_RUN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD> 
select  
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)|| 
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',
'D','D=Cancelled','E','E=Error','G','G=Warning',
'H','H=On Hold','I','I=Normal','M','M=No Manager',
'P','P=Scheduled','Q','Q=Standby','R','R=Normal',
'S','S=Suspended','T','T=Terminating','U','U=Disabled',
'W','W=Paused','X','X=Terminated','Z','Z=Waiting')||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running')||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||r.ACTUAL_COMPLETION_DATE||'</TD>'||chr(10)|| 
'<TD>'||ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2)||'</TD>'||chr(10)||
'<TD>'||FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||
FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||
ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs'||'</TD>'||chr(10)|| 
'<TD>'||r.ARGUMENT_TEXT||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME = 'FNDWFBG'
AND p.LANGUAGE = 'US' 
and r.ACTUAL_COMPLETION_DATE is null
order by r.ACTUAL_START_DATE;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Verify Status of the Workflow Background Engine Deferred Queue Table *******
REM

prompt <script type="text/javascript">    function displayRows4sql3(){var row = document.getElementById("s4sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv143"></a>
prompt     <B>Verify Status of the Workflow Background Engine Deferred Queue Table</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="60">
prompt       <blockquote><p align="left">
prompt          select corr_id, msg_state, count(*)<br>
prompt          from applsys.aq$wf_deferred_table_m<br> 
prompt          group by corr_id, msg_state<br>
prompt          order by msg_state, count(*) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CORR_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||corr_id||'</TD>'||chr(10)|| 
'<TD>'||msg_state||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(*),'999,999,999,999')||'</div></TD></TR>'
from applsys.aq$wf_deferred_table_m 
group by corr_id, msg_state
order by msg_state, count(*) desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Verify Workflow Purge Concurrent Programs *******
REM

prompt <script type="text/javascript">    function displayRows4sql4(){var row = document.getElementById("s4sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv144"></a>
prompt     <B>Verify Workflow Purge Concurrent Programs that have run</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="250">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, p.USER_CONCURRENT_PROGRAM_NAME,<br>
prompt          DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',<br>
prompt          'D','D=Cancelled','E','E=Error','G','G=Warning',<br>
prompt          'H','H=On Hold','I','I=Normal','M','M=No Manager',<br>
prompt          'P','P=Scheduled','Q','Q=Standby','R','R=Normal',<br>
prompt          'S','S=Suspended','T','T=Terminating','U','U=Disabled',<br>
prompt          'W','W=Paused','X','X=Terminated','Z','Z=Waiting'),<br>
prompt          DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running'),<br>
prompt          r.ACTUAL_START_DATE,r.ACTUAL_COMPLETION_DATE,<br>
prompt          ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2),<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||<br>
prompt          FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||<br>
prompt          ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs', <br>
prompt          r.ARGUMENT_TEXT<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME = ('FNDWFPR') <br>
prompt          AND p.LANGUAGE = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')<br>
prompt          order by r.ACTUAL_START_DATE;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_MINS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TIME_TO_RUN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD> 
select  
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)||
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',
'D','D=Cancelled','E','E=Error','G','G=Warning',
'H','H=On Hold','I','I=Normal','M','M=No Manager',
'P','P=Scheduled','Q','Q=Standby','R','R=Normal',
'S','S=Suspended','T','T=Terminating','U','U=Disabled',
'W','W=Paused','X','X=Terminated','Z','Z=Waiting')||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running')||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||r.ACTUAL_COMPLETION_DATE||'</TD>'||chr(10)|| 
'<TD>'||ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2)||'</TD>'||chr(10)||
'<TD>'||FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||
FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||
ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs'||'</TD>'||chr(10)|| 
'<TD>'||r.ARGUMENT_TEXT||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME = ('FNDWFPR') 
AND p.LANGUAGE = 'US' 
and r.ACTUAL_COMPLETION_DATE is null
order by r.ACTUAL_START_DATE;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <table border="1" name="Warning" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td> 
prompt Delivered in 11i.ATG.rup4+ are new Concurrent Programs designed to gather Workflow Statistics after running purge.<BR>
prompt These requests should automatically run every 24hrs by default, however they can be run anytime to refresh the workflow process tables after purging to confirm that the purgeable items were purged.<BR>
prompt <B> - Workflow Agent Activity Statistics (FNDWFAASTATCC)</B> - Gathers statistics for the Agent Activity graph in the Workflow System status page and for the agent activity list in the Agent Activity page.<BR>
prompt <B> - Workflow Mailer Statistics (FNDWFMLRSTATCC)</B> - Gathers statistics for the throughput graph in the Notification Mailer Throughput page.<BR>
prompt <B> - Workflow Work Items Statistics (FNDWFWITSTATCC)</B> - Gathers statistics for the Work Items graph in the Workflow System status page, for 
prompt the Completed Work Items list in the Workflow Purge page, and for the work item lists in the Active Work Items, Deferred Work Items, Suspended Work Items, and Errored Work Items pages.<BR>
prompt </p></td></tr></tbody></table><BR><BR>



REM
REM ******* Verify Workflow Control Queue Cleanup Program *******
REM

prompt <script type="text/javascript">    function displayRows4sql5(){var row = document.getElementById("s4sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv145"></a>
prompt     <B>Verify Workflow Control Queue Cleanup requests that have run</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="250">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, p.USER_CONCURRENT_PROGRAM_NAME,<br>
prompt          DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',<br>
prompt          'D','D=Cancelled','E','E=Error','G','G=Warning',<br>
prompt          'H','H=On Hold','I','I=Normal','M','M=No Manager',<br>
prompt          'P','P=Scheduled','Q','Q=Standby','R','R=Normal',<br>
prompt          'S','S=Suspended','T','T=Terminating','U','U=Disabled',<br>
prompt          'W','W=Paused','X','X=Terminated','Z','Z=Waiting'),<br>
prompt          DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running'),<br>
prompt          r.ACTUAL_START_DATE,r.ACTUAL_COMPLETION_DATE,<br>
prompt          ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2),<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||<br>
prompt          FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||<br>
prompt          ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs', <br>
prompt          r.ARGUMENT_TEXT<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME = ('FNDWFBES_CONTROL_QUEUE_CLEANUP') <br>
prompt          AND p.LANGUAGE = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')<br>
prompt          order by r.ACTUAL_START_DATE;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_MINS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TIME_TO_RUN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD> 
select  
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)||
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',
'D','D=Cancelled','E','E=Error','G','G=Warning',
'H','H=On Hold','I','I=Normal','M','M=No Manager',
'P','P=Scheduled','Q','Q=Standby','R','R=Normal',
'S','S=Suspended','T','T=Terminating','U','U=Disabled',
'W','W=Paused','X','X=Terminated','Z','Z=Waiting')||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running')||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||r.ACTUAL_COMPLETION_DATE||'</TD>'||chr(10)|| 
'<TD>'||ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2)||'</TD>'||chr(10)||
'<TD>'||FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||
FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||
ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs'||'</TD>'||chr(10)|| 
'<TD>'||r.ARGUMENT_TEXT||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME = ('FNDWFBES_CONTROL_QUEUE_CLEANUP') 
AND p.LANGUAGE = 'US' 
and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')
order by r.ACTUAL_START_DATE;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>The Workflow Control Queue Cleanup concurrent program is a seeded request that is automatically scheduled to be run every 12 hours by default.<BR>
prompt          Oracle recommends that this frequency not be changed.<BR><BR>
prompt          Please see <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=453137.1" target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i</p>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

REM **************************************************************************************** 
REM *******                   Section 5 : Workflow Notification Mailer               *******
REM ****************************************************************************************

prompt <a name="section5"></a><B><font size="+2">Workflow Notification Mailer</font></B><BR><BR>

REM
REM ******* Check the Status of Workflow Services *******
REM

prompt <script type="text/javascript">    function displayRows5sql2(){var row = document.getElementById("s5sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv151"></a>
prompt     <B>Check the Status of Workflow Services</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="11" height="253">
prompt       <blockquote><p align="left">
prompt          select  fcq.USER_CONCURRENT_QUEUE_NAME, fsc.COMPONENT_NAME,<br>
prompt          DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID), <br>
prompt          fcq.MAX_PROCESSES, fcq.RUNNING_PROCESSES, v.PARAMETER_VALUE,<br>
prompt          fcq.ENABLED_FLAG, fsc.COMPONENT_ID, fsc.CORRELATION_ID,<br>
prompt          fsc.STARTUP_MODE, fsc.COMPONENT_STATUS<br>
prompt          from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, <br>
prompt          APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v<br>
prompt          where v.COMPONENT_ID=fsc.COMPONENT_ID<br>
prompt          and fcq.MANAGER_TYPE = fcs.SERVICE_ID <br>
prompt          and fcs.SERVICE_HANDLE = 'FNDCPGSC' <br>
prompt          and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)<br>
prompt          and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) <br>
prompt          and fcq.application_id = fcp.queue_application_id(+) <br>
prompt          and fcp.process_status_code(+) = 'A'<br>
prompt          and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'<br>
prompt          order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONTAINER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROCID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TARGET</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTUAL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>#THREADS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ENABLED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CORRELATION_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTUP_MODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
select  
'<TR><TD>'||fcq.USER_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID)||'</TD>'||chr(10)|| 
'<TD>'||fcq.MAX_PROCESSES||'</TD>'||chr(10)|| 
'<TD>'||fcq.RUNNING_PROCESSES||'</TD>'||chr(10)|| 
'<TD>'||v.PARAMETER_VALUE||'</TD>'||chr(10)|| 
'<TD>'||fcq.ENABLED_FLAG||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.CORRELATION_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.STARTUP_MODE||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_STATUS||'</TD></TR>'
from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
where v.COMPONENT_ID=fsc.COMPONENT_ID
and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
and fcq.application_id = fcp.queue_application_id(+) 
and fcp.process_status_code(+) = 'A'
and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

declare

v_comp_id number;

cursor c_mailerIDs IS
	select fsc.COMPONENT_ID
	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
	where v.COMPONENT_ID=fsc.COMPONENT_ID
	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
	and fcq.application_id = fcp.queue_application_id(+) 
	and fcp.process_status_code(+) = 'A'
	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';

begin

	select nvl(max(rownum), 0) into :mailer_cnt
	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
	where v.COMPONENT_ID=fsc.COMPONENT_ID
	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
	and fcq.application_id = fcp.queue_application_id(+) 
	and fcp.process_status_code(+) = 'A'
	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';

dbms_output.put_line('<BR><a name="wfadv152"></a><B><U>Check the status of the Workflow Notification Mailer(s) for this instance</B></U><BR>');

  if (:mailer_cnt = 0) then

       dbms_output.put_line('There is no Mailer Service defined for this instance.<BR>');
       dbms_output.put_line('Check the setup of GSM to understand why the Mailer Service is not created or running.<BR><BR> ');

  elsif (:mailer_cnt = 1) then
 
       dbms_output.put_line('There is only one Notification mailer found on this instance.<BR>');
       dbms_output.put_line('The Workflow Notification Mailer is the default seeded mailer that comes with EBS. <BR><BR> ');
  
  else 
  
       dbms_output.put_line('There are multiple mailers found on this instance.<BR>');
       dbms_output.put_line('The seperate mailers will be looked at individually. <BR><BR> ');
       
  end if;
  
 
  OPEN c_mailerIDs;
  LOOP
  
    Fetch c_mailerIDs INTO v_comp_id;
  
    EXIT WHEN c_mailerIDs%NOTFOUND;
  
    if (:mailer_enabled = 'DISABLED') then
       
        dbms_output.put_line('The '|| :component_name ||' is currently ' || :mailer_enabled || ', so no email notifications can be sent. <BR>');
       
    elsif (:mailer_enabled = 'ENABLED') then
       
       	select fsc.COMPONENT_STATUS into :mailer_status
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service'
       	and fsc.COMPONENT_ID = v_comp_id;

       	select nvl(fsc.CORRELATION_ID,'NULL') into :corrid
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service'
       	and fsc.COMPONENT_ID = v_comp_id;
       	
       	select fsc.STARTUP_MODE into :startup_mode
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service'
       	and fsc.COMPONENT_ID = v_comp_id;
       	
       	select fcq.USER_CONCURRENT_QUEUE_NAME into :container_name
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service'
       	and fsc.COMPONENT_ID = v_comp_id;	
        
	select fsc.COMPONENT_NAME into :component_name
	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
	where v.COMPONENT_ID=fsc.COMPONENT_ID
	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
	and fcq.application_id = fcp.queue_application_id(+) 
	and fcp.process_status_code(+) = 'A'
	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service'
       	and fsc.COMPONENT_ID = v_comp_id;
       	
       	select v.PARAMETER_VALUE into :email_override 
       	from FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS fsc
       	where v.COMPONENT_ID=fsc.COMPONENT_ID 
       	and v.parameter_name = 'TEST_ADDRESS'
       	and fsc.COMPONENT_ID = v_comp_id
       	order by fsc.COMPONENT_ID, v.parameter_name;
       
       
      dbms_output.put_line('The mailer called "'|| :component_name ||'" is ' || :mailer_enabled || ' with a component status of '|| :mailer_status ||'. ');

	 if (:email_override = 'NONE') then 

	    dbms_output.put_line('<BR>The Email Override (Test Address) feature is DISABLED as ' || :email_override || ' for '|| :component_name ||'. ');
	    dbms_output.put_line('<BR>This means that all emails with correlation_id of '|| :corrid ||' that get sent by '|| :component_name ||' will be sent to their intended recipients as expected when the mailer is running.<BR><BR> ');

	 elsif (:email_override is not null) then  

	    dbms_output.put_line('<BR>The Email Override (Test Address) feature is ENABLED to ' || :email_override || ' for '|| :component_name ||'.');
	    dbms_output.put_line('<BR>This means that all emails that get sent by  '|| :component_name ||' are re-routed and sent to this single Override email address (' || :email_override || ') when the '|| :component_name ||' is running.');
	    dbms_output.put_line('<BR>Please ensure this email address is correct.');
	    dbms_output.put_line('<BR>This is a standard setup for a production cloned (TEST or DEV) instance to avoid duplicate emails being sent to users.<BR><BR> ');

         end if;

    
      if (:mailer_status = 'DEACTIVATED_USER') then

          if (:startup_mode = 'AUTOMATIC') then 

                 dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('<B>Warning</B><BR>');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently not running.<BR>');
	         dbms_output.put_line('<B>Action</B><BR>');
	         dbms_output.put_line('If using the Java Mailer to send email notifications and alerts, please bounce the container : '|| :container_name ||'.<BR>'); 
	         dbms_output.put_line('via the Oracle Application Manager - Workflow Manager screen to automatically restart the component : '|| :component_name ||'.<BR>');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1" target="_blank">Note 1191400.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		 
          elsif (:startup_mode = 'MANUAL') then

		 dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
		 dbms_output.put_line('<tbody><tr><td> ');
		 dbms_output.put_line('<p><B>Warning</B><BR>');
		 dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently not running..<BR>');
		 dbms_output.put_line('<B>Action</B><BR>');
		 dbms_output.put_line('If using the Java Mailer to send email notifications and alerts, please manually start the : '|| :component_name ||'.<BR>');
                 dbms_output.put_line('via the Oracle Application Manager - Workflow Manager screen.');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1" target="_blank">Note 1191400.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
       
          end if;
           
      elsif (:mailer_status = 'DEACTIVATED_SYSTEM') then
          
                 dbms_output.put_line('<table border="1" name="Error" cellpadding="10" bgcolor="#CC6666" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('<p><B>Error</B><BR>');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently down due to an error detected by the System.<BR>');
	         dbms_output.put_line('<B>Action</B><BR>');
	         dbms_output.put_line('Please review the email that was sent to SYSADMIN regarding this error.<BR>'); 
	         dbms_output.put_line('The Java Mailer is currently set to startup mode of '|| :startup_mode ||'.<BR>');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1" target="_blank">Note 1191400.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		 
      elsif (:mailer_status = 'NOT_CONFIGURED') then
          
                 dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('<p><B>Warning</B><BR>');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" has been created, but is not configured completely.<BR>');
	         dbms_output.put_line('<B>Action</B><BR>');
	         dbms_output.put_line('Please complete the configuration of the "'|| :component_name ||'" using the Workflow Manager screens if you plan to use it.<BR>'); 
	         dbms_output.put_line('This Java Mailer is currently set to startup mode of '|| :startup_mode ||'.<BR>');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1" target="_blank">Note 1191400.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		 
      elsif (:mailer_status = 'STOPPED') then 
        
                 dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently stopped.<BR>');
		 dbms_output.put_line('</td></tr></tbody></table><BR>');
		 
      elsif (:mailer_status = 'RUNNING') then 
                   
                 dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently running.<BR>');
		 dbms_output.put_line('</td></tr></tbody></table><BR>');
	       
      end if;	  

   end if;
      
 END LOOP;

 CLOSE c_mailerIDs;

end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Check Status of WF_NOTIFICATIONS Table *******
REM

prompt <script type="text/javascript">    function displayRows5sql3(){var row = document.getElementById("s5sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv153"></a>
prompt     <B>Check Status of WF_NOTIFICATIONS Table</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="85">
prompt       <blockquote><p align="left">
prompt          select status, nvl(mail_status,'NULL'), count(notification_id)<br>
prompt          from wf_notifications<br>
prompt          group by status, mail_status<br>
prompt          order by status, count(notification_id) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MAIL_STATUS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||status||'</TD>'||chr(10)|| 
'<TD>'||nvl(mail_status,'NULL')||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(notification_id),'999,999,999,999')||'</div></TD></TR>'
from wf_notifications  
group by status, mail_status
order by status, count(notification_id) desc;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Check Status of WF_NOTIFICATION_OUT Table *******
REM

prompt <script type="text/javascript">    function displayRows5sql4(){var row = document.getElementById("s5sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv154"></a>
prompt     <B>Check Status of WF_NOTIFICATION_OUT Table</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="60">
prompt       <blockquote><p align="left">
prompt          select n.msg_state, count(*)<br>
prompt          from applsys.aq$wf_notification_out n<br>
prompt          group by n.msg_state;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MSG_STATE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||n.msg_state||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(*),'999,999,999,999')||'</div></TD></TR>'
from applsys.aq$wf_notification_out n
group by n.msg_state;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Check for Orphaned Notifications *******
REM

prompt <script type="text/javascript">    function displayRows5sql5(){var row = document.getElementById("s5sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv155"></a>
prompt     <B>Check for Orphaned Notifications</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="155">
prompt       <blockquote><p align="left">
prompt          select WN.MESSAGE_TYPE, wn.MESSAGE_NAME, count(notification_id)<br>
prompt          from WF_NOTIFICATIONS WN<br>
prompt          where not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES WIAS<br>
prompt                            where WIAS.NOTIFICATION_ID = WN.GROUP_ID)<br>
prompt            and not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES_H WIAS<br>
prompt                            where WIAS.NOTIFICATION_ID = WN.GROUP_ID)<br>
prompt          group by wn.message_type, wn.MESSAGE_NAME<br>
prompt          order by count(notification_id) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||WN.MESSAGE_TYPE||'</TD>'||chr(10)|| 
'<TD>'||wn.MESSAGE_NAME||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(notification_id),'999,999,999,999')||'</div></TD></TR>'
from WF_NOTIFICATIONS WN
where not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES WIAS
                  where WIAS.NOTIFICATION_ID = WN.GROUP_ID)
  and not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES_H WIAS
                  where WIAS.NOTIFICATION_ID = WN.GROUP_ID)
group by wn.message_type, wn.MESSAGE_NAME
order by count(notification_id) desc;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM *******                   Section 6 : Workflow Patch Levels                      *******
REM ****************************************************************************************

prompt <a name="section6"></a><B><font size="+2">Current Workflow Patch Levels</font></B><BR><BR>


REM
REM ******* Applied ATG Patches *******
REM

prompt <script type="text/javascript">    function displayRows6sql1(){var row = document.getElementById("s6sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv161"></a>
prompt     <B>Applied ATG/WF Patches</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s6sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="850">
prompt       <blockquote><p align="left">
prompt         select BUG_NUMBER, LAST_UPDATE_DATE,<br> 
prompt         decode(bug_number,2728236, 'OWF.G INCLUDED IN 11.5.9',<br>
prompt         3031977, 'POST OWF.G ROLLUP 1 - 11.5.9.1',<br>
prompt         3061871, 'POST OWF.G ROLLUP 2 - 11.5.9.2',<br>
prompt         3124460, 'POST OWF.G ROLLUP 3 - 11.5.9.3',<br>
prompt         3126422, '11.5.9 Oracle E-Business Suite Consolidated Update 1',<br>
prompt         3171663, '11.5.9 Oracle E-Business Suite Consolidated Update 2',<br>
prompt         3316333, 'POST OWF.G ROLLUP 4 - 11.5.9.4.1',<br>
prompt         3314376, 'POST OWF.G ROLLUP 5 - 11.5.9.5',<br>
prompt         3409889, 'POST OWF.G ROLLUP 5 Consolidated Fixes For OWF.G RUP 5', 3492743, 'POST OWF.G ROLLUP 6 - 11.5.9.6',<br>
prompt         3868138, 'POST OWF.G ROLLUP 7 - 11.5.9.7',<br>
prompt         3262919, 'FMWK.H',<br>
prompt         3262159, 'FND.H INCLUDE OWF.H',<br>
prompt         3258819, 'OWF.H INCLUDED IN 11.5.10',<br>
prompt         3438354, '11i.ATG_PF.H INCLUDE OWF.H',<br>
prompt         3140000, 'ORACLE APPLICATIONS RELEASE 11.5.10 MAINTENANCE PACK',<br>
prompt         3240000, '11.5.10 ORACLE E-BUSINESS SUITE CONSOLIDATED UPDATE 1',<br>
prompt         3460000, '11.5.10 ORACLE E-BUSINESS SUITE CONSOLIDATED UPDATE 2',<br>
prompt         3480000, 'ORACLE APPLICATIONS RELEASE 11.5.10.2 MAINTENANCE PACK',<br>
prompt         4017300 , 'ATG_PF:11.5.10 Consolidated Update (CU1) for ATG Product Family',<br>
prompt         4125550 , 'ATG_PF:11.5.10 Consolidated Update (CU2) for ATG Product Family',<br>
prompt         5121512, 'AOL USER RESPONSIBILITY SECURITY FIXES VERSION 1',<br>
prompt         6008417, 'AOL USER RESPONSIBILITY SECURITY FIXES 2b',<br>
prompt         6047864, 'REHOST JOC FIXES (BASED ON JOC 10.1.2.2) FOR APPS 11i',<br>
prompt         4334965, '11i.ATG_PF.H RUP3',<br>
prompt         4676589, '11i.ATG_PF.H.RUP4',<br>
prompt         5473858, '11i.ATG_PF.H.RUP5',<br>
prompt         5903765, '11i.ATG_PF.H.RUP6',<br>
prompt         6241631, '11i.ATG_PF.H.RUP7',<br>
prompt         4440000, 'Oracle Applications Release 12 Maintenance Pack',<br>
prompt         5082400, '12.0.1 Release Update Pack (RUP1)',<br>
prompt         5484000, '12.0.2 Release Update Pack (RUP2)',<br>
prompt         6141000, '12.0.3 Release Update Pack (RUP3)',<br>
prompt         6435000, '12.0.4 RELEASE UPDATE PACK (RUP4)',<br>
prompt         5907545, 'R12.ATG_PF.A.DELTA.1',<br>
prompt         5917344, 'R12.ATG_PF.A.DELTA.2',<br>
prompt         6077669, 'R12.ATG_PF.A.DELTA.3',<br>
prompt         6272680, 'R12.ATG_PF.A.DELTA.4', <br>
prompt         7237006, 'R12.ATG_PF.A.DELTA.6',<br>
prompt         6728000, '12.0.6 RELEASE UPDATE PACK (RUP6)', <br>
prompt	       6430106, 'R12 ORACLE E-BUSINESS SUITE 12.1', <br>
prompt         7303030, '12.1.1 Maintenance Pack',<br>
prompt         7307198, 'R12.ATG_PF.B.DELTA.1',<br>
prompt         7651091, 'R12.ATG_PF.B.DELTA.2',<br>
prompt         7303033, 'Oracle E-Business Suite 12.1.2 Release Update Pack (RUP2)',<br>
prompt         8919491, 'R12.ATG_PF.B.DELTA.3',<br>
prompt         9239090, 'ORACLE E-BUSINESS SUITE 12.1.3 RELEASE UPDATE PACK',<br>
prompt         10110982, 'R12 ORACLE E-BUSINESS SUITE 12.2', <br>
prompt         bug_number) PATCH, ARU_RELEASE_NAME<br>
prompt         from AD_BUGS b <br>
prompt         where b.BUG_NUMBER in ('2728236', '3031977','3061871','3124460','3126422','3171663','3316333',<br>
prompt         '3314376','3409889', '3492743', '3262159', '3262919', '3868138', '3258819','3438354','3240000', <br>
prompt         '3460000', '3140000','3480000','4017300', '4125550', '6047864', '6008417','5121512', '4334965', <br>
prompt         '4676589', '5473858', '5903765', '6241631', '4440000','5082400','5484000','6141000','6435000', <br>
prompt         '5907545','5917344','6077669','6272680','7237006','6728000','6430106','7303030','7307198', <br>
prompt         '7651091','7303033','8919491', '9239090', '10110982')<br>
prompt         order by BUG_NUMBER,LAST_UPDATE_DATE,ARU_RELEASE_NAME; </p>
prompt         </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BUG_NUMBER</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST_UPDATE_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PATCH</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARU_RELEASE_NAME</B></TD>
select 
'<TR><TD>'||BUG_NUMBER||'</TD>'||chr(10)|| 
'<TD>'||LAST_UPDATE_DATE||'</TD>'||chr(10)|| 
'<TD>'||decode(bug_number,2728236, 'OWF.G INCLUDED IN 11.5.9',
3031977, 'POST OWF.G ROLLUP 1 - 11.5.9.1',
3061871, 'POST OWF.G ROLLUP 2 - 11.5.9.2',
3124460, 'POST OWF.G ROLLUP 3 - 11.5.9.3',
3126422, '11.5.9 Oracle E-Business Suite Consolidated Update 1',
3171663, '11.5.9 Oracle E-Business Suite Consolidated Update 2',
3316333, 'POST OWF.G ROLLUP 4 - 11.5.9.4.1',
3314376, 'POST OWF.G ROLLUP 5 - 11.5.9.5',
3409889, 'POST OWF.G ROLLUP 5 Consolidated Fixes For OWF.G RUP 5', 
3492743, 'POST OWF.G ROLLUP 6 - 11.5.9.6',
3868138, 'POST OWF.G ROLLUP 7 - 11.5.9.7',
3262919, 'FMWK.H',
3262159, 'FND.H INCLUDE OWF.H',
3258819, 'OWF.H INCLUDED IN 11.5.10',
3438354, '11i.ATG_PF.H INCLUDE OWF.H',
3140000, 'Oracle Applications Release 11.5.10 Maintenance Pack',
3240000, '11.5.10 Oracle E-Business Suite Consolidated Update (CU1)',
3460000, '11.5.10 Oracle E-Business Suite Consolidated Update (CU2)',
3480000, 'Oracle Applications Release 11.5.10.2 Maintenance Pack',
4017300 , 'ATG_PF:11.5.10 Consolidated Update (CU1) for ATG Product Family',
4125550 , 'ATG_PF:11.5.10 Consolidated Update (CU2) for ATG Product Family',
5121512, 'AOL USER RESPONSIBILITY SECURITY FIXES VERSION 1',
6008417, 'AOL USER RESPONSIBILITY SECURITY FIXES 2b',
6047864, 'REHOST JOC FIXES (BASED ON JOC 10.1.2.2) FOR APPS 11i',
4334965, '11i.ATG_PF.H RUP3',
4676589, '11i.ATG_PF.H.RUP4',
5473858, '11i.ATG_PF.H.RUP5',
5903765, '11i.ATG_PF.H.RUP6',
6241631, '11i.ATG_PF.H.RUP7',
4440000, 'Oracle Applications Release 12 Maintenance Pack',
5082400, '12.0.1 Release Update Pack (RUP1)',
5484000, '12.0.2 Release Update Pack (RUP2)',
6141000, '12.0.3 Release Update Pack (RUP3)',
6435000, '12.0.4 Release Update Pack (RUP4)',
5907545, 'R12.ATG_PF.A.DELTA.1',
5917344, 'R12.ATG_PF.A.DELTA.2',
6077669, 'R12.ATG_PF.A.DELTA.3',
6272680, 'R12.ATG_PF.A.DELTA.4', 
7237006, 'R12.ATG_PF.A.DELTA.6',
6728000, 'R12 12.0.6 (RUP6)', 
6430106, 'R12 Oracle E-Business Suite 12.1', 
7303030, '12.1.1 Maintenance Pack',
7307198, 'R12.ATG_PF.B.DELTA.1',
7651091, 'R12.ATG_PF.B.DELTA.2',
7303033, 'R12 Oracle E-Business Suite 12.1.2 (RUP2)',
8919491, 'R12.ATG_PF.B.DELTA.3',
9239090, 'R12 Oracle E-Business Suite 12.1.3 (RUP3)',
10110982, 'R12 Oracle E-Business Suite 12.2',
10079002, 'R12 Oracle E-Business Suite 12.2.0 Maintenance Pack',
bug_number)||'</TD>'||chr(10)|| 
'<TD>'||ARU_RELEASE_NAME||'</TD></TR>' 
from AD_BUGS b 
where b.BUG_NUMBER in ('2728236', '3031977','3061871','3124460','3126422','3171663','3316333',
'3314376','3409889', '3492743', '3262159', '3262919', '3868138', '3258819','3438354','3240000',
'3460000', '3140000','3480000','4017300', '4125550', '6047864', '6008417','5121512', '4334965',
'4676589', '5473858', '5903765', '6241631', '4440000','5082400','5484000','6141000','6435000',
'5907545','5917344','6077669','6272680','7237006','6728000','6430106','7303030','7307198',
'7651091','7303033','8919491', '9239090', '10110982','10079002')
order by LAST_UPDATE_DATE,ARU_RELEASE_NAME; 
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <a name="atgrups"></a><B><font size="+2">Known 1-Off Patches on top of ATG Rollups</font></B><BR><BR>

begin


select release_name into :apps_rel 
from fnd_product_groups;

       dbms_output.put_line('This instance has Oracle Applications version ' || :apps_rel || '.<BR>'); 
       
   if (:apps_rel is null) then 

       dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Warning</B><BR>');
       dbms_output.put_line('There is a problem reading the Oracle Apps version : ' || :apps_rel || ' for this instance. ');
       dbms_output.put_line('<BR>');       
       
   elsif (:apps_rel = '11.5.9') then 

       dbms_output.put_line('<B>Warning</B><BR>');
       dbms_output.put_line('The Oracle Apps version is (' || :apps_rel || ') for this instance. ');
       dbms_output.put_line('<BR>');

   elsif (:apps_rel > '11.5.10' and :apps_rel < '12.0') then 

       dbms_output.put_line('<B>One-Off Patches on top of Supported ATG Roll-Up Patches (RUP) for ' || :apps_rel || '.</B><br><br>');
       
       dbms_output.put_line('<P><b>11i.ATG_PF.H RUP4</b><table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >'); 
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td></tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">7829071</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.0.4:ORA-06502 PL/SQL: NUMERIC OR VALUE IN WF_ENGINE_UTIL.NOTIFICATION_SEND</td>');
       dbms_output.put_line('<td width="16%">n/a</td></tr><tr bordercolor="#000066"><td width="10%"> ');
       dbms_output.put_line('<div align="center">8557487</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:5709442: HIGH BUFFER GETS WHEN SENDING NOTIFICATON</td><td width="16%">n/a</td></tr>');
       dbms_output.put_line('</table><br>');

       dbms_output.put_line('<b>11i.ATG_PF.H RUP6</b>');
       dbms_output.put_line('<table width="83%" border="1">');
       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" > ');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">7594112</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">1OFF:6243131:11I.ATG_PF.H.RUP6: APPROVALS GOING INTO DEFFRED MODE </td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">8330993</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">1OFF:8308654:12.0.6:12.0.6:12.0.6:WF_STANDARD.INITIALIZEEVENTERROR ');
       dbms_output.put_line('USING ATTRIB </td>');
       dbms_output.put_line('<td width="16%"></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">9199983</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">1OFF:11.5.10.6RUP:7476877:WORKFLOW PURGE IS CRITICALLY AFFECTING PERFORMANCE</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('</table>');

       dbms_output.put_line('<p><b>11i.ATG_PF.H RUP7</b><br>');
       dbms_output.put_line('<table width="83%" border="1">');
       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" > ');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">9747572</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">1OFF:11i.ATG_PF.H.RUP7:WFBG DOES NOT EXECUTE SELECTOR FUNCTION ');
       dbms_output.put_line('WHEN PROCESSING A SUBSEQUENT DEFERRED ACTIVITY OF SAME ITEM TYPE AND ITEM</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('</table><BR><BR>');

   elsif (:apps_rel >= '12.0' and :apps_rel < '12.1') then 

       dbms_output.put_line('<B>One-Off Patches on top of Supported ATG Roll-Up Patches (RUP) for ' || :apps_rel || '.</B><br><br>');
       
       dbms_output.put_line('<P><b>Rel 12.0.4</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >'); 
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">8201652</div></td>');
       dbms_output.put_line('<td width="74%">1OFF (7538770) ON TOP OF 12.0.4 (R12.ATG_PF.A.DELTA.4)</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('</table><br>');
       
       dbms_output.put_line('<p><b>Rel 12.0.6</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">9123412</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.0.6:8509185:NOTIFICATION HISTORY DOES NOT DISPLAY UP TO DATE CONTENT.</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">8330993</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:8308654:12.0.6:WF_STANDARD.INITIALIZEEVENTERROR USING ATTRIB ERROR_DETAILS THAT DOES NOT EXIST.</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('</table><BR><BR>');

   elsif (:apps_rel >= '12.1' and :apps_rel < '12.2') then 

       dbms_output.put_line('<B>One-Off Patches on top of Supported ATG Roll-Up Patches (RUP) for ' || :apps_rel || '.</B><br><br>');
       
       dbms_output.put_line('<P><b>Rel 12.1.1</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >'); 
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">8531582</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.1:7538770:FNDWFPR PERFORMANCE IS SLOWER THAN GENERATING SPEED</td>');
       dbms_output.put_line('<td width="16%">8832674</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">8603335</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.1:8554209:PERFORMANCE ISSUE WITH WF_NOTIFICATION.SEND()API</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">9102969</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.1:8850464:FND USER IS COMING AS WRONG VALUE</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">9046220</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.1:7842689:WF_ITEM.SET_END_DATE WRONGLY DECREMENTS #WAITFORDETAIL ATTRIBUTE</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">8802718</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.1:8729116:ORA-1422: IN WF_NOTIFICATION.SEND WHEN 2 NTFS ARE SENT FROM AN ACTIVITY</td>');
       dbms_output.put_line('<td width="16%">8832674</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">9227423</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.1:9040136:ACTION HISTORY IS OUT OF SEQUENCE IN A RAC INSTANCE </td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">8853694</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:8509185:R12 ORACLE E-BUSINESS SUITE 1:FND.A:12.1.1:NOTIFICATION HISTORY DOES NOT DISPLAY UP TO DATE CONTENT</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');         
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">9343170</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:8729116:11.5.10.6:ORA-01422 IN WF_NOTIFICATION.SEND WHEN 2 NTFS SENT FROM AN ACTIVITY</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"><td width="10%">');
       dbms_output.put_line('<div align="center">9773716</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.2:9771657:WFBG DOES NOT EXECUTE SELECTOR FUNCTION WHEN PROCESSING A SUBSEQUENT DEFERRED ACTIVITY OF SAME ITEM TYPE AND ITEM KEY</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('</table><BR>');
 
       dbms_output.put_line('<p><b>Rel 12.1.2</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">9773716</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.2:9771657:WFBG DOES NOT EXECUTE SELECTOR FUNCTION WHEN PROCESSING A SUBSEQUENT DEFERRED ACTIVITY OF SAME ITEM TYPE AND ITEM KEY.</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('</table><BR>');
       
       dbms_output.put_line('<p><b>Rel 12.1.3</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">9773716</div></td>');
       dbms_output.put_line('<td width="74%">1OFF:12.1.2:9771657:WFBG DOES NOT EXECUTE SELECTOR FUNCTION WHEN PROCESSING A SUBSEQUENT DEFERRED ACTIVITY OF SAME ITEM TYPE AND ITEM KEY.</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('</table><BR>');

   elsif (:apps_rel >= '12.2') then 

       dbms_output.put_line('<B>One-Off Patches on top of Supported ATG Roll-Up Patches (RUP) for ' || :apps_rel || '.</B><br><br>');
       
       dbms_output.put_line('<p><b>Rel 12.2</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">TBD</div></td>');
       dbms_output.put_line('<td width="74%">n/a</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('</table><BR>');

       
    end if;       
       
       dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');
       
       dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td>');
       dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=453137.1"');
       dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br><br>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');

end;
/


REM
REM ******* Verify Workflow Services Log Levels and Mailer Debug Status *******
REM

prompt <script type="text/javascript">    function displayRows6sql2(){var row = document.getElementById("s6sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv162"></a>
prompt     <B>Check The Status of Workflow Log Levels and Mailer Debug Status</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s6sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote>
prompt         <p align="left">select SC.COMPONENT_NAME, sc.COMPONENT_TYPE,<br>
prompt 			   v.PARAMETER_DISPLAY_NAME,<br>
prompt 			   decode(v.PARAMETER_VALUE,<br>
prompt 			   '1', '1 = Statement',<br>
prompt 			   '2', '2 = Procedure',<br>
prompt 			   '3', '3 = Event',<br>
prompt 			   '4', '4 = Exception',<br>
prompt 			   '5', '5 = Error',<br>
prompt 			   '6', '6 = Unexpected',<br>
prompt 			   'N', 'N = Not Enabled',<br>
prompt 			   'Y', 'Y = Enabled')<br>
prompt 			   FROM FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC<br>
prompt 			   WHERE v.COMPONENT_ID=sc.COMPONENT_ID <br>
prompt 			   AND v.parameter_name in ('COMPONENT_LOG_LEVEL','DEBUG_MAIL_SESSION')<br>
prompt 			   ORDER BY sc.COMPONENT_TYPE, SC.COMPONENT_NAME, v.PARAMETER_VALUE;</p>
prompt         </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARAMETER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
select 
'<TR><TD>'||SC.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD>'||sc.COMPONENT_TYPE||'</TD>'||chr(10)|| 
'<TD>'||v.PARAMETER_DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD>'||decode(v.PARAMETER_VALUE,
'1', '1 = Statement',
'2', '2 = Procedure',
'3', '3 = Event',
'4', '4 = Exception',
'5', '5 = Error',
'6', '6 = Unexpected',	 
'N', 'N = Not Enabled',
'Y', 'Y = Enabled')||'</TD></TR>'
FROM FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC
WHERE v.COMPONENT_ID=sc.COMPONENT_ID 
AND v.parameter_name in ('COMPONENT_LOG_LEVEL','DEBUG_MAIL_SESSION')
ORDER BY sc.COMPONENT_TYPE, SC.COMPONENT_NAME, v.PARAMETER_VALUE;
prompt </TABLE><P><P>

prompt The Mailer Debug parameter (Debug Mail Session) should be ENABLED when troubleshooting issues with any Workflow Notification Mailer.<BR>
prompt Set individual Component Logging Levels to Statement Level logging (Log Level = 1) for the most detail and robust logging level.<BR>
prompt Use $FND_TOP/sql/afsvcpup.sql - AF SVC Parameter UPdate script to change the logging levels.<br>
prompt Remember to reset, or lower the logging level after troubleshooting to not generate excessive log files.
prompt <br><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Verify Workflow Services Current Logs *******
REM

prompt <script type="text/javascript">    function displayRows6sql3(){var row = document.getElementById("s6sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt     <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"> <a name="wfadv163"></a>
prompt     <B>Verify Workflow Services Current Logs</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql3()" >SQL Script</button></div>
prompt     </TD>
prompt   </TR>
prompt   <TR id="s6sql3" style="display:none">
prompt     <TD BGCOLOR=#DEE6EF colspan="5" height="150">
prompt       <blockquote>
prompt        <p align="left">select fcq.concurrent_queue_name, fcp.last_update_date,<br>
prompt           fcp.concurrent_process_id,flkup.meaning,fcp.logfile_name<br>
prompt           FROM fnd_concurrent_queues fcq, fnd_concurrent_processes fcp, fnd_lookups
prompt           flkup<br>
prompt           WHERE concurrent_queue_name in ('WFMLRSVC', 'WFALSNRSVC')<br>
prompt           AND fcq.concurrent_queue_id = fcp.concurrent_queue_id<br>
prompt           AND fcq.application_id = fcp.queue_application_id<br>
prompt           AND flkup.lookup_code=fcp.process_status_code<br>
prompt           AND lookup_type ='CP_PROCESS_STATUS_CODE'<br>
prompt           AND flkup.meaning='Active';</p>
prompt         </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MANAGER</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST_UPDATE_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MEANING</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LOGFILE_NAME</B></TD>
select 
'<TR><TD>'||fcq.concurrent_queue_name||'</TD>'||chr(10)|| 
'<TD>'||fcp.last_update_date||'</TD>'||chr(10)|| 
'<TD>'||fcp.concurrent_process_id||'</TD>'||chr(10)|| 
'<TD>'||flkup.meaning||'</TD>'||chr(10)|| 
'<TD>'||fcp.logfile_name||'</TD></TR>'
FROM fnd_concurrent_queues fcq, fnd_concurrent_processes fcp, fnd_lookups flkup
    WHERE concurrent_queue_name in ('WFMLRSVC', 'WFALSNRSVC')
    AND fcq.concurrent_queue_id = fcp.concurrent_queue_id
    AND fcq.application_id = fcp.queue_application_id
    AND flkup.lookup_code=fcp.process_status_code
    AND lookup_type ='CP_PROCESS_STATUS_CODE'
    AND flkup.meaning='Active';
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM **************************************************************************************** 
REM *******                   Section 7 : References                                 *******
REM ****************************************************************************************

prompt <a name="section7"></a><B><font size="+2">References</font></B><BR><BR>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><font size="-1" face="Calibri"><tr><td><p>   

prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1425053.1" target="_blank">
prompt Note 1425053.1 - How to run EBS Workflow Analyzer Tool as a Concurrent Request</a><br>
prompt <br>
prompt <a href="https://communities.oracle.com/portal/server.pt/community/core_workflow/244" target="_blank">
prompt My Oracle Support - Workflow Communities</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1160285.1" target="_blank">
prompt Application Technology Group (ATG) Product Information Center (PIC) (Doc ID 1160285.1)</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1320509.1" target="_blank">
prompt E-Business Workflow Information Center (PIC) (Doc ID 1320509.1)</a><br>
prompt <br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=186361.1" target="_blank">
prompt Note 186361.1 - Workflow Background Process Performance Troubleshooting Guide</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=453137.1" target="_blank">
prompt Note 453137.1 - Oracle Workflow Best Practices Release 12 and Release 11i</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=225165.1" target="_blank">
prompt Note 225165.1 - Patching Best Practices and Reducing Downtime</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=957426.1" target="_blank">
prompt Note 957426.1 - Health Check Alert: Invalid objects exist for one or more of your EBS applications</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=104457.1" target="_blank">
prompt Note 104457.1 - Invalid Objects In Oracle Applications FAQs</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1191400.1" target="_blank">
prompt Note 1191400.1 - Troubleshooting Oracle Workflow Java Notification Mailer</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=831982.1" target="_blank">
prompt Note 831982.1 - A guide For Troubleshooting Workflow Notification Emails - Inbound and Outbound</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1448095.1" target="_blank">
prompt Note 1448095.1 - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=562551.1" target="_blank">
prompt Note 562551.1 - Workflow Java Mailer FAQ</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=760386.1" target="_blank">
prompt Note 760386.1 - How to enable Bulk Notification Response Processing for Workflow in 11i and R12</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=559996.1" target="_blank">
prompt Note 559996.1 - What Tables Does the Workflow Purge Obsolete Data Program (FNDWFPR) Touch?</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=277124.1" target="_blank">
prompt Note 277124.1 - FAQ on Purging Oracle Workflow Data</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=132254.1" target="_blank">
prompt Note 132254.1 - Speeding Up And Purging Workflow</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=144806.1" target="_blank">
prompt Note 144806.1 - A Detailed Approach To Purging Oracle Workflow Runtime Data</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1378954.1" target="_blank">
prompt Note 1378954.1 - bde_wf_process_tree.sql - For analyzing the Root Parent, Children, Grandchildren Associations of a Single Workflow Process</a><BR>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=375095.1" target="_blank">
prompt Note 375095.1 - How to Purge XDPWFSTD Messages</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=311552.1" target="_blank">
prompt Note 311552.1 - How to Optimize the Purge Process in a High Transaction Applications Environment</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=388672.1" target="_blank">
prompt Note 388672.1 - How to Reorganize Workflow Tables</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=733335.1" target="_blank">
prompt Note 733335.1 - How to Start Workflow Components</a><br>
prompt </p></font></td></tr></tbody>
prompt </table><BR><BR>

REM **************************************************************************************** 
REM *******                   Section 7 : Feedback                                   *******
REM ****************************************************************************************

prompt <a name="section8"></a><B><font size="+2">Feedback</font></B><BR><BR>
prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><font size="-1" face="Calibri"><tr><td><p>
prompt Still have questions? Use the<a title="This is a live browser iFrame window"><em><font color="#FF0000"><b><font size="+1"> live</font></b></font></em></a> My Oracle Support EBS - Core Workflow Community window below,
prompt to search for similar discussions or start a new discussion about the Workflow Analyzer.
prompt As always, you can email the author directly <A HREF="mailto:william.burbage@oracle.com?subject=%20Workflow%20Analyzer%20Feedback&
prompt body=Please attach a copy of your WF Analyzer output">here</A>.<BR>
prompt Be sure to include the output of the script for review.<BR>
prompt </p></font></td></tr></tbody>
prompt </table><BR><BR>

prompt <iframe width="90%" height="550" frameborder="1" 
prompt src="https://communities.oracle.com/portal/server.pt/community/view_discussion_topic/216?threadid=271375\&Portlet=Search%20Results\&PrevPage=Communities-Search" 
prompt id="iframedemo" name="iframedemo" style="border-style: groove; border-width: 4px; margin: 15px;" class="Docframe"> 
prompt </iframe><BR>



begin
select to_char(sysdate,'hh24:mi:ss') into :et_time from dual;
end;
/

declare
	st_hr1 varchar2(10);
	st_mi1 varchar2(10);
	st_ss1 varchar2(10);
	et_hr1 varchar2(10);
	et_mi1 varchar2(10);
	et_ss1 varchar2(10);
	hr_fact varchar2(10);
	mi_fact varchar2(10);
	ss_fact varchar2(10);
begin
	dbms_output.put_line('<br>PL/SQL Script was started at:'||:st_time);
	dbms_output.put_line('<br>PL/SQL Script is complete at:'||:et_time);
	st_hr1 := substr(:st_time,1,2);
	st_mi1 := substr(:st_time,4,2);
	st_ss1 := substr(:st_time,7,2);
	et_hr1 := substr(:et_time,1,2);
	et_mi1 := substr(:et_time,4,2);
	et_ss1 := substr(:et_time,7,2);

	if et_hr1 >= st_hr1 then
		hr_fact := to_number(et_hr1) - to_number(st_hr1);
	else
		hr_fact := to_number(et_hr1+24) - to_number(st_hr1);
	end if;
	if et_ss1 >= st_ss1 then
		mi_fact := to_number(et_mi1) - to_number(st_mi1);
		ss_fact := to_number(et_ss1) - to_number(st_ss1);
	else
		mi_fact := (to_number(et_mi1) - to_number(st_mi1))-1;
		ss_fact := (to_number(et_ss1)+60) - to_number(st_ss1);
	end if;
	dbms_output.put_line('<br><br>Total time taken to complete the script: '||hr_fact||' Hrs '||mi_fact||' Mins '||ss_fact||' Secs');
end;
/

spool off
set heading on
set feedback on  
set verify on
exit
;
