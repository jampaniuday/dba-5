set serveroutput on
set feedback off
set verify off
set heading off
set timing off



declare

req_id          number(15) := &1;

function  get_status(p_status_code varchar2) return varchar2 as

c_status        fnd_lookups.meaning%TYPE;

begin


        select nvl(meaning, 'UNKNOWN')
           into c_status
           from fnd_lookups
           where lookup_type = 'CP_STATUS_CODE'
           and lookup_code = p_status_code;

        return rtrim(c_status);

end get_status;



function  get_phase(p_phase_code varchar2) return varchar2 as

c_phase         fnd_lookups.meaning%TYPE;

begin

        select nvl(meaning, 'UNKNOWN')
           into c_phase
           from fnd_lookups
           where lookup_type = 'CP_PHASE_CODE'
           and lookup_code = p_phase_code;

        return rtrim(c_phase);

end get_phase;

procedure prt(msg varchar2) as
begin
  dbms_output.put_line(msg);
end prt;

procedure prtval(prompt varchar2, val varchar2) as
p    varchar2(240);
begin
  p := prompt || ':';
  prt(rpad(p, 26) || val  );
end prtval;

procedure blankline as
begin
  dbms_output.put(chr(10));
end blankline;



procedure request_info(p_req_id number) as

  reqinfo         fnd_conc_requests_form_v%ROWTYPE;
  proginfo        fnd_concurrent_programs%ROWTYPE;
  buffer          varchar2(240);
  i               number;
  nargs           number;
  sql_stmt        varchar2(100);
  cnt             number;

  REQ_NOTFOUND    exception;
  sep             varchar2(200) := '------------------------------------------------------';

  cursor ppinfo is
    select *
      from fnd_conc_pp_actions
      where concurrent_request_id = p_req_id
      order by action_type, sequence;

