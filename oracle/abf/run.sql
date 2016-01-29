Select Concurrent_Queue_Name Manager,
       Request_Id Request, parent_request_id parent, substr(fcr.oracle_process_id,1,10) SPID, substr(fu.user_name,1,20) usuario,
       substr(Concurrent_Program_Name,1,25) Program, substr(fcr.description,1,20) DESCRIPTION, Run_Alone_Flag,
       To_Char(Actual_Start_Date, 'DD- MON-YY HH24:MI') Started
  from Fnd_Concurrent_Queues Fcq, Fnd_Concurrent_Requests Fcr,
       Fnd_Concurrent_Programs Fcp, Fnd_User Fu, Fnd_Concurrent_Processes Fpro
 where
       Phase_Code = 'R' And
       concurrent_program_name in('CVRDPREOPENRI') or
       
       Fcr.Controlling_Manager = Concurrent_Process_Id       And
      (Fcq.Concurrent_Queue_Id = Fpro.Concurrent_Queue_Id    And
       Fcq.Application_Id      = Fpro.Queue_Application_Id ) And
       (Fcr.Concurrent_Program_Id = Fcp.Concurrent_Program_Id And
       Fcr.Program_Application_Id = Fcp.Application_Id )     And
       Fcr.Requested_By = User_Id
order by actual_start_date desc;
