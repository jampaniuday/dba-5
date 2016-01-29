undefine v_headerinfo
Define   v_headerinfo     =  '$Header:  APListh.sql 1.21 12-JAN-06 support $'
undefine v_scriptlongname
Define   v_scriptlongname = 'R11.5 Payables Data Collection Test'
REM   ========================================================
REM   Copyright © 2002 Oracle Corporation Redwood Shores, California, USA
REM    Oracle Support Services.  All rights reserved.
REM   ========================================================
REM    PURPOSE:		  This script displays ALL of the Data for ALL 
REM				  of the tables used to process an invoice in AP.
REM    PRODUCT:  		  501 - Oracle Payables
REM    PRODUCT VERSIONS:  10.7, 11.0, 11.5
REM    PLATFORM:  	  Generic
REM    PARAMETERS:	Invoice/Check Number
REM				Supplier Name
REM				Invoice ID
REM				Print Null Columns Y or N - Default Y
REM				Details Layout Portrait (P) or Landscape (L) - Default L
REM				GL Details Y or N - Default N
REM				Related Details Y or N - Default Y
REM				Max Rows 
REM   =======================================================
REM   USAGE: 	This script should be run in SQLplus in APPS Schema
REM   EXAMPLE: 	in the SQL prompt execute :SQL>@c:\filepath\APListh.sql
REM   OUTPUT:     The output will be spooled to filename APListh_<The Invoice ID>_<mmddhhmm>_diag.html


REM   =======================================================
REM   CHANGE HISTORY:
REM   DATE	Modifications (In order changes were made)
REM   6/01/02	Created
REM   08/15/02  Changed select from po_distributions_all to use po_distribution_id instead of po_header_id.
REM             Changed select from po_line_locations_all to use line_location_id instead of po_header_id.
REM   09/04/02  Added Upper() to all of the get parameter queries.
REM   10/16/02  Script was linking AP data to GL Data using JE_HEADER_ID only.  Added link to include JE_LINE_NUM.
REM   		Now only the invoice or payment lines related to the invoice_id submitted will be displayed.
REM   10/16/02  Added XLA_GL_TRANSFER_BATCHES table to the GL Info section.
REM   10/20/02	Added AP_Batches_All table to Transaction Details Section
REM   10/20/02  Added Prepayment info section
REM   10/20/02	Added ap_selected_invoices_all and ap_selected_invoice_checks_all tables
REM   10/21/02 	Added Payment Document/Bank Information
REM   1/19/03   Changed queries to find source_table = ap_payment_history and source_id = payment_history_id.  Script
REM		was incorrect looking for source_id = check_id.
REM   2/16/03   Fix disp_lengths for ap_invoice_payments_all summary.
REM   3/26/03   The 1/19 fix caused a cartesian product for the accounting data returned,
REM		if the ap_payment_history_all table had more than one row for a check_id. 
REM   3/26/03	The date format was displaying incorrectly when ran against 9i.
REM   4/02/03   >< Were not displaying around columns
REM   4/9/03	Add data for Argentina localization
REM   12/21/03  Fix ap_encumbrance_lines_all where clause to use invoice_distribution_id  
REM   12/21/03  added third_party_id and third_party_sub_id column to the summary section on ap_ae_lines_all table
REM   12/21/03  added period_name column to the summary section on ap_invoice_distributions and ap_invoice_payment tables
REM   12/21/03  added gl account segments for ccid's to details section for ap_ae_lines, ap_invoice_distributions,
REM             ap_invoice_payments, and ap_bank_accounts_all
REM   12/21/03  added gl_period_statuses data
REM   12/21/03  added Cash Management table data
REM   12/21/03  added Patch Level to Misc Application Info section
REM   12/21/03  added PO Lines table data
REM   12/21/03  added parameter to limit the number of rows returned from each table
REM   12/21/03  added ap_chrg_allocations_all table data
REM   12/21/03  added AP_AWT_GROUPS table data
REM   01/23/04  fixed tax section calling incorrect sql
REM   05/24/04  added ability to run by check_id. Miscellaneous bug fixes.
REM   12/08/04  modified ap_invoices_all summary query to return rows even if vendor data is invalid.
REM   12/08/04  moved detailed ap_payment_history_all table output from accounting to transaction detail section.
REM             this table should now be displayed for AX and non-AX installs.
REM   12/08/04  modified summary output for ax_events to show column descriptions:  invoice_id and check_id for event_field1.
REM   12/08/04  Miscellaneous bug fixes.
REM   12/08/04  Added fv_treasury_confirmations_all table data.
REM   12/08/04  Added AP_INV_APRVL_HIST_ALL table data.
REM   12/08/04  Added AP_MC_PAYMENT_DISTS_ALL table data.
REM   11/20/05  Added parent_reversal_id column to output displayed for ap_invoice_distributions_all in the summary section.
REM   11/20/05  Changed ap_invoice_distributions_all to order by invoice_distribution_id in the summary section.
REM   11/20/05  Print MRC info if it exists even if the flag is N.
REM   11/20/05  Add AP_HOLD_CODES
REM   11/20/05  Add FND_CURRENCIES
REM   11/20/05  Add FND_PRODUCT_GROUPS 
REM   11/20/05  Add FND_PRODUCT_INSTALLATIONS
REM   11/20/05  Display rows in ap_invoice_payments_all for others invoices paid by same check as the target invoice.
REM   11/20/05  Display all the invoice headers for all the invoices associated with the checks associated with the target invoice.
REM   11/20/05  Add Status_Lookup_Code to ap_checks_all summary section
REM   11/20/05  Add base_amount to AP_INVOICE_DISTRIBUTIONS_all summary section
REM   11/20/05  Add invoice_base_amount to ap_invoice_payments_all summary section
REM   11/20/05  Add payment_base_amount to ap_invoice_payments_all summary section
REM   11/20/05  Add base_amount to ap_invoices_all summary section
REM   11/20/05  Add sort by for the AP_LIABILITY_BALANCE table
REM   11/20/05  Add AP_DUPLICATE_VENDORS_ALL
REM   12/07/05  Performance fix
REM   01/12/06  Removed AP_DUPLICATE_VENDORS_ALL due to performance issues
REM   =======================================================

REM  ==============SQL PLUS Environment setup===================
set serveroutput on size 1000000
set autoprint off
set verify off
set echo off

REM ============== Define SQL Variables for input parameters =============
undefine v_invoice_id
undefine v_doc_number
undefine v_doc_amount
undefine v_doc_type
undefine v_doc_type
undefine v_details
undefine v_vendor
undefine v_layout
undefine v_gl_details
undefine v_add_details
undefine v_max_rows
undefine v_date
clear columns

variable v_invoice_idx varchar2(20)
variable v_doc_typex varchar2(1)
variable	v_version		varchar2(17);
variable  	v_nls			varchar2(50);
variable l_applversion varchar2(10);
variable l_mrc_enabled		varchar2(10);
variable l_ax_enabled		varchar2(10);
variable l_ax_info		number;
variable l_continue		varchar2(1);
variable l_org_id		number;
variable l_sob_id 	number;
variable l_patch_level	varchar2(10);
variable l_coa number;


set head off feedback off


set head off feedback off

--Verify RDBMS version

declare

BEGIN

   select MAX(version)
   into :v_version
   from v$instance;

:v_version := substr(:v_version,1,9);


if :v_version < '8.1.6.0.0' 
and :v_version > '4.0' then
dbms_output.put_line(chr(10));
dbms_output.put_line('RDBMS Version = '||:v_version);
dbms_output.put_line('ERROR - The Script requires RDBMS version 8.1.6 or higher');
dbms_output.put_line('ACTION - Type Ctrl-C <Enter> to exit the script.');
dbms_output.put_line(chr(10));
end if;

exception

  when others then
dbms_output.put_line(chr(10));
    DBMS_OUTPUT.PUT_LINE('ERROR  - RDBMS Version error: '|| sqlerrm);
    DBMS_OUTPUT.PUT_LINE('ACTION - Please report the above error to Oracle Support Services.'  || chr(10) ||
                         '         Type Ctrl-C <Enter> to exit the script.'  || chr(10) );
dbms_output.put_line(chr(10));

END;
/


--Verify NLS Character Set

declare

BEGIN

select VALUE 
into :v_nls
from v$nls_parameters 
where PARAMETER = 'NLS_CHARACTERSET';


if :v_version < '8.1.7.4.0' 
and :v_version > '4.0' 
and :v_nls = 'UTF8' then
dbms_output.put_line(chr(10));
dbms_output.put_line('RDBMS Version = '||:v_version);
dbms_output.put_line('NLS Character Set = '||:v_nls);
dbms_output.put_line('ERROR - The HTML version of this script is incompatible with this Character Set for RDBMS version 8.1.7.3 and lower');
dbms_output.put_line('ACTION - Please run the Text version of this script.');
dbms_output.put_line(chr(10));
end if;

exception

  when others then
dbms_output.put_line(chr(10));
    DBMS_OUTPUT.PUT_LINE('ERROR  - NLS Character Set error: '|| sqlerrm);
    DBMS_OUTPUT.PUT_LINE('ACTION - Please report the above error to Oracle Support Services.'  || chr(10) ||
                         '         Type Ctrl-C <Enter> to exit the script.'  || chr(10) );
dbms_output.put_line(chr(10));

END;

/


REM ============ Get the Invoice_ID ====================
set head off verify off linesize 100 feedback off termout on 
set pagesize 200

PROMPT
PROMPT Are you entering an Invoice Number, Check Number, Check Id or Invoice_id?
PROMPT
Prompt Enter 1 for Invoice Number
Prompt Enter 2 for Check Number
Prompt Enter 3 for Check Id
Prompt Enter 4 for Invoice Id
Accept v_doc_type number prompt 'DEFAULT=1>' DEFAULT 1
PROMPT

define v_doc_type = &v_doc_type

Select decode('&v_doc_type','1','Enter the Invoice Number',
				  '2','Enter the Check Number',
				  '3','Enter the Check ID',
				  '4','Press Enter',
				  'Press Ctrl + C to cancel the script and then run the script again and select option 1 - 4')
from sys.dual
/

set head off feedback off

accept v_doc_number Prompt '>' Default NULL

Prompt

Select decode('&v_doc_type','4', 'Press Enter','3','Press Enter','2','Enter the Supplier Name','1','Enter the Supplier Name')
from sys.dual
/
accept v_vendor Prompt '>' Default %

define v_vendor = &v_vendor

Prompt

select decode('&v_doc_type', '1','*****MATCHING INVOICES*****')
from sys.dual
where '&v_doc_type' = 1;

select rpad('Invoice ID',15), rpad('Supplier Name', 25), rpad('Invoice Number',25), 
rpad('Invoice Date',15), rpad('Invoice Amount',15)
from sys.dual 
where '&v_doc_type' = '1';

SELECT distinct rpad(ai.invoice_id,15) invoice_id,  rpad(substr(pv.vendor_name,1,25),25),
rpad(substr(ai.invoice_num,1,25),25), rpad(ai.invoice_date,15), rpad(ai.invoice_amount,15)
FROM   ap_invoices_all ai, po_vendors pv, po_vendor_sites_all pvs
WHERE  Upper(ai.invoice_num) like upper(nvl('&v_doc_number%',''))
and ai.vendor_id = pv.vendor_id
and ai.vendor_site_id = pvs.vendor_site_id
and upper(pv.vendor_name) like upper(nvl('&v_vendor%','%'))
and '&v_doc_type' = '1'
order by invoice_id;

select decode('&v_doc_type', '1',chr(9))
from sys.dual
where '&v_doc_type' = 1;

select 'ERROR - Could not retrieve any Invoices for this Invoice Number and Supplier',
chr(9),'Action - Verify Invoice Number and Supplier is valid and try again', chr(9),
'Press Ctrl + C to Cancel this script and try again'
from sys.dual
where not exists (
SELECT 'x'
FROM   ap_invoices_all ai, po_vendors pv, po_vendor_sites_all pvs
WHERE  Upper(ai.invoice_num) like upper(nvl('&v_doc_number%',''))
and ai.vendor_id = pv.vendor_id
and ai.vendor_site_id = pvs.vendor_site_id
and upper(pv.vendor_name) like upper(nvl('&v_vendor%','%'))
and '&v_doc_type' = '1'
)
and '&v_doc_type' = '1';

select decode('&v_doc_type', '2','*****MATCHING CHECK NUMBERS*****')
from sys.dual
where '&v_doc_type' = 2;

select distinct rpad('Invoice ID',15), rpad('Check ID',15), rpad('Supplier Name', 25), rpad('Check Number',15), 
rpad('Check Amount',15)
from sys.dual 
where '&v_doc_type' = '2';

SELECT distinct rpad(ai.invoice_id,15) invoice_id, rpad(aip.check_id,15), substr(pv.vendor_name,1,25), rpad(aca.check_number,15),
rpad(aca.amount,15)
FROM   ap_invoices_all ai, po_vendors pv, po_vendor_sites_all pvs,
ap_invoice_payments_all aip, ap_checks_all aca
WHERE  Upper(aca.check_number) = upper(nvl('&v_doc_number',''))
and aca.vendor_id = pv.vendor_id
and aca.vendor_site_id = pvs.vendor_site_id
and ai.invoice_id = aip.invoice_id
and aca.check_id = aip.check_id
and upper(pv.vendor_name) like upper(nvl('&v_vendor%','%'))
and &v_doc_type = '2'
order by invoice_id;

select 'ERROR - Could not retrieve any Checks for this Check Number and Supplier'||
chr(10)||'Action - Verify Invoice Number and Supplier is valid and try again', chr(9),
'Press Ctrl + C to Cancel this script and try again'
from sys.dual
where not exists (
SELECT 'x'
FROM   ap_invoices_all ai, po_vendors pv, po_vendor_sites_all pvs,
ap_invoice_payments_all aip, ap_checks_all aca
WHERE  Upper(aca.check_number) = upper(nvl('&v_doc_number',''))
and aca.vendor_id = pv.vendor_id
and aca.vendor_site_id = pvs.vendor_site_id
and ai.invoice_id = aip.invoice_id
and aca.check_id = aip.check_id
and upper(pv.vendor_name) like upper(nvl('&v_vendor%','%'))
and &v_doc_type = '2'
)
and '&v_doc_type' = '2';

