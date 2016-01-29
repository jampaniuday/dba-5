WHENEVER SQLERROR EXIT FAILURE ROLLBACK
CONNECT &1/&2
--
SET DEFINE OFF;
--
CREATE OR REPLACE PACKAGE BODY apps.xxinv_paper_lot_pk AS
--
-- $Header: XXINV_PAPER_LOT_PKB.pls 120.026 2014-06-04 08:38:40 t31364 $
-- $Id: XXINV_PAPER_LOT_PKB.pls 120.0 011-09-19 15:00:00 Daiane Bitencourt $
-- +====================================================================+
-- |                    NINECON, Sao Paulo, Brasil                      |
-- |                       All rights reserved.                         |
-- +====================================================================+
-- | FILENAME                                                           |
-- |   XXINV_PAPER_LOT_PKS.pls                                          |
-- |                                                                    |
-- | PURPOSE                                                            |
-- |                                                                    |
-- | DESCRIPTION                                                        |
-- |   LIMPA_TABELA_TMP_P                                               |
-- |      Exclui os dados da tabela temporáa XXINV_PAPER_LOT_TEMP,    |
-- |      relacionados ao usuáo informado no parametro de entrada     |
-- |   INSERT_PAPER_LOT_TEMP_P                                          |
-- |      Obtéas informaçs inseridas no recebimento da bobina,      |
-- |      baseado no plano de coleta, e insere os dados na tabela       |
-- |      temporáa XXINV_PAPER_LOT_TEMP                               |
-- |   GET_COLUM_NAME_F                                                 |
-- |      Retorna o nome da coluna do plano de coleta, a partir do nome |
-- |      do campo informado em tela                                    |
-- |   GET_SALDO_OS_F                                                   |
-- |      Retorna a quantidade total de papel transacionada (consumido  |
-- |      ou devolvido com avaria), relacionada a uma determinada       |
-- |      orgnaizaç e nú de OS                                    |
-- |   CREATE_TRANSF_P                                                  |
-- |      Gera transaç para as bobinas pertencentes a uma determinada |
-- |      OS que ainda nãforam processadas. Apóerar o pedido de    |
-- |      picking, solicita impressãde etiqueta para a bobina e       |
-- |      exporta as informaçs para o sistema legado Metrics          |
-- |   CREATE_AVARIA_P                                                  |
-- |      Transfere um determinado lote (informado via parametro de     |
-- |      entrada) para um subinventáo de INSPEÇO                    |
-- |   SSP_IFACE_P                                                      |
-- |      Processo de interface com o sistema legado SSP. Obtéas      |
-- |      solicitaçs de impressãefetuadas em gráca externa, e     |
-- |      envia a conta contál na qual deveráer contabilizado       |
-- |   ATUALIZA_RESERVA_P                                               |
-- |      Obtem todas as solicitaçs de papel geradas nos úos      |
-- |      P_NR_DIAS dias, e atualiza o nú da reserva                |
-- |   GERA_DEVOLUCAO_P                                                 |
-- |      Obtétodos os pedidos de devoluç nãprocessada, a OS      |
-- |      correspondente, e cria uma transferencia de devoluç.        |
-- |   ATUALIZA_FLAG_P                                                  |
-- |      Atualiza o flag do plano de coleta para 'Processado'          |
-- |                                                                    |
-- | PARAMETERS                                                         |
-- |   p_login_id                                                       |
-- |   p_documento                                                      |
-- |   p_vendor_code                                                    |
-- |   p_transacao                                                      |
-- |   p_erro                                                           |
-- |   p_plan_id                                                        |
-- |   p_colum_name                                                     |
-- |   p_item_id                                                        |
-- |   p_organization_id                                                |
-- |   p_os_number                                                      |
-- |   p_lot_number                                                     |
-- |   p_inventory_item_id                                              |
-- |   p_transaction_quantity                                           |
-- |   p_c_attribute1                                                   |
-- |   p_c_attribute2                                                   |
-- |   p_n_attribute1                                                   |
-- |   p_n_attribute2                                                   |
-- |   p_separacao                                                      |
-- |   p_cnpj_fornec                                                    |
-- |   p_nf_remessa                                                     |
-- |   p_nf_serie                                                       |
-- |   p_nf_data                                                        |
-- |   p_subinventario                                                  |
-- |   p_location_id                                                    |
-- |   p_organization_id                                                |
-- |   p_nr_dias                                                        |
-- |   p_plan_id                                                        |
-- |   p_lote_volume                                                    |
-- |                                                                    |
-- | CREATED BY  Daiane Bitencourt - 19/09/2011                         |
-- |                                                                    |
-- | UPDATED BY  Heitor Yatabe-16/04/2013                               |
-- |             Heitor Yatabe-10/06/2013                               |
-- |             Heitor Yatabe-19/06/2013                               |
-- |             Heitor Yatabe-01/07/2013                               |
-- |             Heitor Yatabe-20/08/2013                               |
-- |             Heitor Yatabe-16/09/2013 - D-08208 - INV-QA (SSP)      |
-- |             Heitor Yatabe-17/09/2013 - D-08207 - INV-QA (SSP)      |
-- |             Heitor Yatabe-07/10/2013 - D-08209 - INV-QA (SSP)      |
-- |             Heitor Yatabe-24/10/2013 - D-08849 - INV-QA (SSP)      |
-- |             Heitor Yatabe-06/01/2014 - D-09747 - SWIP (Contabil)   |
-- |             Heitor Yatabe-14/05/2014 - D-12935 - INV (PROJ.PLANAS) |
-- +====================================================================+
--
  --
  --Reorg Societ 25/08/2012
  g_vSegment1                gl_code_combinations.segment2%TYPE;
  g_nNewOrg                  NUMBER;
  --
  PROCEDURE limpa_tabela_tmp_p(p_login_id IN NUMBER) IS
  BEGIN
    DELETE bolinf.xxinv_paper_lot_temp
     WHERE login_id = p_login_id;
    --
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Erro ao excluir dados da tabela temporaria XXINV_PAPER_LOT_TEMP. ' || SQLERRM);
  END;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE insert_paper_lot_temp_p(p_login_id     IN NUMBER
                                   ,p_documento    IN VARCHAR2
                                   ,p_lote_number  IN VARCHAR2
                                   ,p_vendor_code  IN VARCHAR2
                                   ,p_transacao    IN VARCHAR2
                                   ,p_erro        OUT VARCHAR2) IS
    --
    l_vFornecedor            qa_results.character1%TYPE;
    l_vCursorStr             VARCHAR2(1000);
    --
    TYPE r_cursor            IS REF CURSOR;
    c_PlanoColeta            r_cursor;
    --
    l_vCodigoBarra           VARCHAR2(150);
    l_vIDVolume              VARCHAR2(150);
    l_nQuantity              NUMBER;
    l_vLote                  VARCHAR2(150);
    l_nProfundidade          NUMBER;
    l_nQuantidadeAvariada    NUMBER;
    l_vFornecedor2           VARCHAR2(150);
    l_vOrganizationCode      org_organization_definitions.organization_code%TYPE;
    l_vTipoAvaria            VARCHAR2(150);
    l_vSegment1              VARCHAR2(150);
    l_vExisteEstoque         VARCHAR2(10) := 'N';
    --
  BEGIN
    --Limpa Tabela Temporaria
    limpa_tabela_tmp_p(p_login_id);
    --
    -- Montando cursor
    BEGIN
      SELECT organization_code
        INTO l_vOrganizationCode
        FROM org_organization_definitions
       WHERE organization_id = fnd_profile.value('MFG_ORGANIZATION_ID');
      --
    EXCEPTION
      WHEN OTHERS THEN
        raise_application_error(-20001, 'Erro ao procurar a organizaç. ' || SQLERRM);
    END;
    --
    l_vCursorStr := 'SELECT codigo_barra, id_volume, quantity, lote, profundidade, quantidade_avariada, fornecedor, tipo_avaria, segment1' ||
                    ' FROM Q_R_RECEBIMENTO_PAPEL_' || l_vOrganizationCode || '_V' ||
                    ' WHERE fornecedor = nvl(' || '''' || p_vendor_code || '''' ||
                    ',fornecedor)' || ' AND lote = ' || '''' || p_lote_number || '''' ||
                    ' AND ((nf_remessa = ' || '''' || p_documento || '''' || ')' ||
                    '  OR  (receiving_trans_num = ' || '''' || p_documento || '''' || '))';
    --
    OPEN c_PlanoColeta FOR l_vCursorStr;
    --
    LOOP
      FETCH c_PlanoColeta
       INTO l_vCodigoBarra, l_vIDVolume, l_nQuantity, l_vLote, l_nProfundidade, l_nQuantidadeAvariada, l_vFornecedor2, l_vTipoAvaria, l_vSegment1;
      --
      EXIT WHEN c_PlanoColeta%NOTFOUND;
      --
      IF l_vCodigoBarra IS NOT NULL THEN
        --Entrada Manual
        --
        --=======================================
        -- Derivar informaçs do Cóo de Barra
        --=======================================
        IF nvl(l_vIDVolume, 'X') = 'X' THEN
          BEGIN
            SELECT substr(l_vCodigoBarra, xivb.volume_from, (xivb.volume_to - xivb.volume_from) + 1) volume
              INTO l_vIDVolume
              FROM bolinf.xxinv_vendor_barcode xivb
             WHERE xivb.vendor_code = p_vendor_code;
            --
          EXCEPTION
            WHEN OTHERS THEN
              p_erro := ('Erro ao derivar volume do cóo de barras do fornecedor: ' || SQLERRM);
          END;
          --
        END IF;
        --
        IF nvl(l_nQuantity, 0) = 0 THEN
          BEGIN
            SELECT to_number(substr(l_vCodigoBarra, xivb.peso_from, (xivb.peso_to - xivb.peso_from) + 1)) peso
              INTO l_nQuantity
              FROM bolinf.xxinv_vendor_barcode xivb
             WHERE xivb.vendor_code = p_vendor_code;
            --
          EXCEPTION
            WHEN OTHERS THEN
              p_erro := ('Erro ao derivar quantidade do cóo de barras do fornecedor: ' ||SQLERRM);
          END;
          --
        END IF;
        --
      END IF;
      --
      -- Razãdo Fornecedor
      BEGIN
        SELECT description
          INTO l_vFornecedor
          FROM fnd_lookup_values
         WHERE lookup_type = 'ABRL_INV_MP_FORNECEDORES'
           AND LANGUAGE    = 'PTB'
           AND lookup_code = l_vFornecedor2;
        --
      EXCEPTION
        WHEN OTHERS THEN
          p_erro := ('Fornecedor nãencontrado. Verifique!');
      END;
      --
      -- Pesquisando se a bobina do plano de coletas jáxiste no estoque (qdo for recebimento)
      IF p_transacao = 'RECEBIMENTO' THEN
        BEGIN
          SELECT 'S'
            INTO l_vExisteEstoque
            FROM mtl_lot_numbers       mln
               , mtl_onhand_quantities moq
           WHERE mln.lot_number        = l_vLote || l_vIDVolume
             AND moq.lot_number        = mln.lot_number
             AND moq.organization_id   = fnd_profile.value('MFG_ORGANIZATION_ID')
             AND moq.inventory_item_id = mln.inventory_item_id
             AND rownum                = 1;
          --
        EXCEPTION
          WHEN no_data_found THEN
            l_vExisteEstoque := 'N';
          WHEN OTHERS THEN
            p_erro := ('Problema para encontrar bobinas no estoque. Verifique!');
            raise_application_error(-20002,'Problema para encontrar bobinas no estoque. Verifique!');
        END;
        --
      END IF;
      --
      IF l_vExisteEstoque = 'N' THEN
        BEGIN
          INSERT INTO bolinf.xxinv_paper_lot_temp
            (lot_number                          --01
            ,transaction_quantity                --02
            ,damage_code                         --03
            ,damage_area                         --04
            ,damage_weight                       --05
            ,paper_type                          --06
            ,peso_medio                          --07
            ,item_quantity                       --08
            ,item_weight                         --09
            ,login_id                            --10
            ,creation_date                       --11
            ,manufacturer                        --12
            ,lot_attribute_category              --13
            )
          VALUES
            (l_vLote || l_vIDVolume              --01
            ,to_number(l_nQuantity)              --02
            ,l_vTipoAvaria                       --03
            ,l_nProfundidade                     --04
            ,l_nQuantidadeAvariada               --05
            ,1                                   --06
            ,NULL                                --07
            ,l_nQuantity                         --08
            ,NULL                                --09
            ,p_login_id                          --10
            ,SYSDATE                             --11
            ,l_vFornecedor                       --12
            ,'PAPEL'                             --13
            );
          --
          COMMIT;
          --
        EXCEPTION
          WHEN OTHERS THEN
            p_erro := ('Erro ao popular BOLINF.XXINV_PAPER_LOT_TEMP: ' || SQLERRM);
            raise_application_error(-20003,'Erro ao popular BOLINF.XXINV_PAPER_LOT_TEMP: ' ||SQLERRM);
        END;
        --
      END IF;
      --
    END LOOP;
    --
  END insert_paper_lot_temp_p;
  --
  -------------------------------------------------------------------------------------------------
  FUNCTION get_colum_name_f(p_plan_id       qa_plans.plan_id%TYPE
                           ,p_colum_name IN VARCHAR2)
    RETURN VARCHAR2 IS
    --
    l_colum_name qa_results.character1%TYPE;
    --
  BEGIN
    BEGIN
      SELECT result_column_name
        INTO l_colum_name
        FROM qa_plan_chars
       WHERE plan_id      = p_plan_id
         AND prompt       = p_colum_name
         AND enabled_flag = 1;
      --
    EXCEPTION
      WHEN OTHERS THEN
        l_colum_name := 'null';
    END;
    --
    RETURN(l_colum_name);
    --
  END get_colum_name_f;
  --
  -------------------------------------------------------------------------------------------------
  FUNCTION get_saldo_os_f(p_item_id         IN mtl_system_items_b.inventory_item_id%TYPE
                         ,p_organization_id IN mtl_system_items_b.organization_id%TYPE
                         ,p_os_number       IN bolinf.xxinv_solicita_papel.num_os%TYPE)
    RETURN NUMBER IS
    --
    l_saldo NUMBER := 0;
    --
  BEGIN
    --
    BEGIN
      --
      SELECT nvl(SUM(transaction_quantity), 0)
        INTO l_saldo
        FROM mtl_material_transactions
       WHERE inventory_item_id      = p_item_id
         AND organization_id        = p_organization_id
         AND transaction_reference  = p_os_number
         AND transaction_type_id   in (SELECT transaction_type_id
                                         FROM mtl_transaction_types
                                        WHERE upper(attribute8) IN ('CON_PROD', 'DEV_PROD'));
      --
    EXCEPTION
      WHEN OTHERS THEN
        l_saldo := 0;
    END;
    --
    RETURN(l_saldo);
    --
  END get_saldo_os_f;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE create_transf_p(errbuf IN OUT VARCHAR2
                           ,retcode IN OUT NUMBER) IS
    -- Criar Picking
    CURSOR c_transaction IS
      SELECT qs.nro_os
            ,qs.organization_id
            ,qs.lote || qs.id_volume lote
            ,qs.lote id_lote
            ,qs.id_volume
            ,qs.created_by_id
            ,qs.quantity qtd_volume
            ,qs.segment1 item
            ,qs.fornecedor
            ,qs.plan_id
        FROM q_s_separacao_v qs
       WHERE nvl(qs.processado, 'N') = 'N';
    --
    l_rMtiRec                mtl_transactions_interface%ROWTYPE;
    l_rMtliRec               mtl_transaction_lots_interface%ROWTYPE;
    l_nTimeout               NUMBER;
    l_vErrorCode             VARCHAR2(1000);
    l_vErrorExplanation      VARCHAR2(1000);
    l_bReturn                BOOLEAN;
    l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_bError                 BOOLEAN := TRUE;
    l_vLoteNumber            mtl_transaction_lots_interface.lot_number%TYPE;
    --l_nCountLote             NUMBER;
    l_nOrganizationID        org_organization_definitions.organization_id%TYPE;
    l_vCodBarra              VARCHAR2(100);
    l_vAttribute14           mtl_material_transactions.attribute14%TYPE;
    l_vLoteErro              VARCHAR2(100);
    l_nValid                 NUMBER := 0;

    l_nCodsubinv             varchar2(100);
    l_nCodInv                varchar2(100);
    --
    -- Cursor para trazer os registros duplicados e com erros de um determinado Lote
    cursor c_loteerro IS
      SELECT mti.transaction_interface_id
        FROM mtl_transactions_interface     mti
            ,mtl_transaction_lots_interface mtli
       WHERE mtli.lot_number                = l_vLoteErro
         AND mtli.transaction_interface_id !=
             (SELECT MAX(mtli.transaction_interface_id)
                FROM mtl_transactions_interface     mti
                    ,mtl_transaction_lots_interface mtli
               WHERE mtli.lot_number               = l_vLoteErro
                 AND mti.transaction_interface_id  = mtli.transaction_interface_id
                 AND mti.error_code               IS NOT NULL)
         AND mti.transaction_interface_id   = mtli.transaction_interface_id
         AND mti.error_code                IS NOT NULL;


    --
  BEGIN
    fnd_file.put_line(fnd_file.output, '===================================');
    fnd_file.put_line(fnd_file.output, '==      TRANSFERÊCIA PICK      ===');
    fnd_file.put_line(fnd_file.output, '===================================');
    fnd_file.put_line(fnd_file.output, NULL);
    --
    FOR r_transaction IN c_transaction LOOP
      --
      l_bError := TRUE;
      --

      IF (l_vDebug = 1) THEN
        fnd_file.put_line(fnd_file.log,'Entrou no loop cursor. OS-> = ' || r_transaction.nro_os);
        --inv_trx_util_pub.trace('Valor do parametro RETCODE:' || retcode,'XXINV_PAPER_LOT_PK',4);
      END IF;

      BEGIN
        SELECT ood.organization_id
              ,xiios.num_reserva
              ,lpad(xiios.cod_sub_inv,3,'0')
              ,lpad(xiios.cod_inv,3,'0')
          INTO l_nOrganizationID
              ,l_vAttribute14
              ,l_nCodsubinv
              ,l_nCodInv
          FROM org_organization_definitions ood
              ,bolinf.xxinv_int_os          xiios
         WHERE ood.organization_code = lpad(xiios.cod_inv, 3, 0)
           AND xiios.num_r           = r_transaction.nro_os
           AND xiios.cod_papel       = to_number(r_transaction.item)      --HY
           AND xiios.cod_transacao   = ( SELECT MAX( ai.cod_transacao )   --incluido para nãretornar mais de uma linha para a OS
                                           FROM bolinf.xxinv_int_os ai
                                          WHERE ai.num_r     = r_transaction.nro_os
                                            AND ai.cod_papel =  to_number(r_transaction.item)
                                            and ai.cod_tipo_os in ('P','C')-- = 'P'
                                        );
        --
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro Localizar a Organizaç da OS= ' || r_transaction.nro_os || '. ' || SQLERRM);
          --
          retcode  := SQLCODE;
          errbuf   := SQLERRM;
          l_bError := FALSE;
          --
      END;
      --
      BEGIN
        SELECT inventory_item_id
          INTO l_rMtiRec.inventory_item_id
          FROM mtl_system_items_b
         WHERE segment1        = r_transaction.item
           AND organization_id = l_nOrganizationID;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Erro ao localizar ID do item= ' || r_transaction.item || '. ' || SQLERRM);
          retcode  := SQLCODE;
          errbuf   := SQLERRM;
          l_bError := FALSE;
      END;
      --

      ------------------------------
      -- Recuperar o ID da transaç
      ------------------------------
      BEGIN
        SELECT transaction_type_id
              ,transaction_action_id
              ,transaction_source_type_id
          INTO l_rMtiRec.transaction_type_id
              ,l_rMtiRec.transaction_action_id
              ,l_rMtiRec.transaction_source_type_id
          FROM mtl_transaction_types
         WHERE upper(attribute8) = 'SOLIC_PROD';
        --
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Erro ao Buscar ID da Transaç SOLIC_PROD. ' || SQLERRM);
          retcode  := SQLCODE;
          errbuf   := SQLERRM;
          l_bError := FALSE;
      END;
      --
      BEGIN
        SELECT subinventory_code
              ,locator_id
          INTO l_rMtiRec.subinventory_code
              ,l_rMtiRec.locator_id
          FROM mtl_onhand_quantities
         WHERE inventory_item_id  = l_rMtiRec.inventory_item_id
           AND organization_id    = l_nOrganizationID
           AND lot_number         = r_transaction.lote
           AND creation_date      = (SELECT MIN(creation_date)
                                       FROM mtl_onhand_quantities
                                      WHERE inventory_item_id = l_rMtiRec.inventory_item_id
                                        AND organization_id   = l_nOrganizationID
                                        AND lot_number        = r_transaction.lote)
         GROUP BY lot_number
                 ,subinventory_code
                 ,locator_id;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Nãforam encontradas quantidades para esse volume. Verifique!= ' ||SQLERRM);
          fnd_file.put_line(fnd_file.log,'inventory_item_id = '        || l_rMtiRec.inventory_item_id ||
                                         'r_transaction.sum_volume = ' || r_transaction.qtd_volume ||
                                         'lote = '                     || r_transaction.lote);
          retcode  := SQLCODE;
          errbuf   := SQLERRM;
          l_bError := FALSE;
      END;

      --verificar o subinventario da OS x LoteVolume (16/04/2013) Demanda D-00548
      --somente para terceiros em nosso poder
      if l_nCodInv = '002' then --or l_nCodsubinv = '003'then
         if l_rMtiRec.subinventory_code != l_nCodsubinv then
            --fnd_file.put_line(fnd_file.log,'Erro na separaç, Sub-inventáo do lote ' || r_transaction.lote  ||  ' diferente da OS ->' || r_transaction.nro_os );
            fnd_file.put_line(fnd_file.output,'Erro na separaç, Sub-inventáo do lote '
                                           || r_transaction.lote  || '(' || l_rMtiRec.subinventory_code || ')'
                                           ||  ' diferente da OS ->'
                                           || r_transaction.nro_os || '(' || l_nCodsubinv || ')'
                                            );
            retcode  := 1;
            errbuf   := 'Erro na separacao do plano de coleta';
            l_bError := FALSE;
         end if;
      end if;

      --
      BEGIN
        SELECT secondary_inventory_name
          INTO l_rMtiRec.transfer_subinventory
          FROM mtl_secondary_inventories
         WHERE upper(attribute4) = 'PICKING'
           AND organization_id   = l_nOrganizationID;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro ao localizar Cóo para o Subinv. PICKING. ' || SQLERRM);
          retcode  := SQLCODE;
          errbuf   := SQLERRM;
          l_bError := FALSE;
      END;
      --
      BEGIN
        SELECT inventory_location_id
          INTO l_rMtiRec.transfer_locator
          FROM mtl_item_locations
         WHERE subinventory_code                     = l_rMtiRec.transfer_subinventory
           AND organization_id                       = l_nOrganizationID
           AND trunc(nvl(disable_date, SYSDATE + 1)) > trunc(SYSDATE);
        --
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro ao localizar Locator Destino. ' || SQLERRM);
          retcode  := SQLCODE;
          errbuf   := SQLERRM;
          l_bError := FALSE;
      END;
      --
      IF l_bError THEN
        -- Excluindo registros duplicados e com erros da Interface do INV para as bobinas do Plano de Coletas
        l_vLoteErro := r_transaction.lote;
        --
        FOR r_loteerro IN c_loteerro LOOP
          --
          BEGIN
            DELETE FROM mtl_transactions_interface
             WHERE transaction_interface_id = r_loteerro.transaction_interface_id;
            --
            DELETE FROM mtl_transaction_lots_interface
             WHERE transaction_interface_id = r_loteerro.transaction_interface_id;
            --
          EXCEPTION
            WHEN no_data_found THEN
              fnd_file.put_line(fnd_file.log,'Registros duplicados ou com erros do lote ' || r_transaction.lote || ' nãforam encontrados para exclusã');
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log,'Erro ao excluir registros duplicados e com erros do lote ' || r_transaction.lote || ' - ' || SQLERRM);
              retcode := 1; -- warning
              errbuf   := SQLERRM;
          END;
          --
        END LOOP;
        --
        COMMIT;
        --
        l_rMtiRec.process_flag          := 1;
        l_rMtiRec.lock_flag             := NULL;
        l_rMtiRec.transaction_mode      := 3;
        l_rMtiRec.error_explanation     := NULL;
        l_rMtiRec.ERROR_CODE            := NULL;
        l_rMtiRec.transaction_uom       := 'KG';
        l_rMtiRec.transaction_quantity  := r_transaction.qtd_volume;
        l_rMtiRec.primary_quantity      := r_transaction.qtd_volume;
        l_rMtiRec.organization_id       := l_nOrganizationID;
        l_rMtiRec.transfer_organization := l_nOrganizationID;
        l_rMtiRec.transaction_reference := r_transaction.nro_os;
        l_rMtiRec.created_by            := r_transaction.created_by_id;
        l_rMtiRec.creation_date         := SYSDATE;
        l_rMtiRec.last_updated_by       := r_transaction.created_by_id;
        l_rMtiRec.last_update_date      := SYSDATE;
        l_rMtiRec.transaction_date      := SYSDATE;
        l_rMtiRec.source_code           := 'INTERFACE MOV. PAPEL';
        l_rMtiRec.attribute14           := l_vAttribute14;
        l_rMtiRec.attribute_category    := l_rMtiRec.transaction_type_id;
        --

        ----------------------------------------
        -- Apropriaç sequences...
        ----------------------------------------
        BEGIN
          SELECT mtl_material_transactions_s.NEXTVAL
            INTO l_rMtiRec.transaction_header_id
            FROM dual;
          --
          SELECT mtl_material_transactions_s.NEXTVAL
            INTO l_rMtiRec.transaction_interface_id
            FROM dual;
          --
          SELECT inv.mtl_txn_request_headers_s.NEXTVAL
            INTO l_rMtiRec.source_header_id
            FROM dual;
          --
          SELECT inv.mtl_txn_request_lines_s.NEXTVAL
            INTO l_rMtiRec.source_line_id
            FROM dual;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Erro ao obter valores para os IDs das Transaçs da Interface.' || SQLERRM);
            retcode  := SQLCODE;
            errbuf   := SQLERRM;
            --l_bError := FALSE;
        END;
        --

        l_nValid := 0;
        --
        BEGIN
          --
          SELECT 1
            INTO l_nValid
            FROM mtl_transaction_lot_numbers mtln
               , mtl_material_transactions   mmt
           WHERE mmt.transaction_id        = mtln.transaction_id
             AND mmt.transaction_type_id   = l_rMtiRec.transaction_type_id
             AND mmt.transaction_reference = l_rMtiRec.transaction_reference
             AND mmt.organization_id       = l_rMtiRec.Organization_Id
             AND mtln.transaction_quantity = l_rMtiRec.transaction_quantity
             and MMT.SUBINVENTORY_CODE     = l_rMtiRec.subinventory_code
             and mmt.transaction_id        = ( select max (amtln.transaction_id )
                                                 from mtl_transaction_lot_numbers amtln
                                                where amtln.lot_number = r_transaction.lote);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_nValid := 0;
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Falha ao localizar a transaç.'||' - '|| SQLERRM);
            l_nValid := 0;
            retcode  := 1; -- warning
        END;
        --
        IF l_nValid = 1 THEN
          fnd_file.put_line(fnd_file.log,'Transaç ja existente.'||' - '|| SQLERRM);
          l_nValid := 0;
          retcode  := 1; -- warning
        ELSE
          --
          BEGIN
            INSERT INTO mtl_transactions_interface VALUES l_rMtiRec;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              fnd_file.put_line(fnd_file.output,'Erro ao incluir registro na tabela: MTL_TRANSACTIONS_INTERFACE. ' || SQLERRM);
              retcode  := 1; -- warning
          END;
          --
        END IF;
        --
        l_vLoteNumber := r_transaction.lote;
        --

