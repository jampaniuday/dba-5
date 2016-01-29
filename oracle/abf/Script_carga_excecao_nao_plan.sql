set serveroutput on
declare
   cursor c_itens is
          select a.organization_code , a.item_number , a.plan_mrp , a.wip ,a.planner_code , a.status , a.msg_erro , ood.organization_id
          from bolinf.xxinv_carga_excecao a, apps.org_organization_definitions ood
          where a.status='PENDENTE'
          and a.organization_code = ood.organization_code;
   l_qtd_sucess number(10);
   l_qtd_error number(10);
   l_msg_erro varchar2(4000);
begin
   for r_itens in c_itens
   loop
      begin
         update apps.mtl_system_items_b set MRP_PLANNING_CODE = r_itens.plan_mrp, build_in_wip_flag = r_itens.wip, 
                planner_code = r_itens.planner_code 
                where segment1 = r_itens.item_number
                and organization_id = r_itens.organization_id;
         
         update bolinf.xxinv_carga_excecao set status = 'OK' 
               where item_number = r_itens.item_number
                 and organization_code = r_itens.organization_code
                 and status = 'PENDENTE';
         l_qtd_sucess := l_qtd_sucess + 1;
         
      exception
         when NO_DATA_FOUND then
            l_msg_erro := 'Organização ' || r_itens.organization_code || ' não encontrada';
         when others then
            l_msg_erro := 'Erro inesperado ao pesquisar organização ' || r_itens.organization_code || ' - ' || sqlerrm;
      end;
      IF l_msg_erro IS NOT NULL THEN 
         l_qtd_error := l_qtd_error + 1;
         update bolinf.xxinv_load_categ set status = 'ERRO', MSG_ERRO = SUBSTR(l_msg_erro,1,3000) 
         where item_number = r_itens.item_number
         and organization_code = r_itens.organization_code and status = 'PENDENTE';
      END IF;
      l_msg_erro := NULL;
      COMMIT;
   end loop;
   dbms_output.put_line('Registros processados com sucesso: ' ||  l_qtd_sucess);
   dbms_output.put_line('Registros processados com erro: ' ||  l_qtd_error);
end;
