col evento for a50
select a.user_data.event_name evento,count(a.user_data.event_name) as count
    FROM   apps.wf_bpel_qtab a
    group by a.user_data.event_name;
select a.user_data.event_name evento,count(a.user_data.event_name) as count
    FROM   apps.XRTARREALCUST_BPEL_QTAB a
   group by a.user_data.event_name;
