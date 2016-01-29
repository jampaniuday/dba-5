
  REM 
  REM Applied_Patches_11i.sql - used to create 11i Applied_Patches_Report.txt
  REM 
   set feedback off
   set linesize 80
   set pagesize 9000
 
   column patch_name head Bug format a10
   column application_short_name head Product format a7
   column patch_type head Patch_Type format a16
   column patch_level head Patch_Level format a12
   column last_update_date head Applied format a11
   column ReportDate head ReportDate format a20
 
   prompt
   prompt 11i Applied Patches by Most Recently Applied Date
   
   SELECT sysdate ReportDate FROM dual;
   
   SELECT distinct ap.patch_name,
          decode(ab.application_short_name, null, mini.app_short_name,
          ab.application_short_name) application_short_name,
          ap.patch_type patch_type,  mini.patch_level patch_level,
          ap.last_update_date Applied
     FROM applsys.ad_bugs ab, applsys.ad_applied_patches ap,
          applsys.ad_patch_drivers pd, applsys.ad_patch_driver_minipks mini
    WHERE ab.bug_number = ap.patch_name
          and ap.applied_patch_id = pd.applied_patch_id
          and pd.patch_driver_id = mini.patch_driver_id(+)
   ORDER BY ap.last_update_date desc;
