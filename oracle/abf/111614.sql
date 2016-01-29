--Reserva
BEGIN
   DBMS_AQADM.DROP_QUEUE_TABLE( 
      queue_table        => 'b2w_bpel_aq.B2W_OM_SOL_RESERVA_AQ_TB', 
      force              => TRUE); 
END;
/
DROP TYPE B2W_BPEL_AQ.rib_tsfindesc_rec FORCE
/
CREATE OR REPLACE TYPE B2W_BPEL_AQ.rib_tsfindesc_rec AS OBJECT
  ( RIB_OID               NUMBER
  , FROM_LOC_TYPE         VARCHAR2(1)
  , FROM_LOC              NUMBER
  , TO_LOC_TYPE           VARCHAR2(1)
  , TO_LOC                VARCHAR2(150)
  , TSF_TYPE              VARCHAR2(6)
  , TSF_BIENAL_IND        VARCHAR2(1)
  , FREIGHT_CODE          VARCHAR2(1)
  , DELIVERY_DATE         DATE
  , APPROVAL_ID           VARCHAR2(30)
  , APPROVAL_DATE         DATE
  , INV_TYPE              VARCHAR2(6)
  , TSF_STATUS            VARCHAR2(1)
  , NOT_AFTER_DATE        DATE
  , REPL_TSF_APPROVE_IND  VARCHAR2(1)
  , NBTSFINDESC           B2W_BPEL_AQ.RIB_NBTSFINDESC_REC
  , TSFINADDRDESC         B2W_BPEL_AQ.RIB_TSFINADDRDESC_REC
  , TSFINCARRIERDESC      B2W_BPEL_AQ.RIB_TSFINCARRIERDESC_REC
  , TSFINDTLDESC          B2W_BPEL_AQ.RIB_TSFINDTLDESC_TBL
  )
/
GRANT EXECUTE ON B2W_BPEL_AQ.rib_tsfindesc_rec  TO apps
/
BEGIN
   dbms_aqadm.create_queue_table( queue_table        => 'b2w_bpel_aq.B2W_OM_SOL_RESERVA_AQ_TB', 
                                  multiple_consumers => FALSE, 
                                  queue_payload_type => 'B2W_BPEL_AQ.B2W_OM_SOLIC_RESERVA_TYPE', 
                                  compatible         => '10.0' );
END;
/

BEGIN
   dbms_aqadm.create_queue( queue_name => 'b2w_bpel_aq.B2W_OM_SOLIC_RESERVA_AQ', 
                            queue_table => 'b2w_bpel_aq.B2W_OM_SOL_RESERVA_AQ_TB', 
                            max_retries => 6, 
                            retry_delay => 600 );
   dbms_aqadm.start_queue('b2w_bpel_aq.B2W_OM_SOLIC_RESERVA_AQ');
END;
/
-- Picking
BEGIN
   DBMS_AQADM.DROP_QUEUE_TABLE( 
      queue_table        => 'b2w_bpel_aq.B2W_OM_RLZ_PICKING_AQ_TB', 
      force              => TRUE); 
END;
/
ALTER TYPE B2W_BPEL_AQ.B2W_OM_REALIZA_PICKING_TYPE COMPILE
/
GRANT EXECUTE ON B2W_BPEL_AQ.B2W_OM_REALIZA_PICKING_TYPE TO apps
/
BEGIN
   dbms_aqadm.create_queue_table( queue_table        => 'b2w_bpel_aq.B2W_OM_RLZ_PICKING_AQ_TB', 
                                  multiple_consumers => FALSE, 
                                  queue_payload_type => 'B2W_BPEL_AQ.B2W_OM_REALIZA_PICKING_TYPE', 
                                  compatible         => '10.0' );
END;
/

BEGIN
   dbms_aqadm.create_queue( queue_name => 'b2w_bpel_aq.B2W_OM_RLZ_PICKING_AQ', 
                            queue_table => 'b2w_bpel_aq.B2W_OM_RLZ_PICKING_AQ_TB', 
                            max_retries => 6, 
                            retry_delay => 600 );
   dbms_aqadm.start_queue('b2w_bpel_aq.B2W_OM_RLZ_PICKING_AQ');
END;
/
