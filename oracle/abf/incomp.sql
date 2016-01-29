set serveroutput on size 1000000
declare
x number;
y number;
cursor CONCS_RODANDO is 
SELECT a.program_short_name, a.request_id
FROM apps.fnd_conc_req_summary_v a, 
     apps.fnd_concurrent_programs_vl b, 
     apps.fnd_concurrent_worker_requests c, 
     apps.fnd_executables execname 
WHERE a.program_short_name = b.concurrent_program_name 
 AND a.request_id = c.request_id 
 AND a.phase_code = 'R' 
 AND a.status_code = 'R' 
 AND a.concurrent_program_id = b.concurrent_program_id 
 AND a.program_application_id = b.application_id 
 AND b.application_id = execname.application_id 
 AND b.executable_id=execname.executable_id;

cursor CONCS_INCOMPATIVEIS(ls_conc IN fnd_concurrent_programs_vl.concurrent_program_name%TYPE) is 
  SELECT 
      e.concurrent_program_name 
  FROM 
      fnd_concurrent_program_serial d, 
      fnd_concurrent_programs e 
  WHERE 
      d.running_concurrent_program_id IN 
      ( 
              SELECT concurrent_program_id 
              FROM fnd_concurrent_programs 
              WHERE concurrent_program_name = ls_conc
      ) 
  AND d.to_run_concurrent_program_id = e.concurrent_program_id;

begin
  for x in CONCS_RODANDO loop
  dbms_output.put_line('================================================================');
  dbms_output.put_line('Request ID: '|| x.request_id ||'  '||'Short Name: '|| x.program_short_name );
  dbms_output.put_line('Concurrents Incompativeis:');
  dbms_output.put_line('--------------------------');
    for y in CONCS_INCOMPATIVEIS (x.program_short_name) loop 
      dbms_output.put_line(y.concurrent_program_name);   
    end loop;
  end loop; 
end; 
/