/*      --comentado em 15/01-2013, variavel l_nCountLote declarada e nãutilizada...

        -- Checando se o lote jáxiste no sistema
        --
        BEGIN
          SELECT COUNT(*)
            INTO l_nCountLote
            FROM mtl_lot_numbers          mln
                ,mtl_onhand_quantities    moq
           WHERE mln.lot_number        = l_vLoteNumber
             AND mln.inventory_item_id = l_rMtiRec.inventory_item_id
             AND moq.inventory_item_id = mln.inventory_item_id
             AND moq.lot_number        = mln.lot_number
             AND moq.organization_id   = mln.organization_id
             AND mln.organization_id   = l_nOrganizationID;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.output,'Erro ao checar se o Lote jáxiste no sistema ' ||l_vLoteNumber || ' ' ||SQLERRM);
        END;
        --
*/
        BEGIN
          SELECT DISTINCT c_attribute1
                         ,c_attribute4
                         ,n_attribute1
                         ,n_attribute2
            INTO l_rMtliRec.c_attribute1
                ,l_rMtliRec.c_attribute4
                ,l_rMtliRec.n_attribute1
                ,l_rMtliRec.n_attribute2
            FROM mtl_lot_numbers
           WHERE lot_number      = l_vLoteNumber
             AND organization_id = l_nOrganizationID;
          --
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro ao recuperar attributos do Lote: ' || l_vLoteNumber || '. ' || SQLERRM);
            retcode  := 1; -- warning
        END;
        --
        l_rMtliRec.lot_number               := l_vLoteNumber;
        l_rMtliRec.transaction_interface_id := l_rMtiRec.transaction_interface_id;
        l_rMtliRec.transaction_quantity     := r_transaction.qtd_volume;
        l_rMtliRec.primary_quantity         := r_transaction.qtd_volume;
        l_rMtliRec.last_update_date         := SYSDATE;
        l_rMtliRec.last_updated_by          := r_transaction.created_by_id;
        l_rMtliRec.creation_date            := SYSDATE;
        l_rMtliRec.created_by               := r_transaction.created_by_id;
        l_rMtliRec.lot_expiration_date      := NULL;
        --
        l_nValid := 0;
        --
        BEGIN
          --
           SELECT 1
            INTO l_nValid
            FROM mtl_transaction_lot_numbers mtln
               , mtl_material_transactions   mmt
           WHERE mmt.transaction_id        = mtln.transaction_id
             AND mmt.transaction_type_id   = l_rMtiRec.transaction_type_id
             AND mmt.transaction_reference = l_rMtiRec.transaction_reference
             AND mmt.organization_id       = l_rMtiRec.Organization_Id
             AND mtln.transaction_quantity = l_rMtiRec.transaction_quantity
             and MMT.SUBINVENTORY_CODE     = l_rMtiRec.subinventory_code
             and mmt.transaction_id        = ( select max (amtln.transaction_id )
                                                 from mtl_transaction_lot_numbers amtln
                                                where amtln.lot_number = r_transaction.lote);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_nValid := 0;
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Falha ao localizar a transaç.'||' - '|| SQLERRM);
            l_nValid := 0;
            retcode  := 1; -- warning
        END;
        --
        IF l_nValid = 1 THEN
          fnd_file.put_line(fnd_file.log,'Transaç ja existente.'||' - '|| SQLERRM);
          l_nValid := 0;
          retcode  := 1; -- warning
        ELSE
          --
          BEGIN
            INSERT INTO mtl_transaction_lots_interface VALUES l_rMtliRec;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              fnd_file.put_line(fnd_file.log,'Erro ao incluir registro na tabela: MTL_TRANSACTION_LOTS_INTERFACE. ' || SQLERRM);
              retcode  := 1; -- warning
          END;
          --
        END IF;
        --

        IF (l_vDebug = 1) THEN
          fnd_file.put_line(fnd_file.log,'Atualizou Open Interface -> = ' || l_rMtiRec.transaction_header_id);
          --inv_trx_util_pub.trace('Valor do parametro RETCODE:' || retcode,'XXINV_PAPER_LOT_PK',4);
        END IF;

        COMMIT;
        --

        begin
            l_bReturn := mtl_online_transaction_pub.process_online(l_rMtiRec.transaction_header_id
                                                                  ,l_nTimeout
                                                                  ,l_vErrorCode
                                                                  ,l_vErrorExplanation);
        exception
          when others then
              fnd_file.put_line(fnd_file.log, 'Erro ao processar Transaç na Interface.(exception) ' || sqlerrm);
              retcode := 1; -- warning
              l_vErrorCode := '1'; --forçcomo erro
        end;

        IF (TRIM(l_vErrorCode) IS NOT NULL) THEN
          fnd_file.put_line(fnd_file.log, 'Erro ao processar Transaç na Interface=' || l_vErrorCode || '-' || l_vErrorExplanation);
          retcode := 1; -- warning
        ELSE
          ---------------------------------------------------
          --Atualizar flag de Processado do Plano de Coleta--
          --alterado em 16/01/2013
          ---------------------------------------------------
          begin
              atualiza_flag_p(p_plan_id     => r_transaction.plan_id
                             ,p_lote_volume => r_transaction.lote);
          exception
            when others then
              fnd_file.put_line(fnd_file.log,'Erro ao atualizar plano de coleta Separacao - Lote=> ' || r_transaction.lote ||'-'||sqlerrm);
              retcode  := 1; -- warning
          end;
          --


          IF (l_vDebug = 1) THEN
            fnd_file.put_line(fnd_file.log,'Processou interface OPEN -> = ' || l_rMtiRec.transaction_header_id);
            --inv_trx_util_pub.trace('Valor do parametro RETCODE:' || retcode,'XXINV_PAPER_LOT_PK',4);
          END IF;


          fnd_file.put_line(fnd_file.log, 'Processado com Sucesso.');
          --

          dbms_lock.sleep(5); -- pausa de 5 segundos para que a interface do INV popule todas as tabelas antes de enviar o XML
          --
          -- Chamada da PKG de impressãde etiquetas
          begin

          xxinv_imprime_etiqueta_pk.start_print_p('S'
                                                  ,r_transaction.nro_os
                                                  ,r_transaction.id_lote
                                                  ,r_transaction.id_volume
                                                  ,r_transaction.qtd_volume
                                                  ,NULL);
          EXCEPTION
            WHEN others THEN
              fnd_file.put_line(fnd_file.log,'ERRO AO EXECUTAR xxinv_exporta_xml_metrics_pk: ' ||errbuf||'-'||retcode);
              retcode  := 1; -- warning
          end;
          --
          -- Chamada da PKG de envio do XML
          fnd_file.put_line(fnd_file.log,'ID da Transaç para chamada do XML: ' ||l_rMtiRec.transaction_header_id);
          --
          l_vCodBarra := ']C1400' || r_transaction.id_lote || '!3100' || lpad(r_transaction.qtd_volume, 6, '0') || '21' || r_transaction.id_volume;
          --
          BEGIN
          bolinf.xxinv_exporta_xml_metrics_pk.gera_arq_xml_picking_p(errbuf
                                                                    ,retcode
                                                                    ,l_rMtiRec.transaction_header_id
                                                                    ,l_vCodBarra);
          EXCEPTION
            WHEN others THEN
              fnd_file.put_line(fnd_file.log,'ERRO AO EXECUTAR xxinv_exporta_xml_metrics_pk.gera_arq_xml_picking_p: ' ||errbuf||'-'||retcode);
              retcode  := 1; -- warning
          END;
          --
        END IF;
        --
      END IF;
    --
    END LOOP r_transaction;
    --
    -- Debug adicionado
    IF (l_vDebug = 1) THEN
       fnd_file.put_line(fnd_file.log,'Fim da rotina -> RETCODE = ' || retcode);
       --inv_trx_util_pub.trace('Valor do parametro RETCODE:' || retcode,'XXINV_PAPER_LOT_PK',4);
    END IF;
    --
  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar plano de coleta de separacao. ' || SQLERRM);
        --raise_application_error(-20001,'Erro ao processar plano de coleta de separacao. ' || SQLERRM);
  END create_transf_p;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE create_avaria_p(errbuf                    IN OUT VARCHAR2
                           ,retcode                   IN OUT NUMBER
                           ,p_lot_number              IN     VARCHAR2
                           ,p_organization_id         IN     NUMBER
                           ,p_inventory_item_id       IN     NUMBER
                           ,p_transaction_quantity    IN     NUMBER
                           ,p_c_attribute1            IN     VARCHAR2
                           ,p_c_attribute4            IN     VARCHAR2
                           ,p_n_attribute1            IN     VARCHAR2
                           ,p_n_attribute2            IN     VARCHAR2) IS
    --
    l_rMtiRec               mtl_transactions_interface%ROWTYPE;
    l_rMtliRec              mtl_transaction_lots_interface%ROWTYPE;
    --
    l_nTimeout              NUMBER;
    l_vErrorCode            VARCHAR2(1000);
    l_vErrorExplanation     VARCHAR2(1000);
    l_bReturn               BOOLEAN;
    l_bError                BOOLEAN := TRUE;
    --
    l_vLoteNumber           mtl_transaction_lots_interface.lot_number%TYPE;
    l_nValid                NUMBER := 0;
    --
  BEGIN
    fnd_file.put_line(fnd_file.output, '============================================');
    fnd_file.put_line(fnd_file.output, '==   TRANSFERÊCIA SUBINVENTÁIO AVARIA  ===');
    fnd_file.put_line(fnd_file.output, '============================================');
    fnd_file.put_line(fnd_file.output, NULL);
    --
    l_bError := TRUE;
    --

    -------------------------
    -- Recuperar ID transaç
    -------------------------
    BEGIN
      SELECT transaction_type_id
            ,transaction_action_id
            ,transaction_source_type_id
        INTO l_rMtiRec.transaction_type_id
            ,l_rMtiRec.transaction_action_id
            ,l_rMtiRec.transaction_source_type_id
        FROM mtl_transaction_types
       WHERE upper(transaction_type_name) = 'TRANSF. SUBINVENTARIO';
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.output, 'Erro ao Buscar Transaç= ' || SQLERRM);
        retcode  := SQLCODE;
        l_bError := FALSE;
    END;
    --
    --Subinventáo Origem
    BEGIN
      SELECT subinventory_code
            ,locator_id
        INTO l_rMtiRec.subinventory_code
            ,l_rMtiRec.locator_id
        FROM mtl_onhand_quantities   moq
       WHERE moq.inventory_item_id = p_inventory_item_id
         AND moq.organization_id   = p_organization_id
         AND moq.lot_number        = p_lot_number;
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Erro ao Buscar Subinventáo Origem=' || SQLERRM);
        retcode  := SQLCODE;
        l_bError := FALSE;
    END;
    --
    -- Subinventáo Destino de Avaria
    BEGIN
      SELECT secondary_inventory_name
        INTO l_rMtiRec.transfer_subinventory
        FROM mtl_secondary_inventories
       WHERE upper(attribute4) = 'INSPECAO'
         AND organization_id   = p_organization_id;
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Subinventáo de Avaria= ' || SQLERRM);
        retcode  := SQLCODE;
        l_bError := FALSE;
    END;
    --
    -- Locator Destino
    BEGIN
      SELECT inventory_location_id
        INTO l_rMtiRec.transfer_locator
        FROM mtl_item_locations
       WHERE subinventory_code = l_rMtiRec.transfer_subinventory
         AND rownum            = 1;
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'Erro ao localizar de Avaria= ' || SQLERRM);
        retcode  := SQLCODE;
        l_bError := FALSE;
    END;
    --
    IF l_bError THEN
      l_rMtiRec.process_flag            := 1;
      l_rMtiRec.lock_flag               := NULL;
      l_rMtiRec.transaction_mode        := 3;
      l_rMtiRec.error_explanation       := NULL;
      l_rMtiRec.ERROR_CODE              := NULL;
      l_rMtiRec.transaction_uom         := 'KG';
      l_rMtiRec.transaction_quantity    := p_transaction_quantity;
      l_rMtiRec.primary_quantity        := p_transaction_quantity;
      l_rMtiRec.organization_id         := p_organization_id;
      l_rMtiRec.transfer_organization   := p_organization_id;
      l_rMtiRec.transaction_reference   := 'Separaç Bobina com Avaria';
      l_rMtiRec.created_by              := fnd_profile.VALUE('USER_ID');
      l_rMtiRec.creation_date           := SYSDATE;
      l_rMtiRec.last_updated_by         := fnd_profile.VALUE('USER_ID');
      l_rMtiRec.last_update_date        := SYSDATE;
      l_rMtiRec.transaction_date        := SYSDATE;
      l_rMtiRec.source_code             := 'INTERFACE MOV. PAPEL';
      l_rMtiRec.transaction_source_name := p_lot_number;
      l_rMtiRec.inventory_item_id       := p_inventory_item_id;
      --

      ----------------------------------------
      -- Apropriaç sequences...
      ----------------------------------------
      BEGIN
        SELECT mtl_material_transactions_s.NEXTVAL
          INTO l_rMtiRec.transaction_header_id
          FROM dual;
        --
        SELECT mtl_material_transactions_s.NEXTVAL
          INTO l_rMtiRec.transaction_interface_id
          FROM dual;
        --
        SELECT inv.mtl_txn_request_headers_s.NEXTVAL
          INTO l_rMtiRec.source_header_id
          FROM dual;
        --
        SELECT inv.mtl_txn_request_lines_s.NEXTVAL
          INTO l_rMtiRec.source_line_id
          FROM dual;
        --
      EXCEPTION
        WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'Erro ao obter valores para os IDs das Transaçs da Interface.' || SQLERRM);
              retcode  := SQLCODE;
              errbuf   := SQLERRM;
              --l_bError := FALSE;
      END;

      --
      l_nValid := 0;
      --
      BEGIN
        SELECT 1
          INTO l_nValid
          FROM mtl_transaction_lot_numbers mtln
             , mtl_material_transactions   mmt
         WHERE mmt.transaction_id        = mtln.transaction_id
           AND mmt.transaction_type_id   = l_rMtiRec.transaction_type_id
           AND mtln.lot_number           = p_lot_number
           AND mmt.transaction_reference = l_rMtiRec.transaction_reference
           AND mmt.organization_id       = l_rMtiRec.organization_id
           AND mtln.transaction_quantity = l_rMtiRec.transaction_quantity
           AND rownum = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_nValid := 0;
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Falha ao localizar a transaç.'||' - '|| SQLERRM);
          l_nValid := 0;
          retcode  := 1; -- warning
      END;
      --
      IF l_nValid = 1 THEN
        fnd_file.put_line(fnd_file.log,'Transaç ja existente.'||' - '|| SQLERRM);
        retcode  := 1; -- warning
      ELSE
        --
        -- Inserindo dados na Interface
        BEGIN
          INSERT INTO mtl_transactions_interface VALUES l_rMtiRec;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro insert into MTL_TRANSACTIONS_INTERFACE= ' ||SQLERRM);
            retcode  := SQLCODE;
        END;
        --
      END IF;
      --
      l_vLoteNumber                       := p_lot_number;
      l_rMtliRec.lot_number               := l_vLoteNumber;
      l_rMtliRec.transaction_interface_id := l_rMtiRec.transaction_interface_id;
      l_rMtliRec.transaction_quantity     := p_transaction_quantity;
      l_rMtliRec.primary_quantity         := p_transaction_quantity;
      l_rMtliRec.last_update_date         := SYSDATE;
      l_rMtliRec.last_updated_by          := fnd_profile.VALUE('USER_ID');
      l_rMtliRec.creation_date            := SYSDATE;
      l_rMtliRec.created_by               := fnd_profile.VALUE('USER_ID');
      l_rMtliRec.lot_expiration_date      := NULL;
      l_rMtliRec.c_attribute1             := p_c_attribute1;
      l_rMtliRec.c_attribute4             := p_c_attribute4;
      l_rMtliRec.n_attribute1             := p_n_attribute1;
      l_rMtliRec.n_attribute2             := p_n_attribute2;
      --

      BEGIN
        INSERT INTO mtl_transaction_lots_interface VALUES l_rMtliRec;

      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          fnd_file.put_line(fnd_file.log,'Erro insert into MTL_TRANSACTION_LOTS_INTERFACE= ' ||SQLERRM);
          retcode  := SQLCODE;
      END;

      COMMIT;
      --

      begin
          l_bReturn := mtl_online_transaction_pub.process_online(l_rMtiRec.transaction_header_id
                                                                ,l_nTimeout
                                                                ,l_vErrorCode
                                                                ,l_vErrorExplanation);
      exception
        when others then
            fnd_file.put_line(fnd_file.log, 'Erro ao processar Transaç na Interface.(exception) ' || sqlerrm);
            retcode := 1; -- warning
            l_vErrorCode := '1'; --forçcomo erro
      end;

      IF (TRIM(l_vErrorCode) IS NOT NULL) THEN
      --IF (l_vErrorCode IS NOT NULL) THEN
         fnd_file.put_line(fnd_file.log,'Erro ao processar Transaç na Interface= ' ||l_vErrorCode|| '-' ||l_vErrorExplanation);
         retcode := 1; -- warning
      END IF;
      --
    END IF;
    --
  END create_avaria_p;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE ssp_iface_p(errbuf            IN OUT VARCHAR2
                       ,retcode           IN OUT NUMBER
                       ,p_separacao       IN VARCHAR2
                       ,p_cnpj_fornec     IN VARCHAR2
                       ,p_nf_remessa      IN VARCHAR2
                       ,p_nf_serie        IN VARCHAR2
                       ,p_nf_data         IN VARCHAR2
                       ,p_subinventario   IN VARCHAR2
                       ,p_location_id     IN VARCHAR2
                       ,p_organization_id IN NUMBER) IS
    --
    -- Interface Solicitaç Papel Grafica Externa
    CURSOR c_transaction IS
      SELECT qs.organization_id
            ,qs.lote || qs.id_volume lote
            ,qs.created_by_id
            ,qs.quantity qtd_volume
            ,qs.fornecedor
            ,qs.tipo_de_transacao tipo_transacao
            ,qs.reserva
            ,qs.segment1
            ,qs.separacao
            ,qs.plan_id
        FROM apps.q_e_envio_grafica_externa_v qs
       WHERE qs.separacao            = p_separacao
         AND nvl(qs.processado, 'N') = 'N';
    --
    l_rMtiRec            mtl_transactions_interface%ROWTYPE;
    l_rMtliRec           mtl_transaction_lots_interface%ROWTYPE;
    l_nTimeout           NUMBER;
    l_vErrorCode         VARCHAR2(1000);
    l_vErrorExplanation  VARCHAR2(1000);
    l_bReturn            BOOLEAN;
    --l_vDebug             VARCHAR2(500);
    l_bError             BOOLEAN := TRUE;
    l_vLoteNumber        mtl_transaction_lots_interface.lot_number%TYPE;
    --l_nCount             NUMBER;
    l_nCountProc         NUMBER := 0;
    --l_vCodEdicao         mtl_transactions_interface.attribute15%TYPE;
    l_vAttribute8        mtl_transaction_types.attribute8%TYPE;
    l_vNROS              varchar2(100); --bolinf.xxinv_solicita_papel.num_os%TYPE;
    l_vCodPapel          bolinf.xxinv_int_ssp.paper_code%TYPE;
    l_vOrganizationCode  org_organization_definitions.organization_code%TYPE;
    --
    l_vSegment2          gl_code_combinations.segment2%TYPE;
    l_vCodOrgInventario  bolinf.xxinv_int_ssp.inventory_org_code%TYPE;
    l_vCodSubinventario  bolinf.xxinv_int_ssp.subinventory_code%TYPE;
    l_vCodCentroCusto    bolinf.xxinv_int_ssp.center_cost_code%TYPE;
    l_nWipEntityID       wip_entities.wip_entity_id%type;
    --
  BEGIN
    fnd_file.put_line(fnd_file.output, '=====================');
    fnd_file.put_line(fnd_file.output, '==  INTERFACE SSP  ==');
    fnd_file.put_line(fnd_file.output, '=====================');
    fnd_file.put_line(fnd_file.output, NULL);
    fnd_file.put_line(fnd_file.output,'################# LOTES PROCESSADOS ###################');
    --
    -- Reorg Societ 25/08/2012
    -- Recuperando novo Organization
    g_nNewOrg   := XXFND_MIGRACAO_R12_PK.get_org_f( p_flag_varejo => 'XX', p_return_type => 'ORG_ID' );
    --
    g_vSegment1 := XXFND_MIGRACAO_R12_PK.get_inf_empresa_f( p_org_id              => g_nNewOrg
                                                          , p_org_name            => NULL
                                                          , p_registered_name     => NULL
                                                          , p_registration_number => NULL
                                                          , p_segment_bal         => NULL
                                                          , p_constante           => 'SEGMENT_BAL'
                                                          );
    --
    FOR r_transaction IN c_transaction LOOP
      --
      l_bError := TRUE;
      --
      BEGIN
        SELECT inventory_item_id
          INTO l_rMtiRec.inventory_item_id
          FROM mtl_system_items_b
         WHERE segment1 = r_transaction.segment1
           AND organization_id = p_organization_id;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Erro Localizar ID do Item= ' || SQLERRM);
          retcode := SQLCODE;
          errbuf  := SQLERRM;
          l_bError := FALSE;
      END;

      -- Recuperar dados separacao SSP
      BEGIN
        SELECT inventory_org_code
              ,subinventory_code
              ,center_cost_code
              ,paper_code
              ,reservation_number
              ,separation_number
          INTO l_vCodOrgInventario
              ,l_vCodSubinventario
              ,l_vCodCentroCusto
              ,l_vCodPapel
              ,l_rMtiRec.attribute14
              ,l_rMtiRec.attribute1
          FROM bolinf.xxinv_int_ssp  xiis
         WHERE xiis.separation_number  = to_number(r_transaction.separacao)
          AND  xiis.int_ssp_number = (select max(xint.int_ssp_number)
                                      from   bolinf.xxinv_int_ssp   xint
                                      where  xint.separation_number  = to_number(r_transaction.separacao)
                                      and    xint.status_code_reservation <> 'C');
      EXCEPTION
        WHEN OTHERS THEN
        --fnd_file.put_line(fnd_file.log,'Erro ao Buscar Informaç de CARAS = ' || SQLERRM);
          fnd_file.put_line(fnd_file.log,'Erro ao Buscar Informaç da SEPARACAO (PNF) = ' || SQLERRM); --alterado em 07/01/2013 Heitor
          retcode  := SQLCODE;
          errbuf   := SQLERRM;
          l_bError := FALSE;
      END;
      --

      IF r_transaction.tipo_transacao = '1_PNFC' THEN

        --CONSUMO
        l_vAttribute8                    := 'CON_PNFC_S_OS';
        l_rMtiRec.transfer_subinventory := NULL;
        l_rMtiRec.transfer_locator      := NULL;
        l_rMtiRec.transfer_organization := NULL;
        l_rMtiRec.transaction_quantity  := r_transaction.qtd_volume * (-1);
        l_rMtiRec.primary_quantity      := r_transaction.qtd_volume * (-1);
        --
        -- Buscando a conta contabil
        BEGIN
          --
/*
        IF (l_vCodOrgInventario = '2' AND l_vCodSubinventario  = '1' ) THEN
            -- TERCEIROS
            l_vSegment2 := '1140201006';
            --
            SELECT code_combination_id
              INTO l_rMtiRec.distribution_account_id
              FROM gl_code_combinations
              --Reorg Societ 25/08/2012
             WHERE segment1              = g_vsegment1
               AND segment2              = l_vSegment2
               AND segment4              = l_vCodCentroCusto
               AND jgzz_recon_flag       = 'Y'
               AND chart_of_accounts_id IN
                   (SELECT chart_of_accounts_id
                      FROM gl_ledgers
                     WHERE ledger_id IN (SELECT inf.org_information1
                      FROM apps.hr_organization_information  inf
                          ,apps.org_organization_definitions ood
                     WHERE inf.org_information_context = 'Accounting Information'
                       AND inf.organization_id         = ood.organization_id
                       AND ood.organization_id         = p_organization_id ));
            --
          ELSE
              SELECT attribute9
*/

            SELECT decode(l_vCodOrgInventario,'1', attribute9, attribute10)
              INTO l_vSegment2
              FROM mtl_transaction_types
             WHERE upper(attribute8) = l_vAttribute8;
            --
            SELECT code_combination_id
              INTO l_rMtiRec.distribution_account_id
              FROM gl_code_combinations
              --Reorg Societ 25/08/2012
             WHERE segment1              = g_vsegment1
               AND segment2              = l_vSegment2
               AND segment4              = l_vCodCentroCusto
               AND jgzz_recon_flag       = 'Y'
               AND chart_of_accounts_id IN
                   (SELECT chart_of_accounts_id
                      FROM gl_ledgers
                     WHERE ledger_id IN (SELECT inf.org_information1
                      FROM apps.hr_organization_information  inf
                          ,apps.org_organization_definitions ood
                     WHERE inf.org_information_context = 'Accounting Information'
                       AND inf.organization_id         = ood.organization_id
                       AND ood.organization_id         = p_organization_id ));
            --
--          END IF;
          --
        EXCEPTION

          WHEN no_data_found THEN
            BEGIN
              -- Caso nãache uma conta váda, criar uma nova
              l_rMtiRec.distribution_account_id := xxinv_carga_arq_txt_pk.xxinv_cria_conta_contabil_f(p_segment1   => g_vsegment1/*'001'*/--Reorg Societ 25/08/2012
                                                                                                     ,p_segment2   => l_vSegment2
                                                                                                     ,p_segment3   => '000'
                                                                                                     ,p_segment4   => l_vCodCentroCusto
                                                                                                     ,p_segment5   => '000000'
                                                                                                     ,p_segment6   => '000'
                                                                                                     ,p_segment7   => '000000'
                                                                                                     ,p_segment8   => '000000'
                                                                                                     ,p_segment9   => '000000'
                                                                                                     ,p_segment10  => '000000'
                                                                                                     ,p_organiz_id => p_organization_id);
              --
              IF l_rMtiRec.distribution_account_id = 0 THEN
                fnd_file.put_line(fnd_file.output,'Erro ao criar uma nova conta contál.');
                l_bError := FALSE;
              END IF;
              --
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.output,'Erro ao chamar a PKG de criaç de uma nova conta contál. ' || SQLERRM);
                l_bError := FALSE;
            END;

          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Erro ao Buscar Conta Contál=' || SQLERRM);
            fnd_file.put_line(fnd_file.log, 'Erro ao Buscar Conta Contál=' ||fnd_profile.VALUE('MFG_CHART_OF_ACCOUNTS_ID'));
            retcode  := SQLCODE;
            l_bError := FALSE;

        END;
        --

        IF l_rMtiRec.attribute14 <> '9999999999' THEN
           l_vAttribute8 := 'CON_PNFC';

            -- Apropria numero da OS
            BEGIN
              SELECT num_r
                INTO l_vNros
                FROM bolinf.xxinv_int_os xiis
               WHERE xiis.num_reserva   = r_transaction.reserva            --HY
                 AND xiis.cod_transacao = ( SELECT MAX(ai.cod_transacao)   --incluido para n¿o retornar mais de uma linha para a OS
                                              FROM bolinf.xxinv_int_os ai
                                             WHERE ai.num_reserva = r_transaction.reserva
                                           --  and   ai.cod_tipo_os <> 'A' --busca sempre a OS principal
                                           );
            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.output,'Erro ao pesquisar a OS -> ' || l_vNROS || '. ' || SQLERRM);
                l_bError := FALSE;
            END;
            --

            -- Pesquisando o nú da OP no WIP
            BEGIN
              SELECT wip_entity_id
                INTO l_nWipEntityID
                FROM apps.wip_entities
               WHERE wip_entity_name = l_vNROS
                 AND organization_id = p_organization_id; -- Alterado para Reorganizaç Societaria

            EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.output,'Erro ao pesquisar a OP para a OS ' || l_vNROS || '. ' || SQLERRM);
                l_bError := FALSE;
            END;
            --
            l_rMtiRec.transaction_source_id   := l_nWipEntityID;
            l_rMtiRec.transaction_source_name := l_vNROS;

        END IF;
        --

      ELSE
        --TRANSFERENCIA
        l_vAttribute8                   := 'TRF_GRAEXT';
        --
        --Subinventáo destino
        l_rMtiRec.transaction_quantity  := r_transaction.qtd_volume;
        l_rMtiRec.primary_quantity      := r_transaction.qtd_volume;
        l_rMtiRec.transfer_subinventory := p_subinventario;
        l_rMtiRec.transfer_locator      := p_location_id;
        --
      END IF;
      --

      -- Checando se o Lote éalido para a reserva
      IF lpad(l_vCodPapel, 8, '0') <> r_transaction.segment1 THEN
          fnd_file.put_line(fnd_file.output,'Lote invádo para a reserva= ' ||r_transaction.reserva|| '. ' ||'Lote ' || r_transaction.lote || '. ' || 'Item ' ||r_transaction.segment1);
          l_bError := FALSE;
          retcode := 1; -- Warning
      END IF;
      --

      --Quantidades e Locais
      BEGIN
        SELECT moq.subinventory_code
              ,moq.locator_id
              ,ood.organization_code
          INTO l_rMtiRec.subinventory_code
              ,l_rMtiRec.locator_id
              ,l_vOrganizationCode
          FROM org_organization_definitions ood
              ,mtl_onhand_quantities        moq
         WHERE moq.inventory_item_id         = l_rMtiRec.inventory_item_id
           AND moq.organization_id           = p_organization_id
           AND moq.lot_number                = r_transaction.lote
           AND ood.organization_id           = moq.organization_id
        HAVING SUM(moq.transaction_quantity) = r_transaction.qtd_volume
        GROUP BY moq.subinventory_code
                ,moq.locator_id
                ,ood.organization_code;
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Nãforam encontradas quantidades para esse volume. Verifique! ' || SQLERRM);
          fnd_file.put_line(fnd_file.log,'inventory_item_id =' || l_rMtiRec.inventory_item_id || 'r_transaction.sum_volume' || r_transaction.qtd_volume ||'Lote=' || r_transaction.lote);
          retcode := SQLCODE;
          l_bError := FALSE;
      END;
      --

      -- Validando se o volume estáo mesmo SubInventáo da Reserva
      IF (l_rMtiRec.subinventory_code != lpad(l_vCodSubinventario, 3, '0') OR l_vOrganizationCode != lpad(l_vCodOrgInventario, 3, '0')) THEN
        fnd_file.put_line(fnd_file.log,'O Volume ' || r_transaction.lote ||' nãencontrado no Subinventáo ' || lpad(l_vCodSubinventario, 3, '0') || ' indicado na Reserva. ');
        l_bError := FALSE;
        retcode  := 1; -- warning
      END IF;
      --

      -- Buscando o ID da Transaç
      BEGIN
        SELECT transaction_type_id
              ,transaction_action_id
              ,transaction_source_type_id
          INTO l_rMtiRec.transaction_type_id
              ,l_rMtiRec.transaction_action_id
              ,l_rMtiRec.transaction_source_type_id
          FROM mtl_transaction_types
         WHERE upper(attribute8) = l_vAttribute8;
        --
      EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log,'Erro ao Buscar Transaç= ' || l_vAttribute8 || '. ' || SQLERRM);
          retcode  := SQLCODE;
          l_bError := FALSE;
      END;
      --


      IF l_bError THEN

          --> Alterado apropriaç de sequence que estava logo no inicio da rotina (Heitor - 07/01/2013)
          -------------------------
          -- Recuperar ID transaç
          -------------------------
          BEGIN
            SELECT mtl_material_transactions_s.NEXTVAL
              INTO l_rMtiRec.transaction_header_id
              FROM dual;
            --
            SELECT mtl_material_transactions_s.NEXTVAL
              INTO l_rMtiRec.transaction_interface_id
              FROM dual;
            --
            SELECT inv.mtl_txn_request_headers_s.NEXTVAL
              INTO l_rMtiRec.source_header_id
              FROM dual;
            --
            SELECT inv.mtl_txn_request_lines_s.NEXTVAL
              INTO l_rMtiRec.source_line_id
              FROM dual;
            --
          EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'Erro ao obter valores para os IDs das Transaçs da Interface.' || SQLERRM);
              retcode  := SQLCODE;
              errbuf   := SQLERRM;
              --l_bError := FALSE;
          END;
          --

        l_rMtiRec.process_flag            := 1;
        l_rMtiRec.lock_flag               := NULL;
        l_rMtiRec.transaction_mode        := 3;
        l_rMtiRec.error_explanation       := NULL;
        l_rMtiRec.ERROR_CODE              := NULL;
        l_rMtiRec.transaction_uom         := 'KG';
        l_rMtiRec.organization_id         := p_organization_id;
        l_rMtiRec.transfer_organization   := p_organization_id;
        l_rMtiRec.transaction_reference   := l_vNROS; --Destino
        l_rMtiRec.created_by              := r_transaction.created_by_id;
        l_rMtiRec.creation_date           := SYSDATE;
        l_rMtiRec.last_updated_by         := r_transaction.created_by_id;
        l_rMtiRec.last_update_date        := SYSDATE;
        l_rMtiRec.transaction_date        := SYSDATE;
        l_rMtiRec.source_code             := 'INTERFACE MOV. PAPEL';
        l_rMtiRec.attribute2              := p_cnpj_fornec;
        l_rMtiRec.attribute4              := p_nf_remessa;
        l_rMtiRec.attribute5              := p_nf_serie;
        l_rMtiRec.attribute6              := p_nf_data;
        l_rMtiRec.attribute_category      := l_rMtiRec.transaction_type_id;
        --
        BEGIN
          INSERT INTO mtl_transactions_interface VALUES l_rMtiRec;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro insert into MTL_TRANSACTIONS_INTERFACE=' || SQLERRM);
            retcode  := SQLCODE;
            --l_bError := FALSE;
        END;
        --
        l_vLoteNumber := r_transaction.lote;
        --
        -- Atributos do Lote
        BEGIN
          SELECT DISTINCT c_attribute1
                         ,c_attribute4
                         ,n_attribute1
                         ,n_attribute2
            INTO l_rMtliRec.c_attribute1
                ,l_rMtliRec.c_attribute4
                ,l_rMtliRec.n_attribute1
                ,l_rMtliRec.n_attribute2
            FROM mtl_lot_numbers
           WHERE lot_number      = l_vLoteNumber
             AND organization_id = p_organization_id;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.output,'Erro ao recuperar attributos do Lote: ' ||l_vLoteNumber||'-'||sqlerrm);
        END;
        --
        l_rMtliRec.lot_number               := l_vLoteNumber;
        l_rMtliRec.transaction_interface_id := l_rMtiRec.transaction_interface_id;
        l_rMtliRec.transaction_quantity     := r_transaction.qtd_volume;
        l_rMtliRec.primary_quantity         := r_transaction.qtd_volume;
        l_rMtliRec.last_update_date         := SYSDATE;
        l_rMtliRec.last_updated_by          := r_transaction.created_by_id;
        l_rMtliRec.creation_date            := SYSDATE;
        l_rMtliRec.created_by               := r_transaction.created_by_id;
        l_rMtliRec.lot_expiration_date      := NULL;
        --
        BEGIN
          INSERT INTO mtl_transaction_lots_interface VALUES l_rMtliRec;
        EXCEPTION
          WHEN OTHERS THEN
            ROLLBACK;
            fnd_file.put_line(fnd_file.log,'Erro insert into MTL_TRANSACTIONS_INTERFACE=' || SQLERRM);
            retcode  := SQLCODE;
        END;
        --
        COMMIT;
        --

        begin
            l_bReturn := mtl_online_transaction_pub.process_online(l_rMtiRec.transaction_header_id
                                                                  ,l_nTimeout
                                                                  ,l_vErrorCode
                                                                  ,l_vErrorExplanation);
        exception
          when others then
              fnd_file.put_line(fnd_file.log, 'Erro ao processar Transaç na Interface.(exception) ' || sqlerrm);
              retcode := 1; -- warning
              l_vErrorCode := '1'; --forçcomo erro
        end;

        IF (TRIM(l_vErrorCode) IS NOT NULL) THEN
        --IF (l_vErrorCode IS NOT NULL) THEN
          fnd_file.put_line(fnd_file.log,'Erro ao processar Transaç na Interface=' || l_vErrorCode || '-' || l_vErrorExplanation);
          retcode := 1;
        ELSE
          fnd_file.put_line(fnd_file.output,'Nr Lote:' || l_vLoteNumber || ' Quantidade: ' || r_transaction.qtd_volume);
          l_nCountProc := l_nCountProc + 1;

          ---------------------------------------------------
          --Atualizar flag de Processado do Plano de Coleta--
          --alterado em 16/01/2013
          ---------------------------------------------------
          begin
              atualiza_flag_p(p_plan_id     => r_transaction.plan_id
                             ,p_lote_volume => l_vLoteNumber);
          exception
            when others then
              fnd_file.put_line(fnd_file.log,'Erro ao atualizar plano de coleta PNFs - Lote=> ' || l_vLoteNumber ||'-'||sqlerrm);
              retcode  := 1; -- warning
          end;
          --

        END IF;
        --
      ELSE
        retcode := 1; -- Termino com Warning
      END IF;
      --
    END LOOP r_transaction;
    --
    fnd_file.put_line(fnd_file.output,'-----------------------------------------------------');
    fnd_file.put_line(fnd_file.output,'###### VOLUMES PROCESSADOS: ' || l_nCountProc || ' #############');
    fnd_file.put_line(fnd_file.output,'################# FIM DO PROCESSO ###################');
    --
  END ssp_iface_p;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE atualiza_reserva_p(errbuf    IN OUT VARCHAR2
                              ,retcode   IN OUT NUMBER
                              ,p_nr_dias IN NUMBER) IS
    --
    CURSOR c_Trans IS(
      SELECT mmt.transaction_id
            ,mmt.transaction_reference nr_os
            ,msib.segment1             item
        FROM mtl_system_items_b        msib
            ,mtl_material_transactions mmt
       WHERE nvl(mmt.attribute14, '0')  = '0'
         AND mmt.transaction_action_id IN (1, 27)
         AND mmt.transaction_date      >= SYSDATE - p_nr_dias
         AND mmt.transaction_type_id   IN
             (SELECT mtt.transaction_type_id
                FROM mtl_txn_source_types  mts
                    ,mtl_transaction_types mtt
               WHERE mts.attribute1                 = 'S'
                 AND upper(mtt.attribute8)     NOT IN ('SOLIC_PROD')
                 AND mts.transaction_source_type_id = mtt.transaction_source_type_id)
         AND msib.inventory_item_id     = mmt.inventory_item_id
         AND msib.organization_id       = mmt.organization_id);
    --
    l_nNumReserva bolinf.xxinv_int_os.num_reserva%TYPE;
    --
  BEGIN
    --
    FOR r_Trans IN c_Trans LOOP
      BEGIN
        SELECT DISTINCT xiio.num_reserva
          INTO l_nNumReserva
          FROM bolinf.xxinv_int_os xiio
         WHERE to_char(xiio.num_r) = r_trans.nr_os
           AND xiio.num_reserva > 0
           AND xiio.cod_papel      = to_number(r_trans.item)         --HY
           AND xiio.cod_transacao  = ( SELECT MAX(ai.cod_transacao)  --incluido para n¿o retornar mais de uma linha para a OS
                                         FROM bolinf.xxinv_int_os ai
                                        WHERE to_char(ai.num_r) = r_trans.nr_os
                                        and   ai.cod_papel = to_number(r_trans.item)
                                     );
      EXCEPTION
        WHEN no_data_found THEN
          fnd_file.put_line(fnd_file.output,'Reserva nãencontrada para a OS ' || r_Trans.nr_os || ' - Item ' || r_Trans.item);
          l_nNumReserva := NULL;
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.output,'Erro ao localizar Reserva para a OS ' || r_Trans.nr_os || ' - Item ' || r_Trans.item || '. ' ||sqlerrm);
          errbuf  := SQLERRM;
          retcode := 1;
      END;
      --
      IF l_nNumReserva IS NOT NULL THEN
        BEGIN
          UPDATE mtl_material_transactions
             SET attribute14      = l_nNumReserva,
                 last_update_date = sysdate,
                 last_updated_by  = fnd_global.user_id
           WHERE transaction_id = r_Trans.transaction_id;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro ao atualizar o nú da Reserva na tabela MTL_MATERIAL_TRANSACTIONS.' || SQLERRM);
            errbuf  := SQLERRM;
            retcode  := 1; -- Warning
        END;
        --
        COMMIT;
        --
      END IF;
      --
    END LOOP;
    --
  END atualiza_reserva_p;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE gera_devolucao_p(errbuf            IN OUT VARCHAR2
                            ,retcode           IN OUT NUMBER
                            ,p_organization_id     IN NUMBER) IS
    --
    l_rMtiRec                mtl_transactions_interface%ROWTYPE;
    l_rMtliRec               mtl_transaction_lots_interface%ROWTYPE;
    l_nTimeout               NUMBER;
    l_vErrorCode             VARCHAR2(1000);
    l_vErrorExplanation      VARCHAR2(1000);
    l_bReturn                BOOLEAN;
    l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_bError                 BOOLEAN := TRUE;
    l_vLoteNumber            mtl_transaction_lots_interface.lot_number%TYPE;
    l_vAttribute9            mtl_transaction_types.attribute9%TYPE;
    l_vNumOS                 mtl_material_transactions.transaction_reference%TYPE;
    l_nCodCentroCusto        bolinf.xxinv_int_os.cod_centro_custo%TYPE;
    l_nCodeCombinationID     gl_code_combinations.code_combination_id%TYPE;
    l_vAttribute8            mtl_transaction_types.attribute8%TYPE;
    l_vAttribute14           mtl_material_transactions.attribute14%TYPE;
    l_vAttbte14              mtl_material_transactions.attribute14%TYPE;
    l_vBobInterrompida       VARCHAR2(10);
    l_vOSAssociada           VARCHAR2(10);
    l_nQtdTotalPapel         bolinf.xxinv_int_os.qtd_kg_papel_reserva%TYPE;
    l_nRowCount              NUMBER;
    l_nTotRows               NUMBER;
    l_vCodBarra              VARCHAR2(100);
    l_vTipoReg               VARCHAR2(10);
    l_vCAttribute2           mtl_lot_numbers.c_attribute2%TYPE;
    l_nOrganizOS             org_organization_definitions.organization_id%TYPE;
    l_vExisteDevprod         VARCHAR2(10);
    l_vLoteErro              VARCHAR2(100);
    l_nValid                 NUMBER := 0;
    l_vOsencerrada           NUMBER := 0;
    l_nCodEdicao             bolinf.xxinv_int_os.cod_edicao%type;
    l_vItem                  mtl_system_items_b.segment1%type;
    l_vNumOS_pesq            mtl_material_transactions.transaction_reference%TYPE;
    --
    --Criar Devoluç
    CURSOR c_transaction IS(
      SELECT qd.organization_id
            ,qd.lote || qd.id_volume lote
            ,qd.lote id_lote
            ,qd.id_volume
            ,qd.created_by_id
            ,qd.peso_atual qtd_volume
            ,qd.segment1 item
            ,qd.subinventario sub_destino
            ,qd.endereco
            ,qd.plan_id
            ,qd.aceita
        FROM q_d_devolucao_v qd
       WHERE nvl(qd.processado, 'N') = 'N');
    --
    -- Cursor para trazer as linhas da OS Associada
    CURSOR c_OSAssoc IS
      SELECT xiio.qtd_kg_papel_reserva
            ,xiio.num_reserva
            ,COUNT(*) over() tot_rows
            ,xiio.cod_edicao
            ,xiio.cod_centro_custo
            ,xiio.num_r
        FROM bolinf.xxinv_int_os xiio
       WHERE substr(xiio.num_r,1,7) = to_number(l_vNumOS) --alterado em 16/01/2013 - demanda 27800
       and   cod_papel = to_number(nvl(l_vItem,0)) --incluido em 14-01/2013 conforme GAN 27800
       and   xiio.qtd_kg_papel_reserva > 0;     --incluido em 14-01/2013 conforme GAN 27800
       --WHERE xiio.num_r = l_vNumOS;


    --
    l_rCur1Rec c_OSAssoc%ROWTYPE;
    --
    -- Cursor para totalizar as quantidades das reservas da OS Associada
    CURSOR c_TotReserv IS
      SELECT SUM(xiio.qtd_kg_papel_reserva)
        FROM bolinf.xxinv_int_os xiio
       WHERE substr(xiio.num_r,1,7) = to_number(l_vNumOS) --alterado em 16/01/2013 - demanda 27800
       and   xiio.qtd_kg_papel_reserva > 0
       and   cod_papel = to_number(nvl(l_vItem,0)) --incluido em 14-01/2013 conforme GAN 27800
       GROUP BY substr(num_r,1,7);
    --
    -- Cursor para trazer somente a linha principal da OS
    CURSOR c_LinhaOS IS
      SELECT xiio.*
            ,COUNT(*) over() tot_rows
        FROM bolinf.xxinv_int_os xiio
       WHERE xiio.num_r  = to_number(l_vNumOS)
         AND cod_tipo_os in ('P','C')
         and cod_papel = to_number(nvl(l_vItem,0)) --incluido em 07-06-2013 conforme GAN D-05379
         and qtd_kg_papel_reserva > 0
         ;
    --
    l_rCur2Rec c_LinhaOS%ROWTYPE;
    --
    --
    -- Cursor para trazer os registros duplicados e com erros de um determinado Lote
    cursor c_loteerro IS
      SELECT mti.transaction_interface_id
        FROM mtl_transaction_types          mtt
            ,mtl_transactions_interface     mti
            ,mtl_transaction_lots_interface mtli
       WHERE mtli.lot_number = l_vLoteErro
         AND mtli.transaction_interface_id !=
             (SELECT MAX(mtli.transaction_interface_id)
                FROM mtl_transaction_types          mtt
                    ,mtl_transactions_interface     mti
                    ,mtl_transaction_lots_interface mtli
               WHERE mtli.lot_number = l_vLoteErro
                 AND mti.transaction_interface_id = mtli.transaction_interface_id
                 AND mti.ERROR_CODE IS NOT NULL
                 AND mtt.transaction_type_id = mti.transaction_type_id
                 AND upper(mtt.attribute8) = l_vAttribute8)
         AND mti.transaction_interface_id = mtli.transaction_interface_id
         AND mti.ERROR_CODE IS NOT NULL
         AND mtt.transaction_type_id = mti.transaction_type_id
         AND upper(mtt.attribute8) = l_vAttribute8;
    --
    ----------------------------------------
  BEGIN
    fnd_file.put_line(fnd_file.output, '===================================');
    fnd_file.put_line(fnd_file.output, '==    TRANSFERÊCIA DEVOLUCAO    ==');
    fnd_file.put_line(fnd_file.output, '===================================');
    fnd_file.put_line(fnd_file.output, NULL);
    --
    -- Reorg Societ 25/08/2012
    -- Recuperando novo Organization
    g_nNewOrg   := XXFND_MIGRACAO_R12_PK.get_org_f( p_flag_varejo => 'XX', p_return_type => 'ORG_ID' );
    --
    g_vSegment1 := XXFND_MIGRACAO_R12_PK.get_inf_empresa_f( p_org_id              => g_nNewOrg
                                                          , p_org_name            => NULL
                                                          , p_registered_name     => NULL
                                                          , p_registration_number => NULL
                                                          , p_segment_bal         => NULL
                                                          , p_constante           => 'SEGMENT_BAL'
                                                          );
    --
    FOR r_transaction IN c_transaction LOOP
      --
      l_bError := TRUE;
      --
      IF  (r_transaction.organization_id IS NULL
        OR r_transaction.sub_destino     IS NULL
        OR r_transaction.endereco        IS NULL) THEN
        --
        fnd_file.put_line(fnd_file.output,'Lote: ' ||r_transaction.lote|| ' sem informaç de organizaç/subinv/endereç');
        retcode := 1; -- warning
        --
      ELSE
        ---
        BEGIN
          SELECT 'S'
            INTO l_vExisteDevprod
            FROM mtl_lot_numbers             mln
                ,mtl_transaction_lot_numbers mtln
                ,mtl_material_transactions   mmt
                ,mtl_transaction_types       mtt
           WHERE mln.lot_number           = r_transaction.lote
             AND mtln.lot_number          = mln.lot_number
             AND mtln.organization_id     = mln.organization_id
             AND mtln.inventory_item_id   = mln.inventory_item_id
             AND mtln.transaction_id      =
                 (SELECT MAX(transaction_id)
                    FROM mtl_transaction_lot_numbers
                   WHERE lot_number = mln.lot_number)
             AND mmt.transaction_id       = mtln.transaction_id
             AND mtt.transaction_type_id  = mmt.transaction_type_id
             AND upper(mtt.attribute8)   IN ('DEV_PROD', 'CON_PROD');
          --
        EXCEPTION
          WHEN no_data_found THEN
            fnd_file.put_line(fnd_file.log,'O volume ' ||r_transaction.lote|| ' ainda nãfoi devolvido.');
            l_vExisteDevprod := 'N';
            retcode          := 1; -- warning
            errbuf           := SQLERRM;
            l_bError         := FALSE;
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro ao checar se o volume ' ||r_transaction.lote|| ' jáoi devolvido. ' ||SQLERRM);
            retcode  := SQLCODE;
            errbuf   := SQLERRM;
            l_bError := FALSE;
        END;
        --
        --
        BEGIN
          SELECT inventory_item_id
                 ,segment1
            INTO l_rMtiRec.inventory_item_id
                ,l_vItem
            FROM mtl_system_items_b
           WHERE segment1        = r_transaction.item
             AND organization_id = r_transaction.organization_id;
          --
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Erro Localizar ID do Item= ' ||SQLERRM);
            retcode  := SQLCODE;
            errbuf   := SQLERRM;
            l_bError := FALSE;
        END;
        -- bobina nãinterrompida
        -- Recuperar a OS da ultima transacao do Lote
        BEGIN
          SELECT mmt.transaction_reference
                ,mmt.attribute14
            INTO l_vNumOS
                ,l_vAttribute14
            FROM mtl_lot_numbers             mln
                ,mtl_transaction_lot_numbers mtln
                ,mtl_material_transactions   mmt
           WHERE mln.lot_number         = r_transaction.lote
             AND mtln.lot_number        = mln.lot_number
             AND mtln.organization_id   = mln.organization_id
             AND mtln.inventory_item_id = mln.inventory_item_id
             AND mtln.transaction_id    =
                 (SELECT MAX(transaction_id)
                    FROM mtl_transaction_lot_numbers
                   WHERE lot_number = mln.lot_number)
             AND mmt.transaction_id     = mtln.transaction_id;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro ao Buscar a OS da ultima transaç do lote= ' ||SQLERRM);
            retcode  := SQLCODE;
            l_bError := FALSE;
        END;
        --
        l_vNumOs := substr(trim(l_vNumOs),1,7); --considera a OS principal caso o ultima transaç foi de OS associada

        -- Pesquisando a Organizaç da OS
        BEGIN
          SELECT organization_id
            INTO l_norganizos
            FROM org_organization_definitions ood
                ,bolinf.xxinv_int_os          xiio
           WHERE xiio.num_r            = l_vnumos
             AND ood.organization_code = lpad(xiio.cod_inv, 3, '0')      --HY
             AND xiio.cod_transacao    = ( SELECT MAX(ai.cod_transacao)  --incluido para n¿o retornar mais de uma linha para a OS
                                             FROM bolinf.xxinv_int_os ai
                                            WHERE ai.num_r = l_vnumos
                                              and ai.cod_papel = to_number(nvl(r_transaction.item,0))
                                          );
        EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line( fnd_file.output, 'Erro ao pesquisar a Organizaç da OS  ' ||l_vNumOS|| ' - ' ||SQLERRM );
            retcode  := SQLCODE;
            l_bError := FALSE;
        END;
        --
        -- Checando se a OS éssociada
        l_vOSAssociada := 'N';

        BEGIN
          SELECT 'S'
            INTO l_vOSAssociada
            FROM bolinf.xxinv_int_os          xiio
           WHERE substr(xiio.num_r,1,7) = l_vNumOS --alterado em 16/01/2013 - demanda 27800
           --WHERE xiio.num_r       = l_vNumOS
             AND xiio.cod_tipo_os = 'A'
           GROUP BY substr(xiio.num_r,1,7);
          --
        EXCEPTION
          WHEN no_data_found THEN
            l_vOSAssociada := 'N';
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.output,'Erro ao checar se a OS éssociada. ' || SQLERRM);
            retcode  := SQLCODE;
            l_bError := FALSE;
        END;
        --
        -- Checando se o status da bobina nãée Interrompido
        BEGIN
          SELECT 'S'
            INTO l_vBobInterrompida
            FROM mtl_lot_numbers
           WHERE lot_number         = r_transaction.lote
             AND organization_id    = l_nOrganizOS
             AND upper(attribute12) = 'INTERROMPIDO';
        EXCEPTION
          WHEN no_data_found THEN
            l_vBobInterrompida := 'N';
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log,'Erro ao checar se a bobina ' ||r_transaction.lote|| ' estánterrompida. ' ||SQLERRM);
            retcode  := SQLCODE;
            errbuf   := SQLERRM;
            l_bError := FALSE;
        END;
        --
        IF l_vBobInterrompida = 'S' THEN
          fnd_file.put_line(fnd_file.log,'A bobina ' ||r_transaction.lote|| ' nãpode ser processada pois estánterrompida.');
          retcode  := 1;
          errbuf   := SQLERRM;
          l_bError := FALSE;
        ELSE
          --
          IF l_bError THEN

            l_nCodEdicao := null;
            l_ncodcentrocusto := null;
            --
            IF l_vOSAssociada = 'S' THEN
              --- Totalizando as quantidades das Reservas
              OPEN c_TotReserv;
                FETCH c_TotReserv INTO l_nQtdTotalPapel;
              CLOSE c_TotReserv;
              --
              OPEN c_OSAssoc;
            ELSE
              OPEN c_LinhaOS;
            END IF;
            --
            LOOP
              -- Cursor
              IF l_vOSAssociada = 'S' THEN
                FETCH c_OSAssoc
                 INTO l_rCur1Rec;
                EXIT WHEN c_OSAssoc%NOTFOUND;
                --
                l_nRowCount := c_OSAssoc%ROWCOUNT;
                l_nTotRows  := l_rCur1Rec.tot_rows;
                l_vAttbte14 := l_rCur1Rec.num_reserva;
                l_nCodEdicao:= l_rCur1Rec.Cod_Edicao;
                l_ncodcentrocusto:=l_rCur1Rec.Cod_Centro_Custo;
                l_vNumOS_pesq :=  l_rCur1Rec.Num_r;
                --> se for ASSOCIADA , se for buscar OS + Cod_EDICAO
                --
              ELSE
                FETCH c_LinhaOS
                 INTO l_rCur2Rec;
                EXIT WHEN c_LinhaOS%NOTFOUND;
                --
                l_nRowCount := c_LinhaOS%ROWCOUNT;
                l_nTotRows  := l_rCur2Rec.tot_rows;
                l_vAttbte14 := l_rCur2Rec.Num_Reserva;
                l_nCodEdicao:= l_rCur2Rec.Cod_Edicao;
                l_ncodcentrocusto:=l_rCur2Rec.Cod_Centro_Custo;
                l_vNumOS_pesq := l_rCur2Rec.Num_r;
                --
              END IF;
              --

              FOR x IN 1 .. 2 LOOP
                -- 1 => CON_DEV / 2 => RET_DEV

                if l_nCodCentroCusto is null then
                    fnd_file.put_line(fnd_file.log,'Erro ao Buscar o Centro de Custo da OS=' || 'Valor Nulo');
                    retcode  := 1;
                    l_bError := FALSE;
                end if;

                ------------------------
                --Recuperar ID transaç
                ------------------------
                IF x = 1 THEN
                  l_vAttribute8 := 'CON_DEV'; --SAIDA DEV MAQ

                ELSE

                  l_vOsencerrada := 0;

                  begin
                      select count(*)
                        INTO l_vOsencerrada
                        from apps.wip_discrete_jobs_v
                       where wip_entity_name = l_vNumOS_pesq
                         and organization_id = l_nOrganizOS