select chr(9)
from sys.dual
where '&v_doc_type' in (1,2);

select decode('&v_doc_type', '3','*****Invoices Paid on Check*****')
from sys.dual
where '&v_doc_type' = 3;

select distinct rpad('Invoice ID',15), rpad('Check ID',15), rpad('Supplier Name', 25), rpad('Check Number',15), 
rpad('Check Amount',15)
from sys.dual 
where '&v_doc_type' = '3';

SELECT distinct rpad(ai.invoice_id,15) invoice_id, rpad(aip.check_id,15), substr(pv.vendor_name,1,25), rpad(aca.check_number,15),
rpad(aca.amount,15)
FROM   ap_invoices_all ai, po_vendors pv, po_vendor_sites_all pvs,
ap_invoice_payments_all aip, ap_checks_all aca
WHERE  to_char(aip.check_id) = upper(nvl('&v_doc_number',''))
and aca.vendor_id = pv.vendor_id
and aca.vendor_site_id = pvs.vendor_site_id
and ai.invoice_id = aip.invoice_id
and aca.check_id = aip.check_id
and &v_doc_type = '3'
order by invoice_id;

select 'ERROR - Could not retrieve any Checks for this Check Number and Supplier'||
chr(10)||'Action - Verify Invoice Number and Supplier is valid and try again', chr(9),
'Press Ctrl + C to Cancel this script and try again'
from sys.dual
where not exists (
SELECT 'x'
FROM   ap_invoices_all ai, po_vendors pv, po_vendor_sites_all pvs,
ap_invoice_payments_all aip, ap_checks_all aca
WHERE  to_char(aip.check_id) = upper(nvl('&v_doc_number',''))
and aca.vendor_id = pv.vendor_id
and aca.vendor_site_id = pvs.vendor_site_id
and ai.invoice_id = aip.invoice_id
and aca.check_id = aip.check_id
and &v_doc_type = '3'
)
and '&v_doc_type' = '3';

select chr(9)
from sys.dual
where '&v_doc_type' in (3);



Prompt Enter the Invoice ID: 
accept v_invoice_id number Prompt '>' default -99
Prompt

define v_invoice_id = &v_invoice_id

PROMPT
Prompt Print NULL Columns (Y or N)?
Accept v_null Prompt 'DEFAULT=Y>' default Y
prompt

set head off verify off feedback off

Select 'Press Ctrl + C to cancel the script and then run the script again and enter Y or N'
from sys.dual
where upper('&v_null') not in ('Y', 'N');

PROMPT
Prompt Show Spaces (Y or N)?
Accept v_spaces Prompt 'DEFAULT=N>' default N
prompt

set head off verify off feedback off

Select 'Press Ctrl + C to cancel the script and then run the script again and enter Y or N'
from sys.dual
where upper('&v_null') not in ('Y', 'N');

PROMPT
Prompt Details Layout: Portrait or Landscape (P or L)?
Accept v_layout Prompt 'DEFAULT=L>' default L
prompt

Select 'Press Ctrl + C to cancel the script and then run the script again and enter P or L'
from sys.dual
where upper('&v_layout') not in ('P', 'L');


PROMPT
Prompt GL Details (Y or N)?
Accept v_gl_details Prompt 'DEFAULT=N>' default N
prompt

Select 'Press Ctrl + C to cancel the script and then run the script again and enter Y or N'
from sys.dual
where upper('&v_gl_details') not in ('Y', 'N');

PROMPT
Prompt Related Details (Y or N)?
Accept v_add_details Prompt 'DEFAULT=Y>' default Y
prompt

Select 'Press Ctrl + C to cancel the script and then run the script again and enter Y or N'
from sys.dual
where upper('&v_add_details') not in ('Y', 'N');


Prompt
Prompt Max number of rows returned?
Accept v_max_rows prompt 'Default=500>' default 500
Prompt

set term off

--Get the Date and Time

COLUMN TODAY NEW_VALUE v_date
SELECT TO_CHAR(SYSDATE, 'MMDDHH24MI') TODAY
from sys.dual;

set term on


set head on feedback on

REM ============ Spooling the output file====================

Prompt
Prompt Running...
Prompt

define outputfilename = APListh_&v_invoice_id._&v_date._diag.html

spool  &outputfilename



REM =================Run the Pl/SQL api file ===================================

@@CoreApiHtmlx.sql
@@AddOnApiHtml.sql
begin  -- begin1

declare --declare 2

p_username varchar2(100);

p_respid number;

/* ------------------------ Declare Section -----------------------------*/

begin  --begin2

Show_Header('148388.1', '&v_scriptlongname');

/* -------------------- Execution secion ------------------------------- */

Declare  --declare 3

l_exception		exception;
l_error_msg		varchar2(500);
l_invoice_id		NUMBER := nvl(&v_invoice_id,-1);
l_count 		NUMBER;
l_null 			varchar2(1) := upper('&v_null');
SqlTxt			varchar2(5000);
SqlTxt2			varchar2(5000);
l_cursor		integer;
l_counter		integer;
l_allow			varchar2(50) := NULL;
ql_markers 		V2T;
ql_titles  		V2T;
l_layout		varchar2(1) := upper('&v_layout');
--l_layout		varchar2(1) := 'P';
l_tax_code_id		number := NULL;
l_vat_code		varchar2(50) := NULL;
l_gl_details		varchar2(1) := upper('&v_gl_details');
l_add_details		varchar2(1) := upper('&v_add_details');
l_dummy		varchar2(240);
l_feedback		varchar2(1) := 'Y';
l_max_rows		number := &v_max_rows;
l_spaces		varchar2(1) := upper('&v_spaces');

cursor c_po_cursor is
select distinct nvl(po.po_header_id,-99) po_header_id, 
po.po_distribution_id, po.line_location_id
from ap_invoice_distributions aid, po_distributions po
where aid.invoice_id = l_invoice_id
and aid.po_distribution_id is not null
and aid.po_distribution_id = po.po_distribution_id;

--Custom API's

procedure Tag(p_txt varchar2) is
begin
  Insert_HTML('<a NAME='||p_txt||'></a>');
end Tag;
procedure Top is
begin
  Insert_HTML('<a HREF=#quicklinks>Back to Quick Links</a><BR>');
end Top; 

procedure Show_Quicklink_Row(p_ql_titles in V2T, p_ql_markers in V2T) is
 l_row_values V2T;
begin
  if p_ql_titles.count = p_ql_markers.count then
    l_row_values := V2T();
    for i in 1..p_ql_titles.count loop
      l_row_values.extend;
      l_row_values(i) := '<a href=#'||p_ql_markers(i)||'>'||
        p_ql_titles(i)||'</a>';
    end loop;
    Show_table_row(l_row_values,null);
  end if;
end Show_Quicklink_Row;


function object_test(object_test varchar2) return number is

	l_object_test 	number;

begin

l_object_test := 0;

select count(*) 
into l_object_test
from dba_objects
where object_name = object_test;

return(l_object_test);

end object_test;


function Check_Column(p_tab in varchar, p_col in varchar) return boolean is
l_counter integer:=0;
begin
  select count(*) into l_counter
  from   all_tab_columns
  where  table_name = upper(p_tab)
  and    column_name = upper(p_col);
  if l_counter > 0 then
    return(true);
  else
    return(false);
  end if;
exception when others then
  ErrorPrint(sqlerrm||' occured in Check_Column');
  ActionErrorPrint('Report this information to your support analyst');
  raise;
end Check_Column;

--end of custom API's

Begin  --begin 3


--Verify that the invoice_id exists

l_count := 0;

select count(*) into l_count from ap_invoices_all where invoice_id = l_invoice_id;


if l_count < 1 
--if 1 < 1 
THEN

BRPRINT;
errorprint('Invoice ID: ' || l_invoice_id ||' does not exist.');
actionerrorprint('Please verify the invoice_id entered and try again.');
BRPRINT;

:l_continue := 'N';

Raise l_exception;

else :l_continue := 'Y';

end if;


--Set the Org_ID

select max(org_id), max(set_of_books_id)
into :l_org_id, :l_sob_id
from ap_invoices_all
where invoice_id = l_invoice_id;

dbms_application_info.set_client_info(:l_org_id);


--Set Application Version

select max(substr(release_name,1,4))  into :l_applversion from fnd_product_groups;

--Verify if MRC is enabled

select nvl(max(multi_currency_flag),'N') into :l_mrc_enabled from fnd_product_groups;

--Set chart of accounts id

select max(chart_of_accounts_id) coa
into :l_coa
from gl_sets_of_books
where set_of_books_id in (
select set_of_books_id 
from ap_system_parameters);


--added 05/07/03
--Verify if AX is enabled

BEGIN 

if :l_org_id is NULL OR :l_sob_id is NULL Then


:l_ax_enabled := 'N';
:l_ax_info := 0;
	
else 

	IF ax_setup_pkg.ax_exists 
	(:l_org_id
	,:l_sob_id
	,200) THEN 
	:l_ax_enabled := 'Y';
	:l_ax_info := 1;

	ELSE 
	
	:l_ax_enabled := 'N';
	:l_ax_info := 0;

	END IF; 

end if;

END; 



/*
if object_test('AX_SETUP_GLOBAL') > 0 then 

sqlTxt := 'select ax_enabled from ax_setup_global';

	  l_cursor := dbms_sql.open_cursor; 
	  dbms_sql.parse(l_cursor, sqltxt, dbms_sql.native);
	  dbms_sql.define_column(l_cursor, 1, l_allow,5);
	  l_counter := dbms_sql.execute(l_cursor); 
	  l_counter := 0;
	  while dbms_sql.fetch_rows(l_cursor) > 0 loop
	    l_counter := l_counter + 1;
	    dbms_sql.column_value(l_cursor, 1, l_allow);
	    :l_ax_enabled := l_allow;
	  end loop;
	   DBMS_OUTPUT.PUT_LINE(chr(9));
	  --if l_counter = 0 then
	  --raise no_data_found;
	  --end if;
	  dbms_sql.close_cursor(l_cursor);

	  
sqlTxt := 'select translation_status from ax_events where application_id = 200 and event_type like ''NON_CASH%'' '
||' and event_field1 = '||l_invoice_id; 

	  l_cursor := dbms_sql.open_cursor; 
	  dbms_sql.parse(l_cursor, sqltxt, dbms_sql.native);
	  dbms_sql.define_column(l_cursor, 1, l_allow,5);
	  l_counter := dbms_sql.execute(l_cursor); 
	  l_counter := 0;
	  while dbms_sql.fetch_rows(l_cursor) > 0 loop
	    l_counter := l_counter + 1;
	    dbms_sql.column_value(l_cursor, 1, l_allow);
	    end loop;
	   DBMS_OUTPUT.PUT_LINE(chr(9));
	  dbms_sql.close_cursor(l_cursor);
	  
:l_ax_info := l_counter;
	  
else

:l_ax_enabled := 'N';
:l_ax_info := 0;

end if;

*/

tag('quicklinks');
SectionPrint('Quick Links to Data');
Start_Table('Quick Links to Data Collection');
ql_markers := V2T('Summary Info','Setup Info','Trial Bal Info','Transaction Details','ATG Details','MRC Details','Tax Details','GL Details');
ql_titles  := V2T('Summary Info','Setup Info','Trial Bal Info','Transaction Details','ATG Details','MRC Details','Tax Details','GL Details');
Show_Quicklink_Row(ql_titles, ql_markers);
ql_markers := V2T('Supplier Info', 'PO Info', 'Encumbrance Info','Prepayment Information','Pymt Doc/Bank Info', 'Localizations');
ql_titles  := V2T('Supplier Info', 'PO Info', 'Encumbrance Info','Prepayment Information','Pymt Doc/Bank Info', 'Localizations');
Show_Quicklink_Row(ql_titles, ql_markers);
ql_markers := V2T('CE Information', 'GL_PERIOD_STATUSES', 'GLOBAL (AX)', 'Treasury Confirmation', 'Currency Details');
ql_titles  := V2T('CE Information', 'GL_PERIOD_STATUSES', 'GLOBAL (AX)', 'Treasury Confirmation', 'Currency Details');
Show_Quicklink_Row(ql_titles, ql_markers);
End_Table;

tag('Summary Info');

BRPRINT;
SEctionPrint ('Summarized Invoice/Payment Information');
BRPRINT;

if :l_applversion = '11.5' then


sqlTxt := 'SELECT ai.invoice_id, substr(pv.vendor_name,1,25) Supplier_Name, '
||' substr(ai.invoice_num,1,25) "Invoice Number", '
||' ai.invoice_date, ai.invoice_amount, ai.base_amount,'
||' substr(ai.invoice_type_lookup_code,1,15) Invoice_Type, '
||' substr(ai.invoice_currency_code,1,3) INV,  '
||' substr(ai.payment_currency_code,1,3) PAY '
||' FROM ap_invoices ai, po_vendors pv, po_vendor_sites pvs '
||' WHERE  ai.invoice_id = '||l_invoice_id 
||' and ai.vendor_id = pv.vendor_id(+) '
||' and ai.vendor_site_id = pvs.vendor_site_id(+) '
||' order by ai.invoice_id asc ';

--disp_lengths := lengths(10,25,25,10,10,10,15,3,3);

