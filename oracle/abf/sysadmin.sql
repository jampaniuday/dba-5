select substr(tl.user_concurrent_program_name,1,50) conc_name,
substr(u.user_name,1,10) usuario,
r.request_id
from fnd_concurrent_Requests r,
fnd_concurrent_programs_tl tl,
fnd_user u
where tl.language = 'PTB'
and r.concurrent_program_id = tl.concurrent_program_id
and r.requested_by = u.user_id
and r.phase_code = 'P'
and r.requested_by = 0;