--                       and status_type = 12;
                         and (status_type             = 12 or
                              to_char(SCHEDULED_START_DATE,'RRRRMM') < to_char(sysdate,'RRRRMM')--incluido demanda D-09747
                             );
                      --
                      IF l_vOsencerrada >= 1 THEN
                        l_vAttribute8 := 'RET_DEV_A';
                      ELSE
                        l_vAttribute8 := 'RET_DEV';
                      END IF;

                  exception when others then
                        fnd_file.put_line(fnd_file.log,'OP do WIP nãencontrada para a OS ' || l_vNumOS_pesq || l_nCodEdicao ||' - '||l_norganizos|| '. ' || SQLERRM);
                        l_bError := FALSE;
                        retcode  := 1; -- warning
                  end;

               END IF;
                --
                BEGIN
                  SELECT transaction_type_id
                        ,transaction_action_id
                        ,transaction_source_type_id
                        --,attribute9
                        ,decode(l_nOrganizOS,'583', attribute9, attribute10)
                    INTO l_rMtiRec.transaction_type_id
                        ,l_rMtiRec.transaction_action_id
                        ,l_rMtiRec.transaction_source_type_id
                        ,l_vAttribute9
                    FROM mtl_transaction_types
                   WHERE upper(attribute8) = l_vAttribute8;
                EXCEPTION
                  WHEN OTHERS THEN
                    fnd_file.put_line( fnd_file.log, 'Erro ao Buscar Transaç= ' || SQLERRM );
                    retcode  := SQLCODE;
                    l_bError := FALSE;
                END;
                --
                -- Recuperando o ID da Conta Contabil
                BEGIN
                  --
                  SELECT code_combination_id
                    INTO l_nCodeCombinationID
                    FROM gl_code_combinations
                   WHERE segment1              = g_vSegment1
                     AND segment2              = l_vAttribute9
                     AND segment4              = l_nCodCentroCusto
                     AND jgzz_recon_flag       = 'Y'
                     AND chart_of_accounts_id IN
                         (SELECT chart_of_accounts_id
                            FROM gl_ledgers
                           WHERE ledger_id IN (SELECT inf.org_information1
                            FROM apps.hr_organization_information  inf
                                ,apps.org_organization_definitions ood
                           WHERE inf.org_information_context = 'Accounting Information'
                             AND inf.organization_id         = ood.organization_id
                             AND ood.organization_id         = l_norganizos)); --p_organization_id));
                EXCEPTION
                  WHEN no_data_found THEN
                    --
                    BEGIN
                      -- Caso nãache uma conta váda, criar uma nova
                      l_nCodeCombinationID := xxinv_carga_arq_txt_pk.xxinv_cria_conta_contabil_f(p_segment1   => g_vsegment1/*'001'*/--Reorg Societ 25/08/2012
                                                                                                ,p_segment2   => l_vAttribute9
                                                                                                ,p_segment3   => '000'
                                                                                                ,p_segment4   => l_nCodCentroCusto
                                                                                                ,p_segment5   => '000000'
                                                                                                ,p_segment6   => '000'
                                                                                                ,p_segment7   => '000000'
                                                                                                ,p_segment8   => '000000'
                                                                                                ,p_segment9   => '000000'
                                                                                                ,p_segment10  => '000000'
                                                                                                ,p_organiz_id => l_norganizos); --p_organization_id);
                      --
                      IF l_nCodeCombinationID = 0 THEN
                        fnd_file.put_line(fnd_file.output,'Erro ao criar uma nova conta contál.');
                        l_bError := FALSE;
                        retcode  := 1;
                      END IF;
                      --
                    EXCEPTION
                      WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.output,'Erro ao chamar a PKG de criaç de uma nova conta contál. ' || SQLERRM);
                        l_bError := FALSE;
                        retcode := 1;
                    END;
                    --
                  WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.log,'Erro ao Buscar o ID da Conta Contabil=' || SQLERRM);
                    retcode := SQLCODE;
                    l_bError := FALSE;
                END;
                --
                -- Pesquisando o nú da OP no WIP

                --> se for ASSOCIADA , se for buscar OS + Cod_EDICAO no wip_entity_name
                IF l_vOSAssociada = 'S' THEN

                    BEGIN
                      SELECT wip_entity_id
                        INTO l_rMtiRec.transaction_source_id
                        FROM apps.wip_entities
                       WHERE wip_entity_name = l_vNumOS_pesq
                         AND organization_id = l_nOrganizOS;
                    EXCEPTION
                      WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.log,'OP do WIP nãencontrada para a OS ' || l_vNumOS_pesq || l_nCodEdicao ||' - '||l_norganizos|| '. ' || SQLERRM);
                        l_bError := FALSE;
                        retcode  := 1; -- warning
                    END;

                ELSE

                    BEGIN
                      SELECT wip_entity_id
                        INTO l_rMtiRec.transaction_source_id
                        FROM apps.wip_entities
                       WHERE wip_entity_name = l_vNumOS_pesq
                         AND organization_id = l_nOrganizOS;
                    EXCEPTION
                      WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.log,'OP do WIP nãencontrada para a OS ' || l_vNumOS_pesq ||' - '||l_norganizos|| '. ' || SQLERRM);
                        l_bError := FALSE;
                        retcode  := 1; -- warning
                    END;

                END IF;
                --
                -- Subinventáo Origem
                --
                IF x = 1 THEN
                  BEGIN
                    SELECT subinventory_code
                          ,locator_id
                      INTO l_rMtiRec.subinventory_code
                          ,l_rMtiRec.locator_id
                      FROM mtl_onhand_quantities
                     WHERE inventory_item_id = l_rMtiRec.inventory_item_id
                       AND organization_id   = l_nOrganizOS
                       AND lot_number        = r_transaction.lote
                       AND creation_date     =
                           (SELECT MIN(creation_date)
                              FROM mtl_onhand_quantities
                             WHERE inventory_item_id = l_rMtiRec.inventory_item_id
                               AND organization_id   = l_nOrganizOS
                               AND lot_number        = r_transaction.lote)
                     GROUP BY lot_number
                             ,subinventory_code
                             ,locator_id;
                  EXCEPTION
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.log,'Nãforam encontradas quantidades para esse volume. Verifique!= ' ||SQLERRM);
                      fnd_file.put_line(fnd_file.log,'inventory_item_id = '        ||l_rMtiRec.inventory_item_id||
                                                     'r_transaction.sum_volume = ' ||r_transaction.qtd_volume||
                                                     'Lote = '                     ||r_transaction.lote);
                      retcode  := SQLCODE;
                      l_bError := FALSE;
                  END;
                ELSE
                  --
                  l_rMtiRec.subinventory_code := r_transaction.sub_destino;
                  --
                  BEGIN
                    SELECT inventory_location_id
                      INTO l_rMtiRec.locator_id
                      FROM mtl_item_locations mil
                     WHERE mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3 || '.' ||
                           mil.segment4    = r_transaction.endereco
                       AND organization_id = l_nOrganizOS;
                  EXCEPTION
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.log,'Erro ao Buscar o Endereco do SubInventario= ' ||SQLERRM);
                      retcode  := SQLCODE;
                      l_bError := FALSE;
                  END;
                END IF;
                --Destino
                l_rMtiRec.transfer_subinventory := NULL;
                l_rMtiRec.transfer_locator      := NULL;
                --
                IF l_bError THEN
                  -- Excluindo registros duplicados e com erros da Interface do INV para as bobinas do Plano de Coletas
                  l_vLoteErro := r_transaction.lote;
                  --
                  FOR r_loteerro IN c_loteerro LOOP
                    --
                    BEGIN
                      DELETE FROM mtl_transactions_interface
                       WHERE transaction_interface_id = r_loteerro.transaction_interface_id;
                      --
                      DELETE FROM mtl_transaction_lots_interface
                       WHERE transaction_interface_id = r_loteerro.transaction_interface_id;
                      --
                    EXCEPTION
                      WHEN no_data_found THEN
                        fnd_file.put_line(fnd_file.log,'Registros duplicados ou com erros do lote ' || r_transaction.lote || ' nãforam encontrados para exclusã');
                      WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.log,'Erro ao excluir registros duplicados e com erros do lote ' || r_transaction.lote || ' - ' || SQLERRM);
                        retcode := 1; -- warning
                    END;
                    --
                  END LOOP;
                  --
                  COMMIT;
                  --
                  l_rMtiRec.process_flag      := 1;
                  l_rMtiRec.lock_flag         := NULL;
                  l_rMtiRec.transaction_mode  := 3;
                  l_rMtiRec.error_explanation := NULL;
                  l_rMtiRec.ERROR_CODE        := NULL;
                  l_rMtiRec.transaction_uom   := 'KG';
                  --
                  IF x = 1 THEN --SAIDA DEV MAQ
                    --
                    l_rMtiRec.attribute14           := NULL;

                    IF l_vOSAssociada = 'S' THEN
                      l_rMtiRec.transaction_quantity := (((l_rCur1Rec.qtd_kg_papel_reserva / l_nQtdTotalPapel) * r_transaction.qtd_volume) * -1);
                      l_rMtiRec.primary_quantity     := (((l_rCur1Rec.qtd_kg_papel_reserva / l_nQtdTotalPapel) * r_transaction.qtd_volume) * -1);
                    -- se for ASSOCIADA apropriar o campo transaction_reference com OS + Cod_edicao
                      l_rMtiRec.transaction_reference := l_vNumOS_pesq;
                    ELSE
                      l_rMtiRec.transaction_quantity := (r_transaction.qtd_volume * -1);
                      l_rMtiRec.primary_quantity     := (r_transaction.qtd_volume * -1);
                      l_rMtiRec.transaction_reference := l_vNumOS_pesq;
                    END IF;
                    --
                  ELSE
                    --
                    l_rMtiRec.attribute14           := l_vAttbte14;--l_vAttribute14;
                    l_rMtiRec.attribute_category    := l_rMtiRec.transaction_type_id;

                    IF l_vOSAssociada = 'S' THEN
                      l_rMtiRec.transaction_quantity := ((l_rCur1Rec.qtd_kg_papel_reserva / l_nQtdTotalPapel) * r_transaction.qtd_volume);
                      l_rMtiRec.primary_quantity     := ((l_rCur1Rec.qtd_kg_papel_reserva / l_nQtdTotalPapel) * r_transaction.qtd_volume);
                    -- se for ASSOCIADA apropriar o campo transaction_reference com OS + Cod_edicao
                      l_rMtiRec.transaction_reference := l_vNumOS_pesq;
                      l_rMtiRec.transaction_source_name := l_vNumOS_pesq;

                    ELSE
                      l_rMtiRec.transaction_quantity := r_transaction.qtd_volume;
                      l_rMtiRec.primary_quantity     := r_transaction.qtd_volume;
                      l_rMtiRec.transaction_reference := l_vNumOS_pesq;
                      l_rMtiRec.transaction_source_name := l_vNumOS_pesq;
                    END IF;
                    --
                  END IF;
                  --
                  l_rMtiRec.organization_id       := l_nOrganizOS;
                  l_rMtiRec.transfer_organization := l_nOrganizOS;
                  l_rMtiRec.created_by              := r_transaction.created_by_id;
                  l_rMtiRec.creation_date           := SYSDATE;
                  l_rMtiRec.last_updated_by         := r_transaction.created_by_id;
                  l_rMtiRec.last_update_date        := SYSDATE;
                  l_rMtiRec.transaction_date        := SYSDATE;
                  l_rMtiRec.source_code             := 'INTERFACE MOV. PAPEL';
                  l_rMtiRec.distribution_account_id := l_nCodeCombinationID;


                  -- -----------------------------------
                  -- Apropriaç dos sequences
                  -- -----------------------------------
                  BEGIN
                    SELECT mtl_material_transactions_s.NEXTVAL
                      INTO l_rMtiRec.transaction_header_id
                      FROM dual;
                    --
                    SELECT mtl_material_transactions_s.NEXTVAL
                      INTO l_rMtiRec.transaction_interface_id
                      FROM dual;
                    --
                    SELECT inv.mtl_txn_request_headers_s.NEXTVAL
                      INTO l_rMtiRec.source_header_id
                      FROM dual;
                    --
                    SELECT inv.mtl_txn_request_lines_s.NEXTVAL
                      INTO l_rMtiRec.source_line_id
                      FROM dual;
                    --
                  EXCEPTION
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.log, 'Erro ao obter valores para os IDs das Transaçs da Interface.' || SQLERRM);
                      retcode  := SQLCODE;
                      errbuf   := SQLERRM;
                      l_bError := FALSE;
                  END;

                  --
                  l_nValid := 0;
                  --
                  BEGIN
                    --
                    SELECT 1
                      INTO l_nValid
                      FROM mtl_transaction_lot_numbers mtln
                         , mtl_material_transactions   mmt
                     WHERE mmt.transaction_id        = mtln.transaction_id
                       AND mmt.transaction_type_id   = l_rMtiRec.transaction_type_id
                       AND mmt.transaction_reference = l_rMtiRec.transaction_reference
                       AND mmt.organization_id       = l_rMtiRec.Organization_Id
                       AND mtln.transaction_quantity = l_rMtiRec.transaction_quantity
                       and MMT.SUBINVENTORY_CODE     = r_transaction.sub_destino
                       and mmt.transaction_id        = ( select max (amtln.transaction_id )
                                                           from  mtl_transaction_lot_numbers amtln
                                                          where amtln.lot_number = r_transaction.lote );

                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      l_nValid := 0;
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.log,'Falha ao localizar a transaç.'||' - '|| SQLERRM);
                      l_nValid := 0;
                      retcode  := 1; -- warning
                  END;
                  --
                  IF l_nValid = 1 THEN
                    fnd_file.put_line(fnd_file.log,'Transaç ja existente.');
                    l_nValid := 0;
                    retcode  := 1; -- warning
                  ELSE
                    --
                    BEGIN
                      INSERT INTO mtl_transactions_interface VALUES l_rMtiRec;
                    EXCEPTION
                      WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.log,'Erro insert into MTL_TRANSACTIONS_INTERFACE= ' ||SQLERRM);
                        retcode  := SQLCODE;
                        l_bError := FALSE;
                    END;
                    --
                  END IF;
                  --
                  l_vLoteNumber := r_transaction.lote;
                  --
                  -- Checando se o lote jáxiste no sistema
                  BEGIN
                    SELECT DISTINCT c_attribute1
                                   ,c_attribute4
                                   ,n_attribute1
                                   ,n_attribute2
                      INTO l_rMtliRec.c_attribute1
                          ,l_rMtliRec.c_attribute4
                          ,l_rMtliRec.n_attribute1
                          ,l_rMtliRec.n_attribute2
                      FROM mtl_lot_numbers
                     WHERE lot_number = l_vLoteNumber
                       AND organization_id = l_nOrganizOS;
                  EXCEPTION
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.log,'Erro ao recuperar attributos do Lote: ' ||l_vLoteNumber);
                      retcode  := SQLCODE;
                      l_bError := FALSE;

                  END;
                  --
                  l_rMtliRec.lot_number := l_vLoteNumber;
                  --
                  IF x = 1 THEN
                    --
                    l_rMtliRec.transaction_interface_id := l_rMtiRec.transaction_interface_id;
                    --
                    IF l_vOSAssociada = 'S' THEN
                      l_rMtliRec.transaction_quantity := (((l_rCur1Rec.qtd_kg_papel_reserva / l_nQtdTotalPapel) * r_transaction.qtd_volume) * -1);
                    ELSE
                      l_rMtliRec.transaction_quantity := (r_transaction.qtd_volume * -1);
                    END IF;
                    --
                  ELSE
                    --
                    l_rMtliRec.transaction_interface_id := l_rMtiRec.transaction_interface_id;
                    --
                    IF l_vOSAssociada = 'S' THEN
                      l_rMtliRec.transaction_quantity := ((l_rCur1Rec.qtd_kg_papel_reserva / l_nQtdTotalPapel) * r_transaction.qtd_volume);
                    ELSE
                      l_rMtliRec.transaction_quantity := r_transaction.qtd_volume;
                    END IF;
                    --
                  END IF;
                  --
                  l_rMtliRec.primary_quantity    := r_transaction.qtd_volume;
                  l_rMtliRec.last_update_date    := SYSDATE;
                  l_rMtliRec.last_updated_by     := r_transaction.created_by_id;
                  l_rMtliRec.creation_date       := SYSDATE;
                  l_rMtliRec.created_by          := r_transaction.created_by_id;
                  l_rMtliRec.lot_expiration_date := NULL;
                  --
                  l_nValid := 0;
                  --
                  BEGIN
                    --
                    SELECT 1
                      INTO l_nValid
                      FROM mtl_transaction_lot_numbers mtln
                         , mtl_material_transactions   mmt
                     WHERE mmt.transaction_id        = mtln.transaction_id
                       AND mmt.transaction_type_id   = l_rMtiRec.transaction_type_id
                       AND mmt.transaction_reference = l_rMtiRec.transaction_reference
                       AND mmt.organization_id       = l_rMtiRec.Organization_Id
                       AND mtln.transaction_quantity = l_rMtiRec.transaction_quantity
                       and MMT.SUBINVENTORY_CODE     = r_transaction.sub_destino
                       and mmt.transaction_id        = (select max (amtln.transaction_id )
                                                          from  mtl_transaction_lot_numbers amtln
                                                         where amtln.lot_number = r_transaction.lote);
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      l_nValid := 0;
                    WHEN OTHERS THEN
                      fnd_file.put_line(fnd_file.log,'Falha ao localizar a transaç.'||' - '|| SQLERRM);
                      l_nValid := 0;
                      retcode  := 1; -- warning
                  END;
                  --
                  IF l_nValid = 1 THEN
                    fnd_file.put_line(fnd_file.log,'Transaç ja existente.');
                    l_nValid := 0;
                    retcode  := 1; -- warning
                  ELSE
                    --
                    BEGIN
                      INSERT INTO mtl_transaction_lots_interface VALUES l_rMtliRec;
                    EXCEPTION
                      WHEN OTHERS THEN
                        ROLLBACK;
                        fnd_file.put_line(fnd_file.log,'Erro ao incluir registro na tabela: MTL_TRANSACTION_LOTS_INTERFACE ' ||SQLERRM);
                        retcode := SQLCODE;
                        l_bError := FALSE;
                    END;
                    --
                  END IF;
                  --
                  COMMIT;
                  --

                  begin
                      l_bReturn := mtl_online_transaction_pub.process_online(l_rMtiRec.transaction_header_id
                                                                            ,l_nTimeout
                                                                            ,l_vErrorCode
                                                                            ,l_vErrorExplanation);
                  exception
                    when others then
                        fnd_file.put_line(fnd_file.log, 'Erro ao processar Transaç na Interface.(exception) ' || sqlerrm);
                        l_vErrorCode := '1'; --forçcomo erro
                        retcode := 1;
                  end;

                  IF (TRIM(l_vErrorCode) IS NOT NULL) THEN
                  --IF (l_vErrorCode IS NOT NULL) THEN
                    fnd_file.put_line(fnd_file.log,'Erro ao processar Transaç na Interface= ' ||l_vErrorCode || '-' || l_vErrorExplanation);
                    retcode := 1;
                  ELSE
                    fnd_file.put_line(fnd_file.log, 'Processado com Sucesso.');
                    ---------------------------------------------------
                    --Atualizar flag de Processado do Plano de Coleta
                    ---------------------------------------------------
                    fnd_file.put_line(fnd_file.log, 'Atualizando Status do Processo');
                    --
                    begin
                        atualiza_flag_p(p_plan_id     => r_transaction.plan_id
                                       ,p_lote_volume => r_transaction.lote);
                    exception
                      when others then
                        fnd_file.put_line(fnd_file.log,'Erro ao atualizar plano de coleta Devolucao - Lote=> ' || r_transaction.lote ||'-'||sqlerrm);
                        retcode  := 1; -- warning
                    end;

                    l_vCAttribute2 := NULL;
                    --
                    BEGIN
                      SELECT c_attribute2
                        INTO l_vCAttribute2
                        FROM mtl_lot_numbers
                       WHERE lot_number      = r_transaction.lote
                         AND organization_id = l_nOrganizOS;
                    EXCEPTION
                      WHEN OTHERS THEN
                        fnd_file.put_line(fnd_file.output,'Erro ao checar se o Lote ' ||r_transaction.lote || ' tem avaria. ' || SQLERRM);
                        retcode := 1; -- Warning
                    END;
                    --
                    IF (x = 2 AND l_nRowCount = l_nTotRows ) THEN
                      -- DEV_RET e ultimo registro do Cursor
                      dbms_lock.sleep(5); -- pausa de 5 segundos para que a interface do INV popule todas as tabelas antes de enviar o XML
                      -- Chamada da PKG de impressãde etiquetas
                      IF l_vCAttribute2 IS NOT NULL THEN
                        l_vTipoReg := 'F';
                      ELSE
                        l_vTipoReg := 'D';
                      END IF;
                      --

                      xxinv_imprime_etiqueta_pk.start_print_p(l_vTipoReg
                                                             ,NULL
                                                             ,r_transaction.id_lote
                                                             ,r_transaction.id_volume
                                                             ,r_transaction.qtd_volume
                                                             ,NULL);
                      --
                      fnd_file.put_line(fnd_file.log,'ID da Transaç para chamada do XML: ' ||l_rMtiRec.transaction_header_id);
                      --
                      l_vCodBarra := ']C1400' || r_transaction.id_lote || '!3100' || lpad(r_transaction.qtd_volume, 6, '0') || '21' || r_transaction.id_volume;
                      --
                      -----------------------------
                      --Chamada PKG de envio do XML
                      -----------------------------
                      begin
                          bolinf.xxinv_exporta_xml_metrics_pk.gera_arq_xml_transacao_p(errbuf
                                                                                      ,retcode
                                                                                      ,l_rMtiRec.transaction_header_id
                                                                                      ,l_vCodBarra);
                      exception
                        when others then
                          fnd_file.put_line(fnd_file.output,'Erro no envio do XML -> ID->  '
                                                          || l_rMtiRec.transaction_header_id
                                                          || ' CodBarra-> '  || l_vCodBarra
                                                          || 'Erro-> '
                                                          || SQLERRM);
                          retcode := 1; -- Warning
                      end;
                      --
                    END IF;
                    --
                  END IF;
                  --
                END IF;
                --
              END LOOP x;
              --
            END LOOP; -- cursor
            --
            IF l_vOSAssociada = 'S' THEN
              CLOSE c_OSAssoc;
            ELSE
              CLOSE c_LinhaOS;
            END IF;
            --
          END IF;
          --
        END IF; -- l_vBobInterrompida = 'S'
        --
      END IF; -- r_organization_id or r_sub_destino is null or r_endereco is null
      --
    END LOOP r_transaction;
    --

    -- Debug adicionado
    IF (l_vDebug = 1) THEN
      fnd_file.put_line(fnd_file.log,'Fim da rotina -> RETCODE = ' || retcode);
      --inv_trx_util_pub.trace('Valor do parametro RETCODE:' || retcode,'XXINV_PAPER_LOT_PK',4);
    END IF;

    -- incluido em 28/11 conforme demanda 27422 - ERP-INV
    begin
          reprocessa_xml;
    exception
        when others then
        fnd_file.put_line(fnd_file.output,'Erro ao chamar procedimento de reenvio dos XML para interface com MCB -> ' || SQLERRM);
    end;

  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar plano de coleta de Devolucao. ' || SQLERRM);
        --raise_application_error(-20001,'Erro ao processar plano de coleta de separacao. ' || SQLERRM);

  END gera_devolucao_p;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE atualiza_flag_p(p_plan_id     IN NUMBER
                           ,p_lote_volume IN VARCHAR2) IS
    --
    l_vLote                  qa_results.character3%TYPE;
    l_vVolume                qa_results.character9%TYPE;
    l_vProcessado            qa_results.character9%TYPE;
    l_vUpdate                VARCHAR2(2000);
    --l_nCount                 NUMBER;
    --
  BEGIN
    --
    BEGIN
        SELECT result_column_name
          INTO l_vLote
          FROM qa_plan_chars
         WHERE plan_id       = p_plan_id
           AND upper(prompt) = 'LOTE'
           AND enabled_flag  = 1;
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Coluna Lote NãEncontrada no Plano de Coleta. ' || SQLERRM);
    END;
    --
    BEGIN
      SELECT result_column_name
        INTO l_vVolume
        FROM qa_plan_chars
       WHERE plan_id = p_plan_id
         AND (upper(prompt) = 'VOLUME'
          OR  upper(prompt) = 'ID VOLUME')
         AND enabled_flag   = 1;
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Coluna Volume NãEncontrada no Plano de Coleta. ' || SQLERRM);
    END;
    --
    BEGIN
      SELECT result_column_name
        INTO l_vProcessado
        FROM qa_plan_chars
       WHERE plan_id       = p_plan_id
         AND upper(prompt) = 'PROCESSADO'
         AND enabled_flag  = 1;
      --
    EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log,'Coluna Flag Processado NãEncontrada no Plano de Coleta.' ||SQLERRM);
    END;
    --
    l_vUpdate := ('UPDATE qa_results SET ' || l_vProcessado || ' = ''S'' WHERE plan_id = ' ||
                  p_plan_id || ' AND ' || l_vLote || '||' || l_vVolume || ' = ' || '''' ||
                  p_lote_volume || '''');
    --
    EXECUTE IMMEDIATE (l_vUpdate);
    --
    --l_nCount := SQL%ROWCOUNT;
    --
    COMMIT;
    --
  END atualiza_flag_p;
  --
  -------------------------------------------------------------------------------------------------
  PROCEDURE reprocessa_xml  IS

    --Busca XML com erro no envio para interface com legado MCB (Metrics)
    CURSOR c_xml_errors IS
      SELECT rm.contexto
            ,rm.transaction_set_id
            ,rm.codigo_barras
        FROM bolinf.xxinv_retorno_ws_metrics rm
       WHERE rm.status = 'Erro'
       and   rm.CREATION_DATE > sysdate - 15
       and   rm.transaction_set_id is not null
       and   rm.codigo_barras is not null
       ;

  errbuf  varchar2(1000);
  retcode number;

  BEGIN

    FOR r_transaction IN c_xml_errors LOOP

        if r_transaction.contexto = 'STK_VL' then --> plano de coleta separacao
            begin
              bolinf.xxinv_exporta_xml_metrics_pk.gera_arq_xml_picking_p  (errbuf
                                                                          ,retcode
                                                                          ,r_transaction.transaction_set_id
                                                                          ,r_transaction.codigo_barras);
           exception
              when others then
                fnd_file.put_line(fnd_file.output,'Erro ao re-enviar XML separaç para MCB. ' || SQLERRM);
                raise_application_error(-20001,'Erro ao re-enviar XML separaç para MCB. ' || SQLERRM);
           end;

        end if;


        if r_transaction.contexto = 'STK_VT' then --> plano de coleta devoluç
            begin
              bolinf.xxinv_exporta_xml_metrics_pk.gera_arq_xml_transacao_p(errbuf
                                                                          ,retcode
                                                                          ,r_transaction.transaction_set_id
                                                                          ,r_transaction.codigo_barras);
           exception
              when others then
                fnd_file.put_line(fnd_file.output,'Erro ao re-enviar XML transacao para MCB. ' || SQLERRM);
                raise_application_error(-20001,'Erro ao re-enviar XML transacao para MCB. ' || SQLERRM);
           end;

        end if;


    END LOOP r_transaction;


  EXCEPTION
      when others then
        fnd_file.put_line(fnd_file.output,'Erro ao re-enviar XML para interface com legado MCB. ' || SQLERRM);
        raise_application_error(-20001,'Erro ao re-enviar XML para interface com legado MCB. ' || SQLERRM);

  END reprocessa_xml;

  -------------------------------------------------------------------------------------------------
  PROCEDURE gera_lst_picking_p (errbuf                IN OUT VARCHAR2
                               ,retcode               IN OUT NUMBER
                               ,p_organization_id     IN NUMBER) IS

    l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_vRegistro              varchar2(1000);

    --Lista Picking
    CURSOR c_picking IS
            select
                   ood.organization_code             ORG
            ,      mln.attribute12                   TpServ
            ,      mmt.transaction_set_ID            SET_ID
            ,      mmt.transaction_id                Trans_ID
            ,      mmt.transaction_date              DATA
            --,      g.segment1 || '.' ||
            --       g.segment2 || '.' ||
            --       g.segment3 || '.' ||
            --       g.segment4 || '.' ||
            --       g.segment5                        as CONTA_CONTABIL
            ,      mmt.transaction_reference         OS
            ,      os.dsc_revista                    REVISTA
            ,      mmt.attribute14                   RESERVA
            ,      msi.segment1                      PAPEL
            ,      moqd.primary_transaction_quantity QTDE
            ,      moqd.subinventory_code            SUBINV
            ,      moqd.lot_number                   VOLUME
            ,      '''' || to_char(moqd.lot_number) || ''',' as ID_Metrics
            ,      CASE WHEN moqd.primary_transaction_quantity < 1000 THEN
                             ']C1400' || lpad(moqd.lot_number,6,'0') || '!31' || '00000' || moqd.primary_transaction_quantity || '21' || substr(moqd.lot_number,7,20)
                        ELSE ']C1400' || lpad(moqd.lot_number,6,'0') || '!31' || '0000' || moqd.primary_transaction_quantity || '21' || substr(moqd.lot_number,7,20)
                   END as CodBarras
            ,      OS.COD_CENTRO_CUSTO
            ,      case
                     when os.dsc_revista='Caras' then 'CARAS'
                      When os.dsc_revista='COSMÉICOS' then 'AVON'
                      When os.dsc_revista='Moda & Casa' then 'AVON'
                      When os.dsc_revista='LUCROS & NOVIDADES' then 'AVON'
                      When os.dsc_revista='TABLÓDE CARREFOUR' then 'Carrefour'
                      When os.dsc_revista='TATUAPÉESP. FESTAS' then 'Comerciais'
                      When os.dsc_revista='REVISTA DO TATUAPÉ then 'Comerciais'
                      When os.dsc_revista='Izunome' then 'Comerciais'
                      When os.dsc_revista='Supl. - Cia do Livro - Trib.' then 'Comerciais'
                      When os.dsc_revista='ÁICA PNLD' then 'Livros'
                      When os.dsc_revista='SCIPIONE PNLD' then 'Livros'
                      When os.dsc_revista='PIAUÍ then 'Comerciais'
                      Else 'Abril'
                   end as Tipo
            from apps.mtl_lot_numbers mln
                ,apps.mtl_onhand_quantities_detail moqd
                ,apps.org_organization_definitions ood
                ,apps.mtl_system_items   msi
                ,apps.mtl_material_transactions mmt
              --,gl_code_combinations g
               ,(SELECT distinct num_r, num_reserva, dsc_revista, cod_centro_custo
                   from bolinf.xxinv_int_os) OS
            where ood.organization_id = mmt.organization_id
            --and   g.code_combination_id (+) = MMT.DISTRIBUTION_ACCOUNT_ID
            and   moqd.organization_id    = msi.organization_id
            and   moqd.inventory_item_id  = msi.inventory_item_id
            and   to_char(os.num_r(+))       = to_char(mmt.transaction_reference)
            and   os.num_reserva          (+)= mmt.attribute14
            and   moqd.subinventory_code IN (SELECT lookup_code
                                      FROM fnd_lookup_values
                                     WHERE lookup_type = 'ABRL_INV_MAQUINA_GRAFICA'
                                       AND LANGUAGE    = 'PTB')
            and   mmt.transaction_id      = moqd.update_transaction_id
            --and   ood.organization_code    not in ('01A','02A')
            and   ood.organization_code    in ('001','002')
            --and   transaction_date <= sysdate - 60
            AND   mln.lot_number               = moqd.lot_number
            AND   mln.organization_id          = ood.organization_id
            AND   msi.primary_uom_code         ='KG'
            and   mln.creation_date =(select max(bb.creation_date)
                                        FROM apps.mtl_lot_numbers bb
                                       WHERE lot_number = moqd.lot_number
                                         AND organization_id = ood.organization_id)
            order by mmt.transaction_date
                    ,mmt.transaction_reference
                    ,moqd.subinventory_code
                    ,msi.segment1;
    --

    ----------------------------------------
  BEGIN
    l_vRegistro := 'ORG;TPSERV;SET_ID;TRANS_ID;DATA;OS;REVISTA;RESERVA;PAPEL;QTDE;SUBINV;VOLUME;ID_METRICS;CODBARRAS;COD_CENTRO_CUSTO;TIPO';

    fnd_file.put_line(fnd_file.output,l_vRegistro);

    --
    FOR r_picking IN c_picking
      LOOP
          l_vRegistro :=  r_picking.ORG                || ';' ||
                          r_picking.TPSERV             || ';' ||
                          r_picking.SET_ID             || ';' ||
                          r_picking.TRANS_ID           || ';' ||
                          r_picking.DATA               || ';' ||
                          r_picking.OS                 || ';' ||
                          r_picking.REVISTA            || ';' ||
                          r_picking.RESERVA            || ';' ||
                          r_picking.PAPEL              || ';' ||
                          r_picking.QTDE               || ';' ||
                          r_picking.SUBINV             || ';' ||
                          r_picking.VOLUME             || ';' ||
                          r_picking.ID_METRICS         || ';' ||
                          r_picking.CODBARRAS          || ';' ||
                          r_picking.COD_CENTRO_CUSTO   || ';' ||
                          r_picking.TIPO;

          fnd_file.put_line(fnd_file.output,l_vRegistro);
   END LOOP r_transaction;


  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de picking. ' || SQLERRM);

  END gera_lst_picking_p;
  -------------------------------------------------------------------------------------------------
  PROCEDURE gera_lst_ossemres_p(errbuf            IN OUT VARCHAR2
                           ,retcode           IN OUT NUMBER
                           ,p_nr_dias         IN NUMBER) IS

    l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_vRegistro              varchar2(1000);

    --Lista OS sem Reservas
    CURSOR c_osemres IS
          SELECT   SUBSTR(mmt.transaction_reference,1,7)  nr_os
                  ,ai.cod_centro_custo
                  ,ai.dsc_revista dsc_revista
                  ,ai.num_edicao
                  ,msib.segment1             cod_papel_corp
                  ,sum(mmt.TRANSACTION_QUANTITY)*-1 QTDE
                  ,max(mmt.last_update_date)dt_util
              FROM apps.mtl_system_items_b        msib
                  ,apps.mtl_material_transactions mmt
                  ,apps.mtl_transaction_types mtt
                  ,bolinf.xxinv_int_os ai
             WHERE nvl(mmt.attribute14, '0')  = '0'
               AND mmt.transaction_action_id IN (1, 27)
               AND mmt.transaction_date      >= SYSDATE - p_nr_dias
               and mmt.transaction_type_id = mtt.transaction_type_id
               AND upper(mtt.attribute8)     = 'CON_PROD'
               AND msib.inventory_item_id     = mmt.inventory_item_id
               AND msib.organization_id       = mmt.organization_id
               and to_char(ai.num_r)          = mmt.transaction_reference
               and ai.cod_papel (+)           = to_number(msib.segment1)
          GROUP BY SUBSTR(mmt.transaction_reference,1,7)
                  ,ai.cod_centro_custo
                  ,ai.dsc_revista
                  ,ai.num_edicao
                  ,msib.segment1
          order by max(mmt.last_update_date);
    --
    ----------------------------------------
  BEGIN
    l_vRegistro := 'RELATORIO DE OS SEM RESERVAS - ' || SYSDATE || ';';
    fnd_file.put_line(fnd_file.output,l_vRegistro);

    l_vRegistro := 'NR_OS;C_CUSTO;DSC_REVISTA;EDICAO;COD_PAPEL_CORP;QTDE;DT_CONSUMO';
    fnd_file.put_line(fnd_file.output,l_vRegistro);

    --
    FOR r_osemres IN c_osemres
      LOOP
          l_vRegistro :=  r_osemres.nr_os                || ';' ||
                          r_osemres.cod_centro_custo     || ';' ||
                          r_osemres.dsc_revista          || ';' ||
                          r_osemres.num_edicao           || ';' ||
                          r_osemres.cod_papel_corp       || ';' ||
                          r_osemres.QTDE                 || ';' ||
                          r_osemres.dt_util;

          fnd_file.put_line(fnd_file.output,l_vRegistro);
   END LOOP;

  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de ossemres. ' || SQLERRM);

  END gera_lst_ossemres_p;
  --

  PROCEDURE gera_lst_ecs_p (errbuf            IN OUT VARCHAR2
                       ,retcode           IN OUT NUMBER
                       ,p_date            IN VARCHAR2 DEFAULT NULL
                       ,p_origem          IN VARCHAR2 DEFAULT NULL) IS

    --l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_vRegistro        varchar2(1000);
    l_dData_inicio     DATE;
    l_dData_final      DATE;
    l_dData_reorg      DATE := to_date('01-10-12', 'dd-mm-yy');

    --relatorio de entrada consumo e saldo
    CURSOR c_recs IS
                    select          ap.origem
                                   ,ap.item_ssp
                                   ,ap.tipo_papel
                                   ,ap.empresa
                                   ,ap.org_id
                                   ,sum(ap.sld_inicial) sld_inicial
                                   ,case when sum(ap.entrada)> 0 then
                                      sum(ap.entrada)
                                   else
                                      0
                                   end entrada
                                   --,sum(ap.entrada)     entrada
                                   ,sum(ap.consumo)     consumo
                                   ,sum(ap.sld_final)   sld_final
                                   ,sum(ap.segregado)   segregado
                                   ,sum(ap.rms) rms
                                   ,sum(ap.dms) dms
                                   ,sum(ap.pnfs) pnfs
                    from (select
                                    xb.origem
                                   ,xb.item_ssp
                                   ,xb.tipo_papel
                                   ,case when xb.org_id <> 604 then
                                      xb.empresa
                                   else
                                      'PAPEL - CARAS'
                                      --i.description
                                   end empresa
                                   --,xb.empresa
                                   ,xb.org_id
                                   ,sum(xb.sld_inicial) sld_inicial
                                -- ,sum(xb.nrs) entrada
                                   ,(sum(xb.sld_inicial) - ( (sum(xb.rms)+sum(xb.pnfs)) - sum(xb.dms) ) - sum(xb.sld_final)) *-1 entrada
                                -- ,sum(xb.sld_inicial) + sum(xb.nrs) - sum(xb.sld_final) consumo
                                   ,sum(xb.rms) - sum(xb.dms) consumo
                                   ,sum(xb.sld_final) sld_final
                                   ,sum(xb.segregado) segregado
                                   ,sum(xb.rms) rms
                                   ,sum(xb.dms) dms
                                   ,sum(xb.pnfs) pnfs
                            from   (select
                                                    b.origem
                                                   ,a.item_ssp
                                                   ,b.tipo_papel
                                                   ,a.empresa
                                                   ,a.org_id
                                                   ,sum(a.sld_inicial) sld_inicial
                                                   ,sum(a.nrs) entrada
                                                   ,(sum(a.sld_inicial) - ( (sum(a.rms)+sum(a.pnfs)) - sum(a.dms) ) - sum(a.sld_final)) *-1 entrada
                                                   --,sum(a.sld_inicial) + sum(a.nrs) - sum(a.sld_final) consumo
                                                   ,sum(a.rms) - sum(a.dms) consumo
                                                   ,sum(a.sld_final) sld_final
                                                   ,sum(a.segregado) segregado
                                                   ,sum(a.rms) rms
                                                   ,sum(a.dms) dms
                                                   ,sum(a.pnfs) pnfs
                                                   ,sum(a.nrs) nrs
                                                   ,a.lot_number
                                            from (
                                                  select item
                                                         ,case when substr(item_ssp,1,1) = '0' then
                                                              substr(item_ssp,3,2)
                                                          else
                                                              substr(item_ssp,2,2)
                                                          end item_ssp
                                                         ,empresa
                                                         ,org_id
                                                         ,sum(sld_inicial) sld_inicial
                                                         ,sum(nrs)     nrs
                                                         ,sum(rms)    rms
                                                         ,sum(dms)    dms
                                                         ,sum(pnfs)   pnfs
                                                         ,sum(outros) outros
                                                         ,sum(sld_final) sld_final
                                                         ,sum(segregado) segregado
                                                         ,lot_number
                                                    from (SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,sum(mtln.PRIMARY_QUANTITY) sld_inicial
                                                                ,0 nrs
                                                                ,0 rms
                                                                ,0 dms
                                                                ,0 pnfs
                                                                ,0 outros
                                                                ,0 sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                              FROM apps.mtl_transaction_types mtt
                                                                  ,apps.mtl_material_transactions mmt
                                                                  ,apps.mtl_transaction_lot_numbers mtln
                                                                  ,apps.mtl_system_items_b       msib
                                                                  ,apps.org_organization_definitions ood
                                                                  ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                             AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                             and mmt.inventory_item_id    = msib.inventory_item_id
                                                             and mmt.organization_id      = msib.organization_id
                                                             AND mmt.transaction_id       = mtln.transaction_id
                                                             and mmt.transaction_type_id  = mtt.transaction_type_id
                                                             and ood.organization_id = mmt.organization_id
                                                             and mmt.transaction_date  <= l_dData_inicio
                                                             --and ood.organization_id in (583,604,585,105,192,584,605)
                                                             and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                          group by  msib.description
                                                                ,msib.segment1
                                                                ,mcr.cross_reference
                                                                ,ood.organization_name
                                                                ,ood.organization_id
                                                                ,mtln.lot_number

                                                          union

                                                        SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,0 nrs
                                                                ,0 rms
                                                                ,0 dms
                                                                ,0 pnfs
                                                                ,0 outros
                                                                ,sum(mtln.PRIMARY_QUANTITY) sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                              FROM apps.mtl_transaction_types mtt
                                                                  ,apps.mtl_material_transactions mmt
                                                                  ,apps.mtl_transaction_lot_numbers mtln
                                                                  ,apps.mtl_system_items_b       msib
                                                                  ,apps.org_organization_definitions ood
                                                                  ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                             AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                             and mmt.inventory_item_id    = msib.inventory_item_id
                                                             and mmt.organization_id      = msib.organization_id
                                                             AND mmt.transaction_id       = mtln.transaction_id
                                                             and mmt.transaction_type_id  = mtt.transaction_type_id
                                                             and ood.organization_id = mmt.organization_id
                                                             and mmt.transaction_date  <= l_dData_final + 0.99999
                                                             --and ood.organization_id in (583,604,585,105,192,584,605)
                                                             and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                          group by  msib.description
                                                                ,msib.segment1
                                                                ,mcr.cross_reference
                                                                ,ood.organization_name
                                                                ,ood.organization_id
                                                                ,mtln.lot_number

                                                          union

                                                        SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,0 nrs
                                                                ,sum(mtln.PRIMARY_QUANTITY *-1) rms
                                                                ,0 dms
                                                                ,0 pnfs
                                                                ,0 outros
                                                                ,0 sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                          FROM  apps.mtl_transaction_types mtt
                                                              ,apps.mtl_material_transactions mmt
                                                              ,apps.mtl_transaction_lot_numbers mtln
                                                              ,apps.mtl_system_items_b       msib
                                                              ,apps.org_organization_definitions ood
                                                              ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           and mmt.inventory_item_id    = msib.inventory_item_id
                                                           and mmt.organization_id      = msib.organization_id
                                                           AND mmt.transaction_id       = mtln.transaction_id
                                                           and mmt.transaction_type_id  = mtt.transaction_type_id
                                                           and ood.organization_id = mmt.organization_id
                                                           and mmt.transaction_date  BETWEEN l_dData_inicio
                                                                                 AND l_dData_final + 0.99999
                                                           and mtln.PRIMARY_QUANTITY < 0
                                                           --and ood.organization_id in (583,604,585,105,192,584,605)
                                                           and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                           and (mmt.transaction_source_type_id  = 5
                                                                  or mtt.attribute8 in ('CON_PROD_A','CON_TXT_A')
                                                                  or mtt.transaction_type_id = 105 )

                                                          group by
                                                               msib.description
                                                              ,msib.segment1
                                                              ,mcr.cross_reference
                                                              ,ood.organization_name
                                                              ,ood.organization_id
                                                              ,mtln.lot_number

                                                          union

                                                        SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,0 nrs
                                                                ,0 rms
                                                                ,sum(mtln.PRIMARY_QUANTITY) dms
                                                                ,0 pnfs
                                                                ,0 outros
                                                                ,0 sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                          FROM  apps.mtl_transaction_types mtt
                                                              ,apps.mtl_material_transactions mmt
                                                              ,apps.mtl_transaction_lot_numbers mtln
                                                              ,apps.mtl_system_items_b       msib
                                                              ,apps.org_organization_definitions ood
                                                              ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           and mmt.inventory_item_id    = msib.inventory_item_id
                                                           and mmt.organization_id      = msib.organization_id
                                                           AND mmt.transaction_id       = mtln.transaction_id
                                                           and mmt.transaction_type_id  = mtt.transaction_type_id
                                                           and ood.organization_id = mmt.organization_id
                                                           and mmt.transaction_date  BETWEEN l_dData_inicio
                                                                                 AND l_dData_final + 0.99999
                                                           and mtln.PRIMARY_QUANTITY > 0
                                                           --and ood.organization_id in (583,604,585,105,192,584,605)
                                                           and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                           and (mmt.transaction_source_type_id  = 5
                                                                  or mtt.attribute8 in ('RET_DEV_A','DEV_GRAEXT_A')
                                                                )
                                                          group by
                                                               msib.description
                                                              ,msib.segment1
                                                              ,mcr.cross_reference
                                                              ,ood.organization_name
                                                              ,ood.organization_id
                                                              ,mtln.lot_number

                                                         union

                                                        SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,sum(mtln.PRIMARY_QUANTITY) nrs
                                                                ,0 rms
                                                                ,0 dms
                                                                ,0 pnfs
                                                                ,0 outros
                                                                ,0 sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                          FROM  apps.mtl_transaction_types mtt
                                                              ,apps.mtl_material_transactions mmt
                                                              ,apps.mtl_transaction_lot_numbers mtln
                                                              ,apps.mtl_system_items_b       msib
                                                              ,apps.org_organization_definitions ood
                                                              ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           and mmt.inventory_item_id    = msib.inventory_item_id
                                                           and mmt.organization_id      = msib.organization_id
                                                           AND mmt.transaction_id       = mtln.transaction_id
                                                           and mmt.transaction_type_id  = mtt.transaction_type_id
                                                           and ood.organization_id = mmt.organization_id
                                                           and mmt.transaction_date  BETWEEN l_dData_inicio
                                                                                 AND l_dData_final + 0.99999
                                                           --and ood.organization_id in (583,604,585,105,192,584,605)
                                                           and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                           and mmt.transaction_type_id IN (18,36,105)
                                                          group by
                                                               msib.description
                                                              ,msib.segment1
                                                              ,mcr.cross_reference
                                                              ,ood.organization_name
                                                              ,ood.organization_id
                                                              ,mtln.lot_number

                                                         union

                                                        SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,0 nrs
                                                                ,0 rms
                                                                ,0 dms
                                                                ,sum(mtln.PRIMARY_QUANTITY *-1) pnfs
                                                                ,0 outros
                                                                ,0 sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                          FROM  apps.mtl_transaction_types mtt
                                                              ,apps.mtl_material_transactions mmt
                                                              ,apps.mtl_transaction_lot_numbers mtln
                                                              ,apps.mtl_system_items_b       msib
                                                              ,apps.org_organization_definitions ood
                                                              ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           and mmt.inventory_item_id    = msib.inventory_item_id
                                                           and mmt.organization_id      = msib.organization_id
                                                           AND mmt.transaction_id       = mtln.transaction_id
                                                           and mmt.transaction_type_id  = mtt.transaction_type_id
                                                           and ood.organization_id = mmt.organization_id
                                                           and mmt.transaction_date  BETWEEN l_dData_inicio
                                                                                 AND l_dData_final + 0.99999
                                                           --and ood.organization_id in (583,604,585,105,192,584,605)
                                                           and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                           AND  mmt.transaction_source_type_id  = 13
                                                           AND  nvl(mtt.attribute8,'X')        in ('CON_PNFC', 'CON_PNFC_S_OS', 'TRF_GRAEXT')

                                                          group by
                                                               msib.description
                                                              ,msib.segment1
                                                              ,mcr.cross_reference
                                                              ,ood.organization_name
                                                              ,ood.organization_id
                                                              ,mtln.lot_number

                                                          union

                                                        SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,0 nrs
                                                                ,0 rms
                                                                ,sum(mtln.PRIMARY_QUANTITY) dms
                                                                ,0 pnfs
                                                                ,0 outros
                                                                ,0 sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                          FROM  apps.mtl_transaction_types mtt
                                                              ,apps.mtl_material_transactions mmt
                                                              ,apps.mtl_transaction_lot_numbers mtln
                                                              ,apps.mtl_system_items_b       msib
                                                              ,apps.org_organization_definitions ood
                                                              ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           and mmt.inventory_item_id    = msib.inventory_item_id
                                                           and mmt.organization_id      = msib.organization_id
                                                           AND mmt.transaction_id       = mtln.transaction_id
                                                           and mmt.transaction_type_id  = mtt.transaction_type_id
                                                           and ood.organization_id = mmt.organization_id
                                                           and mmt.transaction_date  BETWEEN l_dData_inicio
                                                                                 AND l_dData_final + 0.99999
                                                           --and ood.organization_id in (583,604,585,105,192,584,605)
                                                           and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                           AND  mmt.transaction_quantity        > 0
                                                           AND  mmt.transaction_source_type_id  = 13
                                                           AND  nvl(mtt.attribute8,'X')        in ('DEV_INT')

                                                          group by
                                                               msib.description
                                                              ,msib.segment1
                                                              ,mcr.cross_reference
                                                              ,ood.organization_name
                                                              ,ood.organization_id
                                                              ,mtln.lot_number

                                                           union

                                                        SELECT   msib.description papel
                                                                ,msib.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,0 nrs
                                                                ,0 rms
                                                                ,0 dms
                                                                ,0 pnfs
                                                                ,sum(mtln.PRIMARY_QUANTITY) outros
                                                                ,0 sld_final
                                                                ,0 segregado
                                                                ,mtln.lot_number lot_number
                                                          FROM  apps.mtl_transaction_types mtt
                                                              ,apps.mtl_material_transactions mmt
                                                              ,apps.mtl_transaction_lot_numbers mtln
                                                              ,apps.mtl_system_items_b       msib
                                                              ,apps.org_organization_definitions ood
                                                              ,apps.mtl_cross_references     mcr
                                                          WHERE  mcr.inventory_item_id = msib.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           and mmt.inventory_item_id    = msib.inventory_item_id
                                                           and mmt.organization_id      = msib.organization_id
                                                           AND mmt.transaction_id       = mtln.transaction_id
                                                           and mmt.transaction_type_id  = mtt.transaction_type_id
                                                           and ood.organization_id = mmt.organization_id
                                                           and mmt.transaction_date  BETWEEN l_dData_inicio
                                                                                 AND l_dData_final + 0.99999
                                                           --and ood.organization_id in (583,604,585,105,192,584,605)
                                                           and ood.organization_id in (583,584,585,604)--,105,192,605)
                                                           AND  nvl(mtt.attribute8,'X') not in ('RET_DEV_A','CON_PROD_A','CON_TXT_A','DEV_GRAEXT_A','DEV_INT','CON_PNFC', 'CON_PNFC_S_OS', 'TRF_GRAEXT')
                                                           and mmt.transaction_type_id not IN ( 18,36,105 )
                                                           and mmt.transaction_source_type_id  not in (5)--,13)
                                                       group by
                                                               msib.description
                                                              ,msib.segment1
                                                              ,mcr.cross_reference
                                                              ,ood.organization_name
                                                              ,ood.organization_id
                                                              ,mtln.lot_number

                                                       UNION

                                                        SELECT   msi.description papel
                                                                ,msi.segment1 item
                                                                ,mcr.cross_reference item_ssp
                                                                ,ood.organization_name empresa
                                                                ,ood.organization_id org_id
                                                                ,0 sld_inicial
                                                                ,0 nrs
                                                                ,0 rms
                                                                ,0 dms
                                                                ,0 pnfs
                                                                ,0 outros
                                                                ,0 sld_final
                                                               ,sum(nvl(to_number(mln.n_attribute2), 0)) + --qtde_avaria,
                                                                sum(decode(mln.c_attribute2, NULL, 0, moq.transaction_quantity)) segregado--qtd_defeito
                                                                ,mln.lot_number lot_number
                                                          FROM apps.org_organization_definitions ood,
                                                               apps.mtl_cross_references         mcr,
                                                               apps.mtl_lot_numbers              mln,
                                                               apps.mtl_onhand_quantities        moq,
                                                               apps.mtl_system_items_b           msi
                                                         WHERE msi.inventory_item_id = moq.inventory_item_id
                                                           AND msi.organization_id = moq.organization_id
                                                           AND ood.organization_id = moq.organization_id
                                                           AND ood.organization_code IN ('001', '002')
                                                           AND mcr.inventory_item_id = moq.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           AND moq.lot_number = mln.lot_number
                                                           AND moq.inventory_item_id = mln.inventory_item_id
                                                           AND moq.organization_id = mln.organization_id
                                                           AND ood.organization_code || moq.subinventory_code != '002011'
                                                         GROUP BY
                                                               msi.description
                                                              ,msi.segment1
                                                              ,mcr.cross_reference
                                                              ,ood.organization_name
                                                              ,ood.organization_id
                                                              ,mln.lot_number
                                                              ) mov_papel
                                                    where  ( sld_inicial > 0 or
                                                           nrs > 0 or
                                                           rms > 0 or
                                                           dms > 0 or
                                                           pnfs > 0 or
                                                           outros <> 0 or
                                                           sld_final > 0 or
                                                           segregado > 0
                                                           )
                                                    group by
                                                           item
                                                           ,item_ssp
                                                           ,empresa
                                                           ,org_id
                                                           ,lot_number

                                                    order by  empresa
                                                           ,item_ssp
                                                           ) a,
                                                        ( SELECT
                                                               tipo.element_value   || ' ' ||
                                                               proces.element_value || ' ' ||
                                                               proced.element_value || ' ' ||
                                                               indtrib.element_value  tipo_papel
                                                               ,msib.segment1
                                                               ,proced.element_value origem
                                                        FROM
                                                               apps.mtl_system_items_b       msib
                                                              ,apps.mtl_descr_element_values tipo
                                                              ,apps.mtl_descr_element_values indtrib
                                                              ,apps.mtl_descr_element_values proced
                                                              ,apps.mtl_descr_element_values proces
                                                              ,apps.mtl_cross_references     mcr
                                                        where  msib.organization_id  (+)= apps.xxfnd_api_pk.get_organization_f(NULL,'000','ORGANIZATION_ID')
                                                           and mcr.inventory_item_id = msib.inventory_item_id
                                                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                                                           and msib.inventory_item_id   = tipo.inventory_item_id(+)
                                                           AND tipo.element_name     (+)= 'TIPO'
                                                           AND msib.inventory_item_id   = indtrib.inventory_item_id(+)
                                                           AND indtrib.element_name     (+)= 'INDICADOR DE TRIBUTACAO'
                                                           AND msib.inventory_item_id   = proced.inventory_item_id(+)
                                                           AND proced.element_name     (+)= 'PROCEDENCIA'
                                                           AND msib.inventory_item_id   = proces.inventory_item_id(+)
                                                           AND proces.element_name     (+)= 'PROCESSO'
                                                        group by
                                                               tipo.element_value   || ' ' ||
                                                               proces.element_value || ' ' ||
                                                               proced.element_value || ' ' ||
                                                               indtrib.element_value
                                                               ,proced.element_value
                                                              ,msib.segment1
                                                           ) b
                                            where b.segment1 (+) = a.item
                                            and   b.origem = p_origem
                                            and  ( (case
                                                    when a.org_id = 604 then a.lot_number   --Caras
                                                  end                   like '%VL%')
                                               OR
                                                 (case
                                                    when a.org_id <> 604 then 1
                                                  end                   = 1)
                                                 )
                                            group by a.item_ssp
                                                    ,b.tipo_papel
                                                    ,a.empresa
                                                    ,a.org_id
                                                    ,b.origem
                                                    ,a.lot_number
                                            ) xb
                                            ,apps.mtl_material_transactions mmtx
                                            ,apps.mtl_transaction_lot_numbers mtlnx
                                            ,apps.MTL_SECONDARY_INVENTORIES i
                              WHERE mmtx.transaction_id    = mtlnx.transaction_id
                               and  mmtx.organization_id   = i.organization_id
                               and  mmtx.SUBINVENTORY_CODE = i.secondary_inventory_name
                               and  mtlnx.lot_number       = xb.lot_number
                               and  mmtx.transaction_id = (select  min(mmtt.transaction_id)
                                                            FROM  apps.mtl_material_transactions mmtt
                                                                 ,apps.mtl_transaction_lot_numbers mttln
                                                            WHERE mmtt.transaction_id       = mttln.transaction_id
                                                             and  mttln.lot_number = xb.lot_number)
                            group by
                                    xb.origem
                                   ,xb.item_ssp
                                   ,xb.tipo_papel
                                   ,xb.empresa
                                   ,xb.org_id
                                   ,i.description) ap
                    where 1=1
                    group by
                            ap.origem
                           ,ap.item_ssp
                           ,ap.tipo_papel
                           ,ap.empresa
                           ,ap.org_id
                    order by 4,3
                  ;
    --
    ----------------------------------------
  BEGIN

    IF P_ORIGEM <> 'NACIONAL' THEN
       IF P_ORIGEM <> 'IMPORTADO' THEN
          retcode  := 1; -- warning
          raise_application_error(-20001,'Erro ao informar A ORIGEM, DEVE SER NACIONAL OU IMPORTADO -> ' || P_ORIGEM);
       END IF;
    END IF;

    BEGIN
      SELECT min(period_start_date)
           , max(period_end_date)
        INTO l_dData_inicio
           , l_dData_final
        FROM apps.cst_pac_item_costs           cpic
           , apps.cst_pac_periods              cpp
           , apps.cst_cost_groups              ccg
           , apps.org_organization_definitions ood
       WHERE cpp.period_name         = p_date
         AND cpp.pac_period_id       = cpic.pac_period_id
         AND cpic.cost_group_id      = ccg.cost_group_id
         AND cpp.legal_entity        = ood.legal_entity
         AND ((case
               when to_date(p_date,'MON-YY') >= l_dData_reorg then ood.organization_code
               end                   = '001'
           AND case
               when to_date(p_date,'MON-YY') >= l_dData_reorg then ccg.cost_group
               end
             = 'ABRIL')

           OR (case
               when last_day(to_date(p_date,'MON-YY'))  <  l_dData_reorg then ood.organization_code
               end                   = '01A'
           AND case
               when last_day(to_date(p_date,'MON-YY')) < l_dData_reorg then ccg.cost_group
               end                   = 'XABRIL')
            )
    GROUP BY cpp.pac_period_id;

    EXCEPTION
      WHEN OTHERS THEN
        raise_application_error(-20001,'Erro ao ler a tabela CST_PAC_PERIODS. Erro:'||SQLERRM);
    END;
   --
    --DBMS_OUTPUT.PUT_LINE(l_dData_inicio || '-' || l_dData_final );

    IF (l_dData_inicio IS NULL AND l_dData_final IS NULL) THEN
       raise_application_error(-20002,'As datas de ício e fim do perío nãestãpreenchidas. Verifique se o perío informado '||p_date||' existe.');
    END IF;
    --
    l_vRegistro := 'RELATORIO DE ENTRADA,CONSUMO E SALDO - ' || p_date || ' Emitido em ' || sysdate;
    fnd_file.put_line(fnd_file.output,l_vRegistro);
    --DBMS_OUTPUT.PUT_LINE(l_vRegistro);

    l_vRegistro := 'ORIGEM;TIPO;TIPO_DSC;EMPRESA;SLD_INICIAL;ENTRADA;CONSUMO;SLD_FINAL;SEGREGADO;RMS;DMS;PNFS';
    fnd_file.put_line(fnd_file.output,l_vRegistro);
    --DBMS_OUTPUT.PUT_LINE(l_vRegistro);
    --
    FOR r_recs IN c_recs
      LOOP
          l_vRegistro :=  r_recs.origem                                       || ';' ||
                          r_recs.item_ssp                                     || ';' ||
                          r_recs.tipo_papel                                   || ';' ||
                          r_recs.empresa                                      || ';' ||
                          REPLACE(REPLACE(r_recs.sld_inicial,',',''),'.',',') || ';' ||
                          REPLACE(REPLACE(r_recs.entrada,',',''),'.',',')     || ';' ||
                          REPLACE(REPLACE(r_recs.consumo,',',''),'.',',')     || ';' ||
                          REPLACE(REPLACE(r_recs.sld_final,',',''),'.',',')   || ';' ||
                          REPLACE(REPLACE(r_recs.segregado,',',''),'.',',')   || ';' ||
                          REPLACE(REPLACE(r_recs.rms ,',',''),'.',',')        || ';' ||
                          REPLACE(REPLACE(r_recs.dms,',',''),'.',',')         || ';' ||
                          REPLACE(REPLACE(r_recs.pnfs,',',''),'.',',')
                          ;

          fnd_file.put_line(fnd_file.output,l_vRegistro);
          --DBMS_OUTPUT.PUT_LINE(l_vRegistro);

   END LOOP;

  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de entrada,consumo e saldo. ' || SQLERRM);
        --DBMS_OUTPUT.PUT_LINE('Erro ao processar relatorio de entrada,consumo e saldo. ' || SQLERRM);


  END gera_lst_ecs_p;
  -------------------------------------------------------------------------------------------------
  PROCEDURE gera_lst_consumocsv_p (errbuf            IN OUT VARCHAR2
                                  ,retcode           IN OUT NUMBER
                                  ,p_dtinicio        IN VARCHAR2
                                  ,p_dtfinal         IN VARCHAR2) IS

  l_qtde_reserva    number;
  l_codprod         varchar2(100);
  l_codedic         varchar2(100);
  l_dscprod         varchar2(100);
  l_qtdeprev        number;

  l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
  l_vRegistro        varchar2(1000);
  l_empresa          varchar2(1000);

    CURSOR c_recs IS
                    select    a.org_id,
                              a.empresa,
                              a.item_id,
                              a.item,
                              a.item_ssp,
                              a.tipo_papel,
                              min(a.dt_util) dt_util,
                              a.reserva reserva
                      from
                            (SELECT ood.organization_id org_id,
                                   ood.organization_name empresa,
                                   msib.segment1 item,
                                   mcr.cross_reference item_ssp,
                                   msib.description papel,
                                   min(trunc(mmt.transaction_date))  dt_util,
                                   mmt.attribute14 reserva,
                                   mmt.inventory_item_id item_id,
                                   msib.description tipo_papel
                             FROM apps.mtl_transaction_types        mtt,
                                  apps.mtl_material_transactions    mmt,
                                  apps.mtl_transaction_lot_numbers  mtln,
                                  apps.mtl_system_items_b           msib,
                                  apps.org_organization_definitions ood,
                                  apps.mtl_cross_references         mcr
                            WHERE mcr.inventory_item_id    = msib.inventory_item_id
                              AND mcr.cross_reference_type ='CODIGO LEGADO SSP'
                              and mmt.inventory_item_id    = msib.inventory_item_id
                              and mmt.organization_id      = msib.organization_id
                              AND mmt.transaction_id       = mtln.transaction_id
                              and mmt.transaction_type_id  = mtt.transaction_type_id
                              and ood.organization_id = mmt.organization_id
                              and mmt.transaction_date BETWEEN p_dtinicio
                                                           AND p_dtfinal
                              and ood.organization_id in (583, 604, 585, 105, 192, 584, 605)
                              and     mtt.transaction_type_id  not in (246,248,290)  --> 246 = transf picking / 248 = ENTRADA DEV MAQ / 290 = SAIDA DEV MAQ / = 304--
                              and nvl(mmt.attribute14, '0') <> '0'
                            group by msib.description,
                                     msib.segment1,
                                     mcr.cross_reference,
                                     ood.organization_name,
                                     ood.organization_id,
                                     mmt.attribute14,
                                     mmt.inventory_item_id,
                                     msib.description) a
                      group by a.item,
                               a.item_ssp,
                               a.empresa,
                               a.org_id,
                               a.reserva,
                               a.tipo_papel,
                               a.item_id
                      order by a.org_id,a.empresa,a.item
                  ;
    --
    ----------------------------------------
  BEGIN

    IF p_dtinicio is null or p_dtfinal is null THEN
          retcode  := 1; -- warning
          raise_application_error(-20002,'As datas de ício e fim do perío nãestãpreenchidas. Verifique se o perío informado '
                                   || p_dtinicio || '-' || p_dtfinal);
    END IF;


    l_vRegistro := 'Arquivo CSV-Consumo Reservas - ' || p_dtinicio || ' a ' || p_dtfinal || ' emitido em ' || sysdate;
    fnd_file.put_line(fnd_file.output,l_vRegistro);

    --DBMS_OUTPUT.PUT_LINE(l_vRegistro);

    l_vRegistro := 'ORG_ID;EMPRESA;DSC_PROD;APLICACAO;EDICAO;PAPEL;PAPEL_SSP;DSC_PAPEL;DT_UTIL;Q_PREVISTA;Q_REAL;RESERVA';
    fnd_file.put_line(fnd_file.output,l_vRegistro);
    --DBMS_OUTPUT.PUT_LINE(l_vRegistro);
    --
    FOR r_recs IN c_recs
      LOOP

         begin
            l_qtde_reserva := 0;
            SELECT   sum(mtln.PRIMARY_QUANTITY * -1)
                     into l_qtde_reserva
               FROM  apps.mtl_transaction_types mtt
                    ,apps.mtl_material_transactions mmt
                    ,apps.mtl_transaction_lot_numbers mtln
                    ,apps.mtl_system_items   msi
              where  mmt.transaction_id = mtln.transaction_id
              and    mmt.transaction_type_id  = mtt.transaction_type_id
              and    mmt.inventory_item_id    = msi.inventory_item_id
              and    mmt.organization_id      = msi.organization_id
              and    mmt.organization_id      = r_recs.org_id
              and    mmt.inventory_item_id    = r_recs.item_id
              and    mmt.transaction_date    >= r_recs.dt_util-60
              and    nvl(mmt.attribute14,'0') = r_recs.reserva
              and    mmt.source_code = 'INTERFACE MOV. PAPEL'
              and    mtt.transaction_type_id  not in (246,248,290)--> 246 = transf picking / 248 = ENTRADA DEV MAQ / 290 = SAIDA DEV MAQ
            group by mmt.attribute14;

          exception when others then
               null;

          end;

          l_codprod  := null;
          l_codedic  := null;
          l_dscprod  := null;
          l_dscprod  := null;
          l_qtdeprev := 0;

          begin
               select substr(ai.COD_CENTRO_CUSTO,3,4),
                      ai.num_edicao,
                      ai.dsc_revista,
                      sum(ai.QTD_KG_PAPEL_RESERVA)
               into   l_codprod,
                      l_codedic,
                      l_dscprod,
                      l_qtdeprev
               from   bolinf.xxinv_int_os ai
               where  ai.num_reserva     = r_recs.reserva
                 AND  ai.cod_papel       = to_number(r_recs.item)
                 and  ai.last_update_date = (SELECT MAX(aix.last_update_date)
                                                     FROM bolinf.xxinv_int_os aix
                                                    WHERE aix.num_reserva = r_recs.reserva
                                                      AND aix.cod_papel   = to_number(r_recs.item)
                                                      and aix.qtd_kg_papel_reserva > 0
                                                      and aix.cod_tipo_os <> 'L'
                                                   )
              group by  substr(ai.COD_CENTRO_CUSTO,3,4),
                        ai.num_edicao,
                        ai.dsc_revista;


          exception when others then
               null;

          end;


          if l_qtde_reserva <> 0 then

                  l_empresa := r_recs.empresa;

                  if upper(l_dscprod) like '%CARAS%' then
                     l_empresa := 'CARAS';
                  end if;

                  l_vRegistro :=  r_recs.org_id                                       || ';' ||
                                  l_empresa                                           || ';' ||
                                  l_dscprod                                           || ';' ||
                                  l_codprod                                           || ';' ||
                                  l_codedic                                           || ';' ||
                                  r_recs.item                                         || ';' ||
                                  r_recs.item_ssp                                     || ';' ||
                                  r_recs.tipo_papel                                   || ';' ||
                                  r_recs.dt_util                                      || ';' ||
                                  REPLACE(REPLACE(l_qtdeprev,',',''),'.',',')         || ';' ||
                                  REPLACE(REPLACE(l_qtde_reserva,',',''),'.',',')     || ';' ||
                                  r_recs.reserva;

                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --DBMS_OUTPUT.PUT_LINE(l_vRegistro);
           end if;


   END LOOP;


  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de entrada,consumo e saldo. ' || SQLERRM);
        --DBMS_OUTPUT.PUT_LINE('Erro ao processar relatorio CSV reservas. ' || SQLERRM);

  END gera_lst_consumocsv_p;
  -------------------------------------------------------------------------------------------------
  PROCEDURE gera_lst_posicao_pap_p (errbuf            IN OUT VARCHAR2
                                   ,retcode           IN OUT NUMBER
                                   ,p_dtinicio        IN VARCHAR2
                                   ,p_dtfinal         IN VARCHAR2
                                   ,p_item            IN VARCHAR2
                                   ) IS

  l_qtde_reserva    number;
  l_codprod         varchar2(100);
  l_codedic         varchar2(100);
  l_dscprod         varchar2(100);
  l_qtdeprev        number;

  l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
  l_vRegistro        varchar2(1000);
  l_empresa          varchar2(1000);
  l_intlinhas        number;
  l_item_id          number;
  l_dtinicio         date;
  l_dtfinal          date;
  ---
  CURSOR c_recs IS
                   select     a.org_id,
                              a.empresa,
                              a.item_id,
                              a.item,
                              a.item_ssp,
                              a.tipo_papel,
                              min(a.dt_util) dt_util,
                              a.reserva reserva
                      from
                            (SELECT ood.organization_id org_id,
                                   ood.organization_name empresa,
                                   msib.segment1 item,
                                   mcr.cross_reference item_ssp,
                                   msib.description papel,
                                   min(trunc(mmt.transaction_date))  dt_util,
                                   mmt.attribute14 reserva,
                                   mmt.inventory_item_id item_id,
                                   msib.description tipo_papel
                             FROM apps.mtl_transaction_types        mtt,
                                  apps.mtl_material_transactions    mmt,
                                  apps.mtl_transaction_lot_numbers  mtln,
                                  apps.mtl_system_items_b           msib,
                                  apps.org_organization_definitions ood,
                                  apps.mtl_cross_references         mcr
                            WHERE mcr.inventory_item_id    = msib.inventory_item_id
                              AND mcr.cross_reference_type ='CODIGO LEGADO SSP'
                              and mmt.inventory_item_id    = msib.inventory_item_id
                              and mmt.organization_id      = msib.organization_id
                              AND mmt.transaction_id       = mtln.transaction_id
                              and mmt.transaction_type_id  = mtt.transaction_type_id
                              and ood.organization_id = mmt.organization_id
                              --and mmt.transaction_date BETWEEN p_dtinicio
                                --                           AND p_dtfinal
                              and mmt.transaction_date >= l_dtinicio
                              and mmt.transaction_date <= l_dtfinal + 0.99999
                              and ood.organization_id in (583, 604, 585, 105, 192, 584, 605)
                              and mtt.transaction_type_id  not in (246,248,290)  --> 246 = transf picking / 248 = ENTRADA DEV MAQ / 290 = SAIDA DEV MAQ / = 304--
                              and nvl(mmt.attribute14, '0') <> '0'
                              and msib.inventory_item_id = l_item_id
                            group by msib.description,
                                     msib.segment1,
                                     mcr.cross_reference,
                                     ood.organization_name,
                                     ood.organization_id,
                                     mmt.attribute14,
                                     mmt.inventory_item_id,
                                     msib.description) a
                      group by a.item,
                               a.item_ssp,
                               a.empresa,
                               a.org_id,
                               a.reserva,
                               a.tipo_papel,
                               a.item_id
                      order by a.org_id,a.empresa,a.item,a.reserva
                  ;
    --
    CURSOR c_lots ( v_reserva IN VARCHAR2
                   ,v_item_id IN NUMBER
                   ,v_org_id  IN NUMBER
                   ) is
          SELECT distinct(substr(mtln.lot_number,1,6)) lote,
                 sum(mtln.PRIMARY_QUANTITY *-1) qtde_lote,
                 upper(mln.c_attribute4) fornec
           FROM apps.mtl_material_transactions    mmt,
                apps.mtl_transaction_lot_numbers  mtln,
                apps.mtl_system_items_b           msib,
                apps.mtl_lot_numbers              mln,
                apps.mtl_transaction_types        mtt
          WHERE mmt.inventory_item_id    = msib.inventory_item_id
            and mmt.organization_id      = msib.organization_id
            AND mmt.transaction_id       = mtln.transaction_id
            and mmt.transaction_type_id  = mtt.transaction_type_id
            and mtt.transaction_type_id  not in (246,248,290)  --> 246 = transf picking / 248 = ENTRADA DEV MAQ / 290 = SAIDA DEV MAQ / = 304--
            and nvl(mmt.attribute14, '0') = v_reserva
            and mmt.inventory_item_id     = v_item_id
            and mmt.organization_id       = v_org_id
            and mln.inventory_item_id     = msib.inventory_item_id
            and mln.organization_id       = msib.organization_id
            and mln.gen_object_id         = (select min(mlnx.gen_object_id)
                                              from apps.mtl_lot_numbers mlnx
                                              where  mlnx.lot_number like '%' || substr(mtln.lot_number,1,6) || '%'
                                              and    mlnx.inventory_item_id = msib.inventory_item_id
                                              and    mlnx.organization_id   = msib.organization_id
                                              and    nvl(mln.c_attribute4,'X') <> 'X')
          group by
                 substr(mtln.lot_number,1,6),
                 upper(mln.c_attribute4)
    ;
    ----------------------------------------
  BEGIN
    l_dtfinal  := p_dtfinal;
    l_dtinicio := p_dtinicio;

    IF p_dtinicio is null or p_dtfinal is null THEN
          retcode  := 1; -- warning
          raise_application_error(-20002,'As datas de ício e fim do perío nãestãpreenchidas. Verifique se o perío informado '
                                   || p_dtinicio || '-' || p_dtfinal);
    END IF;

    l_vRegistro := 'Arquivo Posicao estoque por lote - ' || p_dtinicio || ' a ' || p_dtfinal || ' emitido em ' || sysdate;
    fnd_file.put_line(fnd_file.output,l_vRegistro);

    --verifica item informado
    l_item_id := 0;

    begin
        SELECT msib.inventory_item_id
        into   l_item_id
         FROM apps.mtl_system_items_b           msib,
              apps.mtl_cross_references         mcr
        WHERE mcr.inventory_item_id    = msib.inventory_item_id
          AND mcr.cross_reference_type ='CODIGO LEGADO SSP'
          and msib.organization_id = 583
          and to_number(msib.segment1) = p_item;

    exception when others then
          retcode  := 1; -- warning
          raise_application_error(-20002,'Item de papel nãcadastrado. Verifique o item informado '|| p_item);
    end;

    l_vRegistro := 'PAPEL_SSP;PAPEL;DSC_PAPEL;ORG_ID;EMPRESA;DSC_PROD;APLICACAO;EDICAO;DT_UTIL;Q_PREVISTA;Q_REAL;RESERVA;LOTE;Q_LOTE;FORNEC';
    fnd_file.put_line(fnd_file.output,l_vRegistro);
    --DBMS_OUTPUT.PUT_LINE(l_vRegistro);
    --
    FOR r_recs IN c_recs
      LOOP

         begin
            l_qtde_reserva := 0;
            SELECT   sum(mtln.PRIMARY_QUANTITY * -1)
                     into l_qtde_reserva
               FROM  apps.mtl_transaction_types mtt
                    ,apps.mtl_material_transactions mmt
                    ,apps.mtl_transaction_lot_numbers mtln
                    ,apps.mtl_system_items   msi
              where  mmt.transaction_id = mtln.transaction_id
              and    mmt.transaction_type_id  = mtt.transaction_type_id
              and    mmt.inventory_item_id    = msi.inventory_item_id
              and    mmt.organization_id      = msi.organization_id
              and    mmt.organization_id      = r_recs.org_id
              and    mmt.inventory_item_id    = r_recs.item_id
             -- and    mmt.transaction_date    >= r_recs.dt_util-60
              and    nvl(mmt.attribute14,'0') = r_recs.reserva
              and    mmt.source_code = 'INTERFACE MOV. PAPEL'
              and    mtt.transaction_type_id  not in (246,248,290)--> 246 = transf picking / 248 = ENTRADA DEV MAQ / 290 = SAIDA DEV MAQ
            group by mmt.attribute14;

          exception when others then
               null;
          end;

          l_codprod  := null;
          l_codedic  := null;
          l_dscprod  := null;
          l_dscprod  := null;
          l_qtdeprev := 0;

          begin
               select substr(ai.COD_CENTRO_CUSTO,3,4),
                      ai.num_edicao,
                      ai.dsc_revista,
                      sum(ai.QTD_KG_PAPEL_RESERVA)
               into   l_codprod,
                      l_codedic,
                      l_dscprod,
                      l_qtdeprev
               from   bolinf.xxinv_int_os ai
               where  ai.num_reserva     = r_recs.reserva
                 AND  ai.cod_papel       = to_number(r_recs.item)
                 and  ai.last_update_date = (SELECT MAX( aix.last_update_date)
                                                     FROM bolinf.xxinv_int_os aix
                                                    WHERE aix.num_reserva = r_recs.reserva
                                                      AND aix.cod_papel   = to_number(r_recs.item)
                                                      and aix.qtd_kg_papel_reserva > 0
                                                      and aix.cod_tipo_os <> 'L'
                                                   )
              group by  substr(ai.COD_CENTRO_CUSTO,3,4),
                        ai.num_edicao,
                        ai.dsc_revista;

          exception when others then
               null;
          end;

          if l_qtde_reserva <> 0 then

                  l_empresa := r_recs.empresa;

                  if upper(l_dscprod) like '%CARAS%' then
                     l_empresa := 'CARAS';
                  end if;

                  l_vRegistro :=  r_recs.item_ssp                                     || ';' ||
                                  r_recs.item                                         || ';' ||
                                  r_recs.tipo_papel                                   || ';' ||
                                  r_recs.org_id                                       || ';' ||
                                  l_empresa                                           || ';' ||
                                  l_dscprod                                           || ';' ||
                                  l_codprod                                           || ';' ||
                                  l_codedic                                           || ';' ||
                                  r_recs.dt_util                                      || ';' ||
                                  REPLACE(REPLACE(l_qtdeprev,',',''),'.',',')         || ';' ||
                                  REPLACE(REPLACE(l_qtde_reserva,',',''),'.',',')     || ';' ||
                                  r_recs.reserva;

                  l_intlinhas := 0;
                  FOR r_lots IN c_lots(r_recs.reserva, r_recs.item_id, r_recs.org_id)
                    LOOP
                          l_intlinhas := l_intlinhas + 1;

                          l_vRegistro := l_vRegistro                                         || ';' ||
                                         r_lots.lote                                         || ';' ||
                                         REPLACE(REPLACE(r_lots.qtde_lote,',',''),'.',',')   || ';' ||
                                         r_lots.fornec;

                          fnd_file.put_line(fnd_file.output,l_vRegistro);
                          --DBMS_OUTPUT.PUT_LINE(l_vRegistro);

                          l_vRegistro :=  ';;;;;;;;;;'                                || ';' ||
                                          r_recs.reserva;
                  END LOOP;

                  if l_intlinhas = 0 then --nao encontrou lotes gera linha das reservas
                      fnd_file.put_line(fnd_file.output,l_vRegistro);
                      --DBMS_OUTPUT.PUT_LINE(l_vRegistro);
                  end if;

           end if;

   END LOOP;

  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de Posicao estoque por lote. ' || SQLERRM);
        --DBMS_OUTPUT.PUT_LINE('Erro ao processar relatorio CSV reservas. ' || SQLERRM);

  END gera_lst_posicao_pap_p;
  -------------------------------------------------------------------------------------------------
  PROCEDURE gera_lst_pos_estoq_fab_p (errbuf            IN OUT VARCHAR2
                                     ,retcode           IN OUT NUMBER
                                   ) IS
  l_dt_ultrm         date;
  l_vRegistro        varchar2(1000);

  ---
  CURSOR c_recs IS
              select
                      upper(tbtpo.fornecedor)       Fornecedor
                     ,MIN(trunc(tbtpo.data_entrada))Data_entrada
                     ,tbtpo.tipo_item_ssp           Cod_tipo
                     ,b.tipo_papel                  Tipo
                     ,tbtpo.lote                    Lote
                     ,SUM(tbtpo.total_volumes)      Qtde_vols
                     ,SUM ( tbtpo.qtd_atual)        Peso_total
                     ,SUM(tbtpo.qtde_avaria)        Qtde_avaria
                     ,SUM(tbtpo.qtd_defeito)        Qtde_defeito
                     ,tbtpo.empresa                 Organizacao
                     ,b.larg                        Larg
                     ,b.gramat                      Gramat
                     ,b.origem                      Origem
                     ,tbtpo.org_id                  Org_id
                     ,b.item_id                     Item_id
              FROM  (SELECT
                               case when substr(tab.cod_papel_ssp,1,1) = '0' then
                                   substr(tab.cod_papel_ssp,3,2)
                               else
                                   substr(tab.cod_papel_ssp,2,2)
                               end tipo_item_ssp
                              ,tab.papel
                              ,tab.lote
                              ,tab.empresa
                              ,SUM ( tab.qtd_atual)                           qtd_atual
                              ,MIN(tab.data_entrada)                          data_entrada
                              ,SUM(tab.qtde_avaria)                           qtde_avaria
                              ,SUM(tab.qtd_defeito)                           qtd_defeito
                              ,SUM(tab.total_volumes)                         total_volumes
                              ,tab.cod_papel_ssp
                              ,tab.fornecedor
                              ,tab.org_id
                          FROM (SELECT msi.segment1                                                  papel
                                      ,substr(nvl(upper(moq.lot_number),' '),1,6)                    lote
                                      ,ood.organization_code                                         empresa
                                      ,mcr.cross_reference                                           cod_papel_ssp
                                      ,MIN(moq.creation_date)                                        data_entrada
                                      ,SUM(nvl(moq.transaction_quantity,0))                          qtd_atual
                                      ,SUM(nvl(to_number(mln.n_attribute2),0))                       qtde_avaria
                                      ,SUM(decode(mln.c_attribute2,NULL,0,moq.transaction_quantity)) qtd_defeito
                                      ,COUNT(1)                                                      total_volumes
                                      ,mln.c_attribute4                                              fornecedor
                                      ,ood.organization_id                                           Org_id
                                  FROM apps.org_organization_definitions ood
                                      ,apps.mtl_cross_references         mcr
                                      ,apps.mtl_lot_numbers              mln
                                      ,apps.mtl_onhand_quantities        moq
                                      ,apps.mtl_system_items_b           msi
                                 WHERE msi.inventory_item_id                         = moq.inventory_item_id
                                   AND msi.organization_id                           = moq.organization_id
                                   AND ood.organization_id                           = moq.organization_id
                                   AND ood.organization_code                        IN ('001', '002')
                                   AND mcr.inventory_item_id                         = moq.inventory_item_id
                                   AND mcr.cross_reference_type                      = 'CODIGO LEGADO SSP'
                                   AND moq.lot_number                                = mln.lot_number
                                   AND moq.inventory_item_id                         = mln.inventory_item_id
                                   AND moq.organization_id                           = mln.organization_id
                                   AND ood.organization_code||moq.subinventory_code != '002011'
                                   AND moq.subinventory_code NOT IN (SELECT lookup_code
                                                              FROM fnd_lookup_values
                                                             WHERE lookup_type = 'ABRL_INV_MAQUINA_GRAFICA'
                                                               AND LANGUAGE    = 'PTB')
                                GROUP BY msi.segment1
                                        ,substr(nvl(upper(moq.lot_number),' '),1,6)
                                        ,ood.organization_code
                                        ,moq.subinventory_code
                                        ,mcr.cross_reference
                                        ,ood.organization_code||moq.subinventory_code||'SD'
                                        ,moq.locator_id
                                        ,mln.c_attribute4
                                        ,msi.description
                                        ,ood.organization_id
                        ) tab
                        --
                        GROUP BY tab.papel
                                ,tab.lote
                                ,tab.empresa
                                ,tab.cod_papel_ssp
                                ,tab.fornecedor
                                ,tab.org_id
                                ) tbtpo,
                       (SELECT
                               tipo.element_value   || ' ' ||
                               proces.element_value || ' ' ||
                               proced.element_value || ' ' ||
                               indtrib.element_value  tipo_papel
                               ,msib.segment1
                               ,proced.element_value   origem
                               ,gramat.element_value   gramat
                               ,larg.element_value     larg
                               ,msib.inventory_item_id item_id
                        FROM
                               apps.mtl_system_items_b       msib
                              ,apps.mtl_descr_element_values tipo
                              ,apps.mtl_descr_element_values indtrib
                              ,apps.mtl_descr_element_values proced
                              ,apps.mtl_descr_element_values proces
                              ,apps.mtl_descr_element_values gramat
                              ,apps.mtl_descr_element_values larg
                              ,apps.mtl_cross_references     mcr
                        where  msib.organization_id  (+)= apps.xxfnd_api_pk.get_organization_f(NULL,'000','ORGANIZATION_ID')
                           and mcr.inventory_item_id = msib.inventory_item_id
                           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
                           and msib.inventory_item_id   = tipo.inventory_item_id(+)
                           AND tipo.element_name     (+)= 'TIPO'
                           AND msib.inventory_item_id   = indtrib.inventory_item_id(+)
                           AND indtrib.element_name     (+)= 'INDICADOR DE TRIBUTACAO'
                           AND msib.inventory_item_id   = proced.inventory_item_id(+)
                           AND proced.element_name     (+)= 'PROCEDENCIA'
                           AND msib.inventory_item_id   = proces.inventory_item_id(+)
                           AND proces.element_name     (+)= 'PROCESSO'
                           AND msib.inventory_item_id   = larg.inventory_item_id(+)
                           AND larg.element_name       (+)= 'LARGURA'
                           AND msib.inventory_item_id   = gramat.inventory_item_id(+)
                           AND gramat.element_name     (+)= 'GRAMATURA'
                        group by
                               tipo.element_value   || ' ' ||
                               proces.element_value || ' ' ||
                               proced.element_value || ' ' ||
                               indtrib.element_value
                              ,proced.element_value
                              ,msib.segment1
                              ,gramat.element_value
                              ,larg.element_value
                              ,msib.inventory_item_id
                           ) b
              where b.segment1 (+) = tbtpo.papel
              GROUP BY tbtpo.tipo_item_ssp
                      ,tbtpo.lote
                      ,tbtpo.empresa
                      ,tbtpo.fornecedor
                      ,b.tipo_papel
                      ,tbtpo.data_entrada
                      ,b.larg
                      ,b.gramat
                      ,b.origem
                      ,tbtpo.org_id
                      ,b.item_id
              order by tbtpo.fornecedor
                      ,tbtpo.data_entrada
                      ,tbtpo.tipo_item_ssp
                      ,b.tipo_papel
                      ,tbtpo.lote
                      ,tbtpo.empresa
              ;
    ----------------------------------------
  BEGIN

    l_vRegistro := 'Relatorio Posicao Estoque por Fornecedor / lote - emitido em ' || sysdate;
    fnd_file.put_line(fnd_file.output,l_vRegistro);

    l_vRegistro := 'FORNECEDOR;DT_ENTRADA;TIPO;DSC_TIPO;LOTE;DT_ULT_RM;QTDE_VOLS;PESO_TOTAL;QTDE_AVARIA;QTDE_DEFEITO;ORG;LARG;GRAMAT;ORIGEM';
    fnd_file.put_line(fnd_file.output,l_vRegistro);
    --DBMS_OUTPUT.PUT_LINE(l_vRegistro);
    --
    FOR r_recs IN c_recs
      LOOP
         --buscar data da ultima RM
         begin
            l_dt_ultrm := null;
            SELECT   max(mmt.transaction_date)
                     into l_dt_ultrm
               FROM  apps.mtl_transaction_types mtt
                    ,apps.mtl_material_transactions mmt
                    ,apps.mtl_transaction_lot_numbers mtln
                    ,apps.mtl_system_items   msi
              where  mmt.transaction_id       = mtln.transaction_id
              and    mmt.transaction_type_id  = mtt.transaction_type_id
              and    mmt.inventory_item_id    = msi.inventory_item_id
              and    mmt.organization_id      = msi.organization_id
              and    mmt.organization_id      = r_recs.org_id
              and    mmt.inventory_item_id    = r_recs.item_id
              and    mmt.transaction_date    >= r_recs.data_entrada
              and    mmt.source_code = 'INTERFACE MOV. PAPEL'
              and    mtt.transaction_type_id  = 284 --consumo grafica
              and    substr(mtln.lot_number,1,6) = r_recs.lote
            group by substr(mtln.lot_number,1,6);

          exception when others then
               null;
          end;
          --
          l_vRegistro :=  r_recs.fornecedor                                      || ';' ||
                          r_recs.data_entrada                                    || ';' ||
                          r_recs.cod_tipo                                        || ';' ||
                          r_recs.tipo                                            || ';' ||
                          r_recs.lote                                            || ';' ||
                          l_dt_ultrm                                             || ';' ||
                          r_recs.qtde_vols                                       || ';' ||
                          REPLACE(REPLACE(r_recs.peso_total,',',''),'.',',')     || ';' ||
                          REPLACE(REPLACE(r_recs.qtde_avaria,',',''),'.',',')    || ';' ||
                          REPLACE(REPLACE(r_recs.qtde_defeito,',',''),'.',',')   || ';' ||
                          r_recs.organizacao                                     || ';' ||
                          r_recs.larg                                            || ';' ||
                          r_recs.gramat                                          || ';' ||
                          r_recs.origem;

          fnd_file.put_line(fnd_file.output,l_vRegistro);
          --DBMS_OUTPUT.PUT_LINE(l_vRegistro);

   END LOOP;

  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de Posicao estoque por Fabricante/lote. ' || SQLERRM);
        --DBMS_OUTPUT.PUT_LINE('Erro ao processar relatorio CSV reservas. ' || SQLERRM);

  END gera_lst_pos_estoq_fab_p;
  -------

  PROCEDURE gera_lst_fifo_p (errbuf               IN OUT VARCHAR2
                            ,retcode              IN OUT NUMBER
                            ,p_organization_id    IN NUMBER) IS

    l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_vRegistro              varchar2(1000);

    -- Lista Picking
    CURSOR c_fifo IS
                SELECT msi.segment1                                                  papel
                      ,substr(nvl(upper(moq.lot_number),' '),1,6)                    lote
                      ,ood.organization_code                                         empresa
                      ,moq.subinventory_code                                         local
                      ,MAX(moq.last_update_date)                                     data_atualizacao
                      ,SUM(nvl(moq.transaction_quantity,0))                          qtd_atual
                      ,SUM(nvl(to_number(mln.n_attribute2),0))                       qtde_avaria
                      ,SUM(decode(mln.c_attribute2,NULL,0,moq.transaction_quantity)) qtd_defeito
                      ,SUM(decode(mln.c_attribute2,NULL,0,moq.transaction_quantity)) +  SUM(nvl(to_number(mln.n_attribute2),0)) QTDE_RUIM
                      ,SUM(nvl(moq.transaction_quantity,0))                          QTD_BOM
                      ,COUNT(1)                                                      total_volumes
                      ,msi.inventory_item_id                                         item_id
                      ,to_char(sysdate,'yyyy')                                       ano
                      ,to_char(sysdate,'mm')                                         mes                   
                      ,decode(sign(length(mil.segment2)-5),-1,'OTAVIANO',mil.segment2)     deposito
                      ,msi.description                                               dsc_item
                      ,tipo.element_value                                            tipo_papel
                      ,ood.organization_name                                         dsc_empresa
                      ,mln.c_attribute4                                              fornecedor
                      ,MIN(moq.creation_date)                                        dt_entrada
                 FROM  apps.org_organization_definitions ood
                      ,apps.hr_all_organization_units    hou
                      ,apps.mtl_cross_references         mcr
                      ,apps.mtl_lot_numbers              mln
                      ,apps.mtl_onhand_quantities        moq
                      ,apps.mtl_system_items_b           msi
                      ,apps.mtl_item_locations           mil
                      ,apps.mtl_parameters               mp
                      ,apps.mtl_descr_element_values    tipo                  
                WHERE  msi.inventory_item_id                         = moq.inventory_item_id
                   AND msi.organization_id                           = moq.organization_id
                   AND ood.organization_id                           = moq.organization_id
                   AND mcr.inventory_item_id                         = moq.inventory_item_id
                   AND mcr.cross_reference_type                      = 'CODIGO LEGADO SSP'
                   AND moq.lot_number                                = mln.lot_number
                   AND moq.inventory_item_id                         = mln.inventory_item_id
                   AND moq.organization_id                           = mln.organization_id
                   AND ood.organization_code||moq.subinventory_code != '002011'
                   and ood.organization_id = hou.organization_id
                   and hou.attribute1 = 'SIM'
                   and mil.organization_id                           = mp.organization_id
                   and moq.locator_id                                = mil.inventory_location_id 
                   AND ood.organization_code                         = mp.organization_code
                   AND moq.subinventory_code                         = mil.subinventory_code 
                   AND msi.inventory_item_id                         = tipo.inventory_item_id
                   AND tipo.element_name                             = 'TIPO'                      
                   and ood.organization_id                           = p_organization_id
                   and moq.subinventory_code NOT IN (SELECT lookup_code
                                                       FROM fnd_lookup_values
                                                      WHERE lookup_type = 'ABRL_INV_MAQUINA_GRAFICA'
                                                        AND LANGUAGE    = 'PTB')                  
                GROUP BY msi.segment1
                      ,msi.inventory_item_id
                      ,substr(nvl(upper(moq.lot_number),' '),1,6)
                      ,ood.organization_code
                      ,moq.subinventory_code
                      ,mil.segment2
                      ,msi.description
                      ,tipo.element_value
                      ,ood.organization_name
                      ,mln.c_attribute4
                order by ood.organization_code                   
                      ,moq.subinventory_code
                      ,msi.segment1
                      ,substr(nvl(upper(moq.lot_number),' '),1,6)
                      ,MAX(moq.last_update_date);

    ----------------------------------------
  BEGIN
    -- cabecalho
    l_vRegistro := 'Relatorio FIFO  -  Emissao em ' || sysdate;
    fnd_file.put_line(fnd_file.output,l_vRegistro);
    --dbms_output.put_line(l_vRegistro);

    l_vRegistro := ';';
    fnd_file.put_line(fnd_file.output,l_vRegistro);
    --dbms_output.put_line(l_vRegistro);  
  
    l_vRegistro := 'EMPRESA;DESC EMPRESA;PAPEL;DESCRICAO;TIPO PAPEL;LOTE;LOCAL;DSC LOCAL;QTD_ATUAL;DT ENTRADA;DT ULT MOV;QTDE_AVARIA;QTD_DEFEITO;QTD_BOM;QTDE_RUIM;TOTAL_VOLUMES;FORNEC;';
    fnd_file.put_line(fnd_file.output,l_vRegistro);

    --
    FOR r_fifo IN c_fifo
      LOOP

          l_vRegistro :=  r_fifo.EMPRESA                || ';' ||
                          r_fifo.DSC_EMPRESA            || ';' ||
                          r_fifo.PAPEL                  || ';' ||
                          r_fifo.DSC_ITEM               || ';' ||
                          r_fifo.TIPO_PAPEL             || ';' ||
                          r_fifo.LOTE                   || ';' ||
                          r_fifo.LOCAL                  || ';' ||
                          r_fifo.deposito               || ';' ||
                          trunc(r_fifo.QTD_ATUAL)       || ';' ||
                          r_fifo.DT_ENTRADA             || ';' ||
                          r_fifo.DATA_ATUALIZACAO       || ';' ||
                          trunc(r_fifo.QTDE_AVARIA)     || ';' ||
                          trunc(r_fifo.QTD_DEFEITO)     || ';' ||
                          trunc(r_fifo.QTD_BOM)         || ';' ||
                          trunc(r_fifo.QTDE_RUIM)       || ';' ||
                          r_fifo.TOTAL_VOLUMES          || ';' ||
                          r_fifo.FORNECEDOR             
                          ;
                          
          fnd_file.put_line(fnd_file.output,l_vRegistro);
   END LOOP r_transaction;


  EXCEPTION
     WHEN OTHERS THEN
        retcode  := 1; -- warning
        fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio FIFO. ' || SQLERRM);

  END gera_lst_fifo_p;

  -------------------------------------------------------------------------------------------------
 --> Projeto Planejamento de Papel <--
