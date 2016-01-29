CREATE OR REPLACE PACKAGE APPS.b2w_om_real_picking_pkg IS
   -- +=================================================================+
   -- |          Copyright (c) 2010 F2C, Rio de Janeiro, Brasil         |
   -- |                       All rights reserved.                      |
   -- +=================================================================+
   -- | FILENAME                                                        |
   -- |   B2W_OM_REAL_PICKING_PKG_S.pls                                 |
   -- |                                                                 |
   -- | PURPOSE                                                         |
   -- |   Scritp de criacao da package B2W_OM_REAL_PICKING_PKG          |
   -- |                                                                 |
   -- | DESCRIPTION                                                     |
   -- |   Popular o TYPE B2W_BPEL_AQ.B2W_OM_REALIZA_PICKING_TYPE e      |
   -- |   enviar para BPEL                                              |
   -- |   Receber as informações do BPEL e confirmar o picking.         |
   -- |                                                                 |
   -- | [PARAMETERS]                                                    |
   -- |                                                                 |
   -- | CREATED BY                                                      |
   -- |   Guilherme Nasser Carvalhal                       21/05/2010   |
   -- |                                                                 |
   -- | Altered By                                                      |
   -- |   Alessandro Chaves - F2C                          16/12/2010   |
   -- |    Inclusao do numero da regiao oriundo do OTM para que o       |
   -- |    picking possa ser realizado, contemplando o mesmo.           |
   -- +=================================================================+
   --
   PROCEDURE b2w_om_real_picking_p
           ( p_ship_set_id IN oe_order_lines_all.ship_set_id%TYPE
           , p_header_id   IN oe_order_lines_all.header_id%TYPE );

   PROCEDURE b2w_om_resp_picking_p
           ( p_status_code   IN VARCHAR2
           , p_error_message IN VARCHAR2
           , p_stk_available IN b2w_bpel_aq.rib_tsfinstkavail_rec );

