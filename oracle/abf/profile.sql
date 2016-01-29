set lines 300;
set pages 100;

col profile_option_value format a25
col user_profile_option_name format a25
col Level format a14
select user_profile_option_name,
decode(level_id,10001,'Site',
10002,'Application',
10003,'Responsibility',
10004,'User',
10005,'Server',
10006,'Organization',
10007, 'ServResp',
level_id) "Level",
profile_option_value,
level_value
from
fnd_profile_option_values,
fnd_profile_options_vl
where (upper(user_profile_option_name) like upper('%DEBUG%ENAB%')
OR upper(user_profile_option_name) like upper('%DEBUG%TRAC%')
OR upper(user_profile_option_name) like upper('%DIAG%'))
AND fnd_profile_option_values.profile_option_id = fnd_profile_options_vl.profile_option_id;