PROCEDURE carga_metrics_p          (errbuf           IN OUT VARCHAR2
                                     ,retcode          IN OUT NUMBER
                                     ,p_ncarga         IN NUMBER
                                     --,p_organization   IN NUMBER
                                     ) is
  Cursor dem_res is
           SELECT
             COD_APLICACAO
            ,COD_CENTRO_CUSTO_LUCRO
            ,COD_DIVISAO
            ,lpad(cod_item,8,'0') COD_ITEM
            ,COD_PRODUTO
            ,COD_UNIDADE_MEDIDA
            ,max(CREATED_BY)    created_by
            ,max(CREATION_DATE) creation_date
            ,max(trunc(DATA_CAPA))     data_capa
            ,max(trunc(DATA_EXPEDICAO)) data_expedicao
            ,DSCREVISTA
            ,max(trunc(DT_CONSUMO)) dt_consumo
            ,max(trunc(DT_INCLUSAO)) dt_inclusao
            ,EDICAO1
            ,max(nvl(IDOSMAE,0)) idosmae
            ,LOC_IMPRESSAO
            ,max(NUM_TIRAGEM) num_tiragem
            ,PERIODICIDADE
            ,PROCESSO PROCESSO_ORIGEM
            ,decode(PROCESSO,'Off-Set Plana','OP','Rotogravura','RO','Off-Set Rotativa','OR','XX') PROCESSO
            ,sum(trunc(QTD_CONSUMO))  qtd_consumo
            ,max(QTD_CORES_NF) qtd_cores_nf
            ,max(QTD_CORES_NV) qtd_cores_nv
            ,sum(QTD_PAGINAS)  qtd_paginas
            ,SGL_SISTEMA_ORIGEM
            ,SUB_INVENTARIO
            ,ORG_INVENTARIO
          FROM    bolinf.XXINV_DEMANDA_PAPEL_METRICS
          WHERE   cod_carga = p_ncarga
          AND     nvl(cod_aplicacao,0) not in (9832,8910,6207,7620,6504,0)
          GROUP BY
             org_inventario
            ,sub_inventario
            ,cod_item
            ,cod_aplicacao
            ,edicao1
            ,COD_CENTRO_CUSTO_LUCRO
            ,COD_DIVISAO
            ,COD_PRODUTO
            ,COD_UNIDADE_MEDIDA
            ,DSCREVISTA
            ,LOC_IMPRESSAO
            ,PERIODICIDADE
            ,PROCESSO
            ,SGL_SISTEMA_ORIGEM
          ORDER BY
             org_inventario
            ,sub_inventario
            ,cod_aplicacao
            ,edicao1
            ,cod_item
            ,DT_CONSUMO
  ;
  Cursor res_cancel is
         Select pc.num_produto
               ,pc.num_edicao
               ,pc.cod_item
               ,pc.cod_inv
               ,pc.cod_sub_inv
               ,nvl(pc.ind_bloqueio_reserva,'N') ind_bloqueio
               ,pc.num_reserva
               ,pc.dat_utilizacao
               ,pc.qtd_paginas
               ,pc.num_tiragem
               ,pc.qtd_kg_papel_reservado qtd_consumo
               ,pc.cod_org
               ,pc.dsc_elemento
               ,msb.description desc_papel
               ,xitp.dsc_revista
               ,msb.inventory_item_id item_id
               ,pc.cod_tipo_reserva
         from   bolinf.xxinv_reserva_papel pc
               ,apps.mtl_system_items_b msb
               ,bolinf.xxinv_tab_aplic xitp
         where  pc.cod_item = msb.segment1
         and    pc.cod_org  = msb.organization_id
         and    pc.num_produto = xitp.num_produto
         and    pc.cod_carga >= 0
         and    pc.cod_carga <> p_ncarga
