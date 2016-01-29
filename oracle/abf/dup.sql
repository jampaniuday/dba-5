col user_concurrent_program_name format a80
col argument_text format a25
col user_name format a20
select p.user_concurrent_program_name, fu.user_name, argument_text, count(*)
from fnd_concurrent_requests r, fnd_concurrent_programs_tl p, fnd_user fu
where r.concurrent_program_id = p.concurrent_program_id
and  r.requested_by = fu.user_id
and requested_start_date> sysdate - 1
and phase_code='P'
and hold_flag = 'N'
and p.language ='US'
and r.resubmit_interval is null
having count(*) >1
group by p.user_concurrent_program_name, fu.user_name, argument_text
order by 4 desc;
