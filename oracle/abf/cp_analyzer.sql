REM HEADER
REM   $Header: cp_analyzer.sql v1.00 MCOSTA $
REM   
REM MODIFICATION LOG:
REM	
REM	MCOSTA 
REM	
REM	Consolidated script to diagnose the current status and footprint of Concurrent Processing on an environment.
REM     This script can be run on 11.5.x or higher.
REM
REM   cp_analyzer.sql
REM     
REM   To collect all the required information for understanding the Concurrent Processing workload on a system
REM
REM   Requirements:
REM   E-Business Suite 11i or R12 install with standard APPS schema setup 
REM    (If using an alternative schema name other than APPS {eg. APPS_FND}, you will need to append the schema references accordingly)
REM
REM   How to run it?
REM   
REM   	sqlplus apps/<password>	@cp_analyzer.sql
REM
REM   
REM   Output should take ~30 minutes or less, and can be opened via a browser after logging into to My Oracle Support (MOS) (to display all content).
REM   
REM	cp_analyzer_<SID>_<HOST_NAME>.html
REM
REM
REM     Created: July 6th, 2011
REM     Last Updated: October 16th, 2012
REM
REM
set term off
set arraysize 1
set heading off
set feedback off  
set echo off
set verify off
SET CONCAT ON
SET CONCAT .
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



COLUMN host_name NOPRINT NEW_VALUE hostname
SELECT host_name from v$instance;
COLUMN instance_name NOPRINT NEW_VALUE instancename
SELECT instance_name from v$instance;
SPOOL cp_analyzer_&&hostname._&&instancename..html


VARIABLE GSM		VARCHAR2(1);
VARIABLE ITEM_CNT    	NUMBER;
VARIABLE SID         	VARCHAR2(20);
VARIABLE HOST        	VARCHAR2(30);
VARIABLE APPS_REL    	VARCHAR2(10);
VARIABLE SYSDATE	VARCHAR2(22);
VARIABLE WF_ADMIN_ROLE	VARCHAR2(320);
VARIABLE APPLPTMP VARCHAR2(240);


declare

	admin_email             varchar2(40);
	gsm         		varchar2(1);
	item_cnt    		number;
	sid         		varchar2(20);
	host        		varchar2(30);
	apps_rel    		varchar2(10);
	sysdate			varchar2(22);
	wf_admin_role 		varchar2(320);
      applptmp                varchar2(240);


begin

  select wf_core.translate('WF_ADMIN_ROLE') into :wf_admin_role from dual;

end;
/			 				 


alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

prompt <HTML>
prompt <HEAD>
prompt <TITLE>E-Business Applications Concurrent Processing Analyzer</TITLE>
prompt <STYLE TYPE="text/css">
prompt <!-- TD {font-size: 10pt; font-family: calibri; font-style: normal} -->
prompt </STYLE>
prompt </HEAD>
prompt <BODY>

prompt <TABLE border="1" cellspacing="0" cellpadding="10">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF"><TD bordercolor="#DEE6EF"><font face="Calibri">
prompt <B><font size="+2">E-Business Applications Concurrent Processing Analyzer for 
select UPPER(instance_name) from v$instance;
prompt <B><font size="+2"> on 
select UPPER(host_name) from v$instance;
prompt </font></B></TD></TR>
prompt </TABLE><BR>

prompt <img width="758" height="81" title="Support URL" src="https://support.oracle.com/oip/faces/secure/km/DownloadAttachment.jspx?attachid=432.1:BANNER2" /></a>
prompt <br>

prompt <font size="-1"><i><b>CP Analyzer v1.0 compiled on : 
select sysdate from dual;
prompt </b></i></font><BR><BR>

prompt <BR>
prompt <BR>


prompt The Oracle E-Business Applications Concurrent Processing Analyzer performs an overall check of the Concurrent Processing environment.  
prompt The included recommendations are based upon best practices used across many Oracle E-Business Suite Environments.  Please check for regular updates, and feel free to provide any additional feedback or other suggestions.
prompt <BR>

prompt ________________________________________________________________________________________________<BR>

prompt <table width="95%" border="0">
prompt   <tr> 
prompt     <td colspan="4" height="46"> 
prompt       <p><a name="top"><b><font size="+2">Table of Contents</font></b></a> </p>
prompt     </td>
prompt   </tr>
prompt   <tr> 
prompt     <td width="50%"> 
prompt       <p><a href="#section1"><b><font size="+1">E-Business Applications Concurrent Processing Analyzer Overview</font></b></a> 
prompt         <br>
prompt       <blockquote> <a href="#cpadv051"> - Total Purge Eligible Records in FND_CONCURRENT_REQUESTS </a><br>
prompt        <a href="#wfadv111"> - E-Business Suite Version</a><br>
prompt        <a href="#wfadv112"> - Concurrent Processing Database Parameter Settings</a><BR>
prompt        <a href="#wfadv1121"> - Concurrent Processing Environment Variables</a><BR>
prompt        <a href="#ebsprofile"> - E-Business Suite Profile Option Settings</a><br>
prompt        <a href="#wfadv161"> - Applied E-Business Suite Technology Stack Patches</a><br>
prompt        <a href="#atgrups"> - Known 1-Off Patches on top of E-Business Suite Technology Stacf Rollups</a><br></blockquote>

prompt       <a href="#section2"><b><font size="+1">E-Business Applications Concurrent Request Analysis</font></b></a> 
prompt       <br>
prompt       <blockquote><a href="#cpadv03"> - Long Running Reports During Business Hours </a><br>
prompt         <a href="#cpadv04"> - Elapsed Time History of Concurrent Requests </a><br>
prompt         <a href="#cpadv05"> - Requests Currently Running on a System </a><br>
prompt         <a href="#cpadv061"> - FND_CONCURRENT_REQUESTS Totals </a><br>
prompt         <a href="#cpadv062"> - Running Requests </a><br>
prompt         <a href="#cpadv063"> - Total Pending Requests by Status Code </a><br>
prompt         <a href="#cpadv064"> - Count Pending Regularly Scheduled/Non Regularly-Scheduled Requests </a><br>
prompt         <a href="#cpadv065"> - Count of Pending Requests on Hold/Not on Hold </a><br>
prompt         <a href="#cpadv066"> - Listing of Scheduled Requests </a><br>
prompt         <a href="#cpadv067"> - Listing of Pending Requests on Hold </a> <br>
prompt         <a href="#cpadv068"> - Listing of Pending Requests Not on Hold </a><BR>
prompt         <a href="#cpadv09"> - Volume of Daily Concurrent Requests for Last Month </a> <BR> 
prompt         <a href="#cpadv010"> - Identify/Resolve the Pending/Standby Issue, if Caused by Run Alone Flag </a> <br>
prompt         <a href="#cpadv08"> - Tablespace Statistics for the fnd_concurrent tables</a></blockquote><br>

prompt       <a href="#section3"><b><font size="+1">E-Business Applications Concurrent Manager Analysis</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#cpadv1"> - Concurrent Managers Active and Enabled </a><br>
prompt         <a href="#cpadv2"> - Concurrent Manager Processes by Workshift </a><br>
prompt         <a href="#cpadv3"> - Active Managers for Applications that are not Installed/Used </a><br>
prompt         <a href="#cpadv4"> - Total Target Processes for Request Managers (Excluding Off-Hours) </a> <br>
prompt         <a href="#cpadv5"> - Request Managers with Incorrect Cache Size </a> <br>
prompt         <a href="#cpadv01"> - Concurrent Manager Request Summary by Manager </a> <br>
prompt         <a href="#cpadv02"> - Check Manager Queues for Pending Requests </a> <br>
prompt         <a href="#cpadv07"> - Check the Configuration of OPP </a></blockqoute><br>


prompt         <BR><a href="#cpadv011"> References </a> <br>
prompt     </p>
prompt     </td>
prompt     </tr>
prompt </table>

prompt ________________________________________________________________________________________________<BR><BR>



REM **************************************************************************************** 
REM *******Section 1 : E-Business Applications Concurrent Processing Analyzer Overview         
REM ****************************************************************************************

prompt <a name="section1"></a><B><U><font size="+2">E-Business Applications Concurrent Processing Analyzer Overview</font></B></U><BR><BR>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt 
prompt Configure the runtime table gauge for your site by entering your own settings for the item_cnt variable in cp_analyzer.sql:<BR>
prompt 1. Change the following for the immediate review setting (critical): '(:item_cnt > 5000)'<BR>
prompt 2. Change the following for the review required setting (bad): '(:item_cnt > 3500)'<BR>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

begin

select upper(instance_name) into :sid from v$instance;

select host_name into :host from fnd_product_groups, v$instance;

select release_name into :apps_rel from fnd_product_groups, v$instance;




