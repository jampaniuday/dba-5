select substr(a.user_data.event_name,1,50) event,
decode(a.state,0,'0 = Ready',1, '1 = Wait',2, '2 = Processed',3, '3 = Exception',to_char(state)) State,
count(a.user_data.event_name) as count
FROM apps.wf_bpel_qtab a
group by a.state,a.user_data.event_name
order by a.user_data.event_name;