begin

  begin
      select *
      into   reqinfo
      from   fnd_conc_requests_form_v
      where  request_id = p_req_id;
  exception
    when no_data_found then
      raise REQ_NOTFOUND;
  end;

  blankline();
  prt(sep);
  prt('Information for request ' ||p_req_id);
  prt(sep);
  blankline();

  prt('General Info');
  prt(sep);

  prtval('Name', reqinfo.program);
  prtval('Phase', get_phase(reqinfo.phase_code)
                                 || ' (' || reqinfo.phase_code || ')');
  prtval('Status', get_status(reqinfo.status_code)
                                  || ' (' || reqinfo.status_code || ')');
  prtval('Submitted on', to_char(reqinfo.request_date, 'DD-MON-RR HH24:MI:SS'));
  prtval('Submitted by', reqinfo.requestor);

  begin
    select responsibility_name
        into   buffer
        from   fnd_responsibility_vl
        where  responsibility_id = reqinfo.responsibility_id
        and    application_id = reqinfo.responsibility_application_id;
  exception
    when no_data_found then
      buffer := '** UNKNOWN **';
  end;

  prtval('Using responsibility', buffer);
  prtval('NLS Language', reqinfo.nls_language);
  prtval('NLS Territory', reqinfo.nls_territory);
  prtval('Requested start date', to_char(reqinfo.requested_start_date, 'DD-MON-RR HH24:MI:SS'));
  prtval('Actual start date', to_char(reqinfo.actual_start_date, 'DD-MON-RR HH24:MI:SS'));
  prtval('Actual completion date', to_char(reqinfo.actual_completion_date, 'DD-MON-RR HH24:MI:SS'));
  prtval('Completion text', '"' || reqinfo.completion_text || '"');
  prtval('Priority', reqinfo.priority);
  prtval('Logfile name', reqinfo.logfile_name);
  prtval('Logfile node', reqinfo.logfile_node_name);
  prtval('Logfile size', reqinfo.lfile_size);
  prtval('Output file name', reqinfo.outfile_name);
  prtval('Output file node', reqinfo.outfile_node_name);
  prtval('Output file size', reqinfo.ofile_size);


  blankline();
  prt('Flags:');
  prt(sep);


  prtval('Hold flag', reqinfo.hold_flag);
  prtval('Single thread', reqinfo.single_thread_flag);
  prtval('Queue control flag', reqinfo.queue_control_flag);
  prtval('Has sub request', reqinfo.has_sub_request);
  prtval('Is sub request', reqinfo.is_sub_request);
  prtval('Implicit code', reqinfo.implicit_code);
  prtval('Update protected', reqinfo.update_protected);
  prtval('Queue method code', reqinfo.queue_method_code);
  prtval('Argument input method', reqinfo.argument_input_method_code);
  prtval('Save output flag', reqinfo.save_output_flag);
  prtval('NLS compliant', reqinfo.nls_compliant);
  prtval('Increment dates', reqinfo.increment_dates);
  prtval('Restart', reqinfo.restart);
  prtval('SQL trace', reqinfo.enable_trace);




  blankline();
  prt('Program info:');
  prt(sep);

  select *
        into proginfo
        from fnd_concurrent_programs
        where concurrent_program_id = reqinfo.concurrent_program_id
        and application_id = reqinfo.program_application_id;

  prtval('Program name', proginfo.concurrent_program_name || ' (' || reqinfo.concurrent_program_id || ')');
  prtval('Application', reqinfo.application_name);

  begin
    select meaning
      into buffer
      from fnd_lookups
      where lookup_type = 'CP_EXECUTION_METHOD_CODE'
      and lookup_code = proginfo.execution_method_code;
  exception
    when no_data_found then
      buffer := '** UNKNOWN **';
  end;

  prtval('Program type', buffer);

  begin
    select user_executable_name
      into buffer
      from fnd_executables_vl
      where executable_id = proginfo.executable_id
      and application_id = proginfo.executable_application_id;
  exception
    when no_data_found then
      buffer := '** UNKNOWN **';
  end;

  prtval('Executable name', buffer);

  if proginfo.execution_method_code = 'S' then
    begin
      select subroutine_name
        into buffer
        from fnd_executables
        where executable_id = proginfo.executable_id
        and application_id = proginfo.executable_application_id;
    exception
      when no_data_found then
        buffer := '** UNKNOWN **';
    end;
      prtval('Subroutine name', buffer);

  elsif  proginfo.execution_method_code = 'K' then
    begin
      select execution_file_path || '.' || execution_file_name
        into buffer
        from fnd_executables
        where executable_id = proginfo.executable_id
        and application_id = proginfo.executable_application_id;
    exception
      when no_data_found then
        buffer := '** UNKNOWN **';
    end;
      prtval('Class name', buffer);

  else
    begin
      select execution_file_name
        into buffer
        from fnd_executables
        where executable_id = proginfo.executable_id
        and application_id = proginfo.executable_application_id;
    exception
      when no_data_found then
        buffer := '** UNKNOWN **';
    end;
    prtval('Executable file', buffer);

  end if;

  prtval('Output file type', proginfo.output_file_type);




  blankline();
  prt('Parameters:');
  prt(sep);

  prtval('Number of parameters', reqinfo.number_of_arguments);

  nargs := 25;
  if reqinfo.number_of_arguments < 25 then
    nargs := reqinfo.number_of_arguments;
  end if;

  for i in 1 .. nargs loop

    sql_stmt := 'select argument' || i || ' from fnd_concurrent_requests where request_id = :id';
    execute immediate sql_stmt into buffer using p_req_id;

    prtval('Parameter ' || i, buffer);
  end loop;


  if reqinfo.number_of_arguments > 25 then

    for i in 26 .. reqinfo.number_of_arguments loop
      sql_stmt := 'select argument' || i || ' from fnd_conc_request_arguments where request_id = :id';
      execute immediate sql_stmt into buffer using p_req_id;

      prtval('Parameter ' || i, buffer);
  end loop;
  end if;




  blankline();
  prt('Post-processing actions:');
  prt(sep);

  cnt := 1;
  for ppreq in ppinfo loop
    if ppreq.action_type = 1 then
      prt(cnt || ') Print ' || ppreq.number_of_copies || ' copies to printer: ' || ppreq.arguments);
      prtval('Using print style', reqinfo.print_style);

      begin
        select printer_driver
          into buffer
          from fnd_printer fp,
          fnd_printer_information fpi
          where fp.printer_name = ppreq.arguments
          and fp.printer_type = fpi.printer_type
          and fpi.printer_style = reqinfo.print_style;
      exception
        when no_data_found then
        buffer := '** UNKNOWN **';
      end;
      prtval('Using print driver', buffer);

    elsif ppreq.action_type = 2 or ppreq.action_type = 3 then
      prt(cnt || ') Send notification to: ' || ppreq.arguments);
      prtval('Workflow source', ppreq.orig_system);

    elsif ppreq.action_type = 4 then
      prt('Executing PLSQL executable id ' || ppreq.program_id || ' (Application id '
           || ppreq.program_application_id || ')');
      begin
        select execution_file_name
          into buffer
          from fnd_executables
          where executable_id = ppreq.program_id
          and application_id = ppreq.program_application_id;
      exception
        when no_data_found then
        buffer := '** UNKNOWN **';
      end;
      prtval('Procedure name', buffer);

    else
      prt('** Unknown post-processing action type: ' || ppreq.action_type || ' **');
    end if;

    prtval('Perform on success', ppreq.status_s_flag);
    prtval('Perform on warning', ppreq.status_w_flag);
    prtval('Perform on failure', ppreq.status_f_flag);
    prtval('Completed', ppreq.completed);
    cnt := cnt + 1;
    blankline();

  end loop;

  if cnt < 2 then
    prt('No post-processing actions found.');
  end if;

  blankline();
  prt(sep);
  blankline();

  exception
        when REQ_NOTFOUND then
            prt('Request '||p_req_id||' not found.');
        when others then
            prt('Error number ' || sqlcode || ' has occurred.');
            prt('Cause: ' || sqlerrm);

end request_info;





begin

  dbms_output.enable(20000);
  request_info(req_id);

end;
/
