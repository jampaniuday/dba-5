DECLARE
   fnd DBMS_AQADM.aq$_purge_options_t;
BEGIN
   fnd.block := TRUE;
   DBMS_AQADM.PURGE_QUEUE_TABLE(queue_table     => 'apps.wf_bpel_qtab',
                                purge_condition => 'qtview.user_data.event_name = ''oracle.apps.abril.anglo.ar.titulos.merge''',
                                purge_options   => fnd);
END;
