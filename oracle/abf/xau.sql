update fnd_concurrent_requests
set phase_code = 'C', status_code = 'T', completion_text = 'AUTORIZADO PELO TIME FUNCIONAL'
where concurrent_program_id = 20393;
commit;
