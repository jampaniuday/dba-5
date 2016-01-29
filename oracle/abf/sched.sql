SELECT distinct r.request_id
, CASE
WHEN pt.user_concurrent_program_name = 'Report Set'
THEN DECODE(
r.description
, NULL, pt.user_concurrent_program_name
, r.description
|| ' ('
|| pt.user_concurrent_program_name
|| ')'
)
ELSE pt.user_concurrent_program_name
END program_name
, u.user_name requestor
, nvl(to_char(r.org_id),'Null') ORG_ID
, u.description requestor_description
, u.email_address
, frt.responsibility_name responsibility
, r.request_date
, r.requested_start_date
, DECODE(
r.hold_flag
, 'Y', 'Yes'
, 'N', 'No'
) on_hold
, CASE
WHEN r.hold_flag = 'Y'
THEN SUBSTR(
u2.description
, 0
, 40
)
END last_update_by
, CASE
WHEN r.hold_flag = 'Y'
THEN r.last_update_date
END last_update_date
, r.argument_text PARAMETERS
, NVL2(
r.resubmit_interval
, 'Periodically'
, NVL2(
r.release_class_id
, 'On specific days'
, 'Once'
)
) AS schedule_type
, r.resubmit_interval resubmit_every
, r.resubmit_interval_unit_code resubmit_time_period
, DECODE(
r.resubmit_interval_type_code
, 'START', 'From the start of the prior run'
, 'END', 'From the Completion of the prior run'
) apply_the_update_option
, r.increment_dates
, TO_CHAR((r.requested_start_date), 'DD/MM/YYYY HH24:MI:SS') start_time
, TO_CHAR((r.resubmit_end_date), 'DD/MM/YYYY HH24:MI:SS') resubmit_end_date
FROM applsys.fnd_concurrent_programs_tl pt
, applsys.fnd_concurrent_programs pb
, applsys.fnd_user u
, applsys.fnd_user u2
, applsys.fnd_printer_styles_tl s
, applsys.fnd_concurrent_requests r
, applsys.fnd_responsibility_tl frt
WHERE pb.application_id = r.program_application_id
AND pb.concurrent_program_id = r.concurrent_program_id
AND pb.application_id = pt.application_id
AND r.responsibility_id = frt.responsibility_id
AND pb.concurrent_program_id = pt.concurrent_program_id
AND u.user_id = r.requested_by
AND u2.user_id = r.last_updated_by
AND s.printer_style_name(+) = r.print_style
AND r.phase_code = 'P'
AND r.status_code in ('I','F','Q')
AND r.requested_start_date > sysdate
AND pt.LANGUAGE = 'US'
AND r.hold_flag = 'N'
AND frt.LANGUAGE = 'US'
AND r.resubmit_interval is not null
AND 1 = 1
order by program_name;