select count(*) into :item_cnt from fnd_concurrent_requests where phase_code='C';


       
if (:item_cnt > 5000) THEN

  dbms_output.put_line('<b>Concurrent Processing Runtime Data Table Gauge</b><BR>');
  dbms_output.put('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put('\&chxt=y');
  dbms_output.put('\&chs=300x150');
  dbms_output.put('\&cht=gm');
  dbms_output.put('\&chd=t:10');
  dbms_output.put('\&chl=Excessive" width="300" height="150" alt="" />');
  dbms_output.put_line('<BR><BR>');
  
    dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">Your overall Concurrent Processing HealthCheck Status is in need of Immediate Review!</font><BR> ');
    dbms_output.put_line('        The data in the FND_CONCURRENT_REQUESTS Table suggests request purging is never performed on a regular basis.<BR><BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');

  else   if (:item_cnt > 3500) THEN

  dbms_output.put_line('<b>Concurrent Processing Runtime Data Table Gauge</b><BR>');
  dbms_output.put('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put('\&chxt=y');
  dbms_output.put('\&chs=300x150');
  dbms_output.put('\&cht=gm');
  dbms_output.put('\&chd=t:50');
  dbms_output.put('\&chl=Poor" width="300" height="150" alt="" />');
  dbms_output.put_line('<BR><BR>');
  
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">Your overall Concurrent Processing HealthCheck Status is in need of Review!</font><BR> ');
    dbms_output.put_line('        The data in the FND_CONCURRENT_REQUESTS Table suggests request purging is not performed as often as required.<BR><BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
  else

  dbms_output.put_line('<b>Concurrent Processing Runtime Data Table Gauge</b><BR>');
  dbms_output.put('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put('\&chxt=y');
  dbms_output.put('\&chs=300x150');
  dbms_output.put('\&cht=gm');
  dbms_output.put('\&chd=t:90');
  dbms_output.put('\&chl=Healthy" width="300" height="150" alt="" />');
  dbms_output.put_line('<BR><BR>');
  
    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#666600" bgcolor="#99FF99" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">Your overall Concurrent Processing HealthCheck Status is Healthy!</font><BR> ');
    dbms_output.put_line('        The data in the FND_CONCURRENT_REQUESTS Table suggests purging is performed on a regular basis.<BR><BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
  end if;
end if;

end;
/

 

REM
REM ******* Total Purge Eligible Records in FND_CONCURRENT_REQUESTS *******
REM
prompt <a name="cpadv051"></a><B><U>Total Purge Eligible Records in FND_CONCURRENT_REQUESTS </B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the Total # of Purge Eligible Records in FND_CONCURRENT_REQUESTS  <BR>The intent is to proactively identify whether request data needs to be purged. <BR>
prompt
prompt <BR><b>Action:</b><BR> Review Concurrent Processing purging status with your team, and determine when purging was last performed on the system. <BR>FNDCPPUR should be executed on a regular basis to avoid performance issues. 
prompt <BR><BR>

prompt <script type="text/javascript">    function displayRows1sql1(){var row = document.getElementById("s1sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Total Purge Eligible Records in FND_CONCURRENT_REQUESTS</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="1" height="60">
prompt       <blockquote><p align="left">
prompt          select count(*) <br>
prompt          from fnd_concurrent_requests <br>
prompt          where phase_code='C';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||count(*)||'</TD>'||chr(10)||'</TR>'
from fnd_concurrent_requests where phase_code='C';
prompt </TABLE><P><P>


REM
REM ******* This is just a Note *******
REM
 
prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=822368.1" target="_blank">
prompt Note 822368.1</a> - How To Run the Purge Concurrent Request FNDCPPUR, Which Tables Are Purged, And Known Issues Like Files Are Not Deleted From File System or Slow Performance<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Ebusiness Suite Version *******
REM

prompt <a name="wfadv111"></a><B><U>E-Business Suite Version </B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the E-Business Suite Version Information for the system being examined.<BR>
prompt
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and documents the current baseline versions for the system<BR> 
prompt <BR>

prompt <script type="text/javascript">    function displayRows1sql2(){var row = document.getElementById("s1sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv111"></a>
prompt     <B>E-Business Suite Version</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="60">
prompt       <blockquote><p align="left">
prompt          select instance_name, release_name, host_name, <br>
prompt          startup_time, version<br>
prompt          from fnd_product_groups, v$instance;</p>
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
from fnd_product_groups, v$instance;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Concurrent Processing Database Parameter Settings *******
REM

prompt <a name="wfadv112"></a><B><U>Concurrent Processing Database Parameter Settings</B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the Current E-Business Suite Database Parameter Settings for the system being examined.<BR>
prompt
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and documents the current database parameters for the system<BR> 
prompt <BR>

prompt <script type="text/javascript">    function displayRows1sql3(){var row = document.getElementById("s1sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv112"></a>
prompt     <B>Concurrent Processing Database Parameter Settings</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql3" style="display:none">
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




REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=396009.1" target="_blank">
prompt Note 396009.1</a> - Database Initialization Parameters for Oracle E-Business Suite Release 12<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Concurrent Processing Environment Variables *******
REM

prompt <a name="wfadv1121"></a><B><U>Concurrent Processing Environment Variables</B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the Current E-Business Suite Concurrent Processing Environment Variables for the system being examined.<BR>
prompt
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and documents the current environment variables for the system<BR> 
prompt <br>

prompt <script type="text/javascript">    function displayRows1sql4(){var row = document.getElementById("s1sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv1121"></a>
prompt     <B>Concurrent Processing Environment Variables</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="45">
prompt       <blockquote><p align="left">
prompt          select unique variable_name, value<br>
prompt          from FND_ENV_CONTEXT<br>
prompt          where CONCURRENT_PROCESS_ID in<br>
prompt          (select max(CONCURRENT_PROCESS_ID) from FND_CONCURRENT_PROCESSES<br>
prompt           where QUEUE_APPLICATION_ID in (select APPLICATION_ID from FND_APPLICATION where APPLICATION_SHORT_NAME = 'FND'))<br>
prompt           and VARIABLE_NAME in ('APPLTMP','APPLPTMP','REPORTS60_TMP','APPLCSF','APPLLOG','APPLOUT');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>

select unique
'<TR><TD>'||variable_name||'</TD>'||chr(10)|| 
'<TD>'||value||'</TD></TR>'
from FND_ENV_CONTEXT
where CONCURRENT_PROCESS_ID in
      (select max(CONCURRENT_PROCESS_ID) from FND_CONCURRENT_PROCESSES
       where QUEUE_APPLICATION_ID in (select APPLICATION_ID from FND_APPLICATION where APPLICATION_SHORT_NAME = 'FND'))
  and VARIABLE_NAME in ('APPLTMP','APPLPTMP','REPORTS60_TMP','APPLCSF','APPLLOG','APPLOUT');

prompt </TABLE><P><P>




REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1355735.1" target="_blank">
prompt Note 1355735.1</a> - Difference between APPLPTMP and APPLTMP Directories in EBS<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* E-Business Suite Profile Settings *******
REM

prompt <a name="ebsprofile"></a><B><U>E-Business Suite Profile Option Settings</B></U><BR>
prompt <BR><b>Description:</b><BR> Displays the Current E-Business Suite Profile Option settings for the system being examined.<BR>
prompt
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and documents the current profile settings for the system<BR> 
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="ebsprofile"></a>
prompt     <B>E-Business Suite Profile Settings</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="125">
prompt       <blockquote><p align="left">
prompt          select t.PROFILE_OPTION_ID, t.PROFILE_OPTION_NAME, z.USER_PROFILE_OPTION_NAME,<br>
prompt          v.PROFILE_OPTION_VALUE, z.DESCRIPTION<br>
prompt          from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z<br>
prompt          where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)<br>
prompt          and (v.level_id = 10001)<br>
prompt          and (z.LANGUAGE='US')<br>
prompt          and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)<br>
prompt          and (t.PROFILE_OPTION_NAME in ('CONC_GSM_ENABLED','CONC_PP_RESPONSE_TIMEOUT','CONC_TM_TRANSPORT_TYPE','GUEST_USER_PWD',<br>
prompt          'AFLOG_ENABLED','AFLOG_FILENAME','AFLOG_LEVEL','AFLOG_BUFFER_MODE','AFLOG_MODULE','FND_FWK_COMPATIBILITY_MODE',<br>
prompt          'FND_VALIDATION_LEVEL','FND_MIGRATED_TO_JRAD','AMPOOL_ENABLED',<br>
prompt          'CONC_PP_PROCESS_TIMEOUT','CONC_DEBUG','CONC_COPIES','CONC_FORCE_LOCAL_OUTPUT_MODE','CONC_HOLD','CONC_PMON_METHOD',<br>
prompt          'CONC_PP_INIT_DELAY','CONC_PRINT_WARNING','CONC_REPORT_ACCESS_LEVEL','CONC_REQUEST_LIMIT','CONC_SINGLE_THREAD',<BR>
prompt          'CONC_TOKEN_TIMEOUT','CONC_VALIDATE_SUBMISSION','FND_CONC_ALLOW_DEBUG','CP_INSTANCE_CHECK'))<br>
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
and and (z.LANGUAGE='US') 
and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)
and (t.PROFILE_OPTION_NAME in ('CONC_GSM_ENABLED','CONC_TM_TRANSPORT_TYPE','GUEST_USER_PWD','AFLOG_ENABLED','AFLOG_FILENAME','AFLOG_LEVEL','AFLOG_BUFFER_MODE','AFLOG_MODULE','FND_FWK_COMPATIBILITY_MODE',
'FND_MIGRATED_TO_JRAD','AMPOOL_ENABLED','CONC_PP_RESPONSE_TIMEOUT','CONC_PP_PROCESS_TIMEOUT','CONC_DEBUG','CONC_COPIES',
'CONC_FORCE_LOCAL_OUTPUT_MODE','CONC_HOLD','CONC_PMON_METHOD','CONC_PP_INIT_DELAY','CONC_PRINT_WARNING','CONC_REPORT_ACCESS_LEVEL',
'CONC_REQUEST_LIMIT','CONC_SINGLE_THREAD','CONC_TOKEN_TIMEOUT','CONC_VALIDATE_SUBMISSION','FND_CONC_ALLOW_DEBUG','CP_INSTANCE_CHECK'))
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
    dbms_output.put_line('The profile "Concurrent:GSM Enabled" is currently set to Y to allow GSM to manage processes on multiple host machines.<BR>'); 
    dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=210062.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 210062.1</a> - Concurrent Processing - Generic Service Management (GSM) in Oracle Applications, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	
  elsif (:gsm = 'N') then

    dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Error<BR>');
    dbms_output.put_line('The EBS profile "Concurrent:GSM Enabled" is not enabled.</B><BR>');
    dbms_output.put_line('<B>Action</B><BR>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=210062.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 210062.1</a> - Concurrent Processing - Generic Service Management (GSM) in Oracle Applications, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> It is unclear what EBS profile "Concurrent:GSM Enabled" is set to.');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=210062.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 210062.1</a> - Concurrent Processing - Generic Service Management (GSM) in Oracle Applications, for more information.<BR>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

end if;
 
end;
/

REM
REM ******* Applied E-Business Suite Technology Stack Patches *******
REM

prompt <a name="section2"></a><B><U><font size="+2">Applied E-Business Suite Technology Stack Patches</font></B></U><BR><BR>


prompt <a name="wfadv161"></a><B><U>Applied E-Business Suite Technology Stack Patches</B></U><BR>
prompt <BR><b>Description:</b><BR> This section looks to identify the applied E-Business Suite technology stack patches. 
prompt
prompt <BR><b>Action:</b><BR>The intent is to proactively identify and make recommendations on any missing technology stack patches. 
prompt <BR><BR>


prompt <script type="text/javascript">    function displayRows6sql1(){var row = document.getElementById("s6sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv161"></a>
prompt     <B>Applied E-Business Suite Technology Stack Patches</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s6sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="850">
prompt       <blockquote><p align="left">
prompt         select BUG_NUMBER, LAST_UPDATE_DATE,<br> 
prompt         decode(bug_number,<br>
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
prompt         7303030, '12.1.1 Maintenance Pack',<br>
prompt         7651091, 'Oracle Applications Technology Release Update Pack 2 for 12.1 (R12.ATG_PF.B.DELTA.2)',<br>
prompt         7303033, 'Oracle E-Business Suite 12.1.2 Release Update Pack (RUP2)',<br>
prompt         9239089, 'Oracle Applications DBA 12.1.3 Product Release Update Pack',<br>
prompt         8919491, 'Oracle Applications Technology 12.1.3 Product Family Release Update Pack',<br>
prompt         9239090, 'ORACLE E-BUSINESS SUITE 12.1.3 RELEASE UPDATE PACK',<br>
prompt         4175764, '11i.ADXE.1 FEB 2005 CUMULATIVE UPDATE (autoconfig)',<br>
prompt         3453499, 'Patch 11i.ADX.F (autoconfig)',<br>
prompt         2682863, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch C (March 2003)',<br>
prompt         2757379, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch D (June 2003)',<br>
prompt         2902755, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch E (August 2003)',<br>
prompt         3104607, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch F (December 2003)',<br>
prompt         3239694, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch G (February 2004)',<br>
prompt         3416234, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH H (May 2004)',<br>
prompt         3594604, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH I (October 2004)',<br>
prompt         3950067, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH J (FEBRUARY 2005)',<br>
prompt         4104924, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH K (July 2005)',<br>
prompt         4489303, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH L (SEP 2005)',<br>
prompt         4709948, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH M (APRIL 2006)',<br>
prompt         5107107, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH N (AUGUST 2006)',<br>
prompt         5478710, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH O (December 2006)',<br>
prompt         5759055, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH P (MAR/APR 2007)',<br>
prompt         5985992, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH Q (JUL/AUG 2007)',<br>
prompt         6323691, 'TXK AUTOCONFIG AND TEMPLATES ROLLUP PATCH R (OCT/NOV 2007)',<br>
prompt         6372396, 'TXK AUTOCONFIG AND TEMPLATES ROLLUP PATCH S (APRIL/MAY 2008)',<br>
prompt         8217898, 'TXK AUTOCONFIG AND TEMPLATES ROLLUP PATCH T (Jul 2009)',<br>
prompt         2728236, 'OWF.G INCLUDED IN 11.5.9',<br>
prompt         3031977, 'POST OWF.G ROLLUP 1 - 11.5.9.1',<br>
prompt         3061871, 'POST OWF.G ROLLUP 2 - 11.5.9.2',<br>
prompt         3124460, 'POST OWF.G ROLLUP 3 - 11.5.9.3',<br>
prompt         3126422, '11.5.9 Oracle E-Business Suite Consolidated Update 1',<br>
prompt         3171663, '11.5.9 Oracle E-Business Suite Consolidated Update 2',<br>
prompt         3316333, 'POST OWF.G ROLLUP 4 - 11.5.9.4.1',<br>
prompt         3314376, 'POST OWF.G ROLLUP 5 - 11.5.9.5',<br>
prompt         3409889, 'POST OWF.G ROLLUP 5 Consolidated Fixes For OWF.G RUP 5', 3492743, 'POST OWF.G ROLLUP 6 - 11.5.9.6',<br>
prompt         3868138, 'POST OWF.G ROLLUP 7 - 11.5.9.7',<br>
prompt         bug_number) PATCH, ARU_RELEASE_NAME<br>
prompt         from AD_BUGS b <br>
prompt         where b.BUG_NUMBER in ('2728236', '3031977','3061871','3124460','3126422','3171663','3316333',<br>
prompt         '3314376','3409889', '3492743', '3262159', '3262919', '3868138', '3258819','3438354','3240000', <br>
prompt         '3460000', '3140000','3480000','4017300', '4125550', '6047864', '6008417','5121512', '4334965', <br>
prompt         '4676589', '5473858', '5903765', '6241631', '4440000','5082400','5484000','6141000','6435000', <br>
prompt         '5907545','5917344','6077669','6272680','7237006','6728000','7303030', '7651091', '7303033', <br>
prompt         '9239089', '8919491', '9239090','4175764','3453499','2682863','2757379','2902755','3104607',<br>
prompt         '3239694','3416234','3594604','3950067','4104924','4489303','4709948','5107107','5478710',<br>
prompt         '5759055','5985992','6323691','6372396','8217898')<br>
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
'<TD>'||decode(bug_number,3262919, 'FMWK.H',
3262159, 'FND.H INCLUDE OWF.H',
3258819, 'OWF.H INCLUDED IN 11.5.10',
3438354, '11i.ATG_PF.H INCLUDE OWF.H',
3140000, 'ORACLE APPLICATIONS RELEASE 11.5.10 MAINTENANCE PACK',
3240000, '11.5.10 ORACLE E-BUSINESS SUITE CONSOLIDATED UPDATE 1',
3460000, '11.5.10 ORACLE E-BUSINESS SUITE CONSOLIDATED UPDATE 2',
3480000, 'ORACLE APPLICATIONS RELEASE 11.5.10.2 MAINTENANCE PACK',
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
6435000, '12.0.4 RELEASE UPDATE PACK (RUP4)',
5907545, 'R12.ATG_PF.A.DELTA.1',
5917344, 'R12.ATG_PF.A.DELTA.2',
6077669, 'R12.ATG_PF.A.DELTA.3',
6272680, 'R12.ATG_PF.A.DELTA.4', 
7237006, 'R12.ATG_PF.A.DELTA.6',
6728000, '12.0.6 RELEASE UPDATE PACK (RUP6)', 
7303030, '12.1.1 Maintenance Pack',
7651091, 'Oracle Applications Technology Release Update Pack 2 for 12.1 (R12.ATG_PF.B.DELTA.2)',
7303033, 'Oracle E-Business Suite 12.1.2 Release Update Pack (RUP2)',
9239089, 'Oracle Applications DBA 12.1.3 Product Release Update Pack',
8919491, 'Oracle Applications Technology 12.1.3 Product Family Release Update Pack',
9239090, 'ORACLE E-BUSINESS SUITE 12.1.3 RELEASE UPDATE PACK',
4175764, '11i.ADXE.1 FEB 2005 CUMULATIVE UPDATE (autoconfig)',
3453499, 'Patch 11i.ADX.F (autoconfig)',
2682863, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch C (March 2003)',
2757379, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch D (June 2003)',
2902755, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch E (August 2003)',
3104607, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch F (December 2003)',
3239694, 'TXK (FND) AutoConfig TEMPLATE ROLLUP Patch G (February 2004)',
3416234, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH H (May 2004)',
3594604, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH I (October 2004)',
3950067, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH J (FEBRUARY 2005)',
4104924, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH K (July 2005)',
4489303, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH L (SEP 2005)',
4709948, 'TXK (FND) AUTOCONFIG TEMPLATE ROLLUP PATCH M (APRIL 2006)',
5107107, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH N (AUGUST 2006)',
5478710, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH O (December 2006)',
5759055, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH P (MAR/APR 2007)',
5985992, 'TXK (FND/ADX) AUTOCONFIG ROLLUP PATCH Q (JUL/AUG 2007)',
6323691, 'TXK AUTOCONFIG AND TEMPLATES ROLLUP PATCH R (OCT/NOV 2007)',
6372396, 'TXK AUTOCONFIG AND TEMPLATES ROLLUP PATCH S (APRIL/MAY 2008)',
8217898, 'TXK AUTOCONFIG AND TEMPLATES ROLLUP PATCH T (Jul 2009)',
2728236, 'OWF.G INCLUDED IN 11.5.9',
3031977, 'POST OWF.G ROLLUP 1 - 11.5.9.1',
3061871, 'POST OWF.G ROLLUP 2 - 11.5.9.2',
3124460, 'POST OWF.G ROLLUP 3 - 11.5.9.3',
3126422, '11.5.9 Oracle E-Business Suite Consolidated Update 1',
3171663, '11.5.9 Oracle E-Business Suite Consolidated Update 2',
3316333, 'POST OWF.G ROLLUP 4 - 11.5.9.4.1',
3314376, 'POST OWF.G ROLLUP 5 - 11.5.9.5',
3409889, 'POST OWF.G ROLLUP 5 Consolidated Fixes For OWF.G RUP 5', 3492743, 'POST OWF.G ROLLUP 6 - 11.5.9.6',
3868138, 'POST OWF.G ROLLUP 7 - 11.5.9.7',
bug_number)||'</TD>'||chr(10)|| 
'<TD>'||ARU_RELEASE_NAME||'</TD></TR>' 
from AD_BUGS b 
where b.BUG_NUMBER in ('2728236', '3031977','3061871','3124460','3126422','3171663','3316333','3314376','3409889', '3492743', '3262159', '3262919', '3868138', '3258819','3438354','3240000', '3460000', '3140000','3480000','4017300', '4125550', '6047864', '6008417','5121512', '4334965', '4676589', '5473858', '5903765', '6241631', '4440000','5082400','5484000','6141000','6435000', 
'5907545','5917344','6077669','6272680','7237006','6728000','7303030', '7651091', '7303033', '9239089', '8919491', '9239090','4175764','3453499','2682863','2757379','2902755','3104607','3239694','3416234','3594604','3950067','4104924','4489303','4709948','5107107','5478710','5759055','5985992','6323691','6372396','8217898')
order by BUG_NUMBER,LAST_UPDATE_DATE,ARU_RELEASE_NAME; 
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <a name="atgrups"></a><B><font size="+2">Known 1-Off Patches on top of E-Business Suite Technology Stack Rollups</font></B><BR><BR>

begin


select release_name into :apps_rel 
from fnd_product_groups;

       dbms_output.put_line('This instance has Oracle Applications version ' || :apps_rel || '.<BR><BR>'); 
       
   if (:apps_rel is null) then 

       dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bgcolor="#DEE6EF" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Warning</B><BR>');
       dbms_output.put_line('There is a problem reading the Oracle Apps version : ' || :apps_rel || ' for this instance. ');
       dbms_output.put_line('<BR>');       
       
   elsif (:apps_rel < '11.5.10') then 

       dbms_output.put_line('<B>Warning</B><BR>');
       dbms_output.put_line('The Oracle Apps version is = 11.5.9 (' || :apps_rel || ') for this instance. ');
       dbms_output.put_line('<BR>');

   elsif (:apps_rel > '11.5.10' and :apps_rel < '12.0') then 

              dbms_output.put_line('<b>11i.ATG_PF.H RUP6 and 11i.ATG_PF.H RUP7</b>');
       dbms_output.put_line('<table width="83%" border="1">');
       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" > ');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">5998511</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">CONCURRENT PROCESSING ROLLUP PATCH FOR 11i.ATG_PF.H.RUP6 (5903765) </td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">8320765</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">CP CONSOLIDATED BUG FOR POST 11.5.10.7 (11.5.10.8) ');
       dbms_output.put_line('USING ATTRIB </td>');
       dbms_output.put_line('<td width="16%"></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">4005572</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">FND:CP - XML PUBLISHER INTEGRATION INFRASTRUCTURE </td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">3897938</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">OAM:NEW CP MANAGER TYPE "OUTPUT POST PROCESSOR" WILL REQUIRE CUSTOMIZE UI</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">4003721</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">FND:CP OAF UI FOR XML PUBLISHER INTEGRATION</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">4005559</div>');
       dbms_output.put_line('</td>');
       dbms_output.put_line('<td width="74%">FND:OUTPUT POST PROCESSOR INFRASTRUCTURE</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('</table><BR><BR>');

   elsif (:apps_rel >= '12.0' and :apps_rel < '12.1') then 

       dbms_output.put_line('<B>One-Off Patches on top of Supported ATG Roll-Up Patches (RUP) for ' || :apps_rel || '.</B><br><br>');
       
         
       dbms_output.put_line('<p><b>Rel 12.0.6</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">4505157</div></td>');
       dbms_output.put_line('<td width="74%">CP ROLLUP PCC FOR PROPAGATION OF 11i BUG FIXES TO R12.0</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">4548420</div></td>');
       dbms_output.put_line('<td width="74%">CP WEBINTERFACE ROLLUPPATCH A FOR PROPAGATION OF FWK 11.5.10.3CUBUGFIXES TO R12</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">8330911</div></td>');
       dbms_output.put_line('<td width="74%">CP CONSOLIDATED BUG FOR 12.0.7 (FND.A)</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066"> ');
       dbms_output.put_line('<td width="10%"> ');
       dbms_output.put_line('<div align="center">6027050</div></td>');
       dbms_output.put_line('<td width="74%">CONCURRENT PROCESSING ROLLUP PATCH FOR R12.FND.A.Delta3</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('</table><BR><BR>');

   elsif (:apps_rel >= '12.1' and :apps_rel < '12.2') then 

       dbms_output.put_line('<B>One-Off Patches on top of Supported ATG Roll-Up Patches (RUP) for ' || :apps_rel || '.</B><br><br>');
       
        
       dbms_output.put_line('<p><b>Rel 12.1.2 - 12.1.3</b><br>');
       dbms_output.put_line('<table width="83%" border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
       dbms_output.put_line('<td width="10%"><b>Patch #</b></td>');
       dbms_output.put_line('<td width="74%"><b>Abstract</b></td>');
       dbms_output.put_line('<td width="16%"><b>Superseeded by</b></td>');
       dbms_output.put_line('</tr>');
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">5897723</div></td>');
       dbms_output.put_line('<td width="74%">R12 CP WEB INTERFACE NEW FEATURES PATCH A-ENH (12.1)</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">5897791</div></td>');
       dbms_output.put_line('<td width="74%">R12 CP NEW FEATURES PATCH A-ENH (12.1)</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
dbms_output.put_line('<tr bordercolor="#000066">');
       dbms_output.put_line('<td width="10%">');
       dbms_output.put_line('<div align="center">9973226</div></td>');
       dbms_output.put_line('<td width="74%">CP CONSOLIDATED BUG FOR 12.1.4 (FND.B)</td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('</table><BR><BR>');

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
       dbms_output.put_line('<div align="center">12417327</div></td>');
       dbms_output.put_line('<td width="74%">CP CONSOLIDATED BUG FOR POST 12.2 </td>');
       dbms_output.put_line('<td width="16%">n/a</td>');
       dbms_output.put_line('</tr>');       
       dbms_output.put_line('</table><BR><BR>');

       
    end if;       
       
       dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');
       
       dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td>');
       dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1304305.1"');
       dbms_output.put_line('target="_blank">Note 1304305.1</a> - Concurrent Processing - Product Information Center (PIC)<br><br>');
       dbms_output.put_line('</td></tr></tbody></table><BR><BR>');

end;
/


REM **************************************************************************************** 
REM ******* Section 2 : E-Business Applications Concurrent Request Analysis          *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><U><font size="+2">E-Business Applications Concurrent Request Analysis</font></B></U><BR><BR>


prompt <a name="cpadv03"></a><B><U>Long Running Reports During Business Hours (Concurrent Program Name, Count, Avg Run Time, Min Run Time, Max Run Time)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section looks to identify to long running requests during business hours. <BR>The intent is to proactively identify requests which could represent potential performance problems. <BR>
prompt
prompt <BR><b>Action:</b><BR> Review the requests listed and confirm if they are intended to run for longer amounts of time. <BR>If the wrong date range is used or a large volume of data exists for the request, a longer run time can be expected.  <BR>Monthly, Quarterly, and Yearly requests would typically run longer. 
prompt <BR><BR>
 
prompt <script type="text/javascript">    function displayRows2sql3(){var row = document.getElementById("s2sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Long Running Reports During Business Hours (Concurrent Program Name, Count, Avg Run Time, Min Run Time, Max Run Time) </B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="85">
prompt       <blockquote><p align="left">
prompt          select p.user_concurrent_program_name program_name, count(r.request_id),<br>
prompt          avg((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440) avg_run_time,<br>
prompt          min((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440) min_run_time,<br>
prompt          max((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440) max_run_time<br>
prompt          from apps.fnd_concurrent_requests r, apps.fnd_concurrent_processes c, apps.fnd_concurrent_queues q,<br>
prompt          apps.fnd_concurrent_programs_vl p<br>
prompt          where p.concurrent_program_id = r.concurrent_program_id and p.application_id = r.program_application_id<br>
prompt          and c.concurrent_process_id = r.controlling_manager and q.concurrent_queue_id = c.concurrent_queue_id<br>
prompt          and q.concurrent_queue_name <> 'HIGH_IMPACT'and p.application_id >= 20000 and r.actual_start_date >= sysdate-31<br>
prompt          and r.status_code = 'C' and r.phase_code in ('C','G')<br>
prompt          and (nvl(r.actual_completion_date,r.actual_start_date) - r.actual_start_date) * 24 * 60 > 30<br>
prompt          and p.user_concurrent_program_name not like 'Gather%Statistics%'<br>
prompt          and ((nvl(r.actual_completion_date,r.actual_start_date) - r.actual_start_date) * 24 > 16<br>
prompt          or (r.actual_start_date-trunc(r.actual_start_date)) * 24 between 9 and 17<br>
prompt          or (r.actual_completion_date-trunc(r.actual_completion_date)) * 24 between 9 and 17)<br>
prompt          group by p.user_concurrent_program_name;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AVG RUN TIME MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MIN RUN TIME MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MAX RUNTIME MINUTES</B></TD>

select  
'<TR><TD>'||p.user_concurrent_program_name||'</TD>'||chr(10)|| 
'<TD>'||count(r.request_id)||'</TD>'||chr(10)||
'<TD>'||round(avg((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440), 2)||'</TD>'||chr(10)||
'<TD>'||round(min((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440), 2)||'</TD>'||chr(10)||
'<TD>'||round(max((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440), 2)||'</TD>'||chr(10)||'</TR>'
from 
apps.fnd_concurrent_requests r,
    apps.fnd_concurrent_processes c,
    apps.fnd_concurrent_queues q,
    apps.fnd_concurrent_programs_vl p
where
    p.concurrent_program_id = r.concurrent_program_id
    and p.application_id = r.program_application_id
    and c.concurrent_process_id = r.controlling_manager
    and q.concurrent_queue_id = c.concurrent_queue_id
    and q.concurrent_queue_name <> 'HIGH_IMPACT'
    and p.application_id >= 20000
    and r.actual_start_date >= sysdate-31
    and r.status_code = 'C'
    and r.phase_code in ('C','G')
    and (nvl(r.actual_completion_date,r.actual_start_date) - r.actual_start_date) * 1440 > 30
    and p.user_concurrent_program_name not like 'Gather%Statistics%'
    and (
      (nvl(r.actual_completion_date,r.actual_start_date) - r.actual_start_date) * 24 > 16
      or
      (r.actual_start_date-trunc(r.actual_start_date)) * 24 between 9 and 17
      or
      (r.actual_completion_date-trunc(r.actual_completion_date)) * 24 between 9 and 17
    )
group by p.user_concurrent_program_name;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Elapsed time history of concurrent requests  *******
REM

prompt <a name="cpadv04"></a><B><U>Elapsed time history of concurrent requests (Sorted by number of executions)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section identifies the total time duration for recently completed requests.<BR>
prompt <BR><b>Action:</b><BR> The output produced can be cross referenced with the enabled managers and defined workshifts outputs, for better 
prompt allocation of requests across the existing managers/workshifts. For example you can consider assigning quick requests to one manager 
prompt and/or workshift, and assigning slow requests to another manager and/or workshift.  Requests with varying runtimes can also be moved 
prompt to their own manager, or remain with the standard manager queue.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql4(){var row = document.getElementById("s2sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=13 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Elapsed Time History of Concurrent Requests (Sorted by number of executions)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="14" height="85">
prompt       <blockquote><p align="left">
prompt        select f.application_short_name, substr(p.user_concurrent_program_name,1,55),<br>
prompt        substr(p.concurrent_program_name,1,20) program, r.priority, count(*),<br>
prompt        sum(actual_completion_date - actual_start_date) * 1440,<br>
prompt       avg(actual_completion_date - actual_start_date) * 1440 ,<br>
prompt       max(actual_completion_date - actual_start_date) * 1440,<br>
prompt       min(actual_completion_date - actual_start_date) * 1440,<br>
prompt       stddev(actual_completion_date - actual_start_date) * 1440,<br>
prompt       stddev(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440,<br>
prompt       sum(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440,<br>
prompt       avg(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440,<br>
prompt       c.request_class_name<br>
prompt      from apps.fnd_concurrent_request_class c, apps.fnd_application f, apps.fnd_concurrent_programs_vl p,<br>
prompt      apps.fnd_concurrent_requests r <br>
prompt      where r.program_application_id = p.application_id and r.concurrent_program_id = p.concurrent_program_id<br>
prompt      and r.status_code in ('C','G') and r.phase_code = 'C' and p.application_id = f.application_id<br>
prompt      and r.program_application_id = f.application_id and r.request_class_application_id = c.application_id(+)<br>
prompt      and r.concurrent_request_class_id = c.request_class_id(+)<br>
prompt      group by c.request_class_name, f.application_short_name, p.concurrent_program_name, p.user_concurrent_program_name, r.priority
prompt      order by count(*);</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PRIORITY</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>#TIMESRUN/SORT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL|MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AVG|MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MAX|MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MIN|MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RUN|STDDEV MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WAIT|STDDEV MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>#WAITED|MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AVG|WAIT MINUTES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>

select  
'<TR><TD>'||f.application_short_name||'</TD>'||chr(10)|| 
'<TD>'||substr(p.user_concurrent_program_name,1,55)||'</TD>'||chr(10)|| 
'<TD>'||substr(p.concurrent_program_name,1,20)||'</TD>'||chr(10)|| 
'<TD>'||r.priority||'</TD>'||chr(10)|| 
'<TD>'||count(*)||'</TD>'||chr(10)|| 
'<TD>'||round(sum(actual_completion_date - actual_start_date) * 1440/60, 2)||'</TD>'||chr(10)||
'<TD>'||round(avg(actual_completion_date - actual_start_date) * 1440/60, 2)||'</TD>'||chr(10)||
'<TD>'||round(max(actual_completion_date - actual_start_date) * 1440/60, 2)||'</TD>'||chr(10)||
'<TD>'||round(min(actual_completion_date - actual_start_date) * 1440/60, 2)||'</TD>'||chr(10)||
'<TD>'||round(stddev(actual_completion_date - actual_start_date) * 1440, 2)||'</TD>'||chr(10)||
'<TD>'||round(stddev(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440, 2)||'</TD>'||chr(10)||
'<TD>'||round(sum(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440/60, 2)||'</TD>'||chr(10)||
'<TD>'||round(avg(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440/60, 2)||'</TD>'||chr(10)||
'<TD>'||c.request_class_name||'</TD></TR>'
FROM 
     apps.fnd_concurrent_request_class c,
     apps.fnd_application f,
     apps.fnd_concurrent_programs_vl p,
     apps.fnd_concurrent_requests r
WHERE
r.program_application_id = p.application_id
   and r.concurrent_program_id = p.concurrent_program_id
   and r.status_code in ('C','G') 
   and r.phase_code = 'C'
   and p.application_id = f.application_id
   and r.program_application_id = f.application_id
   and r.request_class_application_id = c.application_id(+)
   and r.concurrent_request_class_id = c.request_class_id(+)
GROUP BY
   c.request_class_name,
   f.application_short_name,
   p.concurrent_program_name,
   p.user_concurrent_program_name,
   r.priority
ORDER BY count(*);
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Requests Currently Running on a System *******
REM

prompt <a name="cpadv05"></a><B><U>Requests Currently Running on a System</B></U><BR>
prompt <BR><b>Description:</b><BR> This reflects a summary for all concurrent requests running on the instance with thier current state.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently running on the system. Otherwise there is no immediate action required.
prompt <BR><BR>

prompt <script type="text/javascript">    function displayRows2sql5(){var row = document.getElementById("s2sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=12 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Requests Currently Running on a System</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="13" height="85">
prompt       <blockquote><p align="left">
prompt          select w.seconds_in_wait "Secondswait", w.event "waitEvent", w.p1||chr(10)||w.p2||chr(10)||w.p3 "Session Wait",<BR>
prompt          p.spid||chr(10)||s.process "ServerClient", s.sid||chr(10)||s.serial#||chr(10)||s.sql_hash_value "SidSerialSQLHash",<BR>
prompt          u.user_name||chr(10)||PHASE_CODE||' '||STATUS_CODE||chr(10)||s.status "DBPhaseStatusCODEUser",<BR>
prompt          Request_id||chr(10)||priority_request_id||chr(10)||Parent_request_id "Request_id",<BR>
prompt          concurrent_program_name, user_concurrent_program_name,<BR>
prompt          requested_start_Date||chr(10)||round((sysdate- requested_start_date)*1440, 2)||'M' "RequestStartDate",<BR>
prompt          ARGUMENT_TEXT, CONCURRENT_QUEUE_ID, QUEUE_DESCRIPTION<BR>
prompt          FROM FND_CONCURRENT_WORKER_REQUESTS, fnd_user u, v$session s, v$process p, v$session_wait w <BR>
prompt          WHERE (Phase_Code='R')and hold_flag != 'Y'and Requested_Start_Date <= SYSDATE <BR>
prompt          AND ('' IS NULL OR ('' = 'B' AND PHASE_CODE = 'R' AND STATUS_CODE IN ('I', 'Q')))and '1' in (0,1,4)<BR>
prompt          and requested_by=u.user_id and s.paddr=p.addr and s.sid=w.sid and oracle_process_id = p.spid<BR>
prompt          and oracle_session_id = s.audsid <BR>
prompt          order by requested_start_date;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Secondswait</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>waitEvent</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Session Wait</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ServerClient</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SidSerialSQLHash</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DBPhaseStatusCodeUser</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Request_id</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>concurrent_program_name</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>user_concurrent_program_name</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RequestStartDate</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENT_TEXT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONCURRENT_QUEUE_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE_DESCRIPTION</B></TD>

select  
'<TR><TD>'||w.seconds_in_wait||'</TD>'||chr(10)|| 
'<TD>'||w.event||'</TD>'||chr(10)|| 
'<TD>'||w.p1||chr(10)||w.p2||chr(10)||w.p3 ||'</TD>'||chr(10)|| 
'<TD>'||p.spid||chr(10)||s.process||'</TD>'||chr(10)|| 
'<TD>'||s.sid||chr(10)||s.serial#||chr(10)||s.sql_hash_value||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||chr(10)||PHASE_CODE||' '||STATUS_CODE||chr(10)||s.status||'</TD>'||chr(10)|| 
'<TD>'||Request_id||chr(10)||priority_request_id||chr(10)||Parent_request_id||'</TD>'||chr(10)|| 
'<TD>'||concurrent_program_name||'</TD>'||chr(10)|| 
'<TD>'||user_concurrent_program_name||'</TD>'||chr(10)|| 
'<TD>'||requested_start_Date||chr(10)||round((sysdate- requested_start_date)*1440, 2)||'M'||'</TD>'||chr(10)|| 
'<TD>'||ARGUMENT_TEXT||'</TD>'||chr(10)|| 
'<TD>'||CONCURRENT_QUEUE_ID||'</TD>'||chr(10)|| 
'<TD>'||QUEUE_DESCRIPTION||'</TD></TR>'
FROM FND_CONCURRENT_WORKER_REQUESTS, fnd_user u, v$session s, v$process p, v$session_wait w 
WHERE (Phase_Code='R')and hold_flag != 'Y'and Requested_Start_Date <= SYSDATE  
AND ('' IS NULL OR ('' = 'B' AND PHASE_CODE = 'R' AND STATUS_CODE IN ('I', 'Q')))and '1' in (0,1,4)
and requested_by=u.user_id and s.paddr=p.addr and s.sid=w.sid and oracle_process_id = p.spid
and oracle_session_id = s.audsid 
order by requested_start_date;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* FND_CONCURRENT_REQUESTS Totals (Phase, Request Count)  *******
REM

prompt <a name="cpadv061"></a><B><U>FND_CONCURRENT_REQUESTS Totals (Phase, Request Count)</B></U><BR>
prompt <BR><b>Description:</b><BR> Provides a count of concurrent requests in a state of: Pending, Running, or Completed. <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of how often you are purging Concurrent Request tables. If the total records are too large performance issues can result and FNDCPPUR should be run, otherwise there is no immediate action required. 
prompt <BR><BR>

prompt <script type="text/javascript">    function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>FND_CONCURRENT_REQUESTS Totals (Phase, Request Count)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="85">
prompt       <blockquote><p align="left">
prompt          SELECT  decode(phase_code, 'P', 'Pending requests','R', 'Running requests','C', 'Completed requests',phase_code)<BR>
prompt           phase, count(*) numreqs<BR>
prompt           FROM    fnd_concurrent_requests<BR>
promtp           GROUP BY phase_code;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE CODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B># OF REQUESTS</B></TD>
select  
'<TR><TD>'||decode(phase_code, 'P', 'Pending requests','R', 'Running requests','C', 'Completed requests')||'</TD>'||chr(10)|| 
'<TD>'||count(*)||'</TD></TR>'
from fnd_concurrent_requests
group by phase_code;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Running Requests (Request ID, Request Status, Concurrent Program Name, Start Date, Run Alone Flag) *******
REM

prompt <a name="cpadv062"></a><B><U> Running Requests (Request ID, Request Status, Concurrent Program Name, Start Date, Run Alone Flag)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section collects details on all requests that are currently Running. <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently running on the system. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql8(){var row = document.getElementById("s2sql8");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Running Requests (Request ID, Request Status, Concurrent Program Name, Start Date, Run Alone Flag)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql8()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql8" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="165">
prompt       <blockquote><p align="left">
prompt       SELECT request_id id, nvl(meaning, 'UNKNOWN') status, user_concurrent_program_name rpname,<BR>
prompt       to_char(actual_start_date, 'DD-MON-RR HH24:MI:SS') sd, decode(run_alone_flag, 'Y', 'Yes', 'No') ra<BR>
prompt       FROM   fnd_concurrent_requests fcr, fnd_lookups fl, fnd_concurrent_programs_vl fcpv<BR>
prompt       WHERE  phase_code = 'R' AND LOOKUP_TYPE = 'CP_STATUS_CODE' AND lookup_code = status_code<BR>
prompt       AND fcr.concurrent_program_id = fcpv.concurrent_program_id AND fcr.program_application_id = fcpv.application_id<BR>
prompt       ORDER BY actual_start_date, request_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>START DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RUN ALONE FLAG</B></TD>
select  
'<TR><TD>'||request_id||'</TD>'||chr(10)|| 
'<TD>'||nvl(meaning, 'UNKNOWN')||'</TD>'||chr(10)||
'<TD>'||user_concurrent_program_name||'</TD>'||chr(10)|| 
'<TD>'||to_char(actual_start_date, 'DD-MON-RR HH24:MI:SS')||'</TD>'||chr(10)||
'<TD>'||decode(run_alone_flag, 'Y', 'Yes', 'No')||'</TD></TR>'
FROM   fnd_concurrent_requests fcr, fnd_lookups fl, fnd_concurrent_programs_vl fcpv
WHERE  phase_code = 'R' AND LOOKUP_TYPE = 'CP_STATUS_CODE' AND lookup_code = status_code
AND fcr.concurrent_program_id = fcpv.concurrent_program_id AND fcr.program_application_id = fcpv.application_id
ORDER BY actual_start_date, request_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Total Pending Requests by Status Code (Request Phase, Request Status, Request Count)  *******
REM

prompt <a name="cpadv063"></a><B><U> Total Pending Requests by Status Code (Request Phase, Request Status, Request Count)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides another view of all Concurrent Requests that are currently Pending sorted by status code. <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently pending on the system. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql9(){var row = document.getElementById("s2sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Total Pending Requests by Status Code (Request Phase, Request Status, Request Count) </B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql9" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="85">
prompt       <blockquote><p align="left">
prompt       SELECT 'Pending' pphase, meaning status, count(*) numreqs<BR>
prompt       FROM   fnd_concurrent_requests, fnd_lookups<BR>
prompt       WHERE  LOOKUP_TYPE = 'CP_STATUS_CODE' AND lookup_code = status_code AND phase_code = 'P'<BR>
prompt       GROUP BY meaning;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST COUNT</B></TD>
select  
'<TR><TD>'||'Pending'||'</TD>'||chr(10)|| 
'<TD>'||meaning||'</TD>'||chr(10)|| 
'<TD>'||count(*)||'</TD></TR>'
  FROM fnd_concurrent_requests, fnd_lookups
WHERE  LOOKUP_TYPE = 'CP_STATUS_CODE' AND lookup_code = status_code AND phase_code = 'P'
 group by meaning;
prompt </TABLE><P><P>

REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=134033.1" target="_blank">
prompt Note 134033.1</a> - ANALYZEPENDING.SQL - Analyze all Pending Requests<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Count Pending Regularly Scheduled/Non Regularly-Scheduled Requests (Count of Regularly Scheduled Requests, Count of Non Regularly Scheduled Requests)  *******
REM

prompt <a name="cpadv064"></a><B><U> Count of Pending Regularly Scheduled/Non Regularly Scheduled Requests (Count of Pending Scheduled Requests, Count of Pending Non-Scheduled Requests)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section displays a count all pending Concurrent requests that are Regularly Scheduled and those pending requests which are not Regularly scheduled.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. Otherwise there is no immediate action required.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql10(){var row = document.getElementById("s2sql10");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Count of Pending Regularly Scheduled Requests (Count of Pending Regularly Scheduled Requests)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql10()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql10" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="50">
prompt       <blockquote><p align="left">
prompt          select 'Pending Regularly Scheduled requests:' schedt, count(*) schedcnt<BR>
prompt          from   fnd_concurrent_requests<BR>
prompt          WHERE  (requested_start_date > sysdate OR status_code = 'P') AND phase_code = 'P';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PENDING REGULARLY SCHEDULED REQUESTS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||'Pending Regularly Scheduled Requests:'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||count(*)||'</div></TD></TR>'
from fnd_concurrent_requests
WHERE  (requested_start_date > sysdate OR status_code = 'P') AND phase_code = 'P';
prompt </TABLE><P><P>

prompt <script type="text/javascript">    function displayRows2sql11(){var row = document.getElementById("s2sql11");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Count of Pending Non Regularly Scheduled Requests (Count of Pending Non Regularly Scheduled Requests)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql11()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql11" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="50">
prompt       <blockquote><p align="left">
prompt          select 'Pending Non Regularly Scheduled requests:' schedt, count(*) schedcnt<BR>
prompt          from   fnd_concurrent_requests<BR>
prompt          WHERE  requested_start_date <= sysdate AND status_code != 'P' AND phase_code = 'P';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PENDING NON REGULARLY SCHEDULED REQUESTS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||'Pending Non Regularly Scheduled Requests:'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||count(*)||'</div></TD></TR>'
from fnd_concurrent_requests
WHERE  requested_start_date <= sysdate AND status_code != 'P' AND phase_code = 'P';
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Count of Pending Requests on Hold/Not on Hold (Count of Pending Requests On Hold, Count of Pending Requests Not on Hold)  *******
REM

prompt <a name="cpadv065"></a><B><U>Count of Pending Requests on Hold/Not on Hold (Count of Pending Requests On Hold, Count of Pending Requests Not on Hold)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section provides a count of the Total Pending Requests that are currently on Hold and those pending requests not on Hold<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently on hold in the system. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql12(){var row = document.getElementById("s2sql12");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Count of Pending Requests on Hold (Count of Pending Requests On Hold)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql12()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql12" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="50">
prompt       <blockquote><p align="left">
prompt          select 'Pending Requests on hold:' schedt, count(*) schedcnt<BR>
prompt          from   fnd_concurrent_requests<BR>
prompt          WHERE  hold_flag = 'Y' AND phase_code = 'P';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PENDING REQUESTS ON HOLD</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||'Pending Requests on hold:'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||count(*)||'</div></TD></TR>'
from fnd_concurrent_requests
WHERE  hold_flag = 'Y' AND phase_code = 'P';
prompt </TABLE><P><P>

prompt <script type="text/javascript">    function displayRows2sql13(){var row = document.getElementById("s2sql13");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv125"></a>
prompt     <B>Count of Pending Requests Not on Hold ( Count of Pending Requests Not on Hold)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql13()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql13" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="50">
prompt       <blockquote><p align="left">
prompt          select 'Pending Requests Not on hold:' schedt, count(*) schedcnt<BR>
prompt          from   fnd_concurrent_requests<BR>
prompt          WHERE  hold_flag != 'Y' AND phase_code = 'P';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PENDING REQUESTS NOT ON HOLD</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
select  
'<TR><TD>'||'Pending Requests not on Hold:'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||count(*)||'</div></TD></TR>'
from fnd_concurrent_requests
WHERE  hold_flag != 'Y' AND phase_code = 'P';
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Listing of Scheduled Requests (Request ID, Status, Program Name, Request Date, Start Date) *******
REM

prompt <a name="cpadv066"></a><B><U>Listing of Scheduled Requests (Request ID, Status, Program Name, Request Date, Start Date)</B></U><BR>
prompt <BR><b>Description:</b><BR> A listing of Requests that are currently Scheduled to be run <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. Otherwise there is no immediate action required.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql14(){var row = document.getElementById("s2sql14");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv126"></a>
prompt     <B>Listing of Scheduled Requests (Request ID, Status, Program Name, Request Date, Start Date)</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql14()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql14" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT request_id id, nvl(meaning, 'UNKNOWN') status, user_concurrent_program_name pname,<BR>
prompt          to_char(request_date, 'DD-MON-RR HH24:MI:SS') submitd, to_char(requested_start_date, 'DD-MON-RR HH24:MI:SS') requestd<BR>
prompt          FROM   fnd_concurrent_requests fcr,  fnd_lookups fl,  fnd_concurrent_programs_vl fcpv<BR>
prompt          WHERE  phase_code = 'P' AND (fcr.requested_start_date >= sysdate OR status_code = 'P')<BR>
prompt          AND LOOKUP_TYPE = 'CP_STATUS_CODE' AND lookup_code = status_code AND fcr.concurrent_program_id = fcpv.concurrent_program_id<BR>
prompt          AND fcr.program_application_id = fcpv.application_id<BR>
prompt          ORDER BY request_date, request_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUESTED_START_DATE</B></TD>
select  
'<TR><TD>'||request_id||'</TD>'||chr(10)|| 
'<TD>'||nvl(meaning, 'UNKNOWN')||'</TD>'||chr(10)|| 
'<TD>'||user_concurrent_program_name||'</TD>'||chr(10)|| 
'<TD>'||to_char(request_date, 'DD-MON-RR HH24:MI:SS')||'</TD>'||chr(10)|| 
'<TD>'||to_char(requested_start_date, 'DD-MON-RR HH24:MI:SS')||'</TD></TR>'
FROM   fnd_concurrent_requests fcr,
       fnd_lookups fl,
       fnd_concurrent_programs_vl fcpv
WHERE  phase_code = 'P'
AND    (fcr.requested_start_date >= sysdate OR
        status_code = 'P')
AND    LOOKUP_TYPE = 'CP_STATUS_CODE'
AND    lookup_code = status_code
AND    fcr.concurrent_program_id = fcpv.concurrent_program_id
AND    fcr.program_application_id = fcpv.application_id
ORDER BY request_date, request_id;
prompt </TABLE><P><P>


REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>Note: For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=213021.1" target="_blank">
prompt Note 213021.1</a> - Concurrent Processing (CP) / APPS Reporting Scripts<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Listing of Pending Requests on Hold ((Request ID, Status, Program Name, Request Date) *******
REM

prompt <a name="cpadv067"></a><B><U>Listing of Pending Requests on Hold ((Request ID, Status, Program Name, Request Date)</B></U><BR>
prompt <BR><b>Description:</b><BR> A listing of All Pending Requests Currently on Hold and wating to be run <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. Otherwise there is no immediate action required.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql15(){var row = document.getElementById("s2sql15");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv126"></a>
prompt     <B>Listing of Pending Requests on Hold ((Request ID, Status, Program Name, Request Date)</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql15()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql15" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT request_id id, nvl(meaning, 'UNKNOWN') status, user_concurrent_program_name pname,<BR>
prompt          to_char(request_date, 'DD-MON-RR HH24:MI:SS') submitd<BR>
prompt          FROM   fnd_concurrent_requests fcr,  fnd_lookups fl, fnd_concurrent_programs_vl fcpv<BR>
prompt          WHERE  phase_code = 'P' AND hold_flag = 'Y' AND fcr.requested_start_date <= sysdate<BR>
prompt          AND status_code != 'P' AND LOOKUP_TYPE = 'CP_STATUS_CODE' AND lookup_code = status_code<BR>
prompt          AND fcr.concurrent_program_id = fcpv.concurrent_program_id AND fcr.program_application_id = fcpv.application_id<BR>
prompt          ORDER BY request_date, request_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_DATE</B></TD>
select  
'<TR><TD>'||request_id||'</TD>'||chr(10)|| 
'<TD>'||nvl(meaning, 'UNKNOWN')||'</TD>'||chr(10)|| 
'<TD>'||user_concurrent_program_name||'</TD>'||chr(10)|| 
'<TD>'||to_char(request_date, 'DD-MON-RR HH24:MI:SS')||'</TD></TR>'
FROM   fnd_concurrent_requests fcr,
       fnd_lookups fl,
       fnd_concurrent_programs_vl fcpv
WHERE  phase_code = 'P'
AND    hold_flag = 'Y'
AND    fcr.requested_start_date <= sysdate
AND    status_code != 'P'
AND    LOOKUP_TYPE = 'CP_STATUS_CODE'
AND    lookup_code = status_code
AND    fcr.concurrent_program_id = fcpv.concurrent_program_id
AND    fcr.program_application_id = fcpv.application_id
ORDER BY request_date, request_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Listing of Pending Requests Not on Hold (Request ID, Status, Program Name, Request Date) *******
REM

prompt <a name="cpadv068"></a><B><U>Listing of Pending Requests Not on Hold (Request ID, Status, Program Name, Request Date)</B></U><BR>
prompt <BR><b>Description:</b><BR> A Listing of Pending Requests waiting to run that are currently not on hold. <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. Otherwise there is no immediate action required.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql16(){var row = document.getElementById("s2sql16");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv126"></a>
prompt     <B>Listing of Scheduled Requests (Request ID, Status, Program Name, Request Date, Start Date)</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql16()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql16" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT request_id id, nvl(meaning, 'UNKNOWN') status, user_concurrent_program_name pname,<BR>
prompt          to_char(request_date, 'DD-MON-RR HH24:MI:SS') submitd, to_char(requested_start_date, 'DD-MON-RR HH24:MI:SS') requestd<BR>
prompt          FROM   fnd_concurrent_requests fcr, fnd_lookups fl, fnd_concurrent_programs_vl fcpv<BR>
prompt          WHERE  phase_code = 'P' AND hold_flag = 'N' AND fcr.requested_start_date <= sysdate<BR>
prompt          AND status_code != 'P' AND LOOKUP_TYPE = 'CP_STATUS_CODE' AND lookup_code = status_code<BR>
prompt          AND fcr.concurrent_program_id = fcpv.concurrent_program_id AND fcr.program_application_id = fcpv.application_id<BR>
prompt          ORDER BY request_date, request_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_DATE</B></TD>
select  
'<TR><TD>'||request_id||'</TD>'||chr(10)|| 
'<TD>'||nvl(meaning, 'UNKNOWN')||'</TD>'||chr(10)|| 
'<TD>'||user_concurrent_program_name||'</TD>'||chr(10)|| 
'<TD>'||to_char(request_date, 'DD-MON-RR HH24:MI:SS')||'</TD></TR>'
FROM   fnd_concurrent_requests fcr,
       fnd_lookups fl,
       fnd_concurrent_programs_vl fcpv
WHERE  phase_code = 'P'
AND    hold_flag = 'N'
AND    fcr.requested_start_date <= sysdate
AND    status_code != 'P'
AND    LOOKUP_TYPE = 'CP_STATUS_CODE'
AND    lookup_code = status_code
AND    fcr.concurrent_program_id = fcpv.concurrent_program_id
AND    fcr.program_application_id = fcpv.application_id
ORDER BY request_date, request_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM  **********   Volume of Daily Concurrent Requests for Last Month (Requested Start Date, Request Count) **********
REM

prompt <a name="cpadv09"></a><B><U>Volume of Daily Concurrent Requests for Last Month (Requested Start Date, Request Count)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section documents the number of Concurrent Requests run on the instance for the Last Month.<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql17(){var row = document.getElementById("s2sql17");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Volume of Daily Concurrent Requests for Last Month (Requested Start Date, Request Count)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql17()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql17" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT trunc(REQUESTED_START_DATE), count(*)<BR>
prompt          FROM FND_CONCURRENT_REQUESTS<BR>
prompt          WHERE REQUESTED_START_DATE BETWEEN sysdate-30 AND sysdate<BR>
prompt          group by rollup(trunc(REQUESTED_START_DATE));</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Requested Start Date</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Request Count</B></TD> 
select  
'<TR><TD>'||trunc(REQUESTED_START_DATE)||'</TD>'||chr(10)|| 
'<TD><div align="right">'||count(*)||'</div></TD></TR>'
FROM FND_CONCURRENT_REQUESTS
WHERE REQUESTED_START_DATE BETWEEN sysdate-30 AND sysdate
group by rollup(trunc(REQUESTED_START_DATE));
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM  **********   Identify/Resolve the "Pending/Standby" Issue, if Caused by Run Alone Flag    **********
REM

prompt <a name="cpadv010"></a><B><U> Identify/Resolve the "Pending/Standby" Issue, if Caused by Run Alone Flag (User Program Name, Enabled Flag, Program Name, Description, Run Alone Flag) </B></U><BR>
prompt <BR><b>Description:</b><BR> This section documents any resulting Pending/Standby Requests caused by the Run Alone Flag set within the definition of the concurrent program. <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and is intended to identify any concurrent program definitions causing Pending/Standby Requests which may require review.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows2sql18(){var row = document.getElementById("s2sql18");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Identify/Resolve the "Pending/Standby" Issue, if Caused by Run Alone Flag (User Program Name, Enabled Flag, Program Name, Description, Run Alone Flag)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql18()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql18" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT USER_CONCURRENT_PROGRAM_NAME, ENABLED_FLAG, CONCURRENT_PROGRAM_NAME, DESCRIPTION, RUN_ALONE_FLAG<BR>
prompt          FROM FND_CONCURRENT_PROGRAMS_VL<BR>
prompt          WHERE (RUN_ALONE_FLAG='Y');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>User Program Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Enabled Flag</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Program Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Description</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Run Alone Flag</B></TD> 
select  
'<TR><TD>'||USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||ENABLED_FLAG||'</TD>'||chr(10)||
'<TD>'||CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)||
'<TD>'||DESCRIPTION||'</TD>'||chr(10)||
'<TD>'||RUN_ALONE_FLAG||'</TD></TR>'
FROM FND_CONCURRENT_PROGRAMS_VL
WHERE (RUN_ALONE_FLAG='Y');
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>




REM
REM ******* Check the Actual Tables for Concurrent Processing  *******
REM


prompt <a name="cpadv08"></a><B><U> Tablespace Statistics for the FND_CONCURRENT Tables (Table Name, Total Blocks, Size MB)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section collects sizing details of CP your tables (FND_CONCURRENT_REQUESTS, FND_CONCURRENT_PROCESSES, FND_CONCURRENT_QUEUES, FND_ENV_CONTEXT, FND_EVENTS, and FND_EVENT_TOKENS.)<BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline regarding your tablespace disk overhead. You can cross reference the collected information with exisiting notes on tablespace sizing and defragmentation best practices <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows3sql1(){var row = document.getElementById("s3sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Tablespace Statistics for the FND_CONCURRENT Tables (Table Name, Total Blocks, Size MB)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="130">
prompt       <blockquote><p align="left">
prompt          select SEGMENT_NAME "Table Name",sum(BLOCKS)  "Total blocks" , sum(bytes/1024/1024) "Size in MB" <BR>
prompt          from dba_segments<BR>
prompt          where segment_name in ('FND_CONCURRENT_REQUESTS','FND_CONCURRENT_PROCESSES','FND_CONCURRENT_QUEUES',<BR>
prompt          'FND_ENV_CONTEXT','FND_EVENTS','FND_EVENT_TOKENS')<BR>
prompt          group by segment_name<BR>
prompt          order by 2;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Table Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Total Blocks</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Size in MB</B></TD>
select  
'<TR><TD>'||SEGMENT_NAME||'</TD>'||chr(10)|| 
'<TD><div align="right">'||sum(BLOCKS)||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||sum(bytes/1024/1024)||'</div></TD></TR>'
from dba_segments
where segment_name in 
('FND_CONCURRENT_REQUESTS','FND_CONCURRENT_PROCESSES',
'FND_CONCURRENT_QUEUES','FND_ENV_CONTEXT',
'FND_EVENTS','FND_EVENT_TOKENS')
group by segment_name;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <script type="text/javascript">    function displayRows3sql2(){var row = document.getElementById("s3sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Additional Tablespace Statistics for the FND_CONCURRENT Tables (Table Name, Block Count, Empty Blocks, Row Count, Last Analyzed, Sample Size)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="130">
prompt       <blockquote><p align="left">
prompt          SELECT table_name,blocks, empty_blocks, num_rows,last_analyzed,sample_size<BR>
prompt          FROM   all_tables<BR>
prompt          WHERE table_name in ('FND_CONCURRENT_REQUESTS','FND_CONCURRENT_PROCESSES',<BR>
prompt          'FND_CONCURRENT_QUEUES','FND_ENV_CONTEXT','FND_EVENTS','FND_EVENT_TOKENS');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Table Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Total Blocks</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Empty Blocks</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Row Count</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Last Analyzed</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Sample Size</B></TD>
select  
'<TR><TD>'||table_name||'</TD>'||chr(10)|| 
'<TD><div align="right">'||blocks||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||empty_blocks||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||num_rows||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||last_analyzed||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||sample_size||'</div></TD></TR>'
from all_tables
WHERE table_name in ('FND_CONCURRENT_REQUESTS','FND_CONCURRENT_PROCESSES','FND_CONCURRENT_QUEUES','FND_ENV_CONTEXT','FND_EVENTS','FND_EVENT_TOKENS');
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <script type="text/javascript">    function displayRows3sql3(){var row = document.getElementById("s3sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Additional Tablespace Statistics for the FND_CONCURRENT Tables (Table Name, Block Count, Record Count)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="130">
prompt       <blockquote><p align="left">
prompt          select * from (<br>
prompt          SELECT 'TABLE_NAME',COUNT(DISTINCT SUBSTR(rowid,1,15)) "Used Blocks",count(1) "Tot. Records"<BR>
prompt          FROM fnd_concurrent_processes<BR>
prompt          union<BR>
prompt          SELECT 'FND_CONCURRENT_QUEUES',COUNT(DISTINCT SUBSTR(rowid,1,15)) "Used Blocks",count(1) "Tot. Records"<BR>
prompt          FROM fnd_concurrent_queues<BR>
prompt          union<BR>
prompt          SELECT 'FND_ENV_CONTEXT',COUNT(DISTINCT SUBSTR(rowid,1,15)) "Used Blocks",count(1) "Tot. Records"<BR>
prompt          FROM fnd_env_context<BR>
prompt          union<BR>
prompt          SELECT 'FND_EVENTS',COUNT(DISTINCT SUBSTR(rowid,1,15)) "Used Blocks",count(1) "Tot. Records"<BR>
prompt          FROM fnd_events<BR>
prompt          union<BR>
prompt          SELECT 'FND_CONCURRENT_REQUESTS',COUNT(DISTINCT SUBSTR(rowid,1,15)) "Used Blocks",count(1) "Tot. Records"<BR>
prompt          FROM FND_CONCURRENT_REQUESTS);</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Table Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Block Count</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Record Count</B></TD>
select
'<TR><TD>'||'Table Name'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||COUNT(DISTINCT SUBSTR(rowid,1,15))||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||count(1)||'</div></TD></TR>'
from fnd_concurrent_processes;
select
'<TR><TD>'||'Table Name'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||COUNT(DISTINCT SUBSTR(rowid,1,15))||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||count(1)||'</div></TD></TR>'
from fnd_concurrent_queues;
select
'<TR><TD>'||'Table Name'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||COUNT(DISTINCT SUBSTR(rowid,1,15))||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||count(1)||'</div></TD></TR>'
from fnd_env_context;
select
'<TR><TD>'||'Table Name'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||COUNT(DISTINCT SUBSTR(rowid,1,15))||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||count(1)||'</div></TD></TR>'
from fnd_events;
select
'<TR><TD>'||'Table Name'||'</TD>'||chr(10)|| 
'<TD><div align="right">'||COUNT(DISTINCT SUBSTR(rowid,1,15))||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||count(1)||'</div></TD></TR>'
from FND_CONCURRENT_REQUESTS;
prompt </TABLE><P><P> 

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM **************************************************************************************** 
REM ******* Section 2 : E-Business Applications Concurrent Manager Analysis          *******
REM ****************************************************************************************

prompt <a name="section3"></a><B><U><font size="+2">E-Business Applications Concurrent Manager Analysis</font></B></U><BR><BR>


REM 
REM ******* Concurrent Managers Active/Enabled (Queue Name, Manager Type, Module, and Cache Size) *******
REM

prompt <a name="cpadv1"></a><B><U>Concurrent Managers Active/Enabled (Queue Name, Manager Type, Module, and Cache Size)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section collects the Concurrent Managers that are currently Active and Enabled to process data, and establishes a baseline list of managers defined on your system.<BR>
prompt <BR><b>Action:</b><BR> The resulting data is for review and confirmation by your teams, and serves as a baseline for comparison with later outputs below. Otherwise there is no immediate action required.<BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows3sql4(){var row = document.getElementById("s3sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv132"></a>
prompt     <B>Concurrent Managers Active/Enabled (Queue Name, Manager Type, Module, and Cache Size</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt          select q.CONCURRENT_QUEUE_NAME "Queue Name", q.USER_CONCURRENT_QUEUE_NAME "User Queue Name",<BR>
prompt          decode(q.manager_type, 'Y', 'N') "Manager Type", a.application_short_name module, q.cache_size cache<BR>
prompt          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a<BR>
prompt          where i.application_id = q.application_id and a.application_id = q.application_id and q.enabled_flag = 'Y'<BR>
prompt          and nvl(q.control_code,'X') <> 'E'<BR>
prompt          order by   q.running_processes desc, q.manager_type, q.application_id, q.concurrent_queue_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER QUEUE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MANAGER TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MODULE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CACHE SIZE</B></TD>
select  
'<TR><TD>'||q.CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||q.USER_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||q.manager_type||'</TD>'||chr(10)|| 
'<TD>'||a.application_short_name||'</TD>'||chr(10)|| 
'<TD>'||q.cache_size||'</TD></TR>'
from
  apps.fnd_concurrent_queues_vl q,
  apps.fnd_product_installations i,
  apps.fnd_application_vl a
where 
  i.application_id = q.application_id
  and a.application_id = q.application_id
  and q.enabled_flag = 'Y'
  and nvl(q.control_code,'X') <> 'E'
order by
  q.running_processes desc,
  q.manager_type,
  q.application_id,
  q.concurrent_queue_id;
prompt </TABLE><P><P>


REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>Note: For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1373727.1" target="_blank">
prompt Note 1373727.1</a> - FAQ: EBS Concurrent processing Performance and Best Practices<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Concurrent Manager Processes by Workshift(Queue Name, Workshift, Min/Max Queue Size, and Sleep Time) *******
REM

prompt <a name="cpadv2"></a><B><U> Concurrent Manager Processes by Workshift(Queue Name, Workshift, Min/Max Queue Size, and Sleep Time)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section collects the Concurrent Managers associated with a specific Workshift.  Workshifts are created to define specific times when a Manager can run requests. <BR>
prompt <BR><b>Action:</b><BR> The resulting data is for review and confirmation by your teams, and serves as a baseline for comparison with later outputs below. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows3sql5(){var row = document.getElementById("s3sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfsummry"></a>
prompt     <B>Concurrent Manager Processes by Workshift(Queue Name, Workshift, Min/Max Queue Size, and Sleep Time)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="150">
prompt       <blockquote><p align="left">
prompt          select q.CONCURRENT_QUEUE_NAME, p.concurrent_time_period_name, qs.min_processes, qs.max_processes, qs.sleep_seconds <BR>
prompt          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,<BR>
prompt          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs<BR>
prompt          where i.application_id = q.application_id and a.application_id = q.application_id and qs.queue_application_id = q.application_id<BR>
prompt          and qs.concurrent_queue_id = q.concurrent_queue_id and qs.period_application_id = p.application_id<BR>
prompt          and qs.concurrent_time_period_id = p.concurrent_time_period_id and q.enabled_flag = 'Y' and nvl(q.control_code,'X') <> 'E'<BR>
prompt          order by q.concurrent_queue_name, p.concurrent_time_period_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WORKSHIFT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MINIMUM QUEUE SIZE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MAXIMUM QUEUE SIZE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SLEEP TIME</B></TD>
select  
'<TR><TD><div align="right">'||q.CONCURRENT_QUEUE_NAME||'</div></TD>'||chr(10)||
'<TD><div align="center">'||p.concurrent_time_period_name||'</div></TD>'||chr(10)||
'<TD><div align="right">'||qs.min_processes||'</div></TD>'||chr(10)||
'<TD><div align="right">'||qs.max_processes||'</div></TD>'||chr(10)||
'<TD><div align="right">'||qs.sleep_seconds ||'</div></TD></TR>'
from
  apps.fnd_concurrent_queues_vl q,
  apps.fnd_product_installations i,
  apps.fnd_application_vl a,
  apps.fnd_concurrent_time_periods p,
  apps.fnd_concurrent_queue_size qs
where 
  i.application_id = q.application_id
  and a.application_id = q.application_id
  and qs.queue_application_id = q.application_id
  and qs.concurrent_queue_id = q.concurrent_queue_id
  and qs.period_application_id = p.application_id
  and qs.concurrent_time_period_id = p.concurrent_time_period_id
  and q.enabled_flag = 'Y'
  and nvl(q.control_code,'X') <> 'E'
order by
  q.concurrent_queue_name,
  p.concurrent_time_period_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Active Managers for Applications not Installed/Used (Queue Name, Workshift, Min Queue Size) *******
REM

prompt <a name="cpadv3"></a><B><U> Active Managers for Applications not Installed/Used (Queue Name, Workshift, Min Queue Size)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section displays the Concurrent Managers that are active for Application modules not Installed or Used. <BR>
prompt <BR><b>Action:</b><BR> These unused managers can impact performance, and deactivating them can reduce current application overhead on the instance. <BR> 
prompt <BR>

prompt <script type="text/javascript">    function displayRows3sql6(){var row = document.getElementById("s3sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv133"></a>
prompt     <B>Active Managers for Applications not Installed/Used (Queue Name, Workshift, Min Queue Size)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="135">
prompt       <blockquote><p align="left">
prompt          select q.CONCURRENT_QUEUE_NAME, p.concurrent_time_period_name, qs.min_processes<BR>
prompt          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,<BR>
prompt          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs<BR>
prompt          where i.application_id = q.application_id and a.application_id = q.application_id<BR>
prompt          and qs.queue_application_id = q.application_id and qs.concurrent_queue_id = q.concurrent_queue_id<BR>
prompt          and qs.period_application_id = p.application_id and qs.concurrent_time_period_id = p.concurrent_time_period_id<BR>
prompt          and q.enabled_flag = 'Y' and nvl(q.control_code,'X') <> 'E' and qs.min_processes >0 and i.status <> 'I'<BR>
prompt          order by q.concurrent_queue_name, p.concurrent_time_period_id;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WORKSHIFT</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MINIMUM QUEUE SIZE</B></TD>
select  
'<TR><TD>'||q.CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||p.concurrent_time_period_name||'</TD>'||chr(10)|| 
'<TD>'||qs.min_processes||'</TD></TR>'
from
  apps.fnd_concurrent_queues_vl q,
  apps.fnd_product_installations i,
  apps.fnd_application_vl a,
  apps.fnd_concurrent_time_periods p,
  apps.fnd_concurrent_queue_size qs
where 
  i.application_id = q.application_id
  and a.application_id = q.application_id
  and qs.queue_application_id = q.application_id
  and qs.concurrent_queue_id = q.concurrent_queue_id
  and qs.period_application_id = p.application_id
  and qs.concurrent_time_period_id = p.concurrent_time_period_id
  and q.enabled_flag = 'Y'
  and nvl(q.control_code,'X') <> 'E'
  and qs.min_processes >0
  and i.status <> 'I'
order by
  q.concurrent_queue_name,
  p.concurrent_time_period_id;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM
REM ******* Total Target Processes for Request Managers Excluding Off-Hours (Queue Name, Target #, Running #, Primary Node, Secondary Node, Workshift, Max Requests Manager Can Process at 1 Time During Workshift *******
REM

prompt <a name="cpadv4"></a><B><U> Total Target Processes for Request Managers Excluding Off-Hours (Queue Name, Target #, Running #, Primary Node, Secondary Node, Workshift, Max Requests Manager Can Process at 1 Time During Workshift)</B></U><BR>
prompt <BR><b>Description:</b><BR> This identifies the total number of processes that can be run for a given concurrent manager.  The greater the number of processes defined can impact increased Concurrent Processing loads. <BR>
prompt <BR><b>Action:</b><BR> The resulting data is for review and confirmation by your teams, and serves as a baseline for comparison with later outputs below. Otherwise there is no immediate action required. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows3sql7(){var row = document.getElementById("s3sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=6 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv134"></a>
prompt     <B>Total Target Processes for Request Managers Excluding Off-Hours (Queue Name, Target #, Running #, Primary Node, Secondary Node, Workshift, Max Requests Manager Can Process at 1 Time During Workshift)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="7" height="85">
prompt       <blockquote><p align="left">
prompt          select q.CONCURRENT_QUEUE_NAME, q.max_processes, q.running_processes, q.node_name, q.node_name2,<BR>
prompt          p.concurrent_time_period_name, qs.min_processes<BR>
prompt          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,<BR>
prompt          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs<BR>
prompt          where i.application_id = q.application_id and a.application_id = q.application_id<BR>
prompt          and qs.queue_application_id = q.application_id and qs.concurrent_queue_id = q.concurrent_queue_id<BR>
prompt          and qs.period_application_id = p.application_id and qs.concurrent_time_period_id = p.concurrent_time_period_id<BR>
prompt          and q.enabled_flag = 'Y' and nvl(q.control_code,'X') <> 'E' and qs.min_processes >0 and q.manager_type = 1<BR>
prompt          and p.concurrent_time_period_name not in ('Weekend','Off-Peak AM','Off-Peak PM')<BR>
prompt          order by qs.min_processes desc,q.concurrent_queue_name;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TARGET # PROCESSES</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RUNNING # PROCESSES</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PRIMARY NODE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SECONDARY NODE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WORKSHIFT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MAXIMUM REQUESTS PER CYCLE</B></TD> 
select  
'<TR><TD>'||q.CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||q.max_processes||'</TD>'||chr(10)|| 
'<TD>'||q.running_processes||'</TD>'||chr(10)|| 
'<TD>'||q.node_name||'</TD>'||chr(10)|| 
'<TD>'||q.node_name2||'</TD>'||chr(10)|| 
'<TD>'||p.concurrent_time_period_name||'</TD>'||chr(10)||
'<TD>'||qs.min_processes||'</TD></TR>'
from
  apps.fnd_concurrent_queues_vl q,
  apps.fnd_product_installations i,
  apps.fnd_application_vl a,
  apps.fnd_concurrent_time_periods p,
  apps.fnd_concurrent_queue_size qs
where 
  i.application_id = q.application_id
  and a.application_id = q.application_id
  and qs.queue_application_id = q.application_id
  and qs.concurrent_queue_id = q.concurrent_queue_id
  and qs.period_application_id = p.application_id
  and qs.concurrent_time_period_id = p.concurrent_time_period_id
  and q.enabled_flag = 'Y'
  and nvl(q.control_code,'X') <> 'E'
  and qs.min_processes >0
  and q.manager_type = 1
  and p.concurrent_time_period_name not in (
    'Weekend',
    'Off-Peak AM',
    'Off-Peak PM'
  )
order by
  qs.min_processes desc,
  q.concurrent_queue_name;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Request Managers with Incorrect Cache Size (Queue Name, Cache Size{# of requests cached}, Max Target Processes) *******
REM

prompt <a name="cpadv5"></a><B><U> Request Managers with Incorrect Cache Size (Queue Name, Cache Size{# of requests cached}, Max Target Processes)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section collects details on Request Managers and their associated cache sizes. <BR>
prompt <BR><b>Action:</b><BR> A Managers cache size reflects the number of requests a manager adds to its queue, each time it reads available requests to run. For example, if a manager has 1 target process and a cache value of 3, it will read 3 requests and run those requests before returning to cache additional requests. <BR>
prompt <BR>Tip: Enter a value of 1 when defining a manager that runs long, time-consuming jobs, and a value of 3 or 4 for managers that run small, quick jobs.  For managers running small, quick jobs, consider setting the cache size (number of requests cached) to at least twice the number of target processes. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows3sql8(){var row = document.getElementById("s3sql8");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv135"></a>
prompt     <B>Request Managers with Incorrect Cache Size (Queue Name, Cache Size{# of requests cached}, Max Target Processes)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql8()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql8" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="55">
prompt       <blockquote><p align="left">
prompt          select q.CONCURRENT_QUEUE_NAME, q.cache_size, max(qs.min_processes) max_proc<BR>
prompt          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,<BR>
prompt          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs<BR>
prompt          where i.application_id = q.application_id and a.application_id = q.application_id<BR>
prompt          and qs.queue_application_id = q.application_id and qs.concurrent_queue_id = q.concurrent_queue_id<BR>
prompt          and qs.period_application_id = p.application_id and qs.concurrent_time_period_id = p.concurrent_time_period_id<BR>
prompt          and q.enabled_flag = 'Y' and nvl(q.control_code,'X') <> 'E' and qs.min_processes >0 and q.manager_type = 1<BR>
prompt          group by q.CONCURRENT_QUEUE_NAME, q.cache_size<BR>
prompt          having decode(max(qs.min_processes),1,2,max(qs.min_processes)) > nvl(q.cache_size,1)<BR>
prompt          order by  q.concurrent_queue_name;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE NAME</B></font></TD> 
prompt <TD BGCOLOR=#DEE6EF><div align="right"><font face="Calibri"><B>CACHE SIZE</B></font></div></TD>
prompt <TD BGCOLOR=#DEE6EF><div align="right"><font face="Calibri"><B>MAXIMUM TARGET PROCESSES</B></font></div></TD>
select  
'<TR><TD>'||q.CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD><div align="right">'||q.cache_size||'</TD>'||chr(10)||
'<TD><div align="right">'||max(qs.min_processes)||'</div></TD></TR>'
from
  apps.fnd_concurrent_queues_vl q,
  apps.fnd_product_installations i,
  apps.fnd_application_vl a,
  apps.fnd_concurrent_time_periods p,
  apps.fnd_concurrent_queue_size qs
where 
  i.application_id = q.application_id
  and a.application_id = q.application_id
  and qs.queue_application_id = q.application_id
  and qs.concurrent_queue_id = q.concurrent_queue_id
  and qs.period_application_id = p.application_id
  and qs.concurrent_time_period_id = p.concurrent_time_period_id
  and q.enabled_flag = 'Y'
  and nvl(q.control_code,'X') <> 'E'
  and qs.min_processes >0
  and q.manager_type = 1
group by
  q.CONCURRENT_QUEUE_NAME, 
  q.cache_size
having
  decode(max(qs.min_processes),1,2,max(qs.min_processes)) > nvl(q.cache_size,1)
order by
  q.concurrent_queue_name;
prompt </TABLE><P><P> 


REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>Note: For more information refer to <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1373727.1" target="_blank">
prompt Note 1373727.1</a> - FAQ: EBS Concurrent processing Performance and Best Practices<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Concurrent Manager Request Summary by Manager (Queue Name, Submission Count, Sum of Runtime, Average Runtime, Std Dev of Runtime, Sum of Wait Time, Average Wait Time) *******
REM

prompt <a name="cpadv01"></a><B><U> Concurrent Manager Request Summary by Manager (Queue Name, Submission Count, Sum of Runtime, Average Runtime, Std Dev of Runtime, Sum of Wait Time, Average Wait Time)</B></U><BR>
prompt <BR><b>Description:</b><BR> This data set is intended to identify which concurrent managers are being used, and can be compared with the actual concurrent managers allocated at startup. Only considers requests with completion status of normal/warning. <BR>
prompt <BR><b>Action:</b><BR> Please consider deactivation of any managers which are consistently not being used, and are listed as Active/Enabled above. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows3sql9(){var row = document.getElementById("s3sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=6 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv136"></a>
prompt     <B>Concurrent Manager Request Summary by Manager (Queue Name, Submission Count, Sum of Runtime, Average Runtime, Std Dev of Runtime, Sum of Wait Time, Average Wait Time)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql9" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="7" height="125">
prompt       <blockquote><p align="left">
prompt          select  q.concurrent_queue_name, count(*) cnt, sum(r.actual_completion_date - r.actual_start_date) * 24 elapsed,<BR>
prompt          avg(r.actual_completion_date - r.actual_start_date) * 24 average,<BR>
prompt          stddev(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 24 wstddev,<BR>
prompt          sum(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 24 waited,<BR>
prompt          avg(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 24 avewait<BR>
prompt          from apps.fnd_concurrent_programs p, apps.fnd_concurrent_requests r, apps.fnd_concurrent_queues q,<BR>
prompt          apps.fnd_concurrent_processes p <BR>
prompt          where r.program_application_id = p.application_id and r.concurrent_program_id = p.concurrent_program_id <BR>
prompt          and r.phase_code='C' -- completed and r.status_code in ('C','G')  -- completed normal or with warning<BR>
prompt          and r.controlling_manager=p.concurrent_process_id and q.concurrent_queue_id=p.concurrent_queue_id <BR>
prompt          and r.concurrent_program_id=p.concurrent_program_id <BR>
prompt          group by  q.concurrent_queue_name;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">QUEUE NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">SUBMISSION COUNT</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">SUM OF RUNTIME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">AVERAGE RUNTIME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">STDDEV OF RUNTIME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">SUM OF WAIT TIME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">AVERAGE WAIT TIME</B></TD>
SELECT  
'<TR><TD>'||q.concurrent_queue_name||'</TD>'||chr(10)|| 
'<TD>'||count(*)||'</TD>'||chr(10)|| 
'<TD>'||round(sum(r.actual_completion_date - r.actual_start_date) * 1440, 2)||'</TD>'||chr(10)|| 
'<TD>'||round(avg(r.actual_completion_date - r.actual_start_date) * 1440, 2)||'</TD>'||chr(10)|| 
'<TD>'||round(stddev(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440, 2)||'</TD>'||chr(10)|| 
'<TD>'||round(sum(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440, 2)||'</TD>'||chr(10)|| 
'<TD>'||round(avg(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440, 2)||'</TD></TR>'
from    apps.fnd_concurrent_programs p, 
        apps.fnd_concurrent_requests r,
        apps.fnd_concurrent_queues q,
        apps.fnd_concurrent_processes p
where   r.program_application_id = p.application_id  
        and r.concurrent_program_id = p.concurrent_program_id  
        and r.phase_code='C' -- completed
        and r.status_code in ('C','G')  -- completed normal or with warning
        and r.controlling_manager=p.concurrent_process_id 
        and q.concurrent_queue_id=p.concurrent_queue_id 
        and r.concurrent_program_id=p.concurrent_program_id 
group by  q.concurrent_queue_name;
prompt</TABLE><P><P>


prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



REM 
REM *******     Check Manager Queues for Pending Requests (Queue ID #, Application ID #, Queue Name, Phase Code, Request Count              *******
REM 

prompt <a name="cpadv02"></a><B><U> Check Manager Queues for Pending Requests (Queue ID #, Application ID #, Queue Name, Phase Code, Request Count)</B></U><BR>
prompt <BR><b>Description:</b><BR> This section identifies all concurrent requests that are in a Pending state. <BR>
prompt <BR><b>Action:</b><BR> The output below is for review and confirmation by your team. Typically when there are requests pending, the number should be the same as the number of actual processes. However if there are no pending requests or requests were just submitted, the number of requests running may be less than the number of actual processes. Also note if a concurrent program is incompatible with another program currently running, it does not start until the incompatible program has completed. In this case, the number of requests running may be less than number of actual processes even when there are requests pending. <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows4sql1(){var row = document.getElementById("s4sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv141"></a>
prompt     <B>Check Manager Queues for Pending Requests (Queue ID #, Application ID #, Queue Name, Phase Code, Request Count)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="185">
prompt       <blockquote><p align="left">
prompt          SELECT a.CONCURRENT_QUEUE_ID "Queue ID", a.QUEUE_APPLICATION_ID "Apps ID",<BR>
prompt          b.user_CONCURRENT_QUEUE_NAME "Concurrent Manager", decode(a.PHASE_CODE, 'P','PENDING','R','Running') Phase,count(1)<BR>
prompt          FROM FND_CONCURRENT_WORKER_REQUESTS a, fnd_concurrent_queues_vl b<BR>
prompt          WHERE (a.Phase_Code = 'P' or a.Phase_Code = 'R') and a.hold_flag != 'Y' and a.Requested_Start_Date <= SYSDATE<BR>
prompt          AND ('' IS NULL OR ('' = 'B' AND a.PHASE_CODE = 'R' AND a.STATUS_CODE IN ('I', 'Q'))) and '1' in (0,1,4)<BR>
prompt          And a.concurrent_queue_id=b.concurrent_queue_id<BR>
prompt          group by a.CONCURRENT_QUEUE_ID, a.QUEUE_APPLICATION_ID, b.user_CONCURRENT_QUEUE_NAME, a.PHASE_CODE<BR>
prompt          order by 1;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE ID #</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>APPLICATION ID #</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>QUEUE NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE CODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST COUNT</B></TD> 
select  
'<TR><TD>'||a.CONCURRENT_QUEUE_ID||'</TD>'||chr(10)|| 
'<TD>'||a.QUEUE_APPLICATION_ID||'</TD>'||chr(10)|| 
'<TD>'||b.user_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||decode(a.PHASE_CODE, 'P','PENDING','R','Running')||'</TD>'||chr(10)||
'<TD>'||count(1)||'</TD></TR>'
FROM FND_CONCURRENT_WORKER_REQUESTS a, fnd_concurrent_queues_vl b
 WHERE (a.Phase_Code = 'P' or a.Phase_Code = 'R')
 and a.hold_flag != 'Y'
 and a.Requested_Start_Date <= SYSDATE
 AND ('' IS NULL OR ('' = 'B' AND a.PHASE_CODE = 'R' AND a.STATUS_CODE IN ('I', 'Q')))
 and '1' in (0,1,4)
And a.concurrent_queue_id=b.concurrent_queue_id
  group by a.CONCURRENT_QUEUE_ID,
          a.QUEUE_APPLICATION_ID,
          b.user_CONCURRENT_QUEUE_NAME,
          a.PHASE_CODE
order by 1;
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM 
REM *******     Check the Configuration of OPP (OPP Service ID, OPP Service Name, OPP Developer Parameters)        *******
REM 

prompt <a name="cpadv07"></a><B><U> Check the Configuration of OPP (OPP Service ID, OPP Service Name, OPP Developer Parameters)</B></U><BR>
prompt <BR><b>Description:</b><BR> This provides a view for the configuration of how OPP is currently configured identifying the: Service ID, Service Handle, and Parameters used.  <BR>
prompt <BR><b>Action:</b><BR> The output provided is for review and confirmation by your teams, and serves as a baseline regarding your current OPP configuration. You can cross reference the collected information with existing notes on OPP best practices <BR>
prompt <BR>

prompt <script type="text/javascript">    function displayRows4sql2(){var row = document.getElementById("s4sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv141"></a>
prompt     <B>Check the Configuration of OPP (OPP Service ID, OPP Service Name, OPP Developer Parameters)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="185">
prompt       <blockquote><p align="left">
prompt         SELECT service_id, service_handle, developer_parameters<br>
prompt         FROM fnd_cp_services<br>
prompt         WHERE service_id = (SELECT manager_type<br>
prompt                             FROM fnd_concurrent_queues<br>
prompt                             WHERE concurrent_queue_name = 'FNDCPOPP');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SERVICE ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SERVICE HANDLE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DEVELOPER PARAMETERS</B></TD>
select  
'<TR><TD>'||service_id||'</TD>'||chr(10)|| 
'<TD>'||service_handle||'</TD>'||chr(10)|| 
'<TD>'||developer_parameters||'</TD></TR>'
FROM fnd_cp_services
 WHERE service_id = (SELECT manager_type
                       FROM fnd_concurrent_queues
                      WHERE concurrent_queue_name = 'FNDCPOPP');
prompt </TABLE><P><P>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


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
	if et_hr1 > st_hr1 then
		hr_fact := to_number(et_hr1) - to_number(st_hr1);
	else
		hr_fact := 0;
	end if;
	if et_ss1 >= st_ss1 then
		mi_fact := to_number(et_mi1) - to_number(st_mi1);
		ss_fact := to_number(et_ss1) - to_number(st_ss1);
	else
		mi_fact := (to_number(et_mi1) - to_number(st_mi1))-1;
		ss_fact := (to_number(et_ss1)+60) - to_number(st_ss1);
	end if;
	dbms_output.put_line('<br>Total time taken to complete the script: '||hr_fact||' Hrs '||mi_fact||' Mins '||ss_fact||' Secs');
end;
/


prompt <BR>
prompt <BR>
prompt <BR>
prompt <BR>


REM **************************************************************************************** 
REM *******                   Section 7 : References                                 *******
REM ****************************************************************************************

prompt <a name="cpadv011"></a><B><U><font size="+2">Concurrent Processing References</font></B></U><BR><BR>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><font size="-1" face="Calibri"><tr><td><p>   

prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1499538.1" target="_blank">
prompt Concurrent Processing - Sample SQL Statements Including Date Range Parameters Related to Doc 1411723.1 - Concurrent Processing Analyzer for E-Business Suite (Doc ID 1499538.1)</a><br>
prompt <a href="https://communities.oracle.com/portal/server.pt/community/core_concurrent_processing/493" target="_blank">
prompt My Oracle Support - Concurrent Processing Community/a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1160285.1" target="_blank">
prompt Application Technology Group (ATG) Product Information Center (PIC) (Doc ID 1160285.1)</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1304305.1" target="_blank">
prompt Concurrent Processing - Product Information Center (PIC) (Doc ID 1304305.1)</a><br>
prompt <br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1057802.1" target="_blank">
prompt Note 1057802.1 -	Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=104452.1" target="_blank">
prompt Note 104452.1 - Concurrent Processing - Troubleshooting Concurrent Manager Issues (Unix specific)</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=225165.1" target="_blank">
prompt Note 225165.1 - Patching Best Practices and Reducing Downtime</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=957426.1" target="_blank">
prompt Note 957426.1 - Health Check Alert: Invalid objects exist for one or more of your EBS applications</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=104457.1" target="_blank">
prompt Note 104457.1 - Invalid Objects In Oracle Applications FAQs</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=822368.1" target="_blank">
prompt Note 822368.1 - Concurrent Processing - How To Run the Purge Concurrent Request FNDCPPUR, Which Tables Are Purged, And Known Issues Like Files Are Not Deleted From File System or Slow Performance</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=762024.1" target="_blank">
prompt Note 762024.1 - Concurrent Processing - How To Ensure Load Balancing Of Concurrent Manager Processes In PCP-RAC Configuration</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=134007.1" target="_blank">
prompt Note 134007.1 - Concurrent Processing - CMCLEAN.SQL - Non Destructive Script to Clean Concurrent Manager Tables</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=749748.1" target="_blank">
prompt Note 760386.1 - 749748.1 - Concurrent Processing - How to Cancel a Concurrent Request Stuck in the Queue?</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1066332.1" target="_blank">
prompt Note 559996.1 - 1066332.1 - Concurrent Processing - One Concurrent Manager SQL statement shows excessive executions</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=104282.1" target="_blank">
prompt Note 104282.1 - Concurrent Processing - Purge Concurrent Request and/or Manager Data Program (FNDCPPUR)</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1312632.1" target="_blank">
prompt Note 1312632.1 - Concurrent Processing - ICM log file shows 'CONC-SM TNS FAIL', 'Call to PingProcess failed', and/or 'Call to StopProcess failed' for FNDCPGSC/FNDOPP</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=1086013.1" target="_blank">
prompt Note 1086013.1 - Concurrent Processing - How to run the Purge Concurrent Request and/or Manager Data program, and which tables does it purge?</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=134035.1" target="_blank">
prompt Note 134035.1 - ANALYZEREQ.SQL - Detailed Analysis of One Concurrent Request (Release 11 and up)</a><BR>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=171855.1" target="_blank">
prompt Note 171855.1 - CCM.sql Diagnostic Script for Concurrent Manager</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=134033.1" target="_blank">
prompt Note 134033.1 - ANALYZEPENDING.SQL - Analyze all Pending Requests</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=164978.1" target="_blank">
prompt Note 164978.1 - REQCHECK.sql - Diagnostic Script for Concurrent Requests</a><br>
prompt <a href="https://support.oracle.com/CSP/main/article?cmd=show\&type=NOT\&id=213021.1" target="_blank">
prompt Note 213021.1- Concurrent Processing (CP) / APPS Reporting Scripts</a><br>
prompt </p></font></td></tr></tbody>
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM **************************************************************************************** 
REM *******                   Section 7 : Feedback                                   *******
REM ****************************************************************************************

prompt <a name="section8"></a><B><font size="+2">Feedback</font></B><BR><BR>
prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><font size="-1" face="Calibri"><tr><td><p>
prompt Still have questions? Use the<a title="This is a live browser iFrame window"><em><font color="#FF0000"><b><font size="+1"> live</font></b></font></em></a> My Oracle Support EBS - Core Concurrent Processing Community window below,
prompt to search for similar discussions or start a new discussion about the Concurrent Processing Analyzer.
prompt As always, you can email the author directly <A HREF="mailto:michael.costa@oracle.com?subject=%20CP%20Analyzer%20Feedback">here</A>.
prompt Be sure to include the output of the script for review.<BR>
prompt </p></font></td></tr></tbody>
prompt </table><BR><BR>

prompt <iframe width="90%" height="550" frameborder="1" 
prompt src="https://communities.oracle.com/portal/server.pt/community/core_concurrent_processing/493" 
prompt id="iframedemo" name="iframedemo" style="border-style: groove; border-width: 4px; margin: 15px;" class="Docframe"> 
prompt </iframe><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


spool off
set heading on
set feedback on  
set verify on
exit
;



