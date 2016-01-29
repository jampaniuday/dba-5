WHENEVER SQLERROR EXIT FAILURE ROLLBACK
CONNECT &1/&2 
--
CREATE OR REPLACE VIEW BOLINF.XXINV_OC_SSP_V AS
SELECT pha.org_id org_id
-- $Header: XXINV_OC_SSP_V.vw 120.0 2014-04-03 04:56:00 t31364 $
-- +=================================================================+
-- |                 Editora Abril, Sao Paulo, Brasil                |
-- |                       All rights reserved.                      |
-- +=================================================================+
-- | FILENAME                                                        |
-- |   XXINV_OC_SSP_V.vw                                             |
-- | PURPOSE                                                         |
-- |                                                                 |
-- | DESCRIPTION                                                     |
-- |                                                                 |
-- |                                                                 |
-- | CREATED BY  <Nome do Desenvolvedor> / data                      |
-- | UPDATED BY  <Nome do Desenvolvedor> / data                      |
-- |                                                                 |
-- +=================================================================+
--
      ,msib.organization_id
      ,ood.organization_code
      ,ood.organization_name
      ,pd.destination_subinventory cod_sub_inv
      ,plla.line_location_id line_location_id
      ,plla.attribute1 lote
      ,MAX(pha.approved_date) data
      ,MAX(rt.transaction_date) data_entrega
      ,MAX(round(plla.quantity, 2)) qtde_requisitada
      ,MAX(plla.need_by_date) data_prev_entrega
     -- ,MAX(plla.promised_date) data_prev_entrega
      ,round(SUM(rt.quantity), 2) qtde_entregue
      ,SUM(round(plla.quantity_cancelled, 2)) qtde_cancelada
      ,SUM(round(plla.quantity_received, 2)) qtde_recebida
      ,decode(plla.cancel_flag, 'Y', 'C', decode(pha.closed_code, 'CLOSED', 'E', NULL)) situacao
      ,pha.segment1 pedido
      ,pla.line_num linha_pedido
      ,msib.segment1 papel
      ,msib.description des_papel
      ,mcr.cross_reference cod_papel_ssp
      ,plla.attribute3 nome_navio
      ,MAX((nvl(crono.dt_realizada, crono.dt_prevista) + 7)) dt_chegada
      ,SUM(round(rt.primary_quantity * rt.po_unit_price, 2)) total
      ,rt.currency_code moeda
      ,msib.inventory_item_id
      ,pha.authorization_status status_po
      ,asp.vendor_name FORNECEDOR
  FROM apps.mtl_cross_references    mcr
      ,apps.mtl_categories          mc
      ,apps.mtl_item_categories     mic
      ,apps.mtl_system_items_b      msib
      ,apps.rcv_transactions        rt
      ,po.po_line_locations_all     plla
      ,po.po_distributions_all      pd
      ,apps.po_lines_all            pla
      ,apps.po_headers_all          pha
      ,xxecomex.imp_invoices_lin_po iilp
      ,xxecomex.imp_invoices        ii
      ,xxecomex.imp_embarques       ie
      ,xxecomex.imp_conhecimentos   ic
      ,xxecomex.imp_declaracoes     id
      ,xxecomex.imp_cronograma      crono
      ,org_organization_definitions ood
      ,APPS.ap_suppliers asp
 WHERE pha.type_lookup_code || '' = 'STANDARD'
   AND ood.organization_id = msib.organization_id
  -- AND pha.authorization_status in ('APPROVED','REQUIRES REAPPROVAL')
   AND pha.authorization_status not in ('CANCELED','REJECTED')
   and pha.cancel_flag          != 'Y'
   and pha.CLOSED_CODE          != 'CLOSED'
   AND pha.po_header_id = pla.po_header_id
   AND plla.po_header_id = pha.po_header_id
   AND plla.po_line_id = pla.po_line_id
   AND plla.line_location_id = rt.po_line_location_id(+)
   AND pd.po_header_id = plla.po_header_id
   AND pd.po_line_id = plla.po_line_id
   AND pd.line_location_id = plla.line_location_id
   AND rt.destination_type_code(+) = 'INVENTORY'
   AND msib.inventory_item_id = pla.item_id
   AND mic.organization_id = msib.organization_id
   AND mic.inventory_item_id = msib.inventory_item_id
   AND mic.category_id = pla.category_id
   AND mc.category_id = mic.category_id
   AND msib.organization_id = plla.ship_to_organization_id
   AND mc.segment3 LIKE 'PAPEL IMPRESSAO%' -- NA R12, FICOU NO SEGMENT3 E NAO NO SEGMENT2
   AND mcr.inventory_item_id(+) = msib.inventory_item_id
   AND mcr.cross_reference_type(+) LIKE '%SSP%'
   AND (mcr.organization_id = msib.organization_id OR mcr.organization_id IS NULL)
   AND (nvl(plla.closed_code, 'X') != 'CLOSED' OR
       (nvl(plla.closed_code, 'X') = 'CLOSED' AND plla.closed_date >= SYSDATE - 30))
   AND plla.line_location_id = iilp.po_line_location_id(+)
   AND ii.invoice_id(+) = iilp.invoice_id
   AND ie.embarque_id(+) = ii.embarque_id
   AND ie.conhec_id = ic.conhec_id(+)
   AND id.embarque_id(+) = ie.embarque_id
   AND crono.embarque_id(+) = ie.embarque_id
   AND crono.tp_data_id(+) = xxecomex.cmx_pkg_tabelas.tabela_id('131', 'CHEGADA')
   and   pha.vendor_id     = asp.vendor_id
 GROUP BY pha.org_id
         ,msib.organization_id
         ,ood.organization_code
         ,ood.organization_name
         ,pd.destination_subinventory
         ,plla.line_location_id
         ,plla.attribute1
         ,plla.attribute3
         ,decode(plla.cancel_flag, 'Y', 'C', decode(pha.closed_code, 'CLOSED', 'E', NULL))
         ,pha.segment1
         ,pla.line_num
         ,msib.segment1
         ,msib.description
         ,mcr.cross_reference
         ,ic.identificacao_veiculo
         ,rt.currency_code
         ,msib.inventory_item_id
         ,pha.authorization_status
         ,asp.vendor_name

/
SHOW ERRORS