--         and    nvl(pc.ind_bloqueio_reserva,'N') <> 'N'
         and    pc.cod_situacao = 1 --not in (2,3,4) -- situaç da reserva. 1=ativa / 2=provisoria / 3-cancelada/4-encerrada
         order by
                pc.cod_inv
               ,pc.cod_sub_inv
               ,pc.num_produto
               ,pc.num_edicao
               ,pc.cod_item
               ,pc.dat_utilizacao
               ;

  l_ddtdefault      date:=to_date('01/01/1900','dd/mm/rrrr');
  l_ncontador       number:=0;
  v_dtconsumo       date;
  l_vnum_produto    bolinf.xxinv_reserva_papel.num_produto%type;
  l_vdsc_elemento   bolinf.xxinv_reserva_papel.dsc_elemento%type;
  l_berror          boolean := false;
  l_vcodpapel       bolinf.xxinv_demanda_papel_metrics.cod_item%type;
  l_nnum_reserva    bolinf.xxinv_reserva_papel.num_reserva%type;
  l_dutilizacao     bolinf.xxinv_reserva_papel.dat_utilizacao%type;
  l_vsituacao       bolinf.xxinv_reserva_papel.cod_situacao%type;
  l_vregistro       varchar2(1000);
  l_vdescpapel      apps.mtl_system_items_b.description%type;
  l_nnumreserva     bolinf.xxinv_reserva_papel.num_reserva%type;
  l_vitemcrossref   apps.mtl_cross_references.cross_reference%type;
  l_vstatus_log     varchar2(100);
  l_nqtde_reserva   bolinf.xxinv_reserva_papel.qtd_kg_papel_reservado%type;
  l_nqtd_paginas    bolinf.xxinv_reserva_papel.qtd_paginas%type;
  l_vindbloqueio    bolinf.xxinv_reserva_papel.ind_bloqueio_reserva%type;
  l_ntiragem        bolinf.xxinv_reserva_papel.num_tiragem%type;
  l_vcodorg         bolinf.xxinv_reserva_papel.cod_org%type;
  l_ncont_cancel    number:=0;
  l_ncod_aplic      bolinf.xxinv_demanda_papel_metrics.cod_aplicacao%type;
  l_nitemid         apps.mtl_system_items_b.inventory_item_id%type;
  l_ncodtiporeserva bolinf.xxinv_reserva_papel.cod_tipo_reserva%type;
  v_qentregue       number:=0;

  begin

      retcode  := 0; -- warning

      l_vRegistro := 'ATUALIZAÇO DEMANDAS DE RESERVAS - INTERFACE METRICS  X  ERP-INV            Data Carga ' || sysdate || ' Num Carga => ' || lpad(p_ncarga,10,'0');
      fnd_file.put_line(fnd_file.output,l_vRegistro);