END b2w_om_real_picking_pkg;
/
CREATE OR REPLACE PACKAGE BODY APPS.b2w_om_real_picking_pkg IS
   -- +=====================================================================+
   -- |          Copyright (c) 2010 F2C, Rio de Janeiro, Brasil             |
   -- |                       All rights reserved.                          |
   -- +=====================================================================+
   -- | FILENAME                                                            |
   -- |   B2W_OM_REAL_PICKING_PKG_B.pls                                     |
   -- |                                                                     |
   -- | PURPOSE                                                             |
   -- |   Scritp de criacao da package B2W_OM_REAL_PICKING_PKG              |
   -- |                                                                     |
   -- | DESCRIPTION                                                         |
   -- |   Popular o TYPE B2W_BPEL_AQ.B2W_OM_REALIZA_PICKING_TYPE e          |
   -- |   enviar para BPEL                                                  |
   -- |   Receber as informações do BPEL e confirmar o picking.             |
   -- |                                                                     |
   -- | [PARAMETERS]                                                        |
   -- |                                                                     |
   -- | CREATED BY                                                          |
   -- |   Guilherme Nasser Carvalhal                       21/05/2010       |
   -- |                                                                     |
   -- | Altered By                                                          |
   -- |   Alessandro Chaves - F2C                          16/12/2010       |
   -- |    Inclusao do numero da regiao oriundo do OTM para que o           |
   -- |    picking possa ser realizado, contemplando o mesmo.               |
   -- |                                                                     |
   -- |   TCosta                                           17/12/2010       |
   -- |    Implementada funcionalidades para o processo de Vale Fisico.     |
   -- |    Reestruturada a busca de informções  de "select into" para       |
   -- |    o cursor c_infs, para evitar criação de muitas variáveis.        |
   -- |                                                                     |
   -- |  Autor : Sergio Junior da Costa (CADMUS)                            |
   -- |   Data  : 25/07/2011                                                |
   -- |   Motivo: Validar se o produto se encontra disponível, se caso o    |
   -- |   produto esteja indisponível atualizar o status para aguaradando   |
   -- |   Disponibilidade das tabelas oe_order_lines_all e                  |
   -- |   wdd.released_status da procedure b2w_om_resp_picking_p .          |
   -- +=====================================================================+
   --




   PROCEDURE b2w_om_real_picking_p
           ( p_ship_set_id IN oe_order_lines_all.ship_set_id%TYPE
           , p_header_id   IN oe_order_lines_all.header_id%TYPE )
   IS
      l_process_name                  VARCHAR2(200) := 'B2W_OM_REAL_PICKING_PKG.B2W_OM_REAL_PICKING_P';
      l_b2w_om_realiza_picking_type   b2w_bpel_aq.b2w_om_realiza_picking_type;
      l_rib_tsfindesc_rec             b2w_bpel_aq.rib_tsfindesc_rec;
      l_rib_nbtsfindesc_rec           b2w_bpel_aq.rib_nbtsfindesc_rec;
      l_rib_tsfincarrierdesc_rec      b2w_bpel_aq.rib_tsfincarrierdesc_rec;
      --
      l_msg_error                     VARCHAR2(4000);
      l_message_type                  VARCHAR2(20) := 'tsfinmod';
      --
      l_bloqueio_faturamento          NUMBER;
      l_disponibilidade               NUMBER := 0;
      l_postal_code                   ra_addresses_all.postal_code%TYPE;

      /*Ini TCosta 17/12/2010 comentado (variaveis não serão mais necessárias pois foi implementado fetch do cursor c_infs)
      l_attribute2                    oe_order_headers_all.attribute2%TYPE;
      l_sales_channel_code            oe_order_headers_all.sales_channel_code%TYPE;
      l_orig_sys_document_ref         oe_order_headers_all.orig_sys_document_ref%TYPE;
      l_set_name                      oe_sets.set_name%TYPE;
      l_attribute1                    oe_order_lines_all.attribute1%TYPE;
      l_prioridade                    VARCHAR2(1);
      l_pay_in_advanced               VARCHAR2(1);
      l_exchange_ind                  VARCHAR2(1);
      l_carrier                       wsh_new_deliveries.attribute2%TYPE;
      l_awb                           wsh_new_deliveries.attribute7%TYPE;
      l_hub                           wsh_new_deliveries.attribute8%TYPE;
      l_carrier_pickup_dt             wsh_new_deliveries.attribute5%TYPE;
      l_carrier_delivery_dt           wsh_new_deliveries.attribute6%TYPE;
      l_rota                          wsh_new_deliveries.attribute9%TYPE;
      l_hora_corte                    wsh_new_deliveries.attribute10%TYPE;

      l_promise_date                  oe_order_lines_all.promise_date%TYPE;
      l_mega_rota_orig                VARCHAR2(150);
      l_mega_rota_ship                VARCHAR2(150);
      l_contract_orig                 VARCHAR2(150);
      l_contract_ship                 VARCHAR2(150);
      Fim TCosta 17/12/2010 comentado
      */

      --Ini TCosta 17/12/2010 (Type Vale Fisico)
      l_type_valfis                   b2w_bpel_aq.insertVoucherOrderRequest;
      l_order_rec                      b2w_bpel_aq.order_rec;
      l_customer_rec                    b2w_bpel_aq.customer_rec;
      l_phone_tbl                        b2w_bpel_aq.phone_tbl:= b2w_bpel_aq.phone_tbl();
      l_orderLine_tbl                   b2w_bpel_aq.orderLine_tbl:= b2w_bpel_aq.orderLine_tbl();
      l_delivery_rec                    b2w_bpel_aq.delivery_rec;
      l_Address_rec                      b2w_bpel_aq.Address_rec;
      l_carrier_rec                      b2w_bpel_aq.carrier_rec;
      --Fim TCosta 17/12/2010 (Type Vale Fisico)

      e_erro                          EXCEPTION;
      e_next                          EXCEPTION;
      e_notfound                      EXCEPTION;
      e_indisp                        EXCEPTION;

      --Ini TCosta 17/12/2010 (Implementado o Cursor abaixo em troca do select into)
      cursor c_infs is
        select ooha.attribute1                                                           ooha_attribute1
             , ooha.attribute2                                                           ooha_attribute2
             , ooha.attribute3                                                           ooha_attribute3
             , ooha.attribute4                                                           ooha_attribute4
             , oola.attribute1                                                           oola_attribute1             -- FROM_LOC
             , ooha.ordered_date                                                         ordered_date
             , ooha.sales_channel_code                                                   sales_channel_code
             , ooha.orig_sys_document_ref                                                orig_sys_document_ref
             , os.set_name                                                               set_name
             , decode(oola.shipment_priority_code,
                       'NORMAL','N',   'GARANTIDA','G',
                       'URGENTE','U',  'EXPRESSA','E')                                   prioridade             -- SITE_ORDER_TYPE
             , decode(oola.attribute15,  'CAN','Y',  'CAC','Y',  'N')                    pay_in_advanced        -- PAY_IND_ADVANCED
             , decode(otta.attribute6, 'TRO','Y', 'N')                                   exchange_ind           -- EXCHANGE_ID
             , promise_date                                                              promise_date
             , wnd.tp_attribute4                                                         wnd_tp_attribute4      --Valor final do frete
             , wnd.tp_attribute5                                                         wnd_tp_attribute5
             , nvl(wnd.tp_attribute1, wnd.attribute1)                                    carrier_name
             , nvl(wnd.tp_attribute2, wnd.attribute2)                                    carrier                --cnpj
             , nvl(wnd.tp_attribute7, wnd.attribute7)                                    awb                    --AWB
             , nvl(wnd.tp_attribute8, wnd.attribute8)                                    hub
             , to_date(nvl(wnd.tp_attribute5, wnd.attribute5), 'YYYY-MM-DD HH24:MI:SS')  carrier_pickup_dt
             , to_date(nvl(wnd.tp_attribute6, wnd.attribute6), 'YYYY-MM-DD HH24:MI:SS')  carrier_delivery_dt    --Data Limite de Expedição
             , nvl(wnd.tp_attribute9, wnd.attribute9)                                    rota                   --rota
             , nvl(wnd.tp_attribute11, wnd.attribute11)                                  mega_rota_orig
             , nvl(wnd.tp_attribute11, wnd.attribute11)                                  mega_rota_ship
             , to_char(to_date(nvl(wnd.tp_attribute10, wnd.attribute10)
                       ,'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')               hora_corte
             , nvl(opa.attribute3, 'GERAL')                                              contract_orig
             , nvl(opa.attribute3, 'GERAL')                                              contract_ship
             , wnd.volume                                                                volume
             , otta.attribute12                                                          vale_fisico
             , oola.orig_sys_line_ref                                                    orig_sys_line_ref
             , oola.ordered_item                                                         ordered_item

             , (select ffvv.description
                  from apps.fnd_flex_value_sets ffvs,
                       apps.fnd_flex_values_vl  ffvv
                 where ffvs.flex_value_set_name             = 'B2W_GL_MARCA'
                   and ffvs.flex_value_set_id               = ffvv.flex_value_set_id
                   and nvl(ffvv.enabled_flag,'Y')           = 'Y'
                   and ffvv.flex_value_meaning              = ooha.attribute1
                   and nvl(ffvv.start_date_active,sysdate) <= sysdate
                   and nvl(ffvv.end_date_active,sysdate)   >= sysdate)                   brand_info

             , (select ffvt.description
                  from apps.fnd_flex_value_sets ffvs,
                       apps.fnd_flex_values_tl  ffvt,
                       apps.fnd_flex_values     ffv
                 where ffvt.language            = userenv('LANG')
                   and ffvt.flex_value_id       = ffv.flex_value_id
                   and ffv.flex_value_set_id    = ffvs.flex_value_set_id
                   and ffvs.flex_value_set_name in ('B2W_GL_UN_NEGOCIO')
                   and ffv.flex_value           = ooha.attribute4)                       unidade_negocio

             , bef.attribute10                                                           cod_filial
             , ooha.sold_to_org_id                                                       customer_id
             , raa.orig_system_reference                                                 raa_orig_system_reference
             , raa.country                                                               country
             , raa.address_id                                                            address_id
             , trim(raa.Address1||', '||raa.Address4||' '||raa.Province)                 Endereco
             , raa.Address1                                                              Address1
             , raa.Address4                                                              Address4
             , raa.Province                                                              Province

             , (select distinct attribute5
                  from hz_locations
                 where location_id = raa.party_location_id)                              hl_attribute5

             , hca.sales_channel_code                                                    hca_sales_channel_code
             , raa.creation_date                                                         raa_creation_date
             , trim(raa.address2)                                                        bairro
             , raa.city                                                                  city
             , raa.state                                                                 state
             , lpad(replace(raa.postal_code, '-', ''), 8, 0)                             postal_code
             , raa.country                                                               cust_country_id

             , (select max(hcp.email_address)
                  from hz_contact_points hcp
                 where hcp.owner_table_id     = raa.party_id
                   and hcp.contact_point_type = 'EMAIL')                                 email

             , decode(raa.global_attribute2, '2', 'PJ', '1', 'PF')                       customer_type

             , raa.global_attribute3
               || raa.global_attribute4
               || raa.global_attribute5                                                  customer_cpfj

             , hp.party_name                                                             customer_name
             , hca.orig_system_reference                                                 hca_orig_system_reference


             , (select max(hcp.phone_country_code||hcp.phone_area_code||hcp.phone_number)
                  from apps.hz_contact_points hcp
                 where raa.party_site_id       = hcp.owner_table_id
                   and hcp.contact_point_type  = 'PHONE')                                telefone

           --, ottt.name                                                                 tl_type_name
             , bef.attribute35                                                           bef_attribute35
             , oola.line_id                                                              line_id
             , bef.attribute45                                                           num_regiao  --Numero Regiao: Alessandro Chaves - F2C  16/12/2010

           from oe_order_headers_all     ooha
              , oe_sets                  os
              , oe_order_lines_all       oola
              , oe_transaction_types_all otta
              , wsh_delivery_details     wdd
              , wsh_delivery_assignments wda
              , wsh_new_deliveries       wnd
              , oe_price_adjustments     opa
              , b2w_extended_flexfields  bef
              , ra_addresses_all         raa         --ship
              , hz_cust_site_uses_all    hcsua       --ship
              , hz_parties               hp          --ship
              , hz_cust_accounts         hca

          where ooha.header_id             = os.header_id
            and ooha.header_id             = oola.header_id
            and oola.line_type_id          = otta.transaction_type_id
            and oola.header_id             = wdd.source_header_id
            and oola.line_id               = wdd.source_line_id
            and wdd.delivery_detail_id     = wda.delivery_detail_id
            and wnd.delivery_id            = wda.delivery_id
            and otta.context               = 'LINE'
            and opa.line_id                = oola.line_id
            and opa.header_id              = oola.header_id
            and oola.ship_set_id           = os.set_id
            and opa.list_line_type_code    = 'FREIGHT_CHARGE'
            and opa.charge_type_code       = 'FREIGHT'
            and oola.flow_status_code not in ('CANCELLED','HOLD_GARANTIA')
            and os.set_id                  = p_ship_set_id
            and ooha.header_id             = p_header_id

            and bef.related_table_name (+) = 'OE_ORDER_LINES_ALL'
            and bef.related_line_id    (+) = to_char(oola.line_id)
            and hcsua.site_use_id          = ooha.ship_to_org_id
            and raa.address_id             = hcsua.cust_acct_site_id
            and raa.party_id               = hp.party_id
            and hca.cust_account_id        = raa.customer_id
            and rownum                     = 1;

      r_infs   c_infs%rowtype;
      --Fim TCosta 17/12/2010

   BEGIN
      --
      -- Verifica Hold de Bloqueio de Faturamento
      --
      select count(*)
        into l_bloqueio_faturamento
        from ont.oe_order_holds_all  oh
           , ont.oe_hold_sources_all hs
           , ont.oe_hold_definitions hd
       where hs.hold_source_id = oh.hold_source_id
         and hd.hold_id        = hs.hold_id
         and oh.released_flag  = 'N'
         and oh.header_id      = p_header_id
         and oh.line_id in ( select l.line_id
                               from ont.oe_order_lines_all l
                              where l.ship_set_id = p_ship_set_id
                                AND l.flow_status_code NOT IN ('CANCELLED','CLOSED') )
         and hd.name           = 'BLOQUEIO DE FATURAMENTO';
      --
      IF( l_bloqueio_faturamento > 0 )
      THEN
         l_msg_error := 'O Picking da entrega não foi efetuado pois se encontra em hold BLOQUEIO DE FATURAMENTO.';
         --
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p
                                     ( p_set_id        => p_ship_set_id
                                     , p_line_id       => NULL
                                     , p_processo      => l_process_name
                                     , p_erro          => l_msg_error
                                     , p_creation_date => SYSDATE );
         --
         RAISE e_next;
      END IF;
      /*******BACKORDER******/

      --
      -- Atualiza para AGUARDANDO_DISPONIBILIDADE (Backorder) todas as linhas com itens
      -- indisponiveis.
      --
      FOR x IN ( SELECT line_id
                   FROM ont.oe_order_lines_all   oola,
                        wsh.wsh_delivery_details wsh
                  WHERE oola.header_id       = wsh.source_header_id
                    AND oola.line_id         = wsh.source_line_id
                    AND oola.flow_status_code NOT IN ('CANCELLED','HOLD_GARANTIA')
                    AND wsh.released_status != 'Y'             --> Indisponibilidade
                    AND oola.ship_set_id     = p_ship_set_id ) --> Param.
      LOOP
         l_disponibilidade := l_disponibilidade + 1;
         UPDATE ont.oe_order_lines_all l
            SET l.flow_status_code = 'AGUARDANDO_DISPONIBILIDADE'
          WHERE l.line_id          = x.line_id;  --> Param.
      END LOOP;
      --
      IF( l_disponibilidade > 0 )
      THEN
         l_msg_error := 'A entrega '||p_ship_set_id||' contem linhas com item indiponivel.';
         RAISE e_indisp;
      END IF;

      /*******FIM BACKORDER*******/
      --
      --
      /* Ini TCosta 17/12/2010 (Comentado select into em troca fetch do cursor c_infs)
      BEGIN
         SELECT ooha.attribute2
              , ooha.sales_channel_code
              , ooha.orig_sys_document_ref
              , os.set_name
              , oola.attribute1 -- FROM_LOC
              , decode(oola.shipment_priority_code, 'NORMAL', 'N', 'GARANTIDA', 'G', 'URGENTE', 'U', 'EXPRESSA', 'E') -- SITE_ORDER_TYPE
              , decode(oola.attribute15, 'CAN', 'Y', 'CAC', 'Y', 'N') -- PAY_IND_ADVANCED
              , decode(otta.attribute6, 'TRO', 'Y', 'N') -- EXCHANGE_ID
              , promise_date
              , nvl(wnd.tp_attribute2, wnd.attribute2)
              , nvl(wnd.tp_attribute7, wnd.attribute7)
              , nvl(wnd.tp_attribute8, wnd.attribute8)
              , to_date(nvl(wnd.tp_attribute5, wnd.attribute5), 'YYYY-MM-DD HH24:MI:SS')
              , to_date(nvl(wnd.tp_attribute6, wnd.attribute6), 'YYYY-MM-DD HH24:MI:SS')
              , nvl(wnd.tp_attribute9, wnd.attribute9)
              , nvl(wnd.tp_attribute11, wnd.attribute11)
              , nvl(wnd.tp_attribute11, wnd.attribute11)
              , TO_CHAR(to_date(nvl(wnd.tp_attribute10, wnd.attribute10), 'RRRR-MM-DD HH24:MI:SS'), 'RRRR-MM-DD HH24:MI:SS')
              , nvl(opa.attribute3, 'GERAL')
              , nvl(opa.attribute3, 'GERAL')
              , oola.line_id
           INTO l_attribute2
              , l_sales_channel_code
              , l_orig_sys_document_ref
              , l_set_name
              , l_attribute1
              , l_prioridade
              , l_pay_in_advanced
              , l_exchange_ind
              , l_promise_date
              , l_carrier
              , l_awb
              , l_hub
              , l_carrier_pickup_dt
              , l_carrier_delivery_dt
              , l_rota
              , l_mega_rota_orig
              , l_mega_rota_ship
              , l_hora_corte
              , l_contract_orig
              , l_contract_ship
              , l_line_id
           FROM oe_order_headers_all     ooha
              , oe_sets                  os
              , oe_order_lines_all       oola
              , oe_transaction_types_all otta
              , wsh_delivery_details     wdd
              , wsh_delivery_assignments wda
              , wsh_new_deliveries       wnd
              , oe_price_adjustments     opa
          WHERE ooha.header_id          = os.header_id
            AND ooha.header_id          = oola.header_id
            AND oola.line_type_id       = otta.transaction_type_id
            AND oola.header_id          = wdd.source_header_id
            AND oola.line_id            = wdd.source_line_id
            AND wdd.delivery_detail_id  = wda.delivery_detail_id
            AND wnd.delivery_id         = wda.delivery_id
            AND otta.context            = 'LINE'
            AND opa.line_id             = oola.line_id
            AND opa.header_id           = oola.header_id
            AND oola.ship_set_id        = os.set_id
            AND opa.list_line_type_code = 'FREIGHT_CHARGE'
            AND opa.charge_type_code    = 'FREIGHT'
            AND oola.flow_status_code NOT IN ('CANCELLED','HOLD_GARANTIA')
--            AND oola.line_id            = p_line_id
            AND os.set_id               = p_ship_set_id
            AND ooha.header_id          = p_header_id
            AND ROWNUM                 <= 1;
      EXCEPTION
         WHEN OTHERS THEN
            l_msg_error := 'Não foi encontrado nenhum registro da entrega. (' || p_ship_set_id || ')';
            RAISE e_notfound;
      END;
      Fim TCosta 17/12/2010 (Comentado select into em troca do open cursor)
      */


      --Ini TCosta 17/12/2010
      begin
        r_infs:= null;
        open c_infs;
        fetch c_infs into r_infs;
        close c_infs;
      exception
        when others then
          l_msg_error := 'Não foi encontrado nenhum registro da entrega. (' || p_ship_set_id || ')';
          RAISE e_notfound;
      end;
      --Fim TCosta 17/12/2010

      --
      BEGIN
        SELECT raa.postal_code
          INTO l_postal_code
          FROM ra_addresses_all   raa
              ,ra_site_uses_all   rsua
              ,oe_order_lines_all oola
         WHERE rsua.site_use_id   = oola.ship_to_org_id
           AND rsua.site_use_code = 'SHIP_TO'
           AND raa.address_id     = rsua.address_id
           AND oola.header_id     = p_header_id
           AND oola.ship_set_id   = p_ship_set_id
           AND rownum <= 1;
      EXCEPTION
        WHEN OTHERS THEN
          l_msg_error  := 'Erro ao consultar informacões do endereco  - ' || 'HEADER_ID: ' || p_header_id || SQLERRM;
          RAISE e_notfound;
      END;

      --Ini TCosta 17/12/10
      if r_infs.vale_fisico = 'S' then
        --Se é Vale Fisico, popula a AQ para criar o Vale no sistema de ValeFisico
        begin
          --Transportadora
          l_carrier_rec := b2w_bpel_aq.carrier_rec
                            (carrierCode  => r_infs.carrier        --CNPJ da Transportadora
                            ,carrierName  => r_infs.carrier_name); --Razao Social / Nome da Transportadora


          --Endereco de entrega
          l_Address_rec := b2w_bpel_aq.Address_rec
                            (siteAddressId    => r_infs.address_id                     --ID imutável do endereço no site
                            ,addressId        => r_infs.raa_orig_system_reference      --Id do endereço, composto a partir do ID do cliente, traço e um sequencial. Ex: Se o cliente for 01-123, um ID válido do endereço seria 01-123-1. Esse valor é regerado a cada alteração de endereço
                            ,customerId       => r_infs.hca_orig_system_reference      --ID do cliente. Redundante para permitir tráfego independente do endereço
                            ,address          => r_infs.address1                       --Nome da rua, avenida, etc.
                            ,addressNumber    => r_infs.address4                       --Número
                            ,additionalInfo   => r_infs.province                       --Informações adicionais (apto, etc.)
                            ,quarter          => null                                  --Bairro
                            ,neighborhood     => r_infs.bairro                         --Bairro
                            ,city             => r_infs.city                           --Cidade
                            ,state            => r_infs.state                          --Estado
                            ,country          => r_infs.country                        --País
                            ,postalCode       => r_infs.postal_code                    --Código postal. CEP no caso de endereço nacional e código postal qualquer no caso de outros países
                            ,addressReference => r_infs.hl_attribute5                  --Informações de referência do endereço. Por exemplo, condomínio XPTO, próximo a avenida XYZ, etc
                            ,contactName      => r_infs.hca_sales_channel_code         --Nome do contato deste endereço
                            ,creationDate     => r_infs.raa_creation_date);            --Data de criação do endereço


          --Entrega
          l_delivery_rec := b2w_bpel_aq.delivery_rec
                              (deliveryID           => r_infs.set_name          --Identificador único de entrega, composto a partir do identificador do pedido. Para pedido nro 01-123, nro de entrega é 01-123-1, 01-123-2, etc
                              ,carrierContractId    => r_infs.contract_ship     --Identificador do contrato da transportadora
                              ,trackingNumber       => r_infs.awb               --Código de rastreamento postal (AWB).
                              ,freightChargedAmount => r_infs.wnd_tp_attribute4 --Valor final do frete
                              ,maxExpeditionDate    => r_infs.wnd_tp_attribute4 --
                              ,route                => r_infs.rota              --
                              ,deliveryAddress      => l_Address_rec            --Endereço de entrega do cliente para esta entrega
                              ,carrier              => l_carrier_rec);          --Informações da Transportadora


          --Linhas da Entrega
          for r_l in (select oola.*
                            ,nvl((msi.unit_volume * oola.ordered_quantity), 0)        volume
                            ,nvl(msi.Unit_Weight * oola.ordered_quantity,0)           peso
                            ,(select mtl.description
                                from apps.mtl_system_items_tl mtl
                               where mtl.inventory_item_id = oola.inventory_item_id
                                and mtl.organization_id    = oola.ship_from_org_id
                                and mtl.language           = 'PTB')                   item_name
                        from oe_order_lines_all oola
                            ,mtl_system_items   msi
                       where oola.ship_set_id       = p_ship_set_id
                         and oola.ship_from_org_id  = msi.organization_id
                         and oola.inventory_item_id = msi.inventory_item_id)
          loop
            l_orderLine_tbl.extend;
            l_orderLine_tbl(l_orderLine_tbl.count) := b2w_bpel_aq.orderLine_rec
                                                       (orderLineId   => r_infs.orig_sys_line_ref      --Identificador único de orderLine, composto a partir do identificador da entrega. Para entrega nro 01-123-01, orderLine é 01-123-01-1, 01-123-01-2, etc.
                                                       ,sku           => r_infs.ordered_item           --SKU do produto
                                                       ,skuName       => r_l.item_name                 --Nome do sku
                                                       ,skuValue      => nvl(r_l.unit_selling_price,0) --Valor do Item
                                                       ,weight        => r_l.peso);                    --Peso do item
          end loop;


          --Telefone do Cliente
          l_phone_tbl.extend;
          l_phone_tbl(1) := b2w_bpel_aq.phone_rec
                              (countryCode   => null            --Código de país
                              ,areaCode      => null            --Código de área (DDD)
                              ,phoneNumber   => r_infs.telefone --Número do telefone
                              ,extension     => null            --Ramal
                              ,phoneType     => null);          --Tipo do telefone (comercial, residencial, etc.)



          --Cliente
          l_customer_rec := b2w_bpel_aq.customer_rec
                              (customerId        => r_infs.hca_orig_system_reference --Número do cliente gerado pelo site, acrescido do mnemônico inicial e um traço (SHOP=01, ACOM=02, SUBA=03, BLOC=04). Ex: 02-333. Este número é regerado a cada alteração que exija inclusão de novo registro no ERP
                              ,documentNumber    => r_infs.customer_cpfj             --Número do CPF se for pessoa física ou CNPJ se for pessoa jurídica
                              ,custType          => r_infs.customer_type             --Tipo do cliente (PF ou PJ)
                              ,name              => r_infs.customer_name             --Nome do cliente (Razão social se PJ, nome completo se PF
                              ,phoneList         => l_phone_tbl);                    --Lista de telefones do cliente


          l_order_rec :=  b2w_bpel_aq.order_rec
                            (orderID         => r_infs.orig_sys_document_ref --Numero do pedido gerado pelo site, acrescido do mnemônico inicial e um traço (SHOP=01, ACOM=02, SUBA=03, BLOC=04). Ex: 01-1234
                            ,purchaseDate    => r_infs.ordered_date          --Data e hora do pedido fechado no site
                            ,saleChannel     => r_infs.sales_channel_code    --Canal de venda em que o pedido foi fechado. Ex: Tele Vendas, Site, (descrição da location)
                            ,businessUnit    => r_infs.unidade_negocio       --Unidade de negócio, ex: B2B, B2C, B2B2C
                            ,b2bContractId   => r_infs.ooha_attribute3       --Identificador do contrato B2B que originou o pedido. Caso não existir, não é um contrato B2B
                            ,CentralId       => r_infs.ooha_attribute1       --Código do CD de origem
                            ,brandInfo       => b2w_bpel_aq.brandInfo_rec(brandID => r_infs.brand_info)  --Identificador da marca do pedido (ACOM, SHOP, etc.)
                            ,customer        => l_customer_rec               --Dados do cliente
                            ,orderLineList   => l_orderLine_tbl              --Linhas da Ordem
                            ,delivery        => l_delivery_rec);             --Informaçoes da Entrega

          l_type_valfis := b2w_bpel_aq.insertVoucherOrderRequest(order_ => l_order_rec);


          --enqueue para o sistema do vale fisico
          b2w_bpel_aq.b2w_aq_envia_vale_fisico_pkg.envia_vale_fisico_p(p_ship_set_id   => p_ship_set_id
                                                                      ,p_b2w_om_valfis => l_type_valfis);
        end;
      else
      --Fim TCosta 17/12/2010
        begin
           l_rib_nbtsfindesc_rec := b2w_bpel_aq.rib_nbtsfindesc_rec
                                              ( 1
                                              , 'PV'
                                              , r_infs.prioridade
                                              , 'L'
                                              , NULL
                                              , r_infs.carrier_pickup_dt
                                              , r_infs.orig_sys_document_ref
                                              , r_infs.set_name
                                              , r_infs.set_name
                                              , p_header_id
                                              , 'N'
                                              , NULL
                                              , NULL
                                              , NULL
                                              , r_infs.pay_in_advanced
                                              , r_infs.sales_channel_code
                                              , r_infs.exchange_ind
                                              );
           --
           l_rib_tsfincarrierdesc_rec := b2w_bpel_aq.rib_tsfincarrierdesc_rec
                                                   ( 1
                                                   , NULL
                                                   , r_infs.carrier
                                                   , r_infs.awb
                                                   , r_infs.hub
                                                   , l_postal_code
                                                   , r_infs.carrier_pickup_dt
                                                   , NULL
                                                   , r_infs.carrier_delivery_dt
                                                   , r_infs.rota
                                                   , to_date(r_infs.hora_corte, 'RRRR-MM-DD HH24:MI:SS')
                                                   , NULL
                                                   , ltrim(rtrim(r_infs.mega_rota_orig))
                                                   , ltrim(rtrim(r_infs.mega_rota_ship))
                                                   , r_infs.contract_orig
                                                   , r_infs.contract_ship
                                                   , r_infs.num_regiao  --Alessandro Chaves - F2C  16/12/2010
                                                   );
           --
           l_rib_tsfindesc_rec := b2w_bpel_aq.rib_tsfindesc_rec
                                            ( 1
                                            , 'W'
                                            , r_infs.oola_attribute1
                                            , 'S'
                                            , r_infs.ooha_attribute2
                                            , 'CO'
                                            , 'N'
                                            , 'N'
                                            , r_infs.promise_date
                                            , 'site'
                                            , SYSDATE
                                            , 'A'
                                            , 'A'
                                            , NULL
                                            , 'N'
                                            , l_rib_nbtsfindesc_rec
                                            , NULL     -- RIB_TSFINADDRDESC_REC
                                            , l_rib_tsfincarrierdesc_rec
                                            , NULL     -- RIB_TSFINDTLDESC_TBL
                                            );
           --
           l_b2w_om_realiza_picking_type := b2w_bpel_aq.b2w_om_realiza_picking_type
                                                      ( l_rib_tsfindesc_rec
                                                      , l_message_type );
        exception
           when others then
              l_msg_error := 'Erro ao popular os types. (' || SQLCODE || ')' || SQLERRM;
              raise e_erro;
        end;
        --
        BEGIN
           b2w_bpel_aq.b2w_aq_real_picking_pkg.b2w_aq_real_picking_p
           ( p_ship_set_id                 => p_ship_set_id
           , p_b2w_om_realiza_picking_type => l_b2w_om_realiza_picking_type );
        END;
      end if;
   EXCEPTION
      WHEN e_next THEN
         NULL;
      WHEN e_indisp THEN
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p
                                     ( p_set_id        => p_ship_set_id
                                     , p_line_id       => NULL
                                     , p_processo      => l_process_name
                                     , p_erro          => l_msg_error
                                     , p_creation_date => SYSDATE );
      WHEN e_erro THEN
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p
                                     ( p_set_id        => p_ship_set_id
                                     , p_line_id       => NULL
                                     , p_processo      => l_process_name
                                     , p_erro          => l_msg_error
                                     , p_creation_date => SYSDATE );
      WHEN e_notfound THEN
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p
                                     ( p_set_id        => p_ship_set_id
                                     , p_line_id       => NULL
                                     , p_processo      => l_process_name
                                     , p_erro          => l_msg_error
                                     , p_creation_date => SYSDATE );
      WHEN OTHERS THEN
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p
                                     ( p_set_id        => p_ship_set_id
                                     , p_line_id       => NULL
                                     , p_processo      => l_process_name
                                     , p_erro          => 'Erro: (' || SQLCODE || ')' || SQLERRM
                                     , p_creation_date => SYSDATE );
   END b2w_om_real_picking_p;
   --
   --
   PROCEDURE b2w_om_resp_picking_p
           ( p_status_code   IN VARCHAR2
           , p_error_message IN VARCHAR2
           , p_stk_available IN b2w_bpel_aq.rib_tsfinstkavail_rec )
   IS
      l_process_name   VARCHAR2(200) := 'B2W_OM_RESP_PICKING_PKG.B2W_OM_RESP_PICKING_P';
   --   l_error_code     varchar2(100);
      l_msg_error      VARCHAR2(2000);
      l_set_name       oe_sets.set_name%TYPE;
      l_set_id         oe_sets.set_id%TYPE;
      l_status         VARCHAR2(1) := 'S';
      --
      e_bam            EXCEPTION;
   BEGIN
      IF nvl(p_status_code, 'E') = 'S'
      THEN
         BEGIN
            SELECT os.set_name
                 , os.set_id
              INTO l_set_name
                 , l_set_id
              FROM oe_sets              os
                 , oe_order_lines_all   oola
             WHERE os.set_id      = oola.ship_set_id
               AND os.set_name    = p_stk_available.om_delivery_no
               AND ROWNUM        <= 1;
         EXCEPTION
            WHEN OTHERS THEN
               l_msg_error := 'Erro ao buscar dados da entrega. (' || SQLCODE || ')' || SQLERRM;
               RAISE e_bam;
         END;
         --
         BEGIN
           FOR i IN 1 .. p_stk_available.TSFINSTKAVAILDTL.COUNT LOOP
             IF  p_stk_available.TSFINSTKAVAILDTL(i).STK_AVAILABLE = 'N' THEN
                --
                UPDATE oe_order_lines_all
                  SET flow_status_code = 'AGUARDANDO_DISPONIBILIDADE'
                WHERE LINE_ID        = p_stk_available.TSFINSTKAVAILDTL(i).OM_LINE_ID;
                -- 
                UPDATE wsh.wsh_delivery_details 
                   SET released_status = 'B',
                       last_update_date = SYSDATE        
                WHERE source_line_id = p_stk_available.TSFINSTKAVAILDTL(i).OM_LINE_ID;
                --
                l_status := 'N';
                --
             END IF;
           END LOOP;
         IF l_status = 'S' THEN
            UPDATE oe_order_lines_all
               SET flow_status_code = 'ENVIAR_NF_RASCUNHO_ORFMO'
             WHERE header_id        = p_stk_available.om_header_id
               AND flow_status_code IN ('REALIZA_PICKING_RMS');
         END IF;
            --
         EXCEPTION
            WHEN OTHERS THEN
               l_msg_error := 'Erro ao atualizar o status da entrega '||p_stk_available.om_delivery_no||'. (' || SQLCODE || ')' || SQLERRM;
               --
               b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p
                                           ( p_set_id        => l_set_id
                                           , p_line_id       => NULL
                                           , p_processo      => l_process_name
                                           , p_erro          => l_msg_error
                                           , p_creation_date => sysdate );
         END;
      ELSE
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p
                                     ( p_set_id        => null
                                     , p_line_id       => null
                                     , p_processo      => l_process_name
                                     , p_erro          => p_error_message
                                     , p_creation_date => sysdate );
      END IF;
      COMMIT;
   EXCEPTION
      WHEN e_bam THEN
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p( p_set_id        => l_set_id
                                                      , p_line_id       => NULL
                                                      , p_processo      => l_process_name
                                                      , p_erro          => l_msg_error
                                                      , p_creation_date => SYSDATE );
         COMMIT;
      WHEN OTHERS THEN
         b2w_bpel_aq.b2w_log_error_pkg.b2w_log_error_p( p_set_id        => l_set_id
                                                      , p_line_id       => NULL
                                                      , p_processo      => l_process_name
                                                      , p_erro          => 'Erro: (' || SQLCODE || ')' || SQLERRM
                                                      , p_creation_date => SYSDATE );
         COMMIT;
   END b2w_om_resp_picking_p;
END b2w_om_real_picking_pkg;
/

