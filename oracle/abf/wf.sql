Declare
         cursor c_item_keys is
         select act.item_type , act.item_key
              from wf_item_activity_statuses act
             ,wf_notifications n
             ,wf_items itm
             where act.notification_id = n.notification_id
             and act.item_type = itm.item_type
             and act.item_key = itm.item_key
             and itm.end_date is null
             --and act.item_type = 'WFERROR' -- value returned in step 1
             --and act.activity_status in ('ERROR','NOTIFIED')
             --and n.status = 'OPEN' 
             and act.assigned_user = 'SYSADMIN';

             counter number;  

  Begin
    counter := 1 ;
    for item in c_item_keys loop 
         wf_engine.abortprocess(item.item_type,item.item_key); 
         counter := counter + 1 ; 
         if counter > 1000 then 
                counter := 1 ;
                commit; 
         end if;
     end loop;
     commit;
End;