--      dbms_output.put_line(l_vRegistro);

      l_vRegistro := 'ORGANIZACAO;INV;SUBINV;ITEM PAPEL;DSC_PAPEL;DSC PRODUTO;APLICACAO;EDICAO;RESERVA;DT UTIL;ELEMENTO;PAG;TIRAGEM;QTDE;OCORRENCIA';
      fnd_file.put_line(fnd_file.output,l_vRegistro);
--      dbms_output.put_line(l_vRegistro);

      if nvl(p_ncarga,0) <= 0 then
        l_vRegistro:= ('Erro ao apropriar numero da carga. CARGA DEMANDA LEGADO METRICS, processo planejamento de papel. ' || SQLERRM);
--        dbms_output.put_line('Erro ao apropriar numero da carga. CARGA DEMANDA LEGADO METRICS, processo planejamento de papel. ' || SQLERRM);
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        raise_application_error(-20007,'Erro ao apropriar numero da carga. CARGA DEMANDA LEGADO METRICS, processo planejamento de papel. '||SQLERRM);
        retcode  := 1; -- warning
      end if;

      for c_demanda in dem_res loop
          l_nContador := l_nContador + 1;
          l_bError := FALSE;

          v_dtConsumo :=c_demanda.dt_consumo;

          l_vCodOrg :='0';
          begin
              select ood.organization_id
              into   l_vCodOrg
              from   apps.org_organization_definitions ood
              where  ood.organization_code = lpad(c_demanda.org_inventario,3,'0');
          exception
              when others then
                 l_vCodOrg :='0';
          end;

          if nvl(c_demanda.dt_consumo,l_dDtdefault) = l_dDtdefault or
             nvl(c_demanda.dt_consumo,l_dDtdefault) = nvl(c_demanda.data_expedicao,l_dDtdefault) then

             if nvl(c_demanda.cod_divisao,0) in (1000008,1000026,1000030,1000033) then --1000008=COMERCIAIS / 1000026=LIVROS / 1000030=CARREFOUR / 1000033=AVON

                if c_demanda.cod_divisao = 1000030 then
                   v_dtConsumo := c_demanda.dt_consumo - 5;  --CARREFOUR  5 dias
                else
                   v_dtConsumo := c_demanda.dt_consumo - 10; --AVON 10 dias
                end if;

             else

                if c_demanda.periodicidade in ('Quinzenal','Semanal') then
                   if c_demanda.cod_aplicacao = '5150' then
                      v_dtConsumo := c_demanda.dt_consumo - 1;  --Veja 1 dia
                   else
                      v_dtConsumo := c_demanda.dt_consumo - 3;  --Outros 3 dias
                   end if;

                else
                   v_dtConsumo := c_demanda.dt_consumo - 10;  --Eventual  e  Mensal 10 dias

                end if;

             end if;

          end if;

          --atualizar tabela de aplicacao --> bolinf.XXINV_TAB_APLIC
          begin
            SELECT nvl(num_produto,'0')
              INTO l_vNum_produto
              FROM bolinf.XXINV_TAB_APLIC
             WHERE num_produto = c_demanda.cod_aplicacao;

          exception
             when no_data_found then
                  begin
                     insert into bolinf.xxinv_tab_aplic
                            ( NUM_PRODUTO
                             ,DSC_REVISTA
                             ,COD_PRODUTO
                             ,COD_CENTRO_CUSTO_LUCRO
                             ,PERIODICIDADE
                             ,CREATION_DATE
                             ,CREATED_BY
                         --  ,LAST_UPDATE_DATE
                         --  ,LAST_UPDATED_BY
                            )
                     values ( c_demanda.cod_aplicacao
                             ,c_demanda.dscrevista
                             ,c_demanda.cod_produto
                             ,c_demanda.cod_centro_custo_lucro
                             ,c_demanda.periodicidade
                             ,sysdate
                             ,fnd_profile.VALUE('USER_ID')
                            );
                  exception when others then
                     l_vRegistro:= 'Erro INSERT tabela aplicaç XXINV_TAB_APLIC, processo planejamento de papel. ' || SQLERRM;
                     --dbms_output.put_line('Erro INSERT tabela aplicaç XXINV_TAB_APLIC, processo planejamento de papel. ' || SQLERRM);
                     fnd_file.put_line(fnd_file.output,l_vRegistro);
                     retcode  := 1; -- warning
                  end;

             when others then
                  l_vRegistro:= 'Erro SELECT tabela aplicaç XXINV_TAB_APLIC, processo planejamento de papel. ' || SQLERRM;
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);
                  retcode  := 1; -- warning
          end;

          --buscar DSC_ELEMENTO
          l_vDsc_elemento := null;
          for c_dsc_elemento in (select  dsc_elemento
                                   FROM  bolinf.XXINV_DEMANDA_PAPEL_METRICS
                                  WHERE  cod_carga = p_ncarga
                                    AND  nvl(cod_aplicacao,0) not in (9832,8910,6207,7620,6504,0)
                                    AND  org_inventario         = c_demanda.org_inventario
                                    AND  sub_inventario         = c_demanda.sub_inventario
                                    AND  lpad(cod_item,8,'0')   = c_demanda.cod_item
                                    AND  cod_aplicacao          = c_demanda.cod_aplicacao
                                    AND  edicao1                = c_demanda.edicao1
                                    AND  COD_CENTRO_CUSTO_LUCRO = c_demanda.cod_centro_custo_lucro
                                    AND  COD_DIVISAO            = c_demanda.cod_divisao
                                    AND  COD_PRODUTO            = c_demanda.cod_produto
                                    AND  COD_UNIDADE_MEDIDA     = c_demanda.cod_unidade_medida
                                    AND  DSCREVISTA             = c_demanda.dscrevista
                                    AND  LOC_IMPRESSAO          = c_demanda.loc_impressao
                                    AND  PERIODICIDADE          = c_demanda.periodicidade
                                    AND  PROCESSO               = c_demanda.processo_origem
                                 )
          loop
              if l_vDsc_elemento is null then
                 l_vDsc_elemento := c_dsc_elemento.dsc_elemento;
              else
                 begin
                  l_vDsc_elemento := l_vDsc_elemento || '/' || c_dsc_elemento.dsc_elemento;
                 exception when others then
                     --dbms_output.put_line(l_vDsc_elemento);
                     l_vDsc_elemento := substr(l_vDsc_elemento,1,40);
                 end;
              end if;

          end loop;
          --

          --valida codigo de papel
          begin
             select msi.segment1
                  , msi.description
                  , mcr.cross_reference
                  , msi.inventory_item_id
             into   l_vCodpapel
                  , l_vDescpapel
                  , l_vItemCrossRef
                  , l_nItemId
             from   apps.mtl_system_items_b msi
                   ,mtl_cross_references mcr
             where  msi.segment1           = c_demanda.cod_item
             and    msi.inventory_item_id  = mcr.inventory_item_id
             and    msi.organization_id   =  (select organization_id
                                              from apps.hr_all_organization_units
                                              where name like '%MESTRE%');
          exception
             when no_data_found then
                  retcode  := 1; -- warning
                  l_bError := TRUE;
                  l_vRegistro := null;


                  l_vRegistro := l_vCodOrg                  || ';' ||
                                 c_demanda.org_inventario   || ';' ||
                                 c_demanda.sub_inventario   || ';' ||
                                 c_demanda.cod_item         || ';' ||
                                 'Item de papel nãcadastrado no ERP-INV'           || ';' ||
                                 c_demanda.dscrevista       || ';' ||
                                 c_demanda.cod_aplicacao    || ';' ||
                                 c_demanda.edicao1          || ';' ||
                                 '0'                        || ';' ||
                                 c_demanda.dt_consumo       || ';' ||
                                 l_vDsc_elemento            || ';' ||
                                 c_demanda.qtd_paginas      || ';' ||
                                 c_demanda.num_tiragem      || ';' ||
                                 c_demanda.qtd_consumo      || ';' ||
                                 'ITEM NÃ LOCALIZADO'
                                 ;

                  fnd_file.put_line(fnd_file.output,l_vRegistro);
--                  dbms_output.put_line(l_vRegistro);
             when others then
                  retcode  := 1; -- warning
                  l_bError := TRUE;
                  l_vRegistro := l_vCodOrg                  || ';' ||
                                 c_demanda.org_inventario   || ';' ||
                                 c_demanda.sub_inventario   || ';' ||
                                 c_demanda.cod_item         || ';' ||
                                 'nao localizado'           || ';' ||
                                 c_demanda.dscrevista       || ';' ||
                                 c_demanda.cod_aplicacao    || ';' ||
                                 c_demanda.edicao1          || ';' ||
                                 '0'                        || ';' ||
                                 c_demanda.dt_consumo       || ';' ||
                                 l_vDsc_elemento            || ';' ||
                                 c_demanda.qtd_paginas      || ';' ||
                                 c_demanda.num_tiragem      || ';' ||
                                 c_demanda.qtd_consumo      || ';' ||
                                 'Erro SELECT tabela apps.MTL_SYSTEMS_ITEMS_B, processo planejamento de papel. ' ||
                                 SQLERRM
                                 ;
                 --dbms_output.put_line(l_vRegistro);
                 fnd_file.put_line(fnd_file.output,l_vRegistro);

          end;

          if c_demanda.qtd_consumo <= 0 then
                    retcode  := 1; -- warning
                    l_bError := TRUE;
                    l_vRegistro := null;

                    l_vRegistro := l_vCodOrg                  || ';' ||
                                   c_demanda.org_inventario   || ';' ||
                                   c_demanda.sub_inventario   || ';' ||
                                   c_demanda.cod_item         || ';' ||
                                   l_vDescpapel               || ';' ||
                                   c_demanda.dscrevista       || ';' ||
                                   c_demanda.cod_aplicacao    || ';' ||
                                   c_demanda.edicao1          || ';' ||
                                   '0'                        || ';' ||
                                   c_demanda.dt_consumo       || ';' ||
                                   l_vDsc_elemento            || ';' ||
                                   c_demanda.qtd_paginas      || ';' ||
                                   c_demanda.num_tiragem      || ';' ||
                                   c_demanda.qtd_consumo      || ';' ||
                                   'NAO ALTERADA - Qtde menor ou igual a 0'
                                   ;
                     --dbms_output.put_line(l_vRegistro);
                     fnd_file.put_line(fnd_file.output,l_vRegistro);

            end if;

            if not l_bError then
                  -- Atualiza
                  begin
                      select num_reserva
                            ,dat_utilizacao
                            ,cod_situacao  --Situaç da reserva. 1=Ativa / 2=Provisoria / 3-Cancelada / 4-Encerrada
                            ,QTD_KG_PAPEL_RESERVADO
                            ,QTD_PAGINAS
                            ,NUM_TIRAGEM
                            ,nvl(ind_bloqueio_reserva,'N')
                            ,COD_TIPO_RESERVA
                      into   l_nNum_reserva
                            ,l_dUtilizacao
                            ,l_vSituacao
                            ,l_nQtde_reserva
                            ,l_nQtd_paginas
                            ,l_nTiragem
                            ,l_vIndBloqueio
                            ,l_nCodTipoReserva
                      from   bolinf.xxinv_reserva_papel
                      where  num_produto = c_demanda.cod_aplicacao
                      and    lpad(COD_INV,3,'0')     = lpad(c_demanda.org_inventario,3,'0')
                      and    lpad(cod_sub_inv,3,'0') = lpad(c_demanda.sub_inventario,3,'0')
                      and    lpad(cod_item,8,'0')    = lpad(c_demanda.cod_item,8,'0')
                      and    num_edicao  = c_demanda.edicao1
                      ;

                      if (l_dUtilizacao  <> c_demanda.dt_consumo or
                         l_nQtde_reserva <> c_demanda.qtd_consumo or
                         l_nQtd_paginas  <> c_demanda.qtd_paginas) then

                              l_vStatus_log := 'ALTERAR';

                              if l_vSituacao = 4 then --Encerrada
                                 l_vStatus_log := 'NAO ALTERADA - Reserva Encerrada';

                              elsif c_demanda.dt_consumo < sysdate + 30 then
                                  if l_vSituacao = 3 then --Cancelada
                                     l_vStatus_log := 'NAO REATIVADA - NO MES';
                                  else
                                     if ABS(trunc(c_demanda.dt_consumo) - trunc(l_dUtilizacao)) > 5 then
                                         l_vStatus_log := 'NAO ALTERADA - NO MES';
                                     end if;
                                  end if;

                              elsif l_vIndBloqueio = 'S' then
                                  if l_vSituacao = 3 then --cancelada
                                     l_vStatus_log := 'NAO REATIVADA-bloqueada pela area de palnejamento de Papel';
                                  else
                                     l_vStatus_log := 'NAO ALTERADA-bloqueada pela area de palnejamento de Papel';
                                  end if;
                              end if;

                              if l_vStatus_log <> 'ALTERAR' then
                                  l_vRegistro := null;
                                  l_vRegistro := l_vCodOrg                  || ';' ||
                                                 c_demanda.org_inventario   || ';' ||
                                                 c_demanda.sub_inventario   || ';' ||
                                                 c_demanda.cod_item         || ';' ||
                                                 l_vDescpapel               || ';' ||
                                                 c_demanda.dscrevista       || ';' ||
                                                 c_demanda.cod_aplicacao    || ';' ||
                                                 c_demanda.edicao1          || ';' ||
                                                 l_nNum_reserva             || ';' ||
                                                 c_demanda.dt_consumo       || ';' ||
                                                 l_vDsc_elemento            || ';' ||
                                                 c_demanda.qtd_paginas      || ';' ||
                                                 c_demanda.num_tiragem      || ';' ||
                                                 c_demanda.qtd_consumo      || ';' ||
                                                 l_vStatus_log
                                                 ;
                                  --dbms_output.put_line(l_vRegistro);
                                  fnd_file.put_line(fnd_file.output,l_vRegistro);

                              else
                                  l_vStatus_log := 'ALTERAR';
                                  --chamar a funç para verificar quantidade entreque (mtl_transactions)

                                  v_qentregue := apps.xxinv_paper_lot_pk.fnd_qtde_consumo_reserva(l_nItemId,l_nNum_reserva,l_nCodTipoReserva);

                                  if v_qentregue > 0 then
                                     l_vStatus_log := 'NAO ALTERADA - Existe Bxa. Qtde Consumo ';
                                  end if;

                                  if l_vStatus_log = 'ALTERAR' then
                                     --incluir update na tabela de reservas

                                     update bolinf.xxinv_reserva_papel xrp
                                     set   xrp.qtd_kg_papel_reservado = c_demanda.qtd_consumo
                                          ,xrp.dat_utilizacao         = c_demanda.dt_consumo
                                          ,xrp.dsc_elemento           = l_vDsc_elemento
                                          ,xrp.cod_processo           = c_demanda.processo
                                          ,xrp.num_tiragem            = c_demanda.num_tiragem
                                          ,xrp.qtd_paginas            = c_demanda.qtd_paginas
                                          ,xrp.qtd_cores_nf           = c_demanda.qtd_cores_nf
                                          ,xrp.qtd_cores_nv           = c_demanda.qtd_cores_nv
                                          ,xrp.cod_local_impressao    = c_demanda.loc_impressao
                                          ,xrp.cod_id_os_mae          = c_demanda.idosmae
                                          ,xrp.last_update_date       = sysdate
                                          ,xrp.last_updated_by        = fnd_profile.VALUE('USER_ID')
                                          ,xrp.cod_carga              = p_ncarga
                                     where xrp.num_reserva = l_nNum_reserva;

                                      l_vStatus_log := 'ALTERADA DE';
                                      l_vRegistro := null;
                                      l_vRegistro := l_vCodOrg                  || ';' ||
                                                     c_demanda.org_inventario   || ';' ||
                                                     c_demanda.sub_inventario   || ';' ||
                                                     c_demanda.cod_item         || ';' ||
                                                     l_vDescpapel               || ';' ||
                                                     c_demanda.dscrevista       || ';' ||
                                                     c_demanda.cod_aplicacao    || ';' ||
                                                     c_demanda.edicao1          || ';' ||
                                                     l_nNum_reserva             || ';' ||
                                                     l_dUtilizacao              || ';' ||
                                                     l_vDsc_elemento            || ';' ||
                                                     l_nQtd_paginas             || ';' ||
                                                     l_nTiragem                 || ';' ||
                                                     l_nQtde_reserva            || ';' ||
                                                     l_vStatus_log
                                                     ;
                                      --dbms_output.put_line(l_vRegistro);
                                      fnd_file.put_line(fnd_file.output,l_vRegistro);

                                      l_vStatus_log := 'ALTERADA PARA';
                                      l_vRegistro := null;
                                      l_vRegistro := l_vCodOrg                  || ';' ||
                                                     c_demanda.org_inventario   || ';' ||
                                                     c_demanda.sub_inventario   || ';' ||
                                                     c_demanda.cod_item         || ';' ||
                                                     l_vDescpapel               || ';' ||
                                                     c_demanda.dscrevista       || ';' ||
                                                     c_demanda.cod_aplicacao    || ';' ||
                                                     c_demanda.edicao1          || ';' ||
                                                     l_nNum_reserva             || ';' ||
                                                     c_demanda.dt_consumo       || ';' ||
                                                     l_vDsc_elemento            || ';' ||
                                                     c_demanda.qtd_paginas      || ';' ||
                                                     c_demanda.num_tiragem      || ';' ||
                                                     c_demanda.qtd_consumo      || ';' ||
                                                     l_vStatus_log
                                                     ;
                                      --dbms_output.put_line(l_vRegistro);
                                      fnd_file.put_line(fnd_file.output,l_vRegistro);

                                  end if;
                              end if;

                      end if;

                  exception
                              when no_data_found then

                                    if c_demanda.dt_consumo < sysdate + 30 then --inlcusao
                                        l_vRegistro := null;
                                        l_vRegistro := l_vCodOrg                  || ';' ||
                                                       c_demanda.org_inventario   || ';' ||
                                                       c_demanda.sub_inventario   || ';' ||
                                                       c_demanda.cod_item         || ';' ||
                                                       l_vDescpapel               || ';' ||
                                                       c_demanda.dscrevista       || ';' ||
                                                       c_demanda.cod_aplicacao    || ';' ||
                                                       c_demanda.edicao1          || ';' ||
                                                       '0'                        || ';' ||
                                                       c_demanda.dt_consumo       || ';' ||
                                                       l_vDsc_elemento            || ';' ||
                                                       c_demanda.qtd_paginas      || ';' ||
                                                       c_demanda.num_tiragem      || ';' ||
                                                       c_demanda.qtd_consumo      || ';' ||
                                                       'NAO INCLUIDA - NO MES'
                                                       ;
                                        --dbms_output.put_line(l_vRegistro);
                                        fnd_file.put_line(fnd_file.output,l_vRegistro);

                                    else

                                        l_nNumReserva := 0;

                                        begin
                                          select BOLINF.XXINV_RESERVA_S.nextval
                                            into l_nNumReserva
                                            from dual;
                                        exception
                                          when others then
                                            l_vRegistro:= 'Erro SEQUENCE numero da reserva BOLINF.XXINV_RESERVA_S, processo planejamento de papel. ' || SQLERRM;
                                            fnd_file.put_line(fnd_file.output,l_vRegistro);
                                            --dbms_output.put_line(l_vRegistro);

                                            retcode  := 1; -- warning
                                            errbuf   := sqlerrm;
                                            l_nNumReserva := 0;
                                        end;

                                        if l_nNumReserva > 0 then

                                              begin
                                                 insert into bolinf.xxinv_reserva_papel
                                                        (  NUM_RESERVA               --01
                                                         , COD_ORG                   --02
                                                         , COD_INV                   --03
                                                         , COD_SUB_INV               --04
                                                         , COD_ITEM                  --05
                                                         , NUM_PRODUTO               --06
                                                         , NUM_EDICAO                --07
                                                         , QTD_KG_PAPEL_RESERVADO    --08
                                                         , DAT_UTILIZACAO            --09
                                                         , DSC_ELEMENTO              --10
                                                         , COD_PROCESSO              --11
                                                         , COD_TIPO_RESERVA          --12 --1 Reserva/2 PNFC/3 PNFT
                                                         , QTD_PAGINAS               --13
                                                         , QTD_CORES_NF              --14
                                                         , QTD_CORES_NV              --15
                                                         , NUM_TIRAGEM               --16
                                                         , COD_LOCAL_IMPRESSAO       --17
                                                         , CREATION_DATE             --18
                                                         , CREATED_BY                --19
                                                         , COD_ID_OS_MAE             --20
                                                         , COD_ITEM_CROSS_REF        --21
                                                         , COD_SITUACAO              --22
                                                         , IND_BLOQUEIO_RESERVA      --23
                                                         , COD_CARGA                 --24
                                                       --, COD_ID_OS_FILHA           --
                                                        )
                                                 values ( l_nNumReserva                --01
                                                         ,l_vCodOrg                    --02
                                                         ,lpad(c_demanda.org_inventario,3,'0')   --03
                                                         ,lpad(c_demanda.sub_inventario,3,'0')   --04
                                                         ,lpad(c_demanda.cod_item,8,'0')         --05
                                                         ,lpad(c_demanda.cod_aplicacao,4,'0')    --06
                                                         ,c_demanda.edicao1            --07
                                                         ,c_demanda.qtd_consumo        --08
                                                         ,c_demanda.dt_consumo         --09
                                                         ,l_vDsc_elemento              --10
                                                         ,c_demanda.processo           --11
                                                         ,1                            --12
                                                         ,c_demanda.qtd_paginas        --13
                                                         ,c_demanda.qtd_cores_nf       --14
                                                         ,c_demanda.qtd_cores_nv       --15
                                                         ,c_demanda.num_tiragem        --16
                                                         ,c_demanda.loc_impressao      --17
                                                         ,sysdate                      --18
                                                         ,fnd_profile.VALUE('USER_ID') --19
                                                         ,c_demanda.idosmae            --20
                                                         ,lpad(l_vItemCrossRef,8,'0')  --21
                                                         ,'1'                          --22 => Situaç da reserva. 1=Ativa / 2=Provisoria / 3-Cancelada/4-Encerrada
                                                         ,'N'                          --23 => default "N"-nao
                                                         , p_ncarga                    --24
                                                        );

                                                          l_vRegistro := null;
                                                          l_vRegistro := l_vCodOrg                  || ';' ||
                                                                         c_demanda.org_inventario   || ';' ||
                                                                         c_demanda.sub_inventario   || ';' ||
                                                                         c_demanda.cod_item         || ';' ||
                                                                         l_vDescpapel               || ';' ||
                                                                         c_demanda.dscrevista       || ';' ||
                                                                         c_demanda.cod_aplicacao    || ';' ||
                                                                         c_demanda.edicao1          || ';' ||
                                                                         l_nNumReserva              || ';' ||
                                                                         c_demanda.dt_consumo       || ';' ||
                                                                         l_vDsc_elemento            || ';' ||
                                                                         c_demanda.qtd_paginas      || ';' ||
                                                                         c_demanda.num_tiragem      || ';' ||
                                                                         c_demanda.qtd_consumo      || ';' ||
                                                                         'INCLUIDA'
                                                                         ;
                                                          --dbms_output.put_line(l_vRegistro);
                                                          fnd_file.put_line(fnd_file.output,l_vRegistro);

                                                        --> ATUALIZAR TABELA DE HISTORICO RESERVA (NOVO)
                                                        --> criar tabela para guardar historico da reserva.

                                             exception when others then
                                                  l_vRegistro:= 'Erro INSERT tabela reservas XXINV_RESERVA_PAPEL, processo planejamento de papel. ' || SQLERRM;
                                                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                                                  --dbms_output.put_line(l_vRegistro);

                                                  retcode  := 1; -- warning
                                             end;

                                        end if;

                                    end if;

                              when others then
                                    --l_vRegistro:= ('Erro SELECT tabela reservas XXINV_RESERVA_PAPEL, processo planejamento de papel. ' || SQLERRM);
                                    fnd_file.put_line(fnd_file.output,l_vRegistro);
                                    --dbms_output.put_line(l_vRegistro);

                                    retcode  := 1; -- warning
                                    errbuf   := sqlerrm;
                                    l_vRegistro := l_vCodOrg                  || ';' ||
                                                   c_demanda.org_inventario   || ';' ||
                                                   c_demanda.sub_inventario   || ';' ||
                                                   c_demanda.cod_item         || ';' ||
                                                   'nao localizado'           || ';' ||
                                                   c_demanda.dscrevista       || ';' ||
                                                   c_demanda.cod_aplicacao    || ';' ||
                                                   c_demanda.edicao1          || ';' ||
                                                   '0'                        || ';' ||
                                                   c_demanda.dt_consumo       || ';' ||
                                                   l_vDsc_elemento            || ';' ||
                                                   c_demanda.qtd_paginas      || ';' ||
                                                   c_demanda.num_tiragem      || ';' ||
                                                   c_demanda.qtd_consumo      || ';' ||
                                                   sqlerrm
                                                   ;
                                    --dbms_output.put_line(l_vRegistro);
                                    fnd_file.put_line(fnd_file.output,l_vRegistro);

                  end;

            end if;

      end loop;

      commit;
      --

      --> incluir rotina para cancelar/encerrar as reservas, ler a tabela customizada de reservas xxinv_reserva_papel
      --> e comparar com a tabela de interface de carga pelo numero da carga, e fazer o merge....
      FOR c_cancel in res_cancel  LOOP

          l_vRegistro := c_cancel.cod_org                          || ';' ||
                         c_cancel.cod_inv                          || ';' ||
                         lpad(c_cancel.cod_sub_inv,3,'0')          || ';' ||
                         c_cancel.cod_item                         || ';' ||
                         c_cancel.desc_papel                       || ';' ||
                         c_cancel.dsc_revista                      || ';' ||
                         c_cancel.num_produto                      || ';' ||
                         c_cancel.num_edicao                       || ';' ||
                         c_cancel.num_reserva                      || ';' ||
                         c_cancel.dat_utilizacao                   || ';' ||
                         c_cancel.dsc_elemento                     || ';' ||
                         c_cancel.qtd_paginas                      || ';' ||
                         c_cancel.num_tiragem                      || ';' ||
                         c_cancel.qtd_consumo;


          begin

             Select xid.cod_aplicacao
             into   l_ncod_aplic
             from   bolinf.XXINV_DEMANDA_PAPEL_METRICS  xid
             where  xid.cod_aplicacao = c_cancel.num_produto
              and   lpad(xid.org_inventario,3,'0') = lpad(c_cancel.COD_INV,3,'0')
              and   lpad(xid.sub_inventario,3,'0') = lpad(c_cancel.cod_sub_inv,3,'0')
              and   lpad(xid.cod_item,8,'0') = lpad(c_cancel.cod_item,8,'0')
              and   xid.edicao1 = c_cancel.num_edicao
              and   xid.cod_carga = p_ncarga
            group by org_inventario
                    ,sub_inventario
                    ,cod_item
                    ,cod_aplicacao
                    ,edicao1
                    ,cod_centro_custo_lucro
                    ,cod_divisao
                    ,cod_produto
                    ,cod_unidade_medida
                    ,dscrevista
                    ,loc_impressao
                    ,periodicidade
                    ,processo
                    ,sgl_sistema_origem
                    ;

          exception
                   when no_data_found then --cancelar

                       if c_cancel.ind_bloqueio = 'S' then
                            l_vRegistro := l_vRegistro || ';' || 'NAO CANCELADA - Modific p/Depto Papel';
                       elsif c_cancel.dat_utilizacao < sysdate + 30 then
                            l_vRegistro := l_vRegistro || ';' || 'NAO CANCELADA - NO MES';
                       elsif c_cancel.dat_utilizacao >= sysdate + 30 then

                            begin
                               v_qentregue := apps.xxinv_paper_lot_pk.fnd_qtde_consumo_reserva(c_cancel.item_id,c_cancel.Num_reserva,c_cancel.cod_tipo_reserva);
                            exception when others then
                               l_vRegistro := l_vRegistro || ';' || 'ERRO NO CANCELAMENTO DA RESERVA,retorno consumo -> ' || sqlerrm;
                               v_qentregue := 1;
                            end;

                            if v_qentregue > 0 then
                               l_vRegistro := l_vRegistro || ';' || 'NAO CANCELADA - Existe Bxa. Qtde Consumo = ' || '' || v_qentregue;
                            else
                                begin
                                      update bolinf.xxinv_reserva_papel xrp
                                      set xrp.COD_SITUACAO = 3 --CANCELADA
                                         ,xrp.last_update_date       = sysdate
                                         ,xrp.last_updated_by        = fnd_profile.VALUE('USER_ID')
                                      where xrp.num_reserva = c_cancel.Num_reserva;

                                      l_nCont_cancel := l_nCont_cancel+1;
                                      l_vRegistro := l_vRegistro || ';' || 'C A N C E L A D A';

                                exception when others then
                                      l_vRegistro := l_vRegistro || ';' || 'ERRO NO CANCELAMENTO DA RESERVA -> ' || sqlerrm;
                                end;
                            end if;


                       end if;

                       fnd_file.put_line(fnd_file.output,l_vRegistro);
                       --dbms_output.put_line(l_vRegistro);

                   when others then
                            l_vRegistro := l_vRegistro                 || ';' ||
                                        'Erro SELECT DE CANCELAMENTO DA RESERVA -> ' || sqlerrm;
                          --dbms_output.put_line(l_vRegistro);
                          fnd_file.put_line(fnd_file.output,l_vRegistro);

            end;

      END LOOP;
      --
      commit;

EXCEPTION
      WHEN OTHERS THEN
        retcode  := 1; -- warning
        l_vRegistro:= 'Erro ao processar CARGA DEMANDA LEGADO METRICS, processo planejamento de papel. ' || SQLERRM;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

END carga_metrics_p;

