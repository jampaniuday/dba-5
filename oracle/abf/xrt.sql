set lines 200 pages 50 feed on
prompt WF_BPEL_QTAB
select substr(a.user_data.event_name,1,50) event,count(a.user_data.event_name) as count
    FROM   apps.wf_bpel_qtab a
    group by a.user_data.event_name;
prompt XRT
select substr(a.user_data.event_name,1,50) event,count(a.user_data.event_name) as count
    FROM   apps.XRTARREALCUST_BPEL_QTAB a
   group by a.user_data.event_name;