run_sqlpl('AP_INVOICES_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

brprint;
tab0print('Note:  The above results contain a join to the po_vendor table to retrieve the supplier name.');
brprint;


sqlTxt := 'select invoice_id,  '
||' substr(distribution_line_number,1,8) Line_Num,  '
||' substr(line_type_lookup_code,1,9) Line_type,  '
||' accounting_date, period_name, amount, base_amount, posted_flag,  '
||' substr(dist_code_combination_id,1,15) Dist_CCID, '
||' substr(accounting_event_id,1,15) ATG_Event_Id, '
||' substr(invoice_distribution_id,1,15) Dist_id, '
||' substr(parent_reversal_id,1,15) Parent_Rev_id, '
||' substr(po_distribution_id,1,15) PO_Dist_Id '
||' from ap_invoice_distributions '
||' where invoice_id ='||l_invoice_id
||' order by invoice_distribution_id asc';

--disp_lengths := lengths(10,8,9,10,10,10,10,10,15,15,15,15,15);

run_sqlpl('AP_INVOICE_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select check_id, '
||' substr(invoice_payment_id,1,15) Inv_payment_id,  '
||' amount, payment_base_amount, invoice_base_amount, accounting_date, period_name, '
||' posted_flag, accounting_event_id, invoice_id '
||' from ap_invoice_payments '
||' where invoice_id ='|| l_invoice_id
||' order by check_id asc';

--disp_lengths := lengths(15,15,15,10,10,10,10,10,15,15);

run_sqlpl('AP_INVOICE_PAYMENTS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select aph.PAYMENT_HISTORY_ID, aph.CHECK_ID, aph.ACCOUNTING_DATE, '
||' substr(aph.TRANSACTION_TYPE,1,20) "Transaction Type", aph.POSTED_FLAG,  '
||' substr(APH.ACCOUNTING_EVENT_ID,1,10) Event_id, '
||' aph.ORG_ID,aph.REV_PMT_HIST_ID '
||' from ap_payment_history aph '
||' where 2=2 '
||' and aph.check_id in (select distinct check_id  '
||'                        from ap_invoice_payments '
||'                         where invoice_id ='||l_invoice_id||')  '
||' order by aph.payment_history_id asc ';

--disp_lengths := lengths(15,15,15,20,10,15,10,15);

run_sqlpl('AP_PAYMENT_HISTORY_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

end if;


if :l_applversion <> '11.5' then

sqlTxt := 'SELECT ai.invoice_id, substr(pv.vendor_name,1,25) Supplier_Name, '
||' substr(ai.invoice_num,1,25) "Invoice Number", '
||' ai.invoice_date, ai.invoice_amount, base_amount,'
||' substr(ai.invoice_type_lookup_code,1,15) Invoice_Type, '
||' substr(ai.invoice_currency_code,1,3) INV,  '
||' substr(ai.payment_currency_code,1,3) PAY '
||' FROM ap_invoices ai, po_vendors pv, po_vendor_sites pvs '
||' WHERE  ai.invoice_id = '||l_invoice_id 
||' and ai.vendor_id = pv.vendor_id(+) '
||' and ai.vendor_site_id = pvs.vendor_site_id(+) '
||' order by ai.invoice_id asc ';

--disp_lengths := lengths(15,25,25,10,10,10,15,3,3);

run_sqlpl('AP_INVOICES_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

brprint;
tab0print('Note:  The above results contain a join to the po_vendor table to retrieve the supplier name.');
brprint;


sqlTxt := 'select invoice_id,  '
||' substr(distribution_line_number,1,8) Line_Num,  '
||' substr(line_type_lookup_code,1,9) Line_type,  '
||' accounting_date, period_name, amount, base_amount, posted_flag,  '
||' substr(dist_code_combination_id,1,15) Dist_CCID, '
||' substr(po_distribution_id,1,15) PO_Dist_Id '
||' from ap_invoice_distributions '
||' where invoice_id ='||l_invoice_id
||' order by distribution_line_number asc';

--disp_lengths := lengths(15,8,9,10,10,10,10,10,15,15);

run_sqlpl('AP_INVOICE_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select check_id, '
||' substr(invoice_payment_id,1,15) Inv_payment_id,  '
||' amount, payment_base_amount, invoice_base_amount, accounting_date, period_name, '
||' posted_flag, invoice_id '
||' from ap_invoice_payments '
||' where invoice_id ='|| l_invoice_id
||' order by check_id asc';

--disp_lengths := lengths(15,15,15,15,10,10,10,10,15);

run_sqlpl('AP_INVOICE_PAYMENTS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

end if;

if object_test('AP_PAYMENT_DISTRIBUTIONS_ALL') > 0 THEN

sqlTxt := 'SELECT tab.INVOICE_PAYMENT_ID, substr(tab.ACCTS_PAY_CODE_COMBINATION_ID,1,15) ACCT_PAY_CCID, '
||' tab.AMOUNT, tab.BASE_AMOUNT,  '
||' substr(tab.DIST_CODE_COMBINATION_ID,1,15) DIST_CCID, '
||' substr(tab.INVOICE_DISTR_LINE_NUMBER,1,8) INV_LINE, '
||' substr(tab.Payment_LINE_NUMBER,1,8) PAY_LINE, '
||' tab.INV_CURR_AMOUNT,tab.INV_CURR_BASE_AMOUNT '
||' FROM ap_payment_distributions_all tab                                           '
||'    ,ap_invoice_payments aip                                                '
||' WHERE 2=2                                                                       '
||'  and aip.invoice_payment_id = tab.invoice_payment_id '
||'  and aip.invoice_id = '||l_invoice_id
||'  order by tab.invoice_payment_id';

--disp_lengths := lengths(15,15,15,15,15,8,8,15,15);

run_sqlpl('AP_PAYMENT_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

end if;


sqlTxt := 'SELECT Amount_remaining,batch_id, due_date,gross_amount, '
||' hold_flag,invoice_id, Org_id, payment_num, '
||' substr(payment_status_flag,1,1) Pmt_Flag '
||' FROM ap_payment_schedules                           '
||' WHERE 2=2                                                                       '
||' and invoice_id ='||l_invoice_id;

--disp_lengths := lengths(15,15,15,15,10,15,7,15,10);

run_sqlpl('AP_PAYMENT_SCHEDULES_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'SELECT held_by, hold_date, hold_lookup_code, substr(hold_reason,1,25), '
||' invoice_id, org_id, release_lookup_code, substr(release_reason,1,25), status_flag '
||' FROM ap_holds                                                           '
||' WHERE 2=2                                                                       '
||'  and invoice_id ='||l_invoice_id;

--disp_lengths := lengths(25,25,25,25,15,7,25,25,10);


run_sqlpl('AP_HOLDS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');


sqlTxt := 'select asi.checkrun_name, asi.payment_num, asi.payment_amount, asi.ok_to_pay_flag, asi.dont_pay_reason_code, '
||' substr(asi.vendor_name,1,25) vendor_name, substr(asi.vendor_site_code,1,25) site_name, asi.pay_selected_check_id, asi.print_selected_check_id '
||' from ap_selected_invoices asi '
||' where invoice_id ='||l_invoice_id;

--disp_lengths := lengths(25,25,25,25,10,15,25,25,25);


run_sqlpl('AP_SELECTED_INVOICES_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select asic.checkrun_name, asic.check_number, asic.check_amount, asic.ok_to_pay_flag, asic.dont_pay_reason_code, '
||' asic.status_lookup_code, substr(asic.vendor_name,1,25) vendor_name, substr(asic.vendor_site_code,1,25) site_name, asic.check_id, asic.selected_check_id '
||' from ap_selected_invoice_checks asic, ap_selected_invoices asi '
||' where (asic.selected_check_id = asi.pay_selected_check_id or asic.selected_check_id = print_selected_check_id) '
||' and asi.invoice_id = '||l_invoice_id;

--disp_lengths := lengths(25,25,25,25,10,15,25,25,25,25);

run_sqlpl('AP_SELECTED_INVOICE_CHECKS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');


sqlTxt := 'SELECT aca.amount, aca.base_amount, aca.checkrun_id, '
||' aca.checkrun_name, aca.check_date, aca.check_id, '
||' aca.check_number, aca.org_id,ACA.vendor_site_code, '
||' substr(aca.status_lookup_code,1,15) status_lookup_code, aca.void_date '
||' FROM ap_checks aca '
||' WHERE 2=2                                                                        '
||' and aca.check_id in (select distinct check_id  '
||'                         from ap_invoice_payments '
||'                          where invoice_id = '||l_invoice_id||') '
||' order by aca.check_id';

--disp_lengths := lengths(15,15,15,25,15,15,15,7,25,15,15);

run_sqlpl('AP_CHECKS_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

if :l_applversion = '11.5' and :l_ax_info = 0 then

sqlTxt := 'select aea.accounting_event_id,  '
||' substr(aea.source_table,1,15) source_table, aea.source_id, '
||' substr(aea.event_type_code,1,15) event_type_code,  '
||'       aea.event_number, '
||'       substr(aea.event_status_code,1,15) event_status_code '
||' FROM ap_accounting_events aea '
||' where aea.source_id ='||l_invoice_id
||' and aea.source_table = ''AP_INVOICES'' '
||' order by aea.accounting_event_id asc ';

--disp_lengths := lengths(15,15,15,15,15,15);

run_sqlpl('AP_ACCOUNTING_EVENTS_ALL (Invoice) ', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select distinct aea.accounting_event_id,  '
||' substr(aea.source_table,1,15) source_table, aea.source_id, '
||' substr(aea.event_type_code,1,15) event_type_code,  '
||'       aea.event_number, '
||'       substr(aea.event_status_code,1,15) event_status_code '
||' FROM ap_accounting_events aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'        from ap_invoice_payments aip, ap_payment_history aph '
||'               where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' )'
||' order by aea.accounting_event_id asc ';

--disp_lengths := lengths(15,15,15,15,15,15);

run_sqlpl('AP_ACCOUNTING_EVENTS_ALL (Payment) ', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select aeh.accounting_event_id, aeh.ae_header_id, '
||' substr(aeh.gl_transfer_run_id,1,15) GL_Tran_run_id, '
||' aeh.gl_transfer_flag, aeh.accounting_date, '
||' substr(aeh.accounting_error_code,1,15) ATG_Error_Code, '
||' substr(aeh.set_of_books_id,1,6) SOB_ID,  '
||' substr(aeh.org_id,1,6) Org_id, '
||' substr(aeh.description,1,15) Description '
||' from ap_ae_headers aeh, '
||' ap_accounting_events aea '
||' where aeh.accounting_event_id = aea.accounting_event_id '
||' and aea.source_id = '||l_invoice_id
||'  and aea.source_table = ''AP_INVOICES'' '
||' order by aeh.accounting_event_id asc ';

--disp_lengths := lengths(15,15,15,10,15,15,6,6,15);

run_sqlpl('AP_AE_HEADERS_ALL (Invoice)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select distinct aeh.accounting_event_id, aeh.ae_header_id, '
||' substr(aeh.gl_transfer_run_id,1,15) GL_Tran_run_id, '
||' aeh.gl_transfer_flag, aeh.accounting_date, '
||' substr(aeh.accounting_error_code,1,15) ATG_Error_Code, '
||' substr(aeh.set_of_books_id,1,6) SOB_ID,  '
||' substr(aeh.org_id,1,6) Org_id, '
||' substr(aeh.description,1,15) Description '
||' from ap_ae_headers aeh, '
||' ap_accounting_events aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'        from ap_invoice_payments aip, ap_payment_history aph '
||'               where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' )'
||' and aeh.accounting_event_id = aea.accounting_event_id '
||' order by aeh.accounting_event_id asc ';

--disp_lengths := lengths(15,15,15,10,15,15,6,6,15);

run_sqlpl('AP_AE_HEADERS_ALL (Payment)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select ael.ae_header_id, '
||' substr(ael.ae_line_number,1,10) line, '
||' substr(ael.ae_line_type_code,1,10) line_type, '
||' ael.accounted_dr, ael.accounted_cr, ael.entered_dr, ael.entered_cr, '
||' substr(ael.code_combination_id,1,10) CCID, '
||' substr(ael.reference7,1,3) SOB,  '
||' substr(ael.org_id, 1,6) Org_Id, '
||' substr(ael.reference2,1,10) Invoice_id, '
||' substr(ael.third_party_id,1,10) vendor_id, '
||' substr(ael.third_party_sub_id,1,10) site_id, '
||' substr(ael.ae_line_id,1,10) AE_Line_Id, '
||' substr(ael.accounting_error_code,1,10) error_code '
||' from ap_ae_lines ael, '
||' ap_ae_headers aeh, '
||' ap_accounting_events aea '
||' where aea.source_id ='||l_invoice_id
||'  and aea.source_table = ''AP_INVOICES'' '
||' and aeh.accounting_event_id = aea.accounting_event_id '
||' and ael.ae_header_id = aeh.ae_header_id '
||' order by ael.ae_header_id asc, invoice_id, line';

--disp_lengths := lengths(15,10,10,15,15,15,15,10,3,6,10,10,10,10,10);

run_sqlpl('AP_AE_LINES_ALL (Invoice)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select distinct ael.ae_header_id, '
||' substr(ael.ae_line_number,1,10) line, '
||' substr(ael.ae_line_type_code,1,10) line_type, '
||' ael.accounted_dr, ael.accounted_cr, ael.entered_dr, ael.entered_cr, '
||' substr(ael.code_combination_id,1,10) CCID, '
||' substr(ael.reference7,1,3) SOB,  '
||' substr(ael.org_id, 1,6) Org_Id, '
||' substr(ael.reference2,1,10) Invoice_id, '
||' substr(ael.third_party_id,1,10) vendor_id, '
||' substr(ael.third_party_sub_id,1,10) site_id, '
||' substr(ael.ae_line_id,1,10) AE_Line_Id, '
||' substr(ael.accounting_error_code,1,10) error_code '
||' from ap_ae_lines ael, '
||' ap_ae_headers aeh, '
||' ap_accounting_events aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'        from ap_invoice_payments aip, ap_payment_history aph '
||'               where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'    (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' )'
||' and aeh.accounting_event_id = aea.accounting_event_id '
||' and ael.ae_header_id = aeh.ae_header_id '
||' order by ael.ae_header_id asc, invoice_id, line';

--disp_lengths := lengths(15,10,10,15,15,15,15,10,3,6,10,10,10,10,10);

run_sqlpl('AP_AE_LINES_ALL (Payment)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select enc.ae_header_id, '
||' enc.accounted_cr, enc.accounted_dr, '
||' enc.code_combination_id '
||' from ap_encumbrance_lines   enc, '
||' ap_invoice_distributions_all aid '
||' where aid.invoice_id =' || l_invoice_id
||' and aid.invoice_distribution_id = enc.invoice_distribution_id '
||' order by enc.invoice_distribution_id asc ';

--disp_lengths := lengths(15,15,15,15);

run_sqlpl('AP_ENCUMBRANCE_LINES_ALL', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

end if;



if :l_ax_info > 0 then

sqlTxt := 'select event_id '
||'     , set_of_books_id   '
||'     , event_type '
||'     , event_date '
||'     , event_field1 invoice_id '
||'     , translation_status '
||'     , substr(message_text,1,30) message '
||' from ax_events '
||' where application_id = 200  '
||'  and event_type like ''NON_CASH%'' '
||'  and event_field1 = '||l_invoice_id;

--disp_lengths := lengths(15,10,15,15,15,15,30);
 
run_sqlpl('AX_EVENTS (Invoice)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := '  '
||' select event_id '
||'     , set_of_books_id   '
||'     , event_type '
||'     , event_date '
||'     , event_field1 check_id '
||'     , translation_status '
||'     , substr(message_text,1,30) message '
||' from ax_events '
||' where application_id = 200  '
||'  and (event_type like ''CASH%'' '
||'    or event_type like ''FUTURE%'') '
||'  and event_field1 in (select check_id '
||'      from ap_invoice_payments '
||'      where invoice_id ='||l_invoice_id||')';

--disp_lengths := lengths(15,10,15,15,15,15,30);

run_sqlpl('AX_EVENTS (Payment)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');
 
 sqlTxt := 'select ash.event_id, ash.sle_header_id, '
||' ash.journal_sequence_id, '
||' substr(ash.gl_transfer_run_id,1,15) GL_Tran_run_id, '
||' ash.gl_transfer_flag, ash.effective_date, '
||' ash.period_name, '
||' substr(ash.set_of_books_id,1,6) SOB_ID,  '
||' substr(ash.org_id,1,6) Org_id, '
||' substr(ash.description,1,15) Description '
||' from ax_sle_headers ash, '
||' ax_events aea '
||' where ash.event_id = aea.event_id '
||' and ash.application_id = 200  '
||'   and event_type like ''NON_CASH%'' '
||'  and event_field1 ='||l_invoice_id
||'  order by sob_id asc, ash.event_id asc ';


--disp_lengths := lengths(15,15,15,15,10,10,15,6,6,15);

run_sqlpl('AX_SLE_HEADERS (Invoice)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');
 
 sqlTxt := 'select ash.event_id, ash.sle_header_id, '
||' ash.journal_sequence_id, '
||' substr(ash.gl_transfer_run_id,1,15) GL_Tran_run_id, '
||' ash.gl_transfer_flag, ash.effective_date, '
||' ash.period_name, '
||' substr(ash.set_of_books_id,1,6) SOB_ID,  '
||' substr(ash.org_id,1,6) Org_id, '
||' substr(ash.description,1,15) Description '
||' from AX_SLE_headers ash, '
||' aX_events aea '
||' where ash.application_id = 200  '
||'  and aea.event_id = ash.event_id '
||'  and (event_type like ''CASH%'' '
||'    or event_type like ''FUTURE%'') '
||'  and aea.event_field1 in (select check_id '
||'      from ap_invoice_payments '
||'      where invoice_id ='||l_invoice_id||') '
||' order by sob_id asc, ash.event_id asc ';

--disp_lengths := lengths(15,15,15,15,10,10,15,6,6,15);

run_sqlpl('AX_SLE_HEADERS (Payment)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');
 
sqlTxt := 'select ash.sle_header_id Header_id '
||' ,substr(ash.journal_sequence_id,1,6) SEQ_ID '
||'      , substr(asl.sle_line_num,1,10) Line_Num '
||'     , substr(asl.reference_14,1,15) Line_Type '
||'     , asl.accounted_dr '
||'     , asl.accounted_cr '
||'     , asl.entered_dr '
||'     , asl.entered_cr '
||'     , substr(asl.code_combination_id,1,10) CCID '
||'     , asl.gl_posted_flag '
||'     , substr(ash.set_of_books_id,1,6) SOB_ID      '
||'     , substr(ash.org_id,1,6) ORG_ID      '
||'     , substr(asl.reference_22,1,15) Invoice_ID '
||' from ax_sle_lines asl '
||'   , ax_sle_headers ash '
||'   , po_vendors pv '
||' where ash.sle_header_id = asl.sle_header_id '
||'  and ash.journal_sequence_id = asl.journal_sequence_id '
||'  and ash.set_of_books_id = asl.set_of_books_id '
||'  and asl.third_party_id = pv.vendor_id '
||'  and ash.event_id in (select event_id '
||'     from ax_events '
||'    where application_id = 200  '
||'      and event_type like ''NON_CASH%'' '
||'      and event_field1 = '||l_invoice_id||') '
||' order by sob_id, header_id, line_num';

--disp_lengths := lengths(15,6,10,15,15,15,15,15,10,10,6,6,15);

run_sqlpl('AX_SLE_Lines (Invoice)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

sqlTxt := 'select ash.sle_header_id Header_id '
||' ,substr(ash.journal_sequence_id,1,6) SEQ_ID '
||'     , substr(asl.sle_line_num,1,10) Line_Num '
||'     , substr(asl.reference_14,1,15) Line_Type '
||'     , asl.accounted_dr '
||'     , asl.accounted_cr '
||'     , asl.entered_dr '
||'     , asl.entered_cr '
||'     , substr(asl.code_combination_id,1,10) CCID '
||'     , asl.gl_posted_flag '
||'     , substr(ash.set_of_books_id,1,6) SOB_ID      '
||'     , substr(ash.org_id,1,6) ORG_ID      '
||'     , substr(asl.reference_22,1,15) Invoice_ID '
||' from ax_sle_lines asl '
||'   , ax_sle_headers ash '
||'   , po_vendors pv '
||' where ash.sle_header_id = asl.sle_header_id '
||'  and ash.journal_sequence_id = asl.journal_sequence_id '
||'  and ash.set_of_books_id = asl.set_of_books_id '
||'  and asl.third_party_id = pv.vendor_id '
||'  and ash.event_id in ( select event_id '
||'     from ax_events ae,  '
||'          ap_invoice_payments aip '
||'     where ae.application_id = 200  '
||'      and (ae.event_type like ''CASH%'' '
||'        or ae.event_type like ''FUTURE%'') '
||'      and ae.event_field1 = aip.check_id '
||'      and aip.invoice_id = '||l_invoice_id||') '
||' order by sob_id, header_id, line_num';

--disp_lengths := lengths(15,6,10,15,15,15,15,15,10,10,6,6,15);

run_sqlpl('AX_SLE_Lines (Payment)', sqltxt, l_feedback, l_max_rows,0, 'L', 'Y', 'N');

 
end if; 

tag('Trial Bal Info');

BRPRINT;
SEctionPrint ('Trial Balance Info');
BRPRINT;


if :l_applversion = '11.5' then

--R11i

sqlTxt := 'select * from ap_trial_bal '
||' where invoice_id = '||l_invoice_id;

run_sqlpl('AP_TRIAL_BAL', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');


if object_test('AP_LIABILITY_BALANCE') > 0 THEN

sqlTxt := 'select * from ap_liability_balance '
||' where invoice_id = '||l_invoice_id
||' order by set_of_books_id, ae_line_id';

run_sqlpl('AP_LIABILITY_BALANCE', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

end if;


else
--R10.7 and R11

sqlTxt := 'select * from ap_trial_balance '
||' where invoice_id = '||l_invoice_id;

run_sqlpl('AP_TRIAL_BALANCE', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

end if;

tag('Setup Info');

BRPRINT;
SEctionPrint ('Setup Info');
BRPRINT;


if :l_applversion = '11.5' then

sqlTxt := 'SELECT asp.* from ap_system_parameters asp, ap_invoices aia '
||' where nvl(asp.org_id,''-99'') = nvl(aia.org_id,''-99'') '
||' and aia.invoice_id ='||l_invoice_id;
 
run_sqlpl('AP_SYSTEM_PARAMETERS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

sqlTxt := 'SELECT afp.* from financials_system_parameters afp, ap_invoices aia '
||' where nvl(afp.org_id,''-99'') = nvl(aia.org_id,''-99'') '
||' and aia.invoice_id ='||l_invoice_id;

 run_sqlpl('FINANCIAL_SYSTEM_PARAMS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

sqlTxt := 'select max(patch_level) from fnd_product_installations where application_id = 200';

execute immediate sqltxt into :l_patch_level;

sqlTxt := 'select * from fnd_product_installations where application_id = 200';

run_sqlpl('FND_PRODUCT_INSTALLATIONS', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

sqlTxt := 'select * from fnd_product_groups';

run_sqlpl('FND_PRODUCT_GROUPS', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

sqlTxt := 'select '''||:l_mrc_enabled||''' MRC_ENABLED_FLAG, '''
||:l_ax_enabled||''' AX_ENABLED_FLAG,'''
||:l_patch_level||'''PATCH_LEVEL from sys.dual';

run_sqlpl('Misc Application Info', sqltxt, l_feedback, l_max_rows,0, 'P', 'Y', 'Y');

end if;


if :l_applversion in ('11.0','10.7') then

sqlTxt := 'SELECT asp.* from ap_system_parameters asp, ap_invoices aia '
||' where nvl(asp.org_id,''-99'') = nvl(aia.org_id,''-99'') '
||' and aia.invoice_id ='||l_invoice_id;
 
run_sqlpl('AP_SYSTEM_PARAMETERS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

sqlTxt := 'SELECT afp.* from financials_system_parameters afp, ap_invoices aia '
 ||' where nvl(afp.org_id,''-99'') = nvl(aia.org_id,''-99'') '
 ||' and aia.invoice_id ='||l_invoice_id;

 run_sqlpl('FINANCIAL_SYSTEM_PARAMS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, 'N', 'Y');

 
end if;

tag('Transaction Details');

BRPRINT;
SEctionPrint ('Transaction Details');
BRPRINT;

brprint;
tab0print('Note:  Several of the query results below have added account columns showing the account segment values.');
tab0print('       These columns were added to show the corresponding account value for tables with code_combination_ids.');
brprint;


sqlTxt := 'select * FROM ap_batches WHERE batch_id in '||
'(select batch_id from ap_invoices where invoice_id = '||l_invoice_id||')';

run_sqlpl('AP_BATCHES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

if l_add_details = 'N' THEN

sqlTxt := 'select ai.*, '
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', ai.accts_pay_code_combination_id) accts_pay_code_account'
||' FROM ap_invoices ai WHERE ai.invoice_id = '||l_invoice_id||' order by ai.invoice_id asc';

else

sqlTxt := 'select distinct ai.*, '
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', ai.accts_pay_code_combination_id) accts_pay_code_account'
||' FROM ap_invoices_all ai '
||' WHERE ai.invoice_id in ('
||' select aip.invoice_id'
||' from ap_invoice_payments_all aip, ap_invoice_payments_all aip2'
||' where aip.check_id = aip2.check_id'
||' and aip2.invoice_id = '||l_invoice_id
||' UNION'
||' select '||l_invoice_id||' from dual)'
||' order by ai.invoice_id asc';

end if;


run_sqlpl('AP_INVOICES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select aid.*, ' 
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', aid.accts_pay_code_combination_id) accts_pay_code_account,'
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', aid.dist_code_combination_id) dist_code_account'
||' FROM ap_invoice_distributions aid WHERE aid.invoice_id = '||l_invoice_id||' order by aid.distribution_line_number asc';

run_sqlpl('AP_INVOICE_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

if object_test('AP_INV_APRVL_HIST_ALL') > 0 then

sqlTxt := 'select * from ap_inv_aprvl_hist_all where invoice_id = '||l_invoice_id
||' order by 1';

run_sqlpl('AP_INV_APRVL_HIST_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;


if :l_applversion = '11.5' then

sqlTxt := 'select distinct aca.* from ap_chrg_allocations aca, ap_invoice_distributions aid'
||' WHERE (aca.charge_dist_id = aid.invoice_distribution_id'
||' or aca.item_dist_id = aid.invoice_distribution_id)'
||' and aid.invoice_id = '||l_invoice_id
||' order by aca.charge_dist_id';

run_sqlpl('AP_CHRG_ALLOCATIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

if l_add_details = 'N' THEN

sqlTxt := 'select aip.*,' 
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', aip.accts_pay_code_combination_id) accts_pay_code_account'
||' FROM ap_invoice_payments aip WHERE aip.invoice_id = '||l_invoice_id
||' order by aip.check_id asc, aip.invoice_payment_id asc';

else

sqlTxt := 'select distinct aip.*,' 
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', aip.accts_pay_code_combination_id) accts_pay_code_account'
||' FROM ap_invoice_payments aip, ap_invoice_payments_all aip2 '
||' WHERE aip2.check_id = aip.check_id'
||' and aip2.invoice_id = '||l_invoice_id
||' order by aip.check_id asc, aip.invoice_payment_id asc';

end if;

run_sqlpl('AP_INVOICE_PAYMENTS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * FROM ap_invoice_prepays WHERE invoice_id = '||l_invoice_id;

run_sqlpl('AP_INVOICE_PREPAYS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select tab.* FROM ap_invoice_payments aip, ap_payment_distributions tab WHERE aip.invoice_payment_id = tab.invoice_payment_id and aip.invoice_id = '||l_invoice_id;

run_sqlpl('AP_PAYMENT_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * from ap_payment_schedules WHERE invoice_id = '||l_invoice_id;

run_sqlpl('AP_PAYMENT_SCHEDULES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);
  
sqlTxt := 'select * FROM ap_holds WHERE invoice_id = '||l_invoice_id;

run_sqlpl('AP_HOLDS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'Select *'
||' from ap_hold_codes'
||' where hold_lookup_code in ('
||' select a.hold_lookup_code'
||' from ap_holds_all a'
||' where a.invoice_id = '||l_invoice_id||')';

run_sqlpl('AP_HOLD_CODES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * FROM ap_selected_invoices WHERE invoice_id = '||l_invoice_id;

run_sqlpl('AP_SELECTED_INVOICES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select asic.* from ap_selected_invoice_checks asic, ap_selected_invoices asi '
||' where (asic.selected_check_id = asi.pay_selected_check_id or asic.selected_check_id = print_selected_check_id) '
||' and asi.invoice_id = '||l_invoice_id;

run_sqlpl('AP_SELECTED_INVOICE_CHECKS_All', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

--added 5/07/03

sqlTxt := 'select * FROM ap_inv_selection_criteria_all WHERE checkrun_name in ('
||' select distinct checkrun_name from ap_checks where check_id in ('
||' select distinct check_id from ap_invoice_payments where invoice_id = '||l_invoice_id||'))';                                         

run_sqlpl('AP_Inv_Selection_Criteria_All', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * FROM ap_checks WHERE check_id in '||
'(select distinct check_id from ap_invoice_payments where invoice_id = '||l_invoice_id||')';                                         

run_sqlpl('AP_CHECKS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

--added 05/07/03

sqlTxt := 'select * FROM ap_terms WHERE term_id in '
||' (select distinct terms_id from ap_invoices where invoice_id = '||l_invoice_id||')';                                         

run_sqlpl('AP_TERMS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * FROM ap_terms_lines WHERE term_id in '
||' (select distinct terms_id from ap_invoices where invoice_id = '||l_invoice_id||')';                                         

run_sqlpl('AP_TERMS_LINES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


if object_test('AP_RECON_DISTRIBUTIONS_ALL') > 0 then

sqlTxt := 'select * from ap_recon_distributions WHERE check_id in '
||' (select check_id from ap_invoice_payments where invoice_id ='||l_invoice_id||')';

run_sqlpl('AP_RECON_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

END IF;

if object_test('AP_PAYMENT_HISTORY_ALL') > 0 then

sqlTxt := 'select * from ap_payment_history aph where aph.check_id in '
||' (select distinct check_id from ap_invoice_payments where invoice_id = '||l_invoice_id||') '
||' order by aph.accounting_event_id asc';

run_sqlpl('AP_PAYMENT_HISTORY_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

END IF;


EXCEPTION

When l_exception then

tab0print('');

when others then --exception section3

  BRPrint;
  ErrorPrint(sqlerrm ||' occurred in test');
  ActionErrorPrint('Please report the above error to Oracle Support Services.');
  BRPrint;
  Show_Footer('&v_scriptlongname', '&v_headerinfo');
  BRPrint;

end; --end3


/* -------------------- Exception Section -------------------------- */

exception when others then --exception section 2

  BRPrint;
  ErrorPrint(sqlerrm ||' occurred in test');
  ActionErrorPrint('Please report the above error to Oracle Support Services.');
  BRPrint;
  Show_Footer('&v_scriptlongname', '&v_headerinfo');
  BRPrint;

end; --end2

exception when others then   --exceptions section 1

  BRPrint;
  ErrorPrint(sqlerrm ||' occurred in test');
  ActionErrorPrint('Please report the above error to Oracle Support Services.');
  BRPrint;
  Show_Footer('&v_scriptlongname', '&v_headerinfo');
  BRPrint;

end; -- end 1

/

@@CoreApiHtmlx.sql
@@AddOnApiHtml.sql

begin  -- begin1

declare --declare 2

p_username varchar2(100);

p_respid number;

/* ------------------------ Declare Section -----------------------------*/

begin  --begin2

--Show_Header('148388.1', '&v_scriptlongname');
init_block;

/* -------------------- Execution secion ------------------------------- */

Declare  --declare 3

--disp_lengths 	lengths;		
--col_headers  	headers;

l_exception		exception;
l_error_msg		varchar2(500);
l_invoice_id		NUMBER := nvl(&v_invoice_id,-1);
l_count 		NUMBER;
l_null 			varchar2(1) := upper('&v_null');
SqlTxt			varchar2(5000);
SqlTxt2			varchar2(5000);
l_cursor		integer;
l_counter		integer;
l_allow			varchar2(50) := NULL;
ql_markers 		V2T;
ql_titles  		V2T;
l_layout		varchar2(10) := upper('&v_layout');
l_tax_code_id		number := NULL;
l_vat_code		varchar2(50) := NULL;
l_gl_details		varchar2(1) := upper('&v_gl_details');
l_dummy		varchar2(240);
l_feedback		varchar2(1) := 'Y';
l_max_rows		number := &v_max_rows;
l_spaces		varchar2(1) := upper('&v_spaces');
l_add_details		varchar2(1) := upper('&v_add_details');
l_main_cursor 	varchar2(10000);
l_id_list	varchar2(4000);
l_hold_column	varchar2(100);
l_ccid		number;
TYPE RefCurTyp IS REF CURSOR;
c_cur		RefCurTyp;

cursor c_po_cursor is
select distinct nvl(po.po_header_id,-99) po_header_id, 
po.po_distribution_id, po.line_location_id
from ap_invoice_distributions aid, po_distributions po
where aid.invoice_id = l_invoice_id
and aid.po_distribution_id is not null
and aid.po_distribution_id = po.po_distribution_id;

--Custom API's

procedure Tag(p_txt varchar2) is
begin
  Insert_HTML('<a NAME='||p_txt||'></a>');
end Tag;
procedure Top is
begin
  Insert_HTML('<a HREF=#quicklinks>Back to Quick Links</a><BR>');
end Top; 

procedure Show_Quicklink_Row(p_ql_titles in V2T, p_ql_markers in V2T) is
 l_row_values V2T;
begin
  if p_ql_titles.count = p_ql_markers.count then
    l_row_values := V2T();
    for i in 1..p_ql_titles.count loop
      l_row_values.extend;
      l_row_values(i) := '<a href=#'||p_ql_markers(i)||'>'||
        p_ql_titles(i)||'</a>';
    end loop;
    Show_table_row(l_row_values,null);
  end if;
end Show_Quicklink_Row;


function object_test(object_test varchar2) return number is

	l_object_test 	number;

begin

l_object_test := 0;

select count(*) 
into l_object_test
from dba_objects
where object_name = object_test;

return(l_object_test);

end object_test;


function Check_Column(p_tab in varchar, p_col in varchar) return boolean is
l_counter integer:=0;
begin
  select count(*) into l_counter
  from   all_tab_columns
  where  table_name = upper(p_tab)
  and    column_name = upper(p_col);
  if l_counter > 0 then
    return(true);
  else
    return(false);
  end if;
exception when others then
  ErrorPrint(sqlerrm||' occured in Check_Column');
  ActionErrorPrint('Report this information to your support analyst');
  raise;
end Check_Column;

--end of custom API's

Begin  --begin 3

if :l_continue = 'Y' then

tag('ATG Details');

if :l_applversion = '11.5' and :l_ax_info = 0 then

BRPRINT;
SEctionPrint ('Accounting Details');
BRPRINT;

sqlTxt := 'select * FROM ap_accounting_events aea where aea.source_id = '||l_invoice_id
||' and aea.source_table = ''AP_INVOICES'' order by aea.accounting_event_id asc';

run_sqlpl('AP_ACCOUNTING_EVENTS_ALL (Invoice)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct aea.* FROM ap_accounting_events aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'               where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' )'
||' order by aea.accounting_event_id asc';

run_sqlpl('AP_ACCOUNTING_EVENTS_ALL (Payment)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select aeh.* from ap_ae_headers aeh, ap_accounting_events aea '
||' where aeh.accounting_event_id = aea.accounting_event_id and aea.source_id = '||l_invoice_id
||' and aea.source_table = ''AP_INVOICES'' order by aeh.ae_header_id asc';

run_sqlpl('AP_AE_HEADERS_ALL (Invoice)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct aeh.* from ap_ae_headers aeh, ap_accounting_events aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'        from ap_invoice_payments aip, ap_payment_history aph '
||'               where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '||'where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and aeh.accounting_event_id = aea.accounting_event_id '
||' order by aeh.ae_header_id asc';

run_sqlpl('AP_AE_HEADERS_ALL (Payment)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select ael.*,'
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', ael.code_combination_id) account'
||' from ap_ae_lines ael, ap_ae_headers aeh, ap_accounting_events aea'
||' where aea.source_id = '||l_invoice_id 
||' and aea.source_table = ''AP_INVOICES'' and aeh.accounting_event_id = aea.accounting_event_id'
||' and ael.ae_header_id = aeh.ae_header_id order by ael.ae_header_id asc, ael.ae_line_number';

run_sqlpl('AP_AE_LINES_ALL (Invoice)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);



sqlTxt := 'select distinct ael.*,' 
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', ael.code_combination_id) account'
||' from ap_ae_lines ael, ap_ae_headers aeh, ap_accounting_events aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'                where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and aeh.accounting_event_id = aea.accounting_event_id '
||' and ael.ae_header_id = aeh.ae_header_id order by ael.ae_header_id asc, ael.ae_line_number';

run_sqlpl('AP_AE_LINES_ALL (Payment)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select enc.* '
||' from ap_encumbrance_lines enc, '
||' ap_invoice_distributions_all aid '
||' where aid.invoice_id =' || l_invoice_id
||' and aid.invoice_distribution_id = enc.invoice_distribution_id '
||' order by enc.invoice_distribution_id asc ';

run_sqlpl('AP_ENCUMBRANCE_LINES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


end if;


if :l_ax_info > 0 then

sqlTxt := 'select * '
||' from ax_events '
||' where application_id = 200  '
||'  and event_type like ''NON_CASH%'' '
||'  and event_field1 = '||l_invoice_id;
 
run_sqlpl('AX_EVENTS (Invoice)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := '  '
||' select * '
||' from ax_events '
||' where application_id = 200  '
||'  and (event_type like ''CASH%'' '
||'    or event_type like ''FUTURE%'') '
||'  and event_field1 in (select check_id '
||'      from ap_invoice_payments '
||'      where invoice_id ='||l_invoice_id||')';

run_sqlpl('AX_EVENTS (Payment)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);
  
sqlTxt := 'select ash.* '
||' from ax_sle_headers ash, '
||' ax_events aea '
||' where ash.event_id = aea.event_id '
||' and ash.application_id = 200  '
||'  and event_type like ''NON_CASH%'' '
||'  and event_field1 ='||l_invoice_id
||' order by ash.set_of_books_id asc, ash.event_id asc ';

run_sqlpl('AX_SLE_HEADERS (Invoice)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);
  
sqlTxt := 'select ash.* '
||' from AX_SLE_headers ash, '
||' aX_events aea '
||' where ash.application_id = 200  '
||'  and aea.event_id = ash.event_id '
||'  and (event_type like ''CASH%'' '
||'  or event_type like ''FUTURE%'') '
||'  and aea.event_field1 in (select check_id '
||'      from ap_invoice_payments '
||'      where invoice_id ='||l_invoice_id||') '
||' order by ash.set_of_books_id asc, ash.event_id asc ';

run_sqlpl('AX_SLE_HEADERS (Payment)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);
 
sqlTxt := 'select asl.* '
||' from ax_sle_lines asl '
||'   , ax_sle_headers ash '
||'   , po_vendors pv '
||' where ash.sle_header_id = asl.sle_header_id '
||'  and ash.journal_sequence_id = asl.journal_sequence_id '
||'  and ash.set_of_books_id = asl.set_of_books_id '
||'  and asl.third_party_id = pv.vendor_id '
||'  and ash.event_id in (select event_id '
||'     from ax_events '
||'    where application_id = 200  '
||'      and event_type like ''NON_CASH%'' '
||'      and event_field1 = '||l_invoice_id||') '
||' order by ash.set_of_books_id, ash.sle_header_id, asl.sle_line_num';

run_sqlpl('AX_SLE_Lines (Invoice)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select asl.* '
||' from ax_sle_lines asl '
||'   , ax_sle_headers ash '
||'   , po_vendors pv '
||' where ash.sle_header_id = asl.sle_header_id '
||'  and ash.journal_sequence_id = asl.journal_sequence_id '
||'  and ash.set_of_books_id = asl.set_of_books_id '
||'  and asl.third_party_id = pv.vendor_id '
||'  and ash.event_id in ( select event_id '
||'     from ax_events ae,  '
||'          ap_invoice_payments aip '
||'     where ae.application_id = 200  '
||'      and (ae.event_type like ''CASH%'' '
||'        or ae.event_type like ''FUTURE%'') '
||'      and ae.event_field1 = aip.check_id '
||'      and aip.invoice_id = '||l_invoice_id||') '
||' order by ash.set_of_books_id, ash.sle_header_id, asl.sle_line_num';

run_sqlpl('AX_SLE_Lines (Payment)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

tag('MRC Details');

BRPRINT;
sectionprint('MRC Information');
BRPRINT;

if object_test('AP_MC_INVOICES') > 0 THEN

sqlTxt := 'select mc.* FROM ap_checks aca, ap_mc_checks mc WHERE aca.check_id in '
||' (select distinct aa.check_id from ap_invoice_payments aa where aa.invoice_id = '||l_invoice_id||') '
||' and aca.check_id = mc.check_id'; 

run_sqlpl('AP_MC_CHECKS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select mc.* FROM   ap_invoices ai , ap_mc_invoices mc WHERE  ai.invoice_id = '||l_invoice_id
||' and ai.invoice_id = mc.invoice_id order by ai.invoice_id asc';

run_sqlpl('AP_MC_INVOICES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


if :l_applversion = '11.5' then

sqlTxt := 'select mc.* FROM ap_invoice_distributions a, ap_mc_invoice_dists mc where a.invoice_id = '||l_invoice_id
||' and a.invoice_distribution_id = mc.invoice_distribution_id and a.invoice_id = mc.invoice_id';

run_sqlpl('AP_MC_INVOICE_DISTS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

else

sqlTxt := 'select mc.* FROM ap_invoice_distributions a, ap_mc_invoice_dists mc where a.invoice_id = '||l_invoice_id
||' and a.distribution_line_number = mc.distribution_line_number and a.invoice_id = mc.invoice_id';

run_sqlpl('AP_MC_INVOICE_DISTS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


end if;

sqlTxt := 'select mc.* from ap_invoice_payments a, ap_mc_invoice_payments mc where a.invoice_id = '||l_invoice_id
||' and a.invoice_payment_id = mc.invoice_payment_id order by a.check_id asc';

run_sqlpl('AP_MC_INVOICE_PAYMENTS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

if object_test('AP_MC_PAYMENT_DISTS_ALL') > 0 THEN

sqlTxt := 'select distinct mcd.* '
||' from ap_mc_payment_dists_all mcd, ap_invoice_payments_all a, ap_mc_invoice_payments mc'
||' where a.invoice_id = '||l_invoice_id
||' and a.invoice_payment_id = mc.invoice_payment_id'
||' and mcd.invoice_payment_id = a.invoice_payment_id';

run_sqlpl('AP_MC_PAYMENT_DISTS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;


if :l_applversion = '11.5' then

sqlTxt := 'select mc.* from ap_payment_history aph, ap_mc_payment_history mc where aph.check_id in '
||' (select distinct aa.check_id from ap_invoice_payments aa where aa.invoice_id = '||l_invoice_id||') ' 
||' and aph.payment_history_id = mc.payment_history_id order by aph.accounting_event_id asc';

run_sqlpl('AP_MC_PAYMENT_HISTORY', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

END IF;

tag('Supplier Info');

BRPRINT;
sectionprint('Supplier Information');
BRPRINT;

sqlTxt := 'select * from po_vendors where vendor_id in (select vendor_id from ap_invoices where invoice_id ='||l_invoice_id||')';	

run_sqlpl('PO_VENDORS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * from po_vendor_sites where vendor_site_id in (select vendor_site_id from ap_invoices where invoice_id ='||l_invoice_id||')';	

run_sqlpl('PO_VENDOR_SITES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

if :l_applversion = '11.5' then

sqlTxt := 'select * from AP_DUPLICATE_VENDORS_ALL '
||' where 1=1'
||' and ('
||' vendor_id in '
||' (select distinct vendor_id from ap_invoices where invoice_id ='||l_invoice_id
||' UNION'
||' select distinct ac.vendor_id from ap_checks ac, ap_invoice_payments_all aip '
||' where aip.check_id = ac.check_id and aip.invoice_id ='||l_invoice_id
||' UNION '
||' select distinct vendor_id from ap_liability_balance where invoice_id ='||l_invoice_id||')'
||' OR' 
||' duplicate_vendor_id in '
||' (select distinct vendor_id from ap_invoices where invoice_id ='||l_invoice_id
||' UNION '
||' select distinct ac.vendor_id from ap_checks ac, ap_invoice_payments_all aip '
||' where aip.check_id = ac.check_id and aip.invoice_id ='||l_invoice_id
||' UNION '
||' select distinct vendor_id from ap_liability_balance where invoice_id ='||l_invoice_id||')'
||' )';

else


sqlTxt := 'select * from AP_DUPLICATE_VENDORS_ALL '
||' where 1=1'
||' and ('
||' vendor_id in '
||' (select distinct vendor_id from ap_invoices where invoice_id ='||l_invoice_id
||' UNION'
||' select distinct ac.vendor_id from ap_checks ac, ap_invoice_payments_all aip '
||' where aip.check_id = ac.check_id and aip.invoice_id ='||l_invoice_id
||' UNION '
||' select distinct vendor_id from ap_liability_balance where invoice_id ='||l_invoice_id||')'
||' OR' 
||' duplicate_vendor_id in '
||' (select distinct vendor_id from ap_invoices where invoice_id ='||l_invoice_id
||' UNION '
||' select distinct ac.vendor_id from ap_checks ac, ap_invoice_payments_all aip '
||' where aip.check_id = ac.check_id and aip.invoice_id ='||l_invoice_id||')'
||' )';

end if;

--run_sqlpl('AP_DUPLICATE_VENDORS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);



tag('PO Info');

BRPRINT;
sectionprint('PO Information');
BRPRINT;

sqlTxt := 'select * from po_headers where po_header_id in ('
||' select distinct po.po_header_id '
||' from ap_invoice_distributions aid, po_distributions po '
||' where aid.invoice_id = '||l_invoice_id
||'  and aid.po_distribution_id is not null '
||' and aid.po_distribution_id = po.po_distribution_id)';
 
run_sqlpl('PO_HEADERS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * from po_distributions where po_distribution_id in ('
||' select distinct po.po_distribution_id '
||' from ap_invoice_distributions aid, po_distributions po '
||' where aid.invoice_id = '||l_invoice_id
||'  and aid.po_distribution_id is not null '
||' and aid.po_distribution_id = po.po_distribution_id)';

run_sqlpl('PO_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select * from po_lines where (po_header_id, po_line_id) in ('
||' select distinct po.po_header_id, po.po_line_id '
||' from ap_invoice_distributions aid, po_distributions po '
||' where aid.invoice_id = '||l_invoice_id
||'  and aid.po_distribution_id is not null '
||' and aid.po_distribution_id = po.po_distribution_id)';

run_sqlpl('PO_LINES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


sqlTxt := 'select * from po_line_locations where (po_header_id, po_line_id, line_location_id) in ('
||' select distinct po.po_header_id, po.po_line_id, po.line_location_id '
||' from ap_invoice_distributions aid, po_distributions po '
||' where aid.invoice_id = '||l_invoice_id
||' and aid.po_distribution_id is not null '
||' and aid.po_distribution_id = po.po_distribution_id)';

run_sqlpl('PO_LINE_LOCATIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

if object_test('AP_MC_INVOICES') > 0 THEN

sqlTxt := 'select * from po_mc_headers where po_header_id in ('
||' select distinct po.po_header_id '
||' from ap_invoice_distributions aid, po_distributions po '
||' where aid.invoice_id = '||l_invoice_id
||'  and aid.po_distribution_id is not null '
||' and aid.po_distribution_id = po.po_distribution_id)';

run_sqlpl('PO_MC_HEADERS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select mcd.* from po_mc_distributions mcd, po_distributions pd '
||' where pd.po_distribution_id in ('
||' select distinct po.po_distribution_id '
||' from ap_invoice_distributions aid, po_distributions po '
||' where aid.invoice_id = '||l_invoice_id
||' and aid.po_distribution_id is not null '
||' and aid.po_distribution_id = po.po_distribution_id)'
||'  and pd.po_distribution_id = mcd.po_distribution_id';

run_sqlpl('PO_MC_DISTRIBUTIONS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

tag('GL Details');

BRPRINT;
sectionprint('GL Information');
BRPRINT;

if l_gl_details = 'Y' THEN

if :l_applversion = '11.5' then
--R11i

--Added 10/16/02

sqlTxt := 'select distinct xla.* '
||' from ap_ae_headers_all aeh, ap_accounting_events_all aea, xla_gl_transfer_batches_all xla'
||' where aea.source_id = '||l_invoice_id 
||' and aea.source_table = ''AP_INVOICES'''
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.gl_transfer_run_id = xla.gl_transfer_run_id'
||' UNION '
||' select distinct xla.* '
||' from ap_ae_headers_all aeh, ap_accounting_events_all aea, xla_gl_transfer_batches_all xla, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'                where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and xla.gl_transfer_run_id = aeh.gl_transfer_run_id';


run_sqlpl('XLA_GL_TRANSFER_BATCHES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct gi.* '
||' from gl_interface gi, ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea '
||' where ael.gl_sl_link_id = gi.gl_sl_link_id '
||' and aea.source_id = '||l_invoice_id 
||' and aea.source_table = ''AP_INVOICES'''
||' and gi.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id';

run_sqlpl('GL_INTERFACE (Invoices)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct gi.* '
||' from gl_interface gi,ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'                where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and ael.gl_sl_link_id = gi.gl_sl_link_id '
||' and gi.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id';


run_sqlpl('GL_INTERFACE (Payments)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct gir.* '
||' from gl_import_references gir, ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea '
||' where ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and aea.source_id = '||l_invoice_id 
||' and aea.source_table = ''AP_INVOICES'''
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id'
||' UNION '
||' select distinct gir.* '
||' from gl_import_references gir, ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'                where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id';


run_sqlpl('GL_IMPORT_REFERENCES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);



sqlTxt := 'select distinct gjb.* '
||' from gl_import_references gir, gl_je_batches gjb,ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea '
||' where ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and aea.source_id = '||l_invoice_id 
||' and aea.source_table = ''AP_INVOICES'''
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id'
||' and gjb.je_batch_id = gir.je_batch_id'
||' UNION '
||' select distinct gjb.* '
||' from gl_import_references gir, gl_je_batches gjb,ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'                where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id'
||' and gjb.je_batch_id = gir.je_batch_id '; 


run_sqlpl('GL_JE_BATCHES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


sqlTxt := 'select distinct gjh.* '
||' from gl_import_references gir, gl_je_headers gjh,ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea '
||' where ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and aea.source_id = '||l_invoice_id 
||' and aea.source_table = ''AP_INVOICES'''
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id'
||' and gjh.je_header_id = gir.je_header_id';

run_sqlpl('GL_JE_HEADERS (Invoices)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct gjh.* '
||' from gl_import_references gir, gl_je_headers gjh,ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'                where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id'
||' and gjh.je_header_id = gir.je_header_id'; 


run_sqlpl('GL_JE_HEADERS (Payments)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct gll.* '
||' from gl_import_references gir, gl_je_lines gll,ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea '
||' where ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and aea.source_id = '||l_invoice_id 
||' and aea.source_table = ''AP_INVOICES'''
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id'
||' and gll.je_header_id = gir.je_header_id' 
||' and gll.je_line_num = gir.je_line_num ';


run_sqlpl('GL_JE_LINES (Invoices)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct gll.* '
||' from gl_import_references gir, gl_je_lines gll,ap_ae_lines ael,ap_ae_headers_all aeh, ap_accounting_events_all aea, '
||' (select distinct aip.check_id, aph.payment_history_id  '
||'         from ap_invoice_payments aip, ap_payment_history aph '
||'                where aip.invoice_id ='||l_invoice_id
||'               and aph.check_id(+) = aip.check_id) ct '
||' where ('
||'   (aea.source_id = ct.check_id and aea.source_table in (''AP_CHECKS'')) '
||' or '
||'   (aea.source_id = ct.payment_history_id and aea.source_table in (''AP_PAYMENT_HISTORY'')) '
||' ) '
||' and ael.gl_sl_link_id = gir.gl_sl_link_id '
||' and gir.gl_sl_link_table = ''APECL'' '
||' and aea.accounting_event_id = aeh.accounting_event_id'
||' and aeh.ae_header_id = ael.ae_header_id'
||' and gll.je_header_id = gir.je_header_id ' 
||' and gll.je_line_num = gir.je_line_num';


run_sqlpl('GL_JE_LINES (Payments)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


else
--R10.7 and R11

sqlTxt := 'select distinct gi.* from ap_invoice_distributions aid,gl_interface gi where upper(gi.reference26) = ''AP INVOICES'' '
||' and gi.reference22 = to_char(invoice_id) and aid.invoice_id = '||l_invoice_id
||' Union ALL '
||' select distinct gi.* from gl_interface gi, ap_invoice_payments aip where upper(gi.reference26) = ''AP PAYMENTS'' '
||' and gi.reference23 = to_char(aip.check_id) and aip.invoice_id = '||l_invoice_id;

run_sqlpl('GL_INTERFACE', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


sqlTxt := 'select distinct gi.* from gl_import_references gi, ap_invoice_distributions aid where upper(gi.reference_6) = ''AP INVOICES'' '
||' and gi.reference_2 = to_char(aid.invoice_id) and aid.invoice_id = '||l_invoice_id
||' Union ALL '
||' select distinct gi.* from gl_import_references gi, ap_invoice_payments aip where upper(gi.reference_6) = ''AP PAYMENTS'' '
||' and gi.reference_3 = to_char(aip.check_id) and aip.invoice_id = '||l_invoice_id;

run_sqlpl('GL_IMPORT_REFERENCES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct glb.* from gl_import_references gi, ap_invoice_distributions aid, gl_je_batches glb where upper(gi.reference_6) = ''AP INVOICES'' '
||' and gi.reference_2 = to_char(aid.invoice_id) and aid.invoice_id = '||l_invoice_id
||' and glb.je_batch_id = gi.je_batch_id'
||' Union ALL '
||' select distinct glb.* from gl_import_references gi, ap_invoice_payments aip,  gl_je_batches glb where upper(gi.reference_6) = ''AP PAYMENTS'' '
||' and gi.reference_3 = to_char(aip.check_id) and aip.invoice_id = '||l_invoice_id
||' and glb.je_batch_id = gi.je_batch_id';


run_sqlpl('GL_JE_BATCHES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct glh.* from gl_import_references gi, ap_invoice_distributions aid, gl_je_headers glh where upper(gi.reference_6) = ''AP INVOICES'' '
||' and gi.reference_2 = to_char(aid.invoice_id) and aid.invoice_id = '||l_invoice_id
||' and glh.je_header_id = gi.je_header_id'
||' Union ALL '
||' select distinct glh.* from gl_import_references gi, ap_invoice_payments aip,  gl_je_headers glh where upper(gi.reference_6) = ''AP PAYMENTS'' '
||' and gi.reference_3 = to_char(aip.check_id) and aip.invoice_id = '||l_invoice_id
||' and glh.je_header_id = gi.je_header_id';

run_sqlpl('GL_JE_HEADERS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct gll.* from gl_import_references gi, ap_invoice_distributions aid, gl_je_lines gll where upper(gi.reference_6) = ''AP INVOICES'' '
||' and gi.reference_2 = to_char(aid.invoice_id) and aid.invoice_id = '||l_invoice_id
||' and gll.je_header_id = gi.je_header_id '
||' and gll.je_line_num = gi.je_line_Num'  --added 10/16/02
||'  Union ALL '
||' select distinct gll.* from gl_import_references gi, ap_invoice_payments aip,  gl_je_lines gll where upper(gi.reference_6) = ''AP PAYMENTS'' '
||' and gi.reference_3 = to_char(aip.check_id) and aip.invoice_id = '||l_invoice_id
||'  and gll.je_header_id = gi.je_header_id '
||' and gll.je_line_num = gi.je_line_Num';  --added 10/16/02

run_sqlpl('GL_JE_LINES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

else

sectionprint('GL Details Not Selected');

end if;

tag('Tax Details');

BRPRINT;
sectionprint('Tax Information');
BRPRINT;


if :l_applversion in ('11.5') then

sqlTxt := 'select distinct * from ap_tax_codes where tax_id in ('
||' select distinct tax_code_id from ap_invoice_distributions '
||' where tax_code_id is not null and invoice_id = '||l_invoice_id||')'
||' Union '
||' select distinct atc.* from ar_tax_group_codes agc, ap_tax_codes atc, ap_tax_codes atc2 '
||' where agc.tax_group_id = atc2.tax_id and agc.tax_code_id = atc.tax_id '
||' and agc.tax_group_id in ( '
||' select distinct tax_code_id from ap_invoice_distributions '
||' where tax_code_id is not null and invoice_id = '||l_invoice_id||')';


run_sqlpl('AP_TAX_CODES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);
    

sqlTxt := 'select distinct awt.* from ap_awt_groups awt '
||' where awt.group_id in ( '
||' select distinct aid.awt_group_id from ap_invoice_distributions aid '
||' where aid.awt_group_id is not null '
||' and aid.invoice_id = '||l_invoice_id||')';

run_sqlpl('AP_AWT_GROUPS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


sqlTxt := 'select distinct awt.* from AP_AWT_GROUP_TAXES_ALL awt '
||' where awt.group_id in ( '
||' select distinct aid.awt_group_id from ap_invoice_distributions aid '
||' where aid.awt_group_id is not null '
||' and aid.invoice_id = '||l_invoice_id||')';

run_sqlpl('AP_AWT_GROUP_TAXES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct awt.* from ap_tax_codes atc, ap_awt_tax_rates awt '
||' where awt.tax_name = atc.name and atc.tax_id in ( '
||'  select distinct aid.tax_code_id tax_code_id from ap_invoice_distributions aid, ap_tax_codes atc '
||' where aid.tax_code_id = atc.tax_id and aid.tax_code_id is not null '
||' and atc.tax_type = ''AWT'' and aid.invoice_id = '||l_invoice_id||') '
||' UNION '
||' select distinct awt.* from ap_awt_tax_rates awt '
||' where awt.tax_rate_id in ( '
||' select distinct aid.awt_tax_rate_id from ap_invoice_distributions aid '
||' where aid.awt_tax_rate_id is not null '
||' and aid.invoice_id = '||l_invoice_id||')';

run_sqlpl('AP_AWT_TAX_RATES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);
	    
end if;

if :l_applversion in ('10.7', '11.0') then


sqlTxt := 'select * from ap_tax_codes where name in ( '
||' select distinct vat_code from ap_invoice_distributions '
||' where vat_code is not null and invoice_id = '||l_invoice_id||')';

run_sqlpl('AP_TAX_CODES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

	    

sqlTxt := 'select distinct awt.* from ap_tax_codes atc, ap_awt_tax_rates awt '
||' where awt.tax_name = atc.name and atc.name in ('
||' select distinct vat_code from ap_invoice_distributions '
||' where vat_code is not null and invoice_id = '||l_invoice_id||')';

run_sqlpl('AP_AWT_TAX_RATES_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

	  
end if;

--added 5/7/03

if object_test('AP_AWT_TEMP_DISTRIBUTIONS_ALL') > 0 THEN

sqlTxt := 'select * FROM ap_awt_temp_distributions_all where invoice_id = '||l_invoice_id;                                         

run_sqlpl('AP_AWT_TEMP_DISTRIBUTIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

tag('Encumbrance Info');

BRPRINT;
sectionprint('Encumbrance Information');
BRPRINT;

sqlTxt := 'select * from gl_bc_packets where je_source_name = ''Payables'' and reference2 = '||l_invoice_id;

run_sqlpl('GL_BC_PACKETS', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

tag('Prepayment Information');

BRPRINT;
sectionprint('Prepayment Information');
BRPRINT;

if :l_applversion = '11.5' then

l_count := 0;

select count(*)
into l_count
from ap_invoices 
where invoice_type_lookup_code = 'PREPAYMENT'
and invoice_id = l_invoice_id;

	if l_count = 0 then


sqlTxt := 'SELECT apu.VENDOR_NAME, ai.INVOICE_NUM, ai.invoice_amount, apu.PREPAY_ID, apu.PREPAY_DISTRIBUTION_ID,  '
||' apu.PREPAY_AMOUNT_APPLIED,apu.PREPAY_DIST_NUMBER,apu.INVOICE_ID,apu.INVOICE_DISTRIBUTION_ID '
||' FROM AP_UNAPPLY_PREPAYS_FR_PREPAY_V apu, ap_invoices ai '
||' WHERE apu.invoice_ID = '||l_invoice_id
||'  and ai.invoice_id = apu.prepay_id'; 

run_sqlpl('Prepayment Invoices Applied to Invoice', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

	else


sqlTxt := 'SELECT apu.VENDOR_NAME, apu.INVOICE_NUM, apu.INVOICE_ID,apu.INVOICE_DISTRIBUTION_ID, ai.invoice_amount,  '
||' apu.PREPAY_ID,apu.PREPAY_DISTRIBUTION_ID, apu.PREPAY_AMOUNT_APPLIED,apu.PREPAY_DIST_NUMBER '
||' FROM AP_UNAPPLY_PREPAYS_FR_PREPAY_V apu, ap_invoices ai '
||' WHERE prepay_ID = '||l_invoice_id
||' and ai.invoice_id = apu.invoice_id'; 


run_sqlpl('Invoices Prepayment Invoice have been Applied to', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


	end if;

else

sectionprint('Prepayments Applied to Invoice');

 sqlTxt := 'SELECT invoice_id, org_id, prepayment_amount_applied, '
 ||' prepayment_amount_applied, prepay_id '
 ||' FROM ap_invoice_prepays                                            '
 ||' WHERE 2=2                                                                       '
 ||'  and invoice_id ='||l_invoice_id;

run_sqlpl('AP_INVOICE_PREPAYS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

tag('Pymt Doc/Bank Info');

BRPRINT;
sectionprint('Payment Document/Bank Information');
BRPRINT;

sqlTxt := 'select abb.* '
||' from ap_bank_accounts aba, ap_check_stocks acs, ap_bank_branches abb '
||' where acs.check_stock_id in ( '
||' select check_stock_id '
||' from ap_checks '
||' where check_id in ( '
||' select distinct check_id '
||'                     from ap_invoice_payments '
||'                     where invoice_id = '||l_invoice_id||')) '
||' and acs.bank_account_id = aba.bank_account_id '
||' and abb.bank_branch_id = aba.bank_branch_id '
||' order by abb.bank_name';

run_sqlpl('AP_BANK_BRANCHES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select aba.*, '
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', aba.asset_code_combination_id) asset_account,'
||' fnd_flex_ext.get_segs(''SQLGL'',''GL#'', '||:l_coa||', aba.cash_clearing_ccid) cash_clearing_account'
||' from ap_bank_accounts aba, ap_check_stocks acs, ap_bank_branches abb '
||' where acs.check_stock_id in ( '
||' select check_stock_id '
||' from ap_checks '
||' where check_id in ( '
||' select distinct check_id '
||'                      from ap_invoice_payments '
||'                      where invoice_id = '||l_invoice_id||')) '
||' and acs.bank_account_id = aba.bank_account_id '
||' and abb.bank_branch_id = aba.bank_branch_id '
||' order by aba.bank_account_name';

run_sqlpl('AP_BANK_ACCOUNTS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select acs.* '
||' from ap_bank_accounts aba, ap_check_stocks acs, ap_bank_branches abb '
||' where acs.check_stock_id in ( '
||' select check_stock_id '
||' from ap_checks '
||' where check_id in ( '
||' select distinct check_id '
||'                      from ap_invoice_payments '
||'                      where invoice_id = '||l_invoice_id||')) '
||' and acs.bank_account_id = aba.bank_account_id '
||' and abb.bank_branch_id = aba.bank_branch_id '
||' order by acs.name';

run_sqlpl('AP_CHECK_STOCKS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select acf.* '
||' from ap_payment_programs app, ap_check_stocks acs, ap_check_formats acf, '
||' ap_payment_programs app2, ap_payment_programs app3 '
||' where acs.check_stock_id in ( '
||'  select check_stock_id '
||' from ap_checks '
||' where check_id in ( '
||' select distinct check_id '
||'                     from ap_invoice_payments '
||'                       where invoice_id = '||l_invoice_id||')) '
||' and acs.check_format_id = acf.check_format_id '
||' and app.program_id = acf.format_payments_program_id '
||' and acf.build_payments_program_id = app2.program_id '
||' and acf.remittance_advice_program_id = app3.program_id(+) '
||' order by acf.name';

run_sqlpl('AP_CHECK_FORMATS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select app.* '
||' from ap_payment_programs app, ap_check_stocks acs, ap_check_formats acf, '
||' ap_payment_programs app2, ap_payment_programs app3 '
||' where acs.check_stock_id in ( '
||' select check_stock_id '
||' from ap_checks '
||' where check_id in ( '
||' select distinct check_id '
||'                      from ap_invoice_payments '
||'                      where invoice_id = '||l_invoice_id||')) '
||' and acs.check_format_id = acf.check_format_id '
||' and app.program_id = acf.format_payments_program_id '
||' and acf.build_payments_program_id = app2.program_id '
||' and acf.remittance_advice_program_id = app3.program_id(+) '
||' order by app.program_name';

run_sqlpl('AP_PAYMENT_PROGRAMS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

--Add data for Argentina localizations 4/9/03

l_count := 0;

select count(*)
into l_count
from ap_invoices
where global_attribute_category = 'JL.AR.APXINWKB.INVOICES'
and invoice_id = l_invoice_id;

if l_count > 0 then

	if object_test('JL_AR_AP_AWT_CERTIF_ALL') > 0 then

tag('Localizations');

	BRPRINT;
	sectionprint('Argentina Localizations');
	BRPRINT;

	sqlTxt := 'select jl.*'
	|| ' from jl_ar_ap_awt_certif jl, ap_checks ac, ap_invoice_payments aip'
	|| ' where aip.check_id = ac.check_id and aip.invoice_id = '||l_invoice_id
	|| ' and jl.check_number = ac.check_number and jl.checkrun_name = ac.checkrun_name';

	run_sqlpl('JL_AR_AP_AWT_CERTIF_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

	end if;

	if object_test('JL_ZZ_AP_INV_DIS_WH_ALL') > 0 then

	sqlTxt := 'select *'
 	|| ' from jl_zz_ap_inv_dis_wh'
	|| ' where invoice_id = '||l_invoice_id;

	run_sqlpl('JL_ZZ_AP_INV_DIS_WH', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

	end if;

end if;

--added 05/07/03

if :l_ax_info > 0 then

tag('GLOBAL (AX)');

BRPRINT;
sectionprint('Global Accounting (AX) Information');
BRPRINT;

sqlTxt := 'SELECT * from ax_document_statuses '
|| ' where nvl(org_id,-99) = '||:l_org_id 
|| ' and document_id1 ='||l_invoice_id
|| ' AND document_code = ''INVOICE''';

run_sqlpl('AX_DOCUMENT_STATUSES (Invoice)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'SELECT * from ax_document_statuses axd'
|| ' where nvl(org_id,-99) = '||:l_org_id 
|| ' and document_id1 in (select check_id '
|| '      from ap_invoice_payments'
|| '      where invoice_id ='||l_invoice_id||')'
|| ' AND document_code = ''CHECK'' ';

run_sqlpl('AX_DOCUMENT_STATUSES (Payment)', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);


end if;

tag('CE Information');

BRPRINT;
sectionprint('Cash Management (CE) Information');
BRPRINT;


sqlTxt := 'select distinct csr.* ' 
||' from ce_statement_lines cel, ce_statement_headers ceh, ce_statement_reconciliations csr,'
||' ap_invoice_payments aip, ap_checks ac'
||' where cel.statement_header_id = ceh.statement_header_id'
||' and ac.check_id = aip.check_id'
||' and aip.invoice_id = '||l_invoice_id
||' and aip.check_id = ac.check_id'
||' and ac.bank_account_id = ceh.bank_account_id'
||' and to_char(ac.check_number) = cel.bank_trx_number'
||' and csr.statement_line_id = cel.statement_line_id';

run_sqlpl('CE_STATEMENT_RECONCILS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct ceh.* ' 
||' from ce_statement_lines cel, ce_statement_headers ceh, ce_statement_reconciliations csr,'
||' ap_invoice_payments aip, ap_checks ac'
||' where cel.statement_header_id = ceh.statement_header_id'
||' and ac.check_id = aip.check_id'
||' and aip.invoice_id = '||l_invoice_id
||' and aip.check_id = ac.check_id'
||' and ac.bank_account_id = ceh.bank_account_id'
||' and to_char(ac.check_number) = cel.bank_trx_number'
||' and csr.statement_line_id = cel.statement_line_id';

run_sqlpl('CE_STATEMENT_HEADERS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

sqlTxt := 'select distinct cel.* ' 
||' from ce_statement_lines cel, ce_statement_headers ceh, ce_statement_reconciliations csr,'
||' ap_invoice_payments aip, ap_checks ac'
||' where cel.statement_header_id = ceh.statement_header_id'
||' and ac.check_id = aip.check_id'
||' and aip.invoice_id = '||l_invoice_id
||' and aip.check_id = ac.check_id'
||' and ac.bank_account_id = ceh.bank_account_id'
||' and to_char(ac.check_number) = cel.bank_trx_number'
||' and csr.statement_line_id = cel.statement_line_id';

run_sqlpl('CE_STATEMENT_LINES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

if object_test('FV_TREASURY_CONFIRMATIONS_ALL') > 0 then

tag('Treasury Confirmation');

BRPRINT;
sectionprint('Treasury Confirmation Information');
BRPRINT;


sqlTxt := 'select distinct tc.*'
||' from ap_invoice_payments_all aip, ap_checks_all ac, fv_treasury_confirmations_all tc '
||' where ac.checkrun_name = tc.checkrun_name'
||' and ac.check_id = aip.check_id'
||' and aip.invoice_id = '||l_invoice_id;

run_sqlpl('FV_TREASURY_CONFIRMATIONS_ALL', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

end if;

tag('GL_PERIOD_STATUSES');

BRPRINT;
sectionprint('GL Period Information');
BRPRINT;

if :l_applversion = '11.5' then

sqlTxt := 'select distinct gps.* from gl_period_statuses gps,'
||' (select distinct accounting_date, set_of_books_id'
||' from ap_invoice_distributions_all'
||' where invoice_id = '||l_invoice_id
||' UNION '
||' select distinct accounting_date,  set_of_books_id'
||' from ap_invoice_payments_all'
||' where invoice_id = '||l_invoice_id
||' UNION'
||' select distinct accounting_date, -1'
||' from ap_payment_history_all'
||' where check_id in '
||' (select check_id from ap_invoice_payments_all where invoice_id = '||l_invoice_id||')) atg_date'
||' where atg_date.accounting_date between gps.start_date and gps.end_date'
||' and gps.application_id in (101,200)'
||' and gps.set_of_books_id = atg_date.set_of_books_id';


end if;

if :l_applversion <> '11.5' then

sqlTxt := 'select distinct gps.* from gl_period_statuses gps,'
||' (select distinct accounting_date, set_of_books_id'
||' from ap_invoice_distributions_all'
||' where invoice_id = '||l_invoice_id
||' UNION '
||' select distinct accounting_date,  set_of_books_id'
||' from ap_invoice_payments_all'
||' where invoice_id = '||l_invoice_id
||' UNION'
||' select distinct accounting_date, -1'
||' from ap_recon_distributions_all'
||' where check_id in '
||' (select check_id from ap_invoice_payments_all where invoice_id = '||l_invoice_id||')) atg_date'
||' where atg_date.accounting_date between gps.start_date and gps.end_date'
||' and gps.application_id in (101,200)'
||' and gps.set_of_books_id = atg_date.set_of_books_id';

end if;

run_sqlpl('GL_PERIOD_STATUSES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

tag('Currency Details');

BRPRINT;
sectionprint('Currency Details');
BRPRINT;


sqlTxt := 'select *'
||' from fnd_currencies'
||' where currency_code in ('
||' select a.invoice_currency_code'
||' from ap_invoices_all a'
||' where a.invoice_id = '||l_invoice_id
||' UNION'
||' select b.payment_currency_code'
||' from ap_invoices_all b'
||' where b.invoice_id = '||l_invoice_id
||' UNION'
||' select c.base_currency_code'
||' from ap_system_parameters_all c, ap_invoices_all d'
||'  where nvl(c.org_id,-99) = nvl(d.org_id, -99)'
||' and d.invoice_id ='||l_invoice_id||')';


run_sqlpl('FND_CURRENCIES', sqltxt, l_feedback, l_max_rows,0, l_layout, l_null, l_spaces);

l_main_cursor:= 'select distinct i.ACCTS_PAY_CODE_COMBINATION_ID ccid from ap_invoices_all i where i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select d.DIST_CODE_COMBINATION_ID		from ap_invoice_distributions_all d where d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select d.ACCTS_PAY_CODE_COMBINATION_ID	from ap_invoice_distributions_all d where d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select d.PRICE_VAR_CODE_COMBINATION_ID	from ap_invoice_distributions_all d where d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select d.RATE_VAR_CODE_COMBINATION_ID	from ap_invoice_distributions_all d where d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.ACCTS_PAY_CODE_COMBINATION_ID	from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.ASSET_CODE_COMBINATION_ID		from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.GAIN_CODE_COMBINATION_ID		from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.LOSS_CODE_COMBINATION_ID		from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.FUTURE_PAY_CODE_COMBINATION_ID	from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select b.ASSET_CODE_COMBINATION_ID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.GAIN_CODE_COMBINATION_ID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.LOSS_CODE_COMBINATION_ID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.CASH_CLEARING_CCID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.BANK_CHARGES_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.BANK_ERRORS_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.EARNED_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.UNEARNED_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.ON_ACCOUNT_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.UNAPPLIED_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.UNIDENTIFIED_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.FACTOR_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.RECEIPT_CLEARING_CCID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.REMITTANCE_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.SHORT_TERM_DEPOSIT_CCID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.FUTURE_DATED_PAYMENT_CCID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.BR_REMITTANCE_CCID		from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select b.BR_FACTOR_CCID			from ap_bank_accounts_all b where bank_account_id in (select c.bank_account_id from ap_checks_all c where c.check_id in (select p.check_id from ap_invoice_payments_all p where p.invoice_id = ' || &v_invoice_id || '))'
|| chr(10) || 'UNION select l.CODE_COMBINATION_ID		from ap_ae_lines_all l, ap_ae_headers_all h, ap_invoice_distributions_all d where l.ae_header_id = h.ae_header_id and h.accounting_event_id = d.accounting_event_id and d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select l.CODE_COMBINATION_ID		from ap_ae_lines_all l, ap_ae_headers_all h, ap_invoice_payments_all d where l.ae_header_id = h.ae_header_id and h.accounting_event_id = d.accounting_event_id and d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select l.CODE_COMBINATION_ID		from ap_ae_lines_all l, ap_ae_headers_all h, ap_invoice_payments_all d, ap_payment_history_all p where l.ae_header_id = h.ae_header_id and h.accounting_event_id = d.accounting_event_id and d.check_id = p.check_id and d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select s.ACCTS_PAY_CODE_COMBINATION_ID	from ap_invoices_all i, ap_system_parameters_all s where i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select s.PREPAY_CODE_COMBINATION_ID	from ap_invoices_all i, ap_system_parameters_all s where i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select s.GAIN_CODE_COMBINATION_ID		from ap_invoices_all i, ap_system_parameters_all s where i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select s.LOSS_CODE_COMBINATION_ID		from ap_invoices_all i, ap_system_parameters_all s where i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select s.ROUNDING_ERROR_CCID		from ap_invoices_all i, ap_system_parameters_all s where i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select f.ACCTS_PAY_CODE_COMBINATION_ID	from ap_invoices_all i, ap_system_parameters_all s, FINANCIALS_SYSTEM_PARAMS_ALL f where s.org_id = f.org_id and i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select f.PREPAY_CODE_COMBINATION_ID	from ap_invoices_all i, ap_system_parameters_all s, FINANCIALS_SYSTEM_PARAMS_ALL f where s.org_id = f.org_id and i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select f.DISC_TAKEN_CODE_COMBINATION_ID	from ap_invoices_all i, ap_system_parameters_all s, FINANCIALS_SYSTEM_PARAMS_ALL f where s.org_id = f.org_id and i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select f.FUTURE_DATED_PAYMENT_CCID		from ap_invoices_all i, ap_system_parameters_all s, FINANCIALS_SYSTEM_PARAMS_ALL f where s.org_id = f.org_id and i.org_id = s.org_id and i.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.BUDGET_ACCOUNT_ID			from ap_invoice_distributions_all d, po_distributions_all p where d.po_distribution_id = p.po_distribution_id and d.po_distribution_id is not null and d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.ACCRUAL_ACCOUNT_ID		from ap_invoice_distributions_all d, po_distributions_all p where d.po_distribution_id = p.po_distribution_id and d.po_distribution_id is not null and d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.VARIANCE_ACCOUNT_ID		from ap_invoice_distributions_all d, po_distributions_all p where d.po_distribution_id = p.po_distribution_id and d.po_distribution_id is not null and d.invoice_id = ' || &v_invoice_id
|| chr(10) || 'UNION select p.CODE_COMBINATION_ID		from ap_invoice_distributions_all d, po_distributions_all p where d.po_distribution_id = p.po_distribution_id and d.po_distribution_id is not null and d.invoice_id = ' || &v_invoice_id;

begin
	select column_name into l_hold_column from all_tab_columns where table_name = 'PO_DISTRIBUTIONS_ALL' and column_name = 'DEST_CHARGE_ACCOUNT_ID';
	l_main_cursor := l_main_cursor || chr(10) || 'UNION select p.DEST_CHARGE_ACCOUNT_ID		from ap_invoice_distributions_all d, po_distributions_all p where d.po_distribution_id = p.po_distribution_id and d.po_distribution_id is not null and d.invoice_id = ' || &v_invoice_id;
exception
	when others then
		null;
end;

begin
	select column_name into l_hold_column from all_tab_columns where table_name = 'PO_DISTRIBUTIONS_ALL' and column_name = 'DEST_CHARGE_ACCOUNT_ID';
	l_main_cursor := l_main_cursor || chr(10) || 'UNION select p.DEST_VARIANCE_ACCOUNT_ID		from ap_invoice_distributions_all d, po_distributions_all p where d.po_distribution_id = p.po_distribution_id and d.po_distribution_id is not null and d.invoice_id = ' || &v_invoice_id;
exception
	when others then
		null;
end;

l_id_list := '-1';
OPEN c_cur FOR l_main_cursor;
LOOP
	FETCH c_cur INTO l_ccid;
	EXIT WHEN c_cur%NOTFOUND;
	if l_ccid is not null then
		l_id_list := l_id_list || ',' || l_ccid;
	end if;
END LOOP;
CLOSE c_cur;

sqlTxt :=     'select *'
|| chr(10) || '  from gl_code_combinations'
|| chr(10) || ' where code_combination_id in ('
|| l_id_list
|| chr(10) || ')';

run_sqlpl('GL_CODE_COMBINATIONS', sqlTxt, 'N', 100, 0, 'L','Y','N');

sqlTxt :=     'select *'
|| chr(10) || ' from FND_ID_FLEX_SEGMENTS'
|| chr(10) || ' where ID_FLEX_NUM in ('
|| chr(10) || ' select chart_of_accounts_id'
|| chr(10) || '  from gl_code_combinations'
|| chr(10) || ' where application_id = 101'
|| chr(10) || ' and code_combination_id in ('
|| l_id_list
|| chr(10) || '))';

run_sqlpl('FND_ID_FLEX_SEGMENTS', sqlTxt, 'N', 100, 0, 'L','Y','N');

sqlTxt :=     'select *'
|| chr(10) || ' from FND_ID_FLEX_SEGMENTS_TL'
|| chr(10) || ' where ID_FLEX_NUM in ('
|| chr(10) || ' select chart_of_accounts_id'
|| chr(10) || '  from gl_code_combinations'
|| chr(10) || ' where application_id = 101'
|| chr(10) || ' and code_combination_id in ('
|| l_id_list
|| chr(10) || '))';

run_sqlpl('FND_ID_FLEX_SEGMENTS_TL', sqlTxt, 'N', 100, 0, 'L','Y','N');

sqlTxt :=     'select *'
|| chr(10) || 'from FND_FLEX_VALIDATION_QUALIFIERS'
|| chr(10) || 'where flex_value_set_id in ('
|| chr(10) || 'select a.flex_value_set_id'
|| chr(10) || ' from FND_ID_FLEX_SEGMENTS a'
|| chr(10) || ' where ID_FLEX_NUM in ('
|| chr(10) || ' select chart_of_accounts_id'
|| chr(10) || '  from gl_code_combinations'
|| chr(10) || ' where application_id = 101'
|| chr(10) || ' and code_combination_id in ('
|| l_id_list
|| chr(10) || ')))';

run_sqlpl('FND_FLEX_VALIDATION_QUALIFIERS', sqlTxt, 'N', 100, 0, 'L','Y','N');

sqlTxt :=     'select distinct v.*'
|| chr(10) || 'from FND_FLEX_VALUES v'
|| chr(10) || ', FND_ID_FLEX_SEGMENTS a'
|| chr(10) || ', gl_code_combinations g'
|| chr(10) || 'where a.flex_value_set_id = v.flex_value_set_id'
|| chr(10) || 'and a.id_flex_num = g.chart_of_accounts_id'
|| chr(10) || 'and a.application_id = 101'
|| chr(10) || 'and ((nvl(g.segment1,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT1'')'
|| chr(10) || 'or (nvl(g.segment2,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT2'')'
|| chr(10) || 'or (nvl(g.segment3,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT3'')'
|| chr(10) || 'or (nvl(g.segment4,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT4'')'
|| chr(10) || 'or (nvl(g.segment5,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT5'')'
|| chr(10) || 'or (nvl(g.segment6,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT6'')'
|| chr(10) || 'or (nvl(g.segment7,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT7'')'
|| chr(10) || 'or (nvl(g.segment8,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT8'')'
|| chr(10) || 'or (nvl(g.segment9,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT9'')'
|| chr(10) || 'or (nvl(g.segment10,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT10'')'
|| chr(10) || 'or (nvl(g.segment11,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT11'')'
|| chr(10) || 'or (nvl(g.segment12,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT12'')'
|| chr(10) || 'or (nvl(g.segment13,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT13'')'
|| chr(10) || 'or (nvl(g.segment14,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT14'')'
|| chr(10) || 'or (nvl(g.segment15,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT15'')'
|| chr(10) || 'or (nvl(g.segment16,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT16'')'
|| chr(10) || 'or (nvl(g.segment17,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT17'')'
|| chr(10) || 'or (nvl(g.segment18,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT18'')'
|| chr(10) || 'or (nvl(g.segment19,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT19'')'
|| chr(10) || 'or (nvl(g.segment20,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT20'')'
|| chr(10) || 'or (nvl(g.segment21,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT21'')'
|| chr(10) || 'or (nvl(g.segment22,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT22'')'
|| chr(10) || 'or (nvl(g.segment23,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT23'')'
|| chr(10) || 'or (nvl(g.segment24,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT24'')'
|| chr(10) || 'or (nvl(g.segment25,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT25'')'
|| chr(10) || 'or (nvl(g.segment26,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT26'')'
|| chr(10) || 'or (nvl(g.segment27,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT27'')'
|| chr(10) || 'or (nvl(g.segment28,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT28'')'
|| chr(10) || 'or (nvl(g.segment29,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT29'')'
|| chr(10) || 'or (nvl(g.segment30,''xYxYxYxY'') = v.FLEX_VALUE and a.APPLICATION_COLUMN_NAME = ''SEGMENT30''))'
|| chr(10) || 'and g.code_combination_id in ('
|| l_id_list
|| chr(10) || ')';

run_sqlpl('FND_FLEX_VALUES', sqlTxt, 'N', 100, 0, 'L','Y','N');

end if;  --if l_continue

EXCEPTION

When l_exception then

tab0print('');

when others then --exception section3

  BRPrint;
  ErrorPrint(sqlerrm ||' occurred in test');
  ActionErrorPrint('Please report the above error to Oracle Support Services.');
  BRPrint;
  Show_Footer('&v_scriptlongname', '&v_headerinfo');
  BRPrint;

end; --end3



/* -------------------- Feedback ---------------------------- */

    BRPrint;
    Show_Footer('&v_scriptlongname', '&v_headerinfo');

/* -------------------- Exception Section -------------------------- */

exception when others then --exception section 2

  BRPrint;
  ErrorPrint(sqlerrm ||' occurred in test');
  ActionErrorPrint('Please report the above error to Oracle Support Services.');
  BRPrint;
  Show_Footer('&v_scriptlongname', '&v_headerinfo');
  BRPrint;

end; --end2

exception when others then   --exceptions section 1

  BRPrint;
  ErrorPrint(sqlerrm ||' occurred in test');
  ActionErrorPrint('Please report the above error to Oracle Support Services.');
  BRPrint;
  Show_Footer('&v_scriptlongname', '&v_headerinfo');
  BRPrint;

end; -- end 1

/




REM  ==============SQL PLUS Environment setup===================

Spool off

set termout on

PROMPT 
prompt Output spooled to filename &outputfilename
prompt 