PROCEDURE atu_tabelas_demanda_p    (errbuf           IN OUT VARCHAR2
                                   ,retcode           IN OUT NUMBER) is

    --
    l_vWS_Name        bolinf.XXFND_WEBSERVICES.service_name%TYPE := 'PlanejamentoPapelService.SincronizarReservaPapel';
    l_rResponse       apps.xxfnd_soap_pk.g_rResponse;
    l_tTag            apps.XXFND_SOAP_PK.g_tTag;
    l_nIndex          NUMBER         := 0;
    l_vGroup_Nm       VARCHAR2(1000)  := NULL;
    l_Ret_Sttus       VARCHAR2(32767);
    l_Des_Ret_Sttus   VARCHAR2(32767);
    l_nCod_carga      Number;
    l_nOrganization   number;
    l_vErrbuf         varchar2(1000);
    l_vRetcode        varchar2(100);
    --
  BEGIN
     --
      EXECUTE IMMEDIATE ('ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''');
      --
      l_nIndex    := 0;
      l_vGroup_Nm := 'v1:sincronizarReservaPapelRequest';          --

      begin
        select BOLINF.XXINV_CARGA_DEMANDA_PAPEL_S.nextval
          into l_nCod_carga
          from dual;
      exception
        when others then
          fnd_file.put_line(fnd_file.log,'Erro SEQUENCE numero da carga BOLINF.XXINV_CARGA_DEMANDA_PAPEL_S, processo planejamento de papel. ' || SQLERRM);
          --dbms_output.put_line('Erro SEQUENCE numero da carga BOLINF.XXINV_CARGA_DEMANDA_PAPEL_S, processo planejamento de papel. ' || SQLERRM);
          retcode  := 1; -- warning
          l_nCod_carga := 0;
      end;

      if l_nCod_carga > 0 then
            --
              l_nIndex := l_nIndex + 1;
              l_tTag( l_nIndex ).group_name   := l_vGroup_Nm;
              l_tTag( l_nIndex ).element_name := 'codCarga';
              l_tTag( l_nIndex ).value        := l_nCod_carga;
              --
              l_rResponse := apps.XXFND_SOAP_PK.Invoke_f( p_ws_name => l_vWS_Name
                                                        , p_tag     => l_tTag );
              --
              l_Ret_Sttus     := apps.XXFND_SOAP_PK.get_return_value_f( p_response => l_rResponse
                                                                      , p_tag      => 'codigo'    );
              --
              l_Des_Ret_Sttus := apps.XXFND_SOAP_PK.get_return_value_f( p_response => l_rResponse
                                                                      , p_tag      => 'mensagem' );
               --
              IF (nvl(l_Ret_Sttus,1) > '1' or l_Ret_Sttus is null) THEN
                   fnd_file.put_line(fnd_file.log, 'Erro ao executar o Serviçde carga nas tabelas de demanda/reserva: '||l_Ret_Sttus||' - '|| l_Des_Ret_Sttus || SQLERRM);
                   dbms_output.put_line(l_Ret_sttus || ' - ' || l_Des_Ret_Sttus );
                   raise_application_error(-20017,'Erro ao executar o Serviçde carga nas tabelas de demanda/reserva: '||l_Ret_Sttus||' - '||l_Des_Ret_Sttus);
                   retcode  := 1; -- warning
              ELSE
--                dbms_output.put_line(' Executou com SUCESSO -> ' || l_Ret_sttus || ' - ' || l_Des_Ret_Sttus );
                fnd_file.put_line(fnd_file.output, 'Mensagem : Executou com SUCESSO -> ' || l_Ret_sttus || ' - ' || l_Des_Ret_Sttus );
                --fnd_file.put_line(fnd_file.log, 'Mensagem : '||l_Des_Ret_Sttus);
        --
         --          null;

                    --chama procedure de carga_metrics
                    begin
                              apps.xxinv_paper_lot_pk.carga_metrics_p(errbuf           => l_vErrbuf
                                                                ,retcode          => l_vRetcode
                                                                ,p_ncarga          => l_nCod_carga
                                                               -- ,p_organization   => l_nOrganization
                                                                );
                    exception when others then
                       fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
                       --dbms_output.put_line('Mensagem erro : ' || l_vErrbuf);
                       retcode  := 1; -- warning
                    end;

              end if;

      end if;
    --
  EXCEPTION
    WHEN OTHERS THEN
      raise_application_error(-20018,'Erro ao requisitar o servico PlanejamentoPapelService. '|| sqlerrm);
      retcode  := 1; -- warning

END atu_tabelas_demanda_p;

procedure atu_reservas_legado_p( errbuf  OUT VARCHAR2
                               , retcode OUT NUMBER ) IS
  --
    l_vWS_Name        bolinf.XXFND_WEBSERVICES.service_name%TYPE := 'PlanejamentoPapelService.AtualizarReserva';
    l_rResponse       apps.xxfnd_soap_pk.g_rResponse;
    l_tTag            apps.XXFND_SOAP_PK.g_tTag;
    l_nIndex          NUMBER         := 0;
    l_vGroup_Nm       VARCHAR2(1000)  := NULL;
    l_Ret_Sttus       VARCHAR2(32767);
    l_Des_Ret_Sttus   VARCHAR2(32767);
    l_nCod_carga      Number;
    l_nOrganization   number;
    l_vErrbuf         varchar2(1000);
    l_vRetcode        varchar2(100);
    --
  BEGIN
     --
      EXECUTE IMMEDIATE ('ALTER SESSION SET NLS_NUMERIC_CHARACTERS=''.,''');
      --
      l_nIndex    := 0;
      l_vGroup_Nm := 'v1:atualizReservaPapel';          --
    --
      l_nIndex := l_nIndex + 1;
      l_tTag( l_nIndex ).group_name   := l_vGroup_Nm;
      l_tTag( l_nIndex ).element_name := 'Reserva';
      l_tTag( l_nIndex ).value        := 'x';
      --
      l_rResponse := apps.XXFND_SOAP_PK.Invoke_f( p_ws_name => l_vWS_Name
                                                , p_tag     => l_tTag );
      --
      l_Ret_Sttus     := apps.XXFND_SOAP_PK.get_return_value_f( p_response => l_rResponse
                                                              , p_tag      => 'codigo'    );
      --
      l_Des_Ret_Sttus := apps.XXFND_SOAP_PK.get_return_value_f( p_response => l_rResponse
                                                              , p_tag      => 'mensagem' );
       --
      IF (nvl(l_Ret_Sttus,1) > '1' or l_Ret_Sttus is null) THEN
        dbms_output.put_line(l_Ret_sttus || ' - ' || l_Des_Ret_Sttus || ' - ' || sqlerrm);
        raise_application_error(-20017,'Erro ao executar o Serviçde carga nas tabelas de demanda/reserva: '||l_Ret_Sttus||' - '||l_Des_Ret_Sttus);
      ELSE
        dbms_output.put_line(' Executou com SUCESSO -> ' || l_Ret_sttus || ' - ' || l_Des_Ret_Sttus );
        --fnd_file.put_line(fnd_file.output, 'Mensagem : '||l_Des_Ret_Sttus);
        --fnd_file.put_line(fnd_file.log, 'Mensagem : '||l_Des_Ret_Sttus);
      end if;

  --
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Mensagem erro : ' || sqlerrm);
   --   raise_application_error(-20018,'Erro ao requisitar o servico PlanejamentoPapelService. '|| sqlerrm);

  END atu_reservas_legado_p;
  --

FUNCTION fnd_qtde_consumo_reserva (p_item_id      IN mtl_system_items_b.inventory_item_id%TYPE
                                  ,p_num_reserva  IN bolinf.xxinv_reserva_papel.num_reserva%TYPE
                                  ,p_tipo_reserva IN bolinf.xxinv_reserva_papel.COD_TIPO_RESERVA%TYPE)--1=reserva / 2=pnfc / 3=pnft
    RETURN NUMBER IS
    --
    l_saldo NUMBER := 0;
    --
  BEGIN
    --
    if p_tipo_reserva = 1 then --Reserva
        begin
          --
          select nvl(sum(transaction_quantity * -1), 0)
            into l_saldo
            from mtl_material_transactions
           where inventory_item_id      = p_item_id
      --       and organization_id        = p_organization_id
             and attribute14            = p_num_reserva
             and transaction_type_id   in (select transaction_type_id
                                             from mtl_transaction_types
                                            where attribute8 in ('CON_PROD_A','RET_DEV_A','DEV_INT','RET_DEV','CON_PROD',
                                                                 'CON_TXT','DEV_GRAEXT','CON_TXT_A','DEV_GRAEXT_A'
                                                                 ));
        exception
          when others then
            l_saldo := 0;
        end;

    else --PNFC  e   PNFT

        begin
          select nvl(sum(transaction_quantity * -1), 0)
            into l_saldo
            from mtl_material_transactions
           where inventory_item_id      = p_item_id
      --       and organization_id        = p_organization_id
             and attribute1            = p_num_reserva
             and transaction_type_id   in (select transaction_type_id
                                             from mtl_transaction_types
                                            where attribute8 in ('CON_PNFC_S_OS','CON_PNFC','TRF_GRAEXT'));
          --
        exception
          when others then
            l_saldo := 0;
        end;

    end if;
    --
    --l_saldo := 1000; --TESTE

    RETURN(l_saldo);
    --
  END fnd_qtde_consumo_reserva;
  --
  PROCEDURE carga_reservas_planej_p(errbuf              OUT VARCHAR2
                                   ,retcode             OUT NUMBER
                                   ,p_organization_id   IN NUMBER
                                   ,p_origem            IN VARCHAR2
                                   ,p_inventory_item_id IN NUMBER
                                   ) IS
    --

    l_rMrp_Schedule_Interface mrp_schedule_interface%ROWTYPE;
    l_rInv_Safety_stocks      mtl_safety_stocks%ROWTYPE;
    l_nQtdeRegistros          NUMBER;
    l_vPapel                  VARCHAR2(500);
    l_vOrganization_Code      VARCHAR2(3);
    l_vErrbuf                 varchar2(1000);
    l_vItemId                 number;
    l_ndias_safety_stock      number;
    l_nQtde_safety_stocks     number;
    l_nMes_politica           number;
    l_nPolitica               number;

    CURSOR c1 IS
     SELECT  msi.inventory_item_id
            ,res.cod_org
            ,'0000'     cod_aplicacao
            ,'0000'     edicao
            ,'Reservas' dsc_revista
            ,case when max(res.dat_utilizacao) between          trunc(ADD_MONTHS(sysdate + msi.full_lead_time,+1),'MM') 
                                                   and LAST_DAY(TRUNC(add_months(sysdate + msi.full_lead_time,+1),'MM') + to_number(nvl(a.attribute1,0)) ) then
                trunc(LAST_DAY(sysdate + msi.full_lead_time))
             else
                LAST_DAY(max(res.dat_utilizacao))
             end dat_utilizacao
                        
            ,sum(res.qtd_kg_papel_reservado ) schedule_quantity
            ,msi.segment1 papel
            ,msi.organization_id
        FROM bolinf.xxinv_reserva_papel_v  res
            ,bolinf.xxinv_tab_aplic        apl
            ,apps.mtl_system_items_b       msi
            ,apps.mtl_descr_element_values orig
            ,bolinf.xxfnd_extended_flexfields a
       WHERE res.num_produto = apl.num_produto
         AND msi.organization_id = res.cod_org
         AND res.cod_situacao = 1 --ativa
         AND lpad(res.cod_item, 8, '0') = msi.segment1
         AND res.cod_org = decode(p_organization_id,'105','604',p_organization_id)
         AND res.cod_inv = decode(p_organization_id,'105','002',res.cod_inv)
         and res.cod_sub_inv = decode(p_organization_id,'105','001',res.cod_sub_inv)
         AND orig.inventory_item_id = msi.inventory_item_id
         AND orig.element_name = 'PROCEDENCIA'
         AND orig.element_value = p_origem
         AND msi.inventory_item_id = nvl(p_inventory_item_id, msi.inventory_item_id)
         AND a.ref_line_rowid(+) =  msi.ROWID
         AND a.ref_table_name(+) = 'MTL_SYSTEM_ITEMS_FVL'
         AND a.FLEXFIELD_CONTEXT(+) = 'MTL_SYSTEM_ITEMS_FVL'         
      group by
           msi.inventory_item_id
          ,res.cod_org
          ,TO_CHAR(res.dat_utilizacao, 'YYYY/MM')
          ,msi.segment1
          ,orig.element_value
          ,msi.organization_id
          ,msi.full_lead_time
          ,a.attribute1
       ORDER BY msi.inventory_item_id
               ,res.cod_org
               ,TO_CHAR(res.dat_utilizacao , 'YYYY/MM')
               ,msi.segment1;
    --
    --
  BEGIN
   l_nQtdeRegistros         :=0;
    --
   BEGIN
        SELECT organization_code
          INTO l_vOrganization_Code
          FROM org_organization_definitions
         WHERE organization_id = p_organization_id;
   EXCEPTION
         WHEN OTHERS THEN
          retcode  := 1; -- warning
         
           l_vErrbuf := 'ERRO AO SELECIONAR ORGANIZACAO : '||p_organization_id||
                                         ' E ORIGEM: '||p_origem;
             fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
             dbms_output.put_line('Mensagem erro : '||l_vErrbuf);

             RAISE_APPLICATION_ERROR(-20001,l_vErrbuf);

   END;
   
   IF ( p_inventory_item_id IS not NULL ) THEN
      BEGIN
        SELECT segment1||' - '||description
          INTO l_vPapel
          FROM mtl_system_items_b
         WHERE organization_id = p_organization_id
           AND inventory_item_id = p_inventory_item_id;
      EXCEPTION
         WHEN others THEN
         l_vErrbuf := 'ERRO AO SELECIONAR O PAPEL PARA A ORGANIZACAO: ' || p_organization_id||
                                         'E ITEM_ID: '||p_inventory_item_id;
         fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
         dbms_output.put_line('Mensagem erro : '||l_vErrbuf);

         RAISE_APPLICATION_ERROR(-20001,l_vErrbuf);
      END;
    ELSE
      l_vPapel := 'TODOS';
    END IF;
    --
    
    FOR r1 IN c1 LOOP
    
            --Limpar tabela interface com status de processado
            begin
                DELETE mrp_schedule_interface o
                where o.schedule_designator = 'MD-PAP-14'
                and   o.process_status in (4,5)
                and   o.inventory_item_id = nvl(r1.inventory_item_id, o.inventory_item_id)
                and   o.organization_id = r1.organization_id;
            exception when others then
               l_vErrbuf := SQLERRM;
               dbms_output.put_line('Mensagem erro : '||l_vErrbuf);
               fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
            end;

            begin
                DELETE mrp_schedule_items o
                where o.schedule_designator = 'MD-PAP-14'
                and   o.organization_id= p_organization_id
                and   o.inventory_item_id = nvl(r1.inventory_item_id, o.inventory_item_id)
                and   o.organization_id = r1.organization_id;
            exception when others then
               l_vErrbuf := SQLERRM;
               dbms_output.put_line('Mensagem erro : '||l_vErrbuf);
               fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
            end;

            begin
                DELETE mrp_schedule_dates o
                where o.schedule_designator = 'MD-PAP-14'
                and   o.organization_id= p_organization_id
                and   o.inventory_item_id = nvl(r1.inventory_item_id, o.inventory_item_id)
                and   o.organization_id = r1.organization_id;
            exception when others then
               l_vErrbuf := SQLERRM;
               dbms_output.put_line('Mensagem erro : '||l_vErrbuf);
               fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
            end;

    end loop;
    --
    l_vItemId := 9999999999;

    FOR r1 IN c1 LOOP
      --
        begin
            l_nQtdeRegistros := l_nQtdeRegistros + 1;

            l_rMrp_Schedule_Interface.inventory_item_id   := r1.inventory_item_id;
            l_rMrp_Schedule_Interface.schedule_designator := 'MD-PAP-14'; --alterar para variavel entrada concorrente
            l_rMrp_Schedule_Interface.organization_id     := p_organization_id;
            l_rMrp_Schedule_Interface.last_update_date    := SYSDATE;
            l_rMrp_Schedule_Interface.last_updated_by     := fnd_profile.VALUE('USER_ID');
            l_rMrp_Schedule_Interface.creation_date       := SYSDATE;
            l_rMrp_Schedule_Interface.created_by          := fnd_profile.VALUE('USER_ID');
            l_rMrp_Schedule_Interface.last_update_login   := fnd_profile.VALUE('LOGIN_ID');
            l_rMrp_Schedule_Interface.schedule_date       := r1.dat_utilizacao;
            l_rMrp_Schedule_Interface.schedule_quantity   := r1.schedule_quantity;
            l_rMrp_Schedule_Interface.schedule_comments   := r1.cod_aplicacao || '-' || r1.edicao || '-' || r1.dsc_revista;
            l_rMrp_Schedule_Interface.workday_control     := '2';
            l_rMrp_Schedule_Interface.process_status      := '2';
            l_rMrp_Schedule_Interface.source_code         := 'PLAN_PAPEL';
--          l_rMrp_Schedule_Interface.source_line_id      := r1.num_reserva;
            l_rMrp_Schedule_Interface.source_line_id      := l_nQtdeRegistros;--r1.num_reserva;
            --
            INSERT INTO mrp_schedule_interface VALUES l_rMrp_Schedule_Interface;
            --
        exception
          when others then
             l_vErrbuf := 'ERRO AO ATUALIZAR MRP DAS DEMANDAS PARA A ORGANIZACAO: '||p_organization_id||
                                         ' E ORIGEM: '||p_origem;
             fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
             dbms_output.put_line('Mensagem erro : '||l_vErrbuf);

             RAISE_APPLICATION_ERROR(-20001,l_vErrbuf);

        end;

        l_vItemid := r1.inventory_item_id;

    END LOOP;

    commit;

    --
    fnd_file.put_line(fnd_file.output,'Carga Planejamento da Organizaç '||l_vOrganization_Code || '(' || p_organization_id   ||')'|| ' em '||TO_CHAR(SYSDATE,'DD/MM/RRRR'));
    fnd_file.put_line(fnd_file.output,'Origem: '||p_origem);
    fnd_file.put_line(fnd_file.output,'Item Papel: '||l_vPapel);
    fnd_file.put_line(fnd_file.output,'Atualizados na interface MPS: '||l_nQtdeRegistros||' Registros');

    dbms_output.put_line('Carga Planejamento da Organizaç '||l_vOrganization_Code||' em '||TO_CHAR(SYSDATE,'DD/MM/RRRR'));
    dbms_output.put_line('Origem: '||p_origem);
    dbms_output.put_line('Item Papel: '||l_vPapel);
    dbms_output.put_line('Atualizados na interface MPS: '||l_nQtdeRegistros||' Registros');

    --

EXCEPTION
   WHEN OTHERS THEN
     l_vErrbuf := SQLERRM;
     dbms_output.put_line('Mensagem erro : '||l_vErrbuf);
     fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
     --RAISE_APPLICATION_ERROR(-20001,l_vErrbuf);

END carga_reservas_planej_p;
  --
  PROCEDURE gera_lote_ssp_p ( p_organization_id    IN  NUMBER
                             ,p_inventory_item_id  IN  NUMBER
                             ,p_segment1           IN  VARCHAR2
                             ,p_batch_name         OUT VARCHAR2 ) IS
  --
  l_nSequence                NUMBER;
  l_nItem_Id                 NUMBER;
  l_vPrefixo                 VARCHAR2(5);
  l_vTipo_tributacao         VARCHAR2(1);
  --
  BEGIN
    --
    SELECT NVL(tag,0) + 1
          ,description
      INTO l_nSequence
          ,l_vPrefixo
      FROM fnd_lookup_values
     WHERE lookup_type = 'ABRL_INV_LOTE_COMPRA_PAPEL'
       AND meaning = to_char(p_organization_id)
       AND language = 'PTB';
    --
    BEGIN
      IF ( p_inventory_item_id IS NOT NULL ) THEN
        SELECT msi.inventory_item_id
          INTO l_nItem_Id
          FROM apps.mtl_cross_references mcr
              ,apps.mtl_system_items     msi
         WHERE mcr.inventory_item_id    = msi.inventory_item_id
           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
           AND msi.organization_id      = p_organization_id
           AND msi.inventory_item_id    = p_inventory_item_id;
      ELSE
        SELECT msi.inventory_item_id
          INTO l_nItem_Id
          FROM apps.mtl_cross_references mcr
              ,apps.mtl_system_items     msi
         WHERE mcr.inventory_item_id    = msi.inventory_item_id
           AND mcr.cross_reference_type = 'CODIGO LEGADO SSP'
           AND msi.organization_id      = p_organization_id
           AND msi.segment1             = p_segment1;
      END IF;
      --
      BEGIN
        --
        SELECT SUBSTR(indtrib.element_value,1,1)
          INTO l_vTipo_tributacao
          FROM apps.mtl_descr_element_values indtrib
         WHERE indtrib.inventory_item_id = l_nItem_Id
           AND indtrib.element_name      = 'INDICADOR DE TRIBUTACAO';
        --
        p_batch_name := l_vPrefixo||LPAD(l_nSequence,4,'0')||l_vTipo_tributacao;
        --
        UPDATE fnd_lookup_values
           SET tag = l_nSequence
         WHERE lookup_type = 'ABRL_INV_LOTE_COMPRA_PAPEL'
           AND meaning = to_char(p_organization_id);
        --
      EXCEPTION
        WHEN no_data_found THEN NULL;
      END;
      --
    EXCEPTION
      WHEN no_data_found THEN NULL;
    END;
  EXCEPTION
    WHEN no_data_found THEN NULL;
  END gera_lote_ssp_p;
  --
  PROCEDURE copy_batch_from_req ( p_po_header_id IN NUMBER ) IS
  --
  l_erro                     varchar2(2000);
  l_vLote                    VARCHAR2(240);
  l_vLine_Num                VARCHAR2(240);
  l_vReq_Number              VARCHAR2(240);
  l_nPo_Distribution_id      NUMBER;
  l_organization_id          NUMBER;
  --
  BEGIN
    --
  
    
    FOR i IN ( SELECT pl.po_line_id
                     ,pl.item_id
                 FROM po_lines_all pl
                WHERE po_header_id = p_po_header_id ) LOOP
      --
      -- EXIT;   --COMENTAR APOS VALIDACAO    
      
      BEGIN
        SELECT DISTINCT prl.attribute9
                       ,prl.line_num
                       ,prh.segment1
                       ,pd.po_distribution_id
          INTO l_vLote
              ,l_vLine_Num
              ,l_vReq_Number
              ,l_nPo_Distribution_id
          FROM po_req_distributions_all prd
              ,po_requisition_lines_all prl
              ,po_distributions_all     pd
              ,po_requisition_headers_all prh
         WHERE prd.distribution_id = pd.req_distribution_id
           AND pd.po_header_id     = p_po_header_id
           AND pd.po_line_id       = i.po_line_id
           AND prl.requisition_line_id = prd.requisition_line_id
           AND prl.requisition_header_id = prh.requisition_header_id
           AND prl.attribute9 IS NOT NULL;
        --
        UPDATE po_distributions_all
           SET req_header_reference_num = l_vReq_Number
              ,req_line_reference_num   = l_vLine_Num
         WHERE po_distribution_id       = l_nPo_Distribution_id;
        --
      EXCEPTION
        WHEN no_data_found THEN
          BEGIN
            --
            SELECT prl.attribute9
                  ,prl.line_num
                  ,prh.segment1
                  ,pd.po_distribution_id
              INTO l_vLote
                  ,l_vLine_Num
                  ,l_vReq_Number
                  ,l_nPo_Distribution_id
              FROM po_distributions_all     pd
                  ,po_req_distributions_all prd
                  ,po_requisition_lines_all prl
                  ,po_requisition_headers_all prh
             WHERE pd.po_header_id = p_po_header_id
               AND pd.po_line_id   = i.po_line_id
               AND pd.req_distribution_id IS NOT NULL
               AND pd.req_distribution_id = prd.distribution_id
               AND prl.requisition_line_id = prd.requisition_line_id
               AND prl.requisition_header_id = prh.requisition_header_id
               AND prl.attribute9 IS NOT NULL;
            --
            UPDATE po_distributions_all
               SET req_header_reference_num = l_vReq_Number
                  ,req_line_reference_num   = l_vLine_Num
             WHERE po_distribution_id       = l_nPo_Distribution_id;
            --
          EXCEPTION
            WHEN no_data_found THEN
              l_vLote := NULL;
              BEGIN
                SELECT DISTINCT pll.attribute1
                  INTO l_vLote
                  FROM po_line_locations_all pll
                      ,po_distributions      pd
                 WHERE pd.po_header_id = p_po_header_id
                   AND pd.po_line_id   = i.po_line_id
                   AND pd.line_location_id = pll.line_location_id
                   AND pll.attribute1 IS NOT NULL;
              EXCEPTION
                WHEN no_data_found THEN
                  BEGIN
                    --
                    SELECT DISTINCT destination_organization_id
                      INTO l_organization_id
                      FROM po_distributions_all pd
                     WHERE pd.po_header_id = p_po_header_id
                       AND pd.po_line_id   = i.po_line_id;
                    --
                    xxinv_paper_lot_pk.gera_lote_ssp_p( p_organization_id   => l_organization_id
                                                       ,p_inventory_item_id => i.item_id
                                                       ,p_segment1          => NULL
                                                       ,p_batch_name        => l_vLote );
                    --
                  EXCEPTION
                    WHEN no_data_found THEN
                  null;
                  END;
              END;
            WHEN OTHERS THEN
        null;
          END;
      END;
      --
      IF ( l_vLote IS NOT NULL ) THEN
        UPDATE po_line_locations_all
           SET attribute1 = l_vLote
         WHERE line_location_id IN ( SELECT line_location_id
                                       FROM po_distributions_all
                                      WHERE po_header_id = p_po_header_id
                                        AND po_line_id   = i.po_line_id );
        --
      END IF;
    END LOOP;
    --
    COMMIT;
    --
  END copy_batch_from_req;
  --
                                    
  PROCEDURE relatorio_alertas( errbuf               OUT VARCHAR2
                             , retcode              OUT NUMBER 
                             , p_organization_id    IN NUMBER
                             , p_local              IN VARCHAR2 
                             , p_inventory_item_id  IN NUMBER
                             , p_origem             IN VARCHAR2
                             , p_ndias              IN NUMBER
                             ) IS
    cursor c_estoque is
           select xtp.*
           from   bolinf.xxinv_tipo_papel_v         xtp,
                  apps.org_organization_definitions ood
          where   ood.organization_id    = p_organization_id
           and    ood.organization_code  = xtp.organization_code
           and    xtp.ITEM_ID            = nvl(p_inventory_item_id,xtp.ITEM_ID)
           and    xtp.local              = nvl(p_local,xtp.local)  
           and    xtp.procedencia        = p_origem             
           and    xtp.saldo > 0
           order by xtp.organization_code,xtp.local,xtp.cod_papel;

    cursor c_movres (   v_local     IN VARCHAR2
                       ,v_org_code  IN varchar2
                       ,v_item_id   IN NUMBER    ) is

           select  xirp.*
            from   bolinf.xxinv_reserva_papel_v xirp 
            where  xirp.inventory_item_id  = v_item_id  
            and    xirp.cod_inv            = v_org_code  
            and    xirp.cod_sub_inv        = v_local  
            and    xirp.cod_situacao in (1,2)  --(1=Ativa 2=Provisoria 3=Cancelada 4=Encerrada)
            and    xirp.dat_utilizacao <= sysdate + p_ndias
            order by xirp.cod_inv,xirp.inventory_item_id, xirp.dat_utilizacao;
            
    cursor c_pedidos (  v_local     IN VARCHAR2
                       ,v_org_code  IN varchar2
                       ,v_item_id   IN NUMBER ) is
            SELECT xos.pedido
                  ,xos.lote
                  ,xos.qtde_requisitada
                  ,xos.data_prev_entrega 
                  ,xos.qtde_entregue
                  ,to_char(xos.nome_navio) navio
                  ,xos.data_entrega
                  ,xos.dt_chegada 
                  ,xos.FORNECEDOR
              FROM bolinf.xxinv_oc_ssp_v xos
             WHERE xos.lote IS NOT NULL
             and   xos.organization_code = v_org_code 
             and   xos.inventory_item_id = v_item_id 
             and   xos.cod_sub_inv       = v_local
             ORDER BY xos.data_prev_entrega;                       
      

    --l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
    l_vRegistro              varchar2(1000);
    l_vSaldo                 number;
    l_vQtde_Reservas         number;
    l_vDsc_Organizacao       varchar2(1000);
    l_vOrg_Code              apps.org_organization_definitions.organization_code%type;

    begin
      
       begin
          select ood.organization_name,
                 ood.organization_code
          into   l_vDsc_Organizacao,
                 l_vOrg_Code
          from   apps.org_organization_definitions ood
          where  ood.organization_id = p_organization_id;
          
       exception when others then
          l_vDsc_Organizacao := null;
       end;
       
       -- cabecalho
        l_vRegistro := 'Relatorio de Alertas - Emissao em ' || sysdate || '  Considerando ALERTAS ate ' || p_ndias || ' dias';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := 'Organizaç -> ' || l_vOrg_Code || ' - ' || l_vDsc_Organizacao;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);


        --
        FOR r_estoque IN c_estoque
          LOOP
     
              begin
                  select sum(xirp.qtd_kg_papel_reservado) - sum(xirp.qtd_consumo)
                  into   l_vQtde_Reservas
                  from   bolinf.xxinv_reserva_papel_v xirp 
                  where  xirp.inventory_item_id  = r_estoque.item_id
                  and    xirp.cod_inv            = r_estoque.organization_code
                  and    xirp.cod_sub_inv        = r_estoque.local
                  and    xirp.cod_situacao = 1  --(1=Ativa 2=Provisoria 3=Cancelada 4=Encerrada)
                  and    xirp.dat_utilizacao <= sysdate + p_ndias
                  order by xirp.cod_inv,xirp.inventory_item_id, xirp.dat_utilizacao;
                  
              exception when others then
                  l_vQtde_Reservas := 0;
              end;

              if r_estoque.saldo < l_vQtde_Reservas then
              
                  l_vRegistro := 'Empresa : ' || r_estoque.des_local ;
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);

                  l_vRegistro := 'Papel : ' || r_estoque.cod_papel || ' - ' || r_estoque.des_papel || ';;;; Saldo Inicial;' || r_estoque.saldo ;
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);

                  l_vRegistro := ';';
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);

                  l_vRegistro := 'RESERVA;PRODUTO;EDICAO;DATA UTIL; QTDE;SALDO';
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);
                  
                  l_vSaldo := r_estoque.saldo;
                  
                  FOR r_movres IN c_movres(r_estoque.local, r_estoque.organization_code, r_estoque.item_id)               
                     loop
                     
                          l_vSaldo := l_vSaldo - (r_movres.qtd_kg_papel_reservado - r_movres.qtd_consumo);

                          l_vRegistro :=  r_movres.NUM_RESERVA                            || ';' ||
                                          r_movres.DSC_REVISTA                            || ';' ||
                                          r_movres.NUM_EDICAO                             || ';' ||
                                          r_movres.DAT_UTILIZACAO                         || ';' ||
                                          (r_movres.qtd_kg_papel_reservado - r_movres.qtd_consumo) || ';' ||
                                          l_vSaldo;
                                          
                          fnd_file.put_line(fnd_file.output,l_vRegistro);
                          --dbms_output.put_line(l_vRegistro);

                   end loop;
                  
                   --informacoes de pedidos... 
                   l_vRegistro := ';';
                   fnd_file.put_line(fnd_file.output,l_vRegistro);
                   --dbms_output.put_line(l_vRegistro);

                   if p_origem = 'IMPORTADO' then
                      l_vRegistro := 'PO;QTDE PED; QTDE ENTR;DT PREV ENTR;LOTE;FORNECEDOR;NAVIO; DT CHEGADA PORTO';
                   else
                      l_vRegistro := 'PO;QTDE PED; QTDE ENTR;DT PREV ENTR;LOTE; FORNECEDOR';
                   end if;
                   fnd_file.put_line(fnd_file.output,l_vRegistro);
                   --dbms_output.put_line(l_vRegistro);
                  
                   FOR r_pedidos IN c_pedidos(r_estoque.local, r_estoque.organization_code, r_estoque.item_id)               
                      loop
                          l_vRegistro :=  r_pedidos.pedido                    || ';' ||
                                          r_pedidos.qtde_requisitada          || ';' ||
                                          r_pedidos.qtde_entregue             || ';' ||
                                          r_pedidos.data_prev_entrega         || ';' ||
                                          r_pedidos.lote                      || ';' ||
                                          r_pedidos.fornecedor;

                           if p_origem = 'IMPORTADO' then                                          
                              l_vRegistro :=  l_vRegistro || ';' || r_pedidos.navio
                                                          || ';' || r_pedidos.dt_chegada;
                           end if;
                                          
                          fnd_file.put_line(fnd_file.output,l_vRegistro);
                          --dbms_output.put_line(l_vRegistro); 
                   END LOOP;

                   --l_vRegistro := '########################################################################################################################################;';
                   --fnd_file.put_line(fnd_file.output,l_vRegistro);
                   --dbms_output.put_line(l_vRegistro);

                   l_vRegistro := ';';
                   fnd_file.put_line(fnd_file.output,l_vRegistro);
                   --dbms_output.put_line(l_vRegistro);

               end if;

       END LOOP;

       retcode  := 0; -- warning


  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio ALERTAS. ' || SQLERRM);
          --dbms_output.put_line('Erro ao processar relatorio ALERTAS. ' || SQLERRM);
                  
  END relatorio_alertas;
  --
  PROCEDURE gera_lst_res_pend_p( errbuf          OUT VARCHAR2
                             , retcode           OUT NUMBER 
                             , p_organization_id IN NUMBER
                             , p_dtinicio        IN varchar2
                             , p_dtfinal         IN varchar2) is                             
 
  cursor c_respend is
         select   res.des_sub_inv             des_local            
                 ,res.cod_item               cod_papel            
                 ,res.qtd_kg_papel_reservado qtde_reserva    
                 ,res.qtd_consumo            qtde_ERP                                            
                 ,res.num_produto            aplicacao            
                 ,res.dsc_revista            dsc_aplicacao
                 ,res.num_edicao             edicao               
                 ,res.dsc_elemento           elemento             
                 ,res.num_reserva            reserva              
                 ,res.dat_utilizacao         dat_utilizacao       
                 ,res.COD_ORG
                 ,res.COD_INV
                 ,res.COD_SUB_INV
                 ,res.COD_ITEM
                 ,res.COD_TIPO_RESERVA
                 ,res.DSC_OBSERVACAO
                 ,res.COD_ITEM_CROSS_REF
                 ,res.COD_LOCAL_IMPRESSAO
                 ,res.COD_TIPO_SEPARACAO
                 ,res.CREATION_DATE
                 ,res.num_tiragem
                 ,res.des_tipo_reserva
                 ,res.des_tipo_separacao
                 ,res.organization_name
                 ,res.des_item
                 ,res.inventory_item_id
                 ,res.des_situacao
            FROM bolinf.xxinv_reserva_papel_v  res
           WHERE res.dat_utilizacao      between  p_dtinicio and  p_dtfinal
             and res.cod_org             = nvl(p_organization_id,res.cod_org)
             and res.cod_situacao        in (1,2) --ativa e provisoria
           order by res.COD_ORG
                   ,res.COD_INV
                   ,res.COD_SUB_INV
                   ,res.COD_ITEM
             ;  

  --l_vDebug                 NUMBER := nvl(fnd_profile.value('INV_DEBUG_TRACE'), 0);
  l_vRegistro              varchar2(1000);
  l_vDsc_Organizacao       apps.org_organization_definitions.organization_name%type;
  l_vOrg_Code              apps.org_organization_definitions.organization_code%type;
  l_vLocal                 varchar2(1000);
  l_vOsEmitida             varchar2(10);
  l_vRes_OS                varchar2(10);
  
  BEGIN
       l_vRegistro := 'data inicial -> ' || p_dtinicio  || ' / data final ' || p_dtfinal ;
       --fnd_file.put_line(fnd_file.output,l_vRegistro);

       begin
          select ood.organization_name,
                 ood.organization_code
          into   l_vDsc_Organizacao,
                 l_vOrg_Code
          from   apps.org_organization_definitions ood
          where  ood.organization_id = p_organization_id;
          
       exception when others then
          l_vDsc_Organizacao := null;
       end;
       
       -- cabecalho
        l_vRegistro := 'Relatorio de RESERVAS PENDENTES  Emissao em ' || sysdate || '   /  Periodo de ' || p_dtinicio || ' ate ' || p_dtfinal;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := 'Organizaç =>' || l_vOrg_Code || ' - ' || l_vDsc_Organizacao;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vLocal := 'x';
        FOR r_respend IN c_respend
            LOOP

                  if l_vLocal <> r_respend.des_local then
                     l_vRegistro := ';';
                     fnd_file.put_line(fnd_file.output,l_vRegistro);
                     --dbms_output.put_line(l_vRegistro);

                     l_vRegistro := 'EMPRESA;PAPEL;QTDE RESERVA; QTDE INV;APLICACAO; EDICAO; ELEMENTO;RESERVA;DT UTIL; OS Emitida';
                      fnd_file.put_line(fnd_file.output,l_vRegistro);
                      --dbms_output.put_line(l_vRegistro);
                      l_vLocal := r_respend.des_local;
                  end if;
                  
                  begin
                      select 'SIM'
                             ,xios.num_reserva
                      into    l_vOsEmitida
                             ,l_vRes_OS
                      from   bolinf.xxinv_int_os xios
                      where  xios.num_reserva = r_respend.reserva
                      and    xios.cod_papel   = r_respend.cod_papel
                      group by xios.num_reserva;

                  exception when others then
                      l_vOsEmitida := null;
                  end;
                  
                  l_vRegistro :=  r_respend.des_local            || ';' ||
                                  r_respend.cod_papel            || ';' ||
                                  r_respend.qtde_reserva         || ';' ||
                                  r_respend.qtde_ERP             || ';' ||
                                  r_respend.aplicacao            || ';' ||
                                  r_respend.edicao               || ';' ||
                                  r_respend.elemento             || ';' ||
                                  r_respend.reserva              || ';' ||
                                  r_respend.DAT_UTILIZACAO       || ';' ||
                                  l_vOsEmitida;
                                          
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);
        END LOOP;
                       
  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio RESERVAS PENDENTES. ' || SQLERRM);
          --dbms_output.put_line('Erro ao processar relatorio RESERVAS PENDENTES. ' || SQLERRM);
  END gera_lst_res_pend_p;
  
  --
  
  PROCEDURE gera_lst_reservas ( errbuf              OUT VARCHAR2
                              , retcode             OUT NUMBER 
                              , p_organization_id    IN NUMBER
                              , p_local              IN VARCHAR2 
                              , p_inventory_item_id  IN NUMBER
                              , p_origem             IN VARCHAR2
                              , p_dtinicio           IN varchar2
                              , p_dtfinal            IN varchar2) is
                              
  cursor c_reservas is
          select  res.des_sub_inv           des_local            
                 ,res.cod_item               cod_papel            
                 ,res.qtd_kg_papel_reservado qtde_reserva    
                 ,res.qtd_consumo            qtde_ERP                                             
                 ,res.num_produto            aplicacao            
                 ,res.dsc_revista            dsc_aplicacao
                 ,res.num_edicao             edicao               
                 ,res.dsc_elemento           elemento             
                 ,res.num_reserva            reserva              
                 ,res.dat_utilizacao         dat_utilizacao       
                 ,res.COD_ORG
                 ,res.COD_INV
                 ,res.COD_SUB_INV
                 ,res.COD_ITEM
                 ,res.COD_TIPO_RESERVA
                 ,res.DSC_OBSERVACAO
                 ,res.COD_ITEM_CROSS_REF
                 ,res.COD_LOCAL_IMPRESSAO
                 ,res.COD_TIPO_SEPARACAO
                 ,res.CREATION_DATE
                 ,res.num_tiragem
                 ,res.des_tipo_reserva
                 ,res.des_tipo_separacao
                 ,res.organization_name
                 ,res.des_item
                 ,res.inventory_item_id
                 ,res.des_situacao
            FROM bolinf.xxinv_reserva_papel_v  res
                ,apps.mtl_descr_element_values proced                
           WHERE res.dat_utilizacao      between  p_dtinicio and  p_dtfinal
             and res.cod_org             = nvl(p_organization_id,res.cod_org)
             and res.inventory_item_id   = nvl(p_inventory_item_id,res.inventory_item_id)
             and res.cod_sub_inv         = nvl(p_local,res.cod_sub_inv)  
             and proced.element_name     = 'PROCEDENCIA'
             and res.inventory_item_id   = proced.inventory_item_id     
             and proced.element_value    = nvl(p_origem,proced.element_value)          
           order by res.COD_ORG
                   ,res.COD_INV
                   ,res.COD_SUB_INV
                   ,res.COD_ITEM
             ;

  l_vRegistro              varchar2(1000);
  l_vDsc_Organizacao       apps.org_organization_definitions.organization_name%type;
  l_vOrg_Code              apps.org_organization_definitions.organization_code%type;
  l_vLocal                 varchar2(1000);
  
  BEGIN
       l_vRegistro := 'data inicial -> ' || p_dtinicio  || ' / data final ' || p_dtfinal ;
       --fnd_file.put_line(fnd_file.output,l_vRegistro);

       begin
          select ood.organization_name,
                 ood.organization_code
          into   l_vDsc_Organizacao,
                 l_vOrg_Code
          from   apps.org_organization_definitions ood
          where  ood.organization_id = p_organization_id;
          
       exception when others then
          l_vDsc_Organizacao := null;
       end;
       
       -- cabecalho
        l_vRegistro := 'Relatorio de RESERVAS de PAPEL  -  Emissao em ' || sysdate || '   /  Periodo de ' || p_dtinicio || ' ate ' || p_dtfinal;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := 'Empresa;Nome Emp;Nome Aplic;AplIcacao;Edic;Papel;Desc Papel;Dt Util;Tiragem;Q Prevista;Q Real;Reserva;Tipo Reserva;Situacao';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        FOR r_reservas IN c_reservas
            LOOP
                  l_vRegistro :=  r_reservas.organization_name    || ';' ||
                                  r_reservas.des_local            || ';' ||
                                  r_reservas.dsc_aplicacao        || ';' ||
                                  r_reservas.aplicacao            || ';' ||
                                  r_reservas.edicao               || ';' ||
                                  r_reservas.cod_papel            || ';' ||
                                  r_reservas.des_item             || ';' ||
                                  r_reservas.DAT_UTILIZACAO       || ';' ||
                                  r_reservas.num_tiragem          || ';' ||
                                  r_reservas.qtde_reserva         || ';' ||
                                  r_reservas.qtde_ERP             || ';' ||
                                  r_reservas.reserva              || ';' ||
                                  r_reservas.des_tipo_reserva     || ';' ||
                                  r_reservas.des_situacao
                                  ;                                  
                                          
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);
        END LOOP;
                                                     
  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio RESERVAS DE PAPEL. ' || SQLERRM);
          --dbms_output.put_line('Erro ao processar relatorio RESERVAS PENDENTES. ' || SQLERRM);
  
  END gera_lst_reservas;     
  
  --
  PROCEDURE encerra_reservas ( errbuf               OUT VARCHAR2
                             , retcode              OUT NUMBER 
                             , p_ndias              IN NUMBER) is
  
  BEGIN
  
      FOR r_reservas in ( select res.num_reserva
                               ,res.qtd_kg_papel_reservado
                               ,qtd_consumo 
                          from  bolinf.xxinv_reserva_papel_v  res
                         where  res.dat_utilizacao between (sysdate - p_ndias) and (sysdate + p_ndias)
                           and  res.cod_situacao in (1,2) )-- 1=Ativa / 2=Provisoria / 3-Cancelada/4-Encerrada
      LOOP

                if r_reservas.qtd_kg_papel_reservado <= r_reservas.qtd_consumo then
                 
                   begin
                        update bolinf.xxinv_reserva_papel xrp
                        set    xrp.cod_situacao = 4
                        where  xrp.num_reserva = r_reservas.num_reserva;
                        
                   exception when others then
                        retcode  := 1; -- warning
                        fnd_file.put_line(fnd_file.log,'Erro ao processar encerramento automatico das RESERVAS DE PAPEL (loop). ' || SQLERRM);
                   end;  
                
                end if;
                
                commit;

        END LOOP;
                                                                                        
  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar encerramento automatico das RESERVAS DE PAPEL. ' || SQLERRM);
          --dbms_output.put_line('Erro ao processar relatorio RESERVAS PENDENTES. ' || SQLERRM);
  
  END encerra_reservas;     
  --  
