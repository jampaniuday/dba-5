begin
  
  -- limpa tabela de carga
  delete from b2w.b2w_carga_gap435;
  
  -- insere novos templates na tabela de carga
  insert into b2w.b2w_carga_gap435 values ('Envio de Nfe','OM-1278','NOTA_GERADA','ACOM','D','VDA','','','','','','','','','','','','N');
  insert into b2w.b2w_carga_gap435 values ('Recebemos seu pedido','OM-1060','AGUARDANDO_RESERVA','ACOM','O','VDA','','','','','','','','','','','','N');
  insert into b2w.b2w_carga_gap435 values ('Expedição da entrega (com data ajustada de entrega)','OM-1011','SEC','ACOM','D','VDA','','','','','','','','','','','','N');
  insert into b2w.b2w_carga_gap435 values ('Confirmação do pedido','OM-1055','REALIZA_PICKING_RMS','ACOM','D','VDA','','','','','','','','','','','','N');

  -- carrega os templates da tabela de carga nas tabelas utilizadas pelo programa de email
  apps.b2w_om_config_email_pkg.efetua_config;
  
  commit;
  
end;
