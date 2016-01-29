set timi on feed on
select instance_name,host_name,to_char(sysdate,'dd/mm/yy hh24:mi') from v$instance;
exec dbms_application_info.set_module('RESYNC ICX','RESYNC ICX');
exec ad_ctx_ddl.sync_index(IDX_NAME => 'ICX.ICX_CAT_ITEMSCTXDESC_HDRS');
EXECUTE ad_ctx_ddl.optimize_index( idx_name =>  'ICX.ICX_CAT_ITEMSCTXDESC_HDRS', optlevel => 'FULL');
select instance_name,host_name,to_char(sysdate,'dd/mm/yy hh24:mi') from v$instance;