PROCEDURE copia_reservas_fech ( errbuf            OUT VARCHAR2
                              , retcode           OUT NUMBER) IS
                             
  cursor c_reservas is
         Select * from bolinf.xxinv_reserva_papel 
         where dat_utilizacao > sysdate - 365
         order by dat_utilizacao;
  
  l_nReserva_papel_fech bolinf.xxinv_reserva_papel_fech%ROWTYPE;
  l_nQtdeRegistros      number;                                   
  l_vErrbuf         varchar2(1000);
  l_vRetcode        varchar2(100);
  
  BEGIN
  
    --Limpar tabela de reservas no fechamento
    begin
        DELETE bolinf.xxinv_reserva_papel_fech 
        where dat_fechamento = trunc(sysdate);

    exception
       when others then
         l_vErrbuf := SQLERRM;
         dbms_output.put_line('Mensagem erro : '||l_vErrbuf);
         fnd_file.put_line(fnd_file.log, 'Mensagem erro : '||l_vErrbuf);
    end;

    l_nQtdeRegistros  :=0;

    for r_reservas in c_reservas 
        loop
        
            l_nReserva_papel_fech.NUM_RESERVA             := r_reservas.NUM_RESERVA;           
            l_nReserva_papel_fech.COD_ORG                 := r_reservas.COD_ORG    ;           
            l_nReserva_papel_fech.COD_INV                 := r_reservas.COD_INV    ;           
            l_nReserva_papel_fech.COD_SUB_INV             := r_reservas.COD_SUB_INV;           
            l_nReserva_papel_fech.COD_ITEM                := r_reservas.COD_ITEM   ;           
            l_nReserva_papel_fech.QTD_KG_PAPEL_RESERVADO  := r_reservas.QTD_KG_PAPEL_RESERVADO;
            l_nReserva_papel_fech.NUM_PRODUTO             := r_reservas.NUM_PRODUTO;           
            l_nReserva_papel_fech.NUM_EDICAO              := r_reservas.NUM_EDICAO ;           
            l_nReserva_papel_fech.DAT_UTILIZACAO          := r_reservas.DAT_UTILIZACAO;        
            l_nReserva_papel_fech.DSC_ELEMENTO            := r_reservas.DSC_ELEMENTO;          
            l_nReserva_papel_fech.COD_PROCESSO            := r_reservas.COD_PROCESSO;          
            l_nReserva_papel_fech.COD_SITUACAO            := r_reservas.COD_SITUACAO;          
            l_nReserva_papel_fech.COD_TIPO_RESERVA        := r_reservas.COD_TIPO_RESERVA;     
            l_nReserva_papel_fech.QTD_PAGINAS             := r_reservas.QTD_PAGINAS;           
            l_nReserva_papel_fech.QTD_CORES_NF            := r_reservas.QTD_CORES_NF;          
            l_nReserva_papel_fech.QTD_CORES_NV            := r_reservas.QTD_CORES_NV;         
            l_nReserva_papel_fech.NUM_TIRAGEM             := r_reservas.NUM_TIRAGEM;           
            l_nReserva_papel_fech.DSC_OBSERVACAO          := r_reservas.DSC_OBSERVACAO;        
            l_nReserva_papel_fech.COD_ID_OS_FILHA         := r_reservas.COD_ID_OS_FILHA;       
            l_nReserva_papel_fech.COD_ID_OS_MAE           := r_reservas.COD_ID_OS_MAE;         
            l_nReserva_papel_fech.COD_ITEM_CROSS_REF      := r_reservas.COD_ITEM_CROSS_REF;    
            l_nReserva_papel_fech.COD_LOCAL_IMPRESSAO     := r_reservas.COD_LOCAL_IMPRESSAO;   
            l_nReserva_papel_fech.COD_ID_FORNEC_EXTERNO   := r_reservas.COD_ID_FORNEC_EXTERNO; 
            l_nReserva_papel_fech.COD_TIPO_SEPARACAO      := r_reservas.COD_TIPO_SEPARACAO;    
            l_nReserva_papel_fech.DAT_LIBERACAO           := r_reservas.DAT_LIBERACAO;         
            l_nReserva_papel_fech.CREATION_DATE           := r_reservas.CREATION_DATE;         
            l_nReserva_papel_fech.CREATED_BY              := r_reservas.CREATED_BY;            
            l_nReserva_papel_fech.LAST_UPDATE_DATE        := r_reservas.LAST_UPDATE_DATE;      
            l_nReserva_papel_fech.LAST_UPDATED_BY         := r_reservas.LAST_UPDATED_BY;       
            l_nReserva_papel_fech.IND_BLOQUEIO_RESERVA    := r_reservas.IND_BLOQUEIO_RESERVA;  
            l_nReserva_papel_fech.COD_CARGA               := r_reservas.COD_CARGA;             
            l_nReserva_papel_fech.DAT_FECHAMENTO          := trunc(sysdate);
            
            INSERT INTO bolinf.xxinv_reserva_papel_fech VALUES l_nReserva_papel_fech;

            l_nQtdeRegistros := l_nQtdeRegistros +1;

     end loop;

     commit;

    fnd_file.put_line(fnd_file.output,'Atualizacao Reservas Fechamento em '||TO_CHAR(SYSDATE,'DD/MM/RRRR'));
    fnd_file.put_line(fnd_file.output,'Atualizados : '||l_nQtdeRegistros||' Registros');
     
  
  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar copia das reservas no fechamento. ' || SQLERRM);
          --dbms_output.put_line('Erro ao processar copia das reservas no fechamento. ' || SQLERRM);
  
  END copia_reservas_fech;
  --
  PROCEDURE gera_lst_compara_reserva ( errbuf       OUT VARCHAR2
                                     , retcode      OUT NUMBER
                                     , p_dtcompara  IN DATE
                                     , p_dtinicio   IN DATE
                                     , p_dtfinal    IN DATE
                                     ) is
  cursor c_compara is 
          select  res.des_sub_inv            des_local            
                 ,res.cod_item               cod_papel            
                 ,res.qtd_kg_papel_reservado qtde_reserva    
                 ,res.qtd_consumo            
                 ,res.num_produto            aplicacao            
                 ,res.dsc_revista            dsc_aplicacao
                 ,res.num_edicao             edicao               
                 ,res.dsc_elemento           elemento             
                 ,res.num_reserva            reserva              
                 ,res.dat_utilizacao         dat_utilizacao       
                 ,res.COD_ORG
                 ,res.COD_INV
                 ,res.COD_SUB_INV
                 ,res.COD_ITEM
                 ,res.COD_TIPO_RESERVA
                 ,res.DSC_OBSERVACAO
                 ,res.COD_ITEM_CROSS_REF
                 ,res.COD_LOCAL_IMPRESSAO
                 ,res.COD_TIPO_SEPARACAO
                 ,res.CREATION_DATE
                 ,res.num_tiragem
                 ,res.des_tipo_reserva
                 ,res.des_tipo_separacao
                 ,res.organization_name
                 ,res.des_item
                 ,res.inventory_item_id
                 ,res.des_situacao
                 ,res.qtd_paginas
                 ,rfe.num_tiragem            num_tir_fech
                 ,rfe.dat_utilizacao         dat_util_fech
                 ,rfe.qtd_paginas            qtd_pag_fech
                 ,rfe.cod_item               cod_item_fech
                 ,rfe.qtd_kg_papel_reservado qtde_res_fech 
            FROM bolinf.xxinv_reserva_papel_v  res
                ,bolinf.xxinv_reserva_papel_fech rfe
           WHERE res.dat_utilizacao  between  p_dtinicio and  p_dtfinal
             and res.num_reserva = rfe.num_reserva (+)           
             and rfe.DAT_FECHAMENTO (+) = p_dtcompara
             and res.cod_org     = rfe.cod_org (+)
             and res.cod_inv     = rfe.cod_inv (+)
             and res.cod_sub_inv = rfe.cod_sub_inv (+)
             and res.num_produto = rfe.num_produto (+)
             and res.num_edicao  = rfe.num_edicao (+)
             and (   res.num_tiragem    <> rfe.num_tiragem
                  or res.dat_utilizacao <> rfe.dat_utilizacao
                  or res.qtd_paginas    <> rfe.qtd_paginas
                  or res.QTD_KG_PAPEL_RESERVADO <> rfe.qtd_kg_papel_reservado
                  or res.cod_item       <> rfe.cod_item
                 )    
           order by res.COD_ORG
                   ,res.COD_INV
                   ,res.COD_SUB_INV
                   ,res.num_produto
                   ,res.num_edicao
                   ,res.cod_item
                   ,res.dat_utilizacao
             ;

  l_vRegistro              varchar2(1000);
  l_vDivergencia           varchar2(1000);
  
  BEGIN
        l_vRegistro := 'data inicial -> ' || p_dtinicio  || ' / data final ' || p_dtfinal || ' - data compara => ' || p_dtcompara ;
        fnd_file.put_line(fnd_file.log,l_vRegistro);

       -- cabecalho
        l_vRegistro := 'Relatorio de comparacao das reservas - data de congelamento => ' || p_dtcompara || '   /  Periodo de ' || p_dtinicio || ' ate ' || p_dtfinal;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
    --    dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
    --    dbms_output.put_line(l_vRegistro);

        l_vRegistro := 
        'Codigo Produto;Desc Produto;Edicao;Reserva;Tipo Reserva;Situacao;Dt util Atual;Papel Atual;Desc Papel Atual;Tiragem Atual;Paginas Atual;Qtde Atual;Dt util Prev;Papel Prev;Tiragem Prev;Paginas Prev;Qtde Prev;Status Comparacao';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
      --  dbms_output.put_line(l_vRegistro);

        FOR r_compara IN c_compara
            LOOP
            
                  l_vDivergencia := '';

                  if r_compara.dat_utilizacao <> r_compara.dat_util_fech then
                     l_vDivergencia := l_vDivergencia || 'Alt. Data Util / ';
                  end if;
                  
                  if r_compara.cod_papel <> r_compara.cod_item_fech then
                     l_vDivergencia := l_vDivergencia || 'Alt. Cod Papel / ';
                  end if;
                  
                  if r_compara.num_tiragem <> r_compara.num_tir_fech then 
                     l_vDivergencia := l_vDivergencia || 'Alt. Tiragem / ';
                  end if;

                  if r_compara.qtd_paginas <> r_compara.qtd_pag_fech then
                     l_vDivergencia := l_vDivergencia || 'Alt. Qtde Paginas / ';
                  end if;

                  if r_compara.qtde_reserva <> r_compara.qtde_res_fech then
                     l_vDivergencia := l_vDivergencia || 'Alt. Qtde Reservada';
                  end if;

                  l_vRegistro :=  r_compara.aplicacao            || ';' ||
                                  r_compara.dsc_aplicacao        || ';' ||
                                  r_compara.edicao               || ';' ||
                                  r_compara.reserva              || ';' ||
                                  r_compara.des_tipo_reserva     || ';' ||
                                  r_compara.des_situacao         || ';' ||
                                  r_compara.DAT_UTILIZACAO       || ';' ||
                                  r_compara.cod_papel            || ';' ||
                                  r_compara.des_item             || ';' ||
                                  r_compara.num_tiragem          || ';' ||
                                  r_compara.qtd_paginas          || ';' ||
                                  r_compara.qtde_reserva         || ';' ||
                                  
                                  r_compara.dat_util_fech        || ';' ||
                                  r_compara.cod_item_fech        || ';' ||
                               -- r_compara.des_item             || ';' ||
                                  r_compara.num_tir_fech         || ';' ||
                                  r_compara.qtd_pag_fech         || ';' ||
                                  r_compara.qtde_res_fech        || ';' ||
                                  l_vDivergencia;
                               -- r_compara.qtde_ERP             || ';' ||
                                          
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                 -- dbms_output.put_line(l_vRegistro);
        END LOOP;
                                                                                        
  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de comparaç das RESERVAS DE PAPEL. ' || SQLERRM);
         -- dbms_output.put_line('Erro ao processar relatorio de comparaç das RESERVAS DE PAPEL. ' || SQLERRM);
                             
  END  gera_lst_compara_reserva;   
  --
  PROCEDURE gera_lst_politica_estoque (errbuf               OUT VARCHAR2
                                     , retcode              OUT NUMBER
                                     , p_organization_id    IN NUMBER
                                     , p_tipo               IN  varchar2
                                     ) is  
  cursor c_politica is
              select b.segment1                           cod_item,
                     trunc((a.attribute1 / 30),1)         meses_pol_est,
                     nvl(a.attribute1,0)                  dias_pol,
                  -- (c.saldo * (a.attribute1 / 30) ) sld_pol,
                     (select sum(rsp.QTD_KG_PAPEL_RESERVADO - rsp.qtd_consumo) 
                        from BOLINF.XXINV_RESERVA_PAPEL_V rsp
                       where rsp.DAT_UTILIZACAO between trunc(sysdate) and trunc(sysdate + nvl(a.attribute1,0))
                       and   rsp.cod_situacao = 1 
                       and   rsp.cod_item = b.segment1
                      )                                   tot_res,
                     trunc ( ( (c.saldo * (nvl(a.attribute1,0) / 30)) / (  select sum(rsp.QTD_KG_PAPEL_RESERVADO - rsp.qtd_consumo) 
                                                              from BOLINF.XXINV_RESERVA_PAPEL_V rsp
                                                             where rsp.DAT_UTILIZACAO between trunc(sysdate) and trunc(sysdate + nvl(a.attribute1,0))
                                                             and   rsp.cod_situacao = 1 
                                                             and   rsp.cod_item = b.segment1 )),2)
                                                           politica,
                     c.tipo_papel,
                     c.tipo,
                     c.des_papel,
                     c.formato,
                     c.GRAMAT,
                     c.organization_code,
                     c.organization_name,
                     c.local,
                     c.des_local,
                     c.saldo,
                     b.inventory_item_id
                     --nvl(d.custo,0) pco_medio
              from   bolinf.xxfnd_extended_flexfields a
                    ,apps.mtl_system_items_b          b
                    ,bolinf.xxinv_tipo_papel_v        c
                    ,apps.org_organization_definitions ood                        
               WHERE a.ref_line_rowid(+) = b.ROWID
                 AND a.ref_table_name(+) = 'MTL_SYSTEM_ITEMS_FVL'
                 AND a.FLEXFIELD_CONTEXT = 'MTL_SYSTEM_ITEMS_FVL'         
                 and c.cod_papel = b.segment1
                 and c.tipo = nvl(p_tipo,c.tipo)
                 and ood.organization_code         = c.organization_code                 
                 and b.organization_id             = ood.organization_id
                 and b.organization_id             = nvl(p_organization_id,b.organization_id)
              order by c.organization_code
                      ,c.tipo_papel
                      ,c.local
                      ,c.saldo
             ;

  l_vRegistro              varchar2(1000);
  l_vTipo                  varchar2(1000);
  l_vAplic                 varchar2(1000);
  l_vPmedio                number;
  BEGIN
        l_vTipo := p_tipo;
        if p_tipo is null then
           l_vTipo := 'Todos os Tipos';
        end if;
    
       -- cabecalho
        l_vRegistro := 'Relatorio de POLITICA DE ESTOQUE  -  Emissao em ' || sysdate || '   /  Tipo -> ' || l_vTipo;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        --l_vRegistro := 'Empresa;Nome Emp;Papel;Desc Papel;Tipo Papel;Tipo;Formato;Gramat;Local;Desc Local;Saldo Atual;Estoque;Politica;DiferençDias Polit;Total Reservas Polit;Pco Medio Contabil;Aplicacoes';
        l_vRegistro := 'Empresa;Nome Emp;Papel;Desc Papel;Tipo Papel;Tipo;Formato;Gramat;Local;Desc Local;Saldo Atual;Estoque;Politica;DiferençTotal Reservas Polit;Pco Medio Contabil;Aplicacoes';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        --dbms_output.put_line(l_vRegistro);

        FOR r_politica IN c_politica
            LOOP
                  --buscar aplicacoes
                  l_vAplic := null;
                  for r_aplic in (select distinct(dsc_revista) dsc_revista
                                    from BOLINF.XXINV_RESERVA_PAPEL_V
                                   where DAT_UTILIZACAO between trunc(sysdate) and trunc(sysdate + nvl(r_politica.dias_pol,0))
                                   and   cod_situacao = 1 
                                   and   cod_item = r_politica.cod_item
                      ) loop
                      
                           l_vAplic := l_vAplic ||' / '|| r_aplic.dsc_revista;
                           
                  end loop;
                  --buscar preco medio
                  l_vPmedio :=0;
                  begin
                           SELECT  decode(nvl(cpic.item_cost,0),0,0.01,cpic.item_cost) custo
                              into l_vPmedio
                              FROM apps.cst_pac_item_costs           cpic
                                 , apps.cst_pac_periods              cpp
                                 , apps.cst_cost_groups              ccg
                                 , apps.org_organization_definitions ood
                                 , apps.mtl_system_items_b           msib
                                 , apps.mtl_cross_references         mcr
                             WHERE cpp.pac_period_id             = cpic.pac_period_id
                               AND cpic.cost_group_id            = ccg.cost_group_id
                               AND cpic.inventory_item_id        = msib.inventory_item_id
                               AND cpp.legal_entity              = ood.legal_entity
                               AND ood.organization_id           = msib.organization_id
                               AND ccg.cost_group                = 'ABRIL'
                               and sysdate - 170 between cpp.period_start_date and cpp.period_end_date   
                               and mcr.inventory_item_id         = msib.inventory_item_id
                               AND mcr.cross_reference_type      = 'CODIGO LEGADO SSP'
                               and ood.organization_code         = r_politica.organization_code
                               and msib.inventory_item_id        = r_politica.inventory_item_id
                               ;                     
                  exception when others then
                            null;
                  end;
                  
                  l_vRegistro :=  r_politica.organization_code    || ';' ||
                                  r_politica.organization_name    || ';' ||
                                  r_politica.cod_item             || ';' ||
                                  r_politica.des_papel            || ';' ||
                                  r_politica.tipo_papel           || ';' ||
                                  r_politica.tipo                 || ';' ||
                                  r_politica.formato              || ';' ||
                                  r_politica.GRAMAT               || ';' ||
                                  r_politica.local                || ';' ||
                                  r_politica.des_local            || ';' ||
                                  REPLACE(REPLACE(r_politica.saldo,',',''),'.',',') || ';' ||
                                  r_politica.politica             || ';' ||
                                  r_politica.meses_pol_est        || ';' ||
                                  REPLACE(REPLACE(r_politica.saldo-r_politica.tot_res,',',''),'.',',') || ';' ||
                                  --r_politica.dias_pol             || ';' ||
                                  REPLACE(REPLACE(r_politica.tot_res,',',''),'.',',')   || ';' ||
                                  REPLACE(REPLACE(l_vPmedio,',',''),'.',',') || ';' ||
                                  l_vAplic;                                  
                                          
                  fnd_file.put_line(fnd_file.output,l_vRegistro);
                  --dbms_output.put_line(l_vRegistro);
        END LOOP;
                                                     
  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de POLITICA DE ESTOQUE. ' || SQLERRM);
          --dbms_output.put_line('Erro ao processar relatorio RESERVAS PENDENTES. ' || SQLERRM);
  
  END gera_lst_politica_estoque;

  PROCEDURE gera_estat_consumo ( errbuf               OUT VARCHAR2
                               , retcode              OUT NUMBER
                               , p_organization_id    IN NUMBER
                               , p_ano                IN NUMBER) is
  
  cursor c_consumo_org is
                 select  sum(xirp.QTD_KG_PAPEL_RESERVADO - nvl(xirp.qtd_consumo,0)) qtd_mes
                        ,tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' ||
                         indtrib.element_value tipo_papel        
                        ,to_char(xirp.dat_utilizacao,'mm')   mes
                        ,to_char(xirp.dat_utilizacao,'rrrr') ano
                        ,proced.element_value                procedencia
                        ,xirp.COD_ORG                        
                  from   bolinf.xxinv_reserva_papel_v xirp 
                        ,apps.mtl_descr_element_values    tipo
                        ,apps.mtl_descr_element_values    proced
                        ,apps.mtl_descr_element_values    proces
                        ,apps.mtl_descr_element_values    indtrib
                  where  xirp.cod_situacao in (1,4)  --(1=Ativa 2=Provisoria 3=Cancelada 4=Encerrada)
                    and  to_char(xirp.dat_utilizacao,'rrrr') = p_ano
                    AND  xirp.inventory_item_id = tipo.inventory_item_id
                    AND  tipo.element_name  = 'TIPO'
                    AND  xirp.inventory_item_id = proced.inventory_item_id
                    AND  proced.element_name = 'PROCEDENCIA'
                    AND  xirp.inventory_item_id = proces.inventory_item_id
                    AND  proces.element_name = 'PROCESSO'
                    AND  xirp.inventory_item_id = indtrib.inventory_item_id
                    AND  indtrib.element_name = 'INDICADOR DE TRIBUTACAO'
                    AND  xirp.cod_org         = nvl(p_organization_id,xirp.cod_org)
                group by xirp.COD_ORG     
                        ,tipo.element_value
                        ,to_char(xirp.dat_utilizacao,'mm')  
                        ,to_char(xirp.dat_utilizacao,'rrrr')
                        ,proced.element_value 
                        ,tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' || indtrib.element_value
                order by xirp.COD_ORG
                        ,proced.element_value
                        ,tipo.element_value
                        ,tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' || indtrib.element_value
                        ,to_char(xirp.dat_utilizacao,'mm')  
                        ,to_char(xirp.dat_utilizacao,'rrrr') ;
                    
  cursor c_consumo_tipo (v_ano             in number,
                         v_organization_id in number,
                         v_tipo            in varchar2,
                         v_mes             in varchar2) is
                  select  sum(xirp.QTD_KG_PAPEL_RESERVADO - nvl(xirp.qtd_consumo,0)) qtd_mes
                        ,tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' ||
                         indtrib.element_value tipo_papel        
                        ,to_char(xirp.dat_utilizacao,'mm')   mes
                        ,to_char(xirp.dat_utilizacao,'rrrr') ano
                        ,proced.element_value                procedencia
                  from   bolinf.xxinv_reserva_papel_v xirp 
                        ,apps.mtl_descr_element_values    tipo
                        ,apps.mtl_descr_element_values    proced
                        ,apps.mtl_descr_element_values    proces
                        ,apps.mtl_descr_element_values    indtrib
                  where  xirp.cod_situacao in (1,4)  --(1=Ativa 2=Provisoria 3=Cancelada 4=Encerrada)
                    and  to_char(xirp.dat_utilizacao,'rrrr') = v_ano
                    AND  xirp.inventory_item_id = tipo.inventory_item_id
                    AND  tipo.element_name  = 'TIPO'
                    AND  xirp.inventory_item_id = proced.inventory_item_id
                    AND  proced.element_name = 'PROCEDENCIA'
                    AND  xirp.inventory_item_id = proces.inventory_item_id
                    AND  proces.element_name = 'PROCESSO'
                    AND  xirp.inventory_item_id = indtrib.inventory_item_id
                    AND  indtrib.element_name = 'INDICADOR DE TRIBUTACAO'
                    AND  xirp.cod_org         = nvl(v_organization_id,xirp.cod_org)
                    AND  tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' ||
                         indtrib.element_value = v_tipo
                    AND  to_char(xirp.dat_utilizacao,'mm') = v_mes
                group by tipo.element_value
                        ,to_char(xirp.dat_utilizacao,'mm')  
                        ,to_char(xirp.dat_utilizacao,'rrrr')
                        ,proced.element_value 
                        ,tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' || indtrib.element_value
                order by proced.element_value
                        ,tipo.element_value
                        ,tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' || indtrib.element_value
                        ,to_char(xirp.dat_utilizacao,'mm')  
                        ,to_char(xirp.dat_utilizacao,'rrrr') ;

  cursor c_consumo_orig is
                 select  sum(xirp.QTD_KG_PAPEL_RESERVADO - nvl(xirp.qtd_consumo,0)) qtd_mes
                        ,to_char(xirp.dat_utilizacao,'mm')   mes
                        ,to_char(xirp.dat_utilizacao,'rrrr') ano
                        ,proced.element_value                procedencia
                        ,xirp.COD_ORG                        
                  from   bolinf.xxinv_reserva_papel_v xirp 
                        ,apps.mtl_descr_element_values    proced
                  where  xirp.cod_situacao in (1,4)  --(1=Ativa 2=Provisoria 3=Cancelada 4=Encerrada)
                    and  to_char(xirp.dat_utilizacao,'rrrr') = p_ano
                    AND  xirp.inventory_item_id = proced.inventory_item_id
                    AND  proced.element_name = 'PROCEDENCIA'
                    AND  xirp.cod_org         = nvl(p_organization_id,xirp.cod_org)
                group by xirp.COD_ORG     
                        ,to_char(xirp.dat_utilizacao,'mm')  
                        ,to_char(xirp.dat_utilizacao,'rrrr')
                        ,proced.element_value 
                order by xirp.COD_ORG
                        ,proced.element_value
                        ,to_char(xirp.dat_utilizacao,'mm')  
                        ,to_char(xirp.dat_utilizacao,'rrrr') ;
  
  cursor c_origem is
         select element_value origem
         from bolinf.xxinv_origem 
         ;
         
  cursor c_tipos (v_origem in varchar2) is
        select distinct(tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' || indtrib.element_value) tipo_papel        
        from   bolinf.xxinv_reserva_papel_v xirp 
              ,apps.mtl_descr_element_values    tipo
              ,apps.mtl_descr_element_values    proced
              ,apps.mtl_descr_element_values    proces
              ,apps.mtl_descr_element_values    indtrib
        where  xirp.cod_situacao in (1,4)  --(1=Ativa 2=Provisoria 3=Cancelada 4=Encerrada)
          and  to_char(xirp.dat_utilizacao,'rrrr') = p_ano
          AND  xirp.inventory_item_id = tipo.inventory_item_id
          AND  tipo.element_name  = 'TIPO'
          AND  xirp.inventory_item_id = proced.inventory_item_id
          AND  proced.element_name = 'PROCEDENCIA'
          AND  xirp.inventory_item_id = proces.inventory_item_id
          AND  proces.element_name = 'PROCESSO'
          AND  xirp.inventory_item_id = indtrib.inventory_item_id
          AND  indtrib.element_name = 'INDICADOR DE TRIBUTACAO'
          AND  proced.element_value = v_origem
        group by tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' || indtrib.element_value
        order by tipo.element_value || ' ' || proces.element_value || ' ' || proced.element_value || ' ' || indtrib.element_value
         ;                              
  
  l_vRegistro              varchar2(1000);
  l_vOrg                   varchar2(1000);
  l_vAplic                 varchar2(1000);
  l_vPmedio                number;
  l_vQTotal                number;
  l_vQtd_mes               number;
  
  begin

        l_vOrg := p_organization_id;
        if p_organization_id is null then
           l_vOrg := 'Todas as Organizacoes';
        end if;
    
       -- cabecalho
        l_vRegistro := 'Relatorio de ESTATISTICA DE CONSUMO  - ANO = ' || p_ano || ' -  Emissao em ' || sysdate || '   /  Org -> ' || l_vOrg;
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        dbms_output.put_line(l_vRegistro);

        l_vRegistro := 'RESUMO POR TIPO DE PAPEL';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        dbms_output.put_line(l_vRegistro);

        l_vRegistro := ';';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        dbms_output.put_line(l_vRegistro);

        l_vRegistro := 'Tipo de Papel;Jan;Fev;Mar;Abr;Mai;Jun;Jul;Ago;Set;Out;Nov;Dez;TOTAL';
        fnd_file.put_line(fnd_file.output,l_vRegistro);
        dbms_output.put_line(l_vRegistro);
        
        For r_origem in c_origem
        Loop
              For r_tipos in c_tipos (r_origem.origem)
                  loop
                      l_vRegistro := r_tipos.tipo_papel || ';';
                      l_vQTotal := 0;

                      For i_mes in 1..12 loop
                      
                          l_vQtd_mes :=0;
                          FOR r_cons_tipo IN c_consumo_tipo (p_ano,p_organization_id,r_tipos.tipo_papel,lpad(i_mes,2,'0'))
                              LOOP
                                    --l_vRegistro := l_vRegistro || r_cons_tipo.qtd_mes || ';';
                                    l_vQtd_mes  := r_cons_tipo.qtd_mes;                                  
                                    l_vQTotal   := l_vQTotal + r_cons_tipo.qtd_mes;
                          END LOOP;
                          l_vRegistro := l_vRegistro || l_vQtd_mes || ';';                                  

                      end loop;

                      l_vRegistro :=  l_vRegistro || l_vQTotal;
                      fnd_file.put_line(fnd_file.output,l_vRegistro);
                      dbms_output.put_line(l_vRegistro);       
               end loop;
         end loop;
                                                      
  EXCEPTION
       WHEN OTHERS THEN
          retcode  := 1; -- warning
          fnd_file.put_line(fnd_file.log,'Erro ao processar relatorio de ESTATISTICA DE CONSUMO. ' || SQLERRM);
          dbms_output.put_line('Erro ao processar relatorio RESERVAS PENDENTES. ' || SQLERRM);
  
  END gera_estat_consumo;
                               
END xxinv_paper_lot_pk;
/
