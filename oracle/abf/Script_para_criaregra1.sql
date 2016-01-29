DECLARE
  --
  -- Script tem que rodar em DEDA5i, porque busca informações em TEDA8i, --
  -- como terá que rodar em PEDA1i buscando informações em TEDA8i.       --
  --
  l_nrule_id           NUMBER       := NULL;
  l_user_id            NUMBER       := NULL;
  l_responsibility_id  NUMBER       := NULL;
  l_application_id     NUMBER       := NULL;
  l_norganization_id   NUMBER       := NULL;
  l_ncreated_by        NUMBER       := fnd_profile.value('USER_ID');
  l_dcreation_date     DATE         := SYSDATE;
  l_nlast_updated_by   NUMBER       := fnd_profile.value('USER_ID');
  l_dlast_update_date  DATE         := SYSDATE;
  l_nlast_update_login NUMBER       := fnd_profile.value('LOGIN_ID');
  l_nprimvez           BOOLEAN      := TRUE;
  l_nrule_id_old       NUMBER       := 9999999999999999;
  l_nIdOrganizationAnt apps.hr_all_organization_units.organization_id%TYPE := NULL;
  l_nIdOrganizationNva apps.hr_all_organization_units.organization_id%TYPE := NULL;
  l_vDescrorgan        apps.hr_all_organization_units.name%TYPE            := NULL;
  l_nCmt               NUMBER       := 0;
  --
  CURSOR c_Orgs IS
    SELECT 'TICA'     Nome
         , '4'        TpOrg
      FROM dual
    UNION ALL
    SELECT 'SCIPIONE' Nome
         , '5'        TpOrg
      FROM dual;
  --
  CURSOR c_DePara ( pc_OrgCode IN apps.org_organization_definitions.organization_code%TYPE ) IS 
    SELECT haou.organization_id        organization_id_ant  --ID das organizações atual
         , to_number(haou.attribute20) organization_id_novo --ID das novas organizações
         , haou.name                   descr_organ
      FROM apps.hr_all_organization_units haou
     WHERE haou.attribute20 IS NOT NULL
       AND haou.organization_id IN ( SELECT organization_id
                                       FROM apps.org_organization_definitions
                                      WHERE organization_code = pc_OrgCode );
  --
  CURSOR c_cad ( pc_nm IN VARCHAR2 ) IS
    SELECT frv.responsibility_id
         , frv.application_id
         , (SELECT fu.user_id FROM fnd_user fu WHERE fu.user_name = 'ABRLCONC') id_usuario
         , frv.responsibility_name
      FROM apps.fnd_responsibility_vl@TEDA8i frv
         , apps.fnd_application_tl@TEDA8i    fat
     WHERE fat.application_id                = frv.application_id
       AND fat.language                      = userenv('LANG')
       AND upper(frv.responsibility_name) LIKE '%GERENTE%DEP%'||pc_nm
       AND frv.end_date                     IS NULL;
  --
  l_rCad    c_cad%ROWTYPE;
  l_rOrgs   c_Orgs%ROWTYPE;
  l_rDePara c_DePara%ROWTYPE;
  --
BEGIN
  --
  OPEN c_Orgs;
    LOOP
      FETCH c_Orgs INTO l_rOrgs;
      EXIT WHEN c_Orgs%NOTFOUND;
      --
      OPEN c_cad ( pc_nm => l_rOrgs.Nome );
        FETCH c_cad INTO l_rCad;
        --
        IF c_cad%FOUND THEN
          --
          l_user_id            := l_rCad.id_usuario;
          l_responsibility_id  := l_rCad.responsibility_id;
          l_application_id     := l_rCad.application_id;
          --
        ELSIF
          c_cad%NOTFOUND THEN
          --
          l_user_id            := NULL;
          l_responsibility_id  := NULL;
          l_application_id     := NULL;
          --
        END IF;
        --
      CLOSE c_cad;
      --
      fnd_global.apps_initialize(l_user_id, l_responsibility_id, l_application_id);
      --
      l_ncreated_by        := fnd_profile.value('USER_ID');
      l_nlast_updated_by   := fnd_profile.value('USER_ID');
      l_nlast_update_login := fnd_profile.value('LOGIN_ID');
      --
      FOR wr IN ( SELECT ood.organization_code
                       , wrb.organization_id
                       , wrb.rule_id
                    FROM wms_rules_b@TEDA8i                  wrb
                       , org_organization_definitions@TEDA8i ood
                   WHERE wrb.organization_id                 = ood.organization_id
                     AND substr(ood.organization_code, 1, 1) = l_rOrgs.TpOrg
                 ) LOOP
        --
        l_nCmt := l_nCmt + 1;
        --
        OPEN c_DePara (pc_OrgCode => wr.organization_code);
          FETCH c_DePara INTO l_rDePara;
            IF c_DePara%FOUND THEN
              --
              l_nIdOrganizationAnt := l_rDePara.organization_id_ant;
              l_nIdOrganizationNva := l_rDePara.organization_id_novo;
              l_vDescrorgan        := l_rDePara.descr_organ;
              l_norganization_id   := l_nIdOrganizationNva;
              --
            ELSIF
              c_DePara%NOTFOUND THEN
              --
              l_nIdOrganizationAnt := NULL;
              l_nIdOrganizationNva := NULL;
              l_vDescrorgan        := NULL;
              l_norganization_id   := NULL;
              --
            END IF;
        CLOSE c_DePara;
        --        
        
/*        BEGIN
          SELECT organization_id
            INTO l_norganization_id
            FROM org_organization_definitions
           WHERE organization_code = wr.organization_code;
        EXCEPTION
          WHEN OTHERS THEN
            raise_application_error(-20001,'Erro ao selecionar organization_id - ' || SQLERRM);
        END;*/
        --
        dbms_output.put_line('Organization_id OLD = ' || wr.organization_id ||' - Organization_id NEW = ' || l_norganization_id);
        -- 
        FOR i IN ( SELECT * 
                     FROM wms_rules_tl@TEDA8i 
                    WHERE rule_id = wr.rule_id ) LOOP
          --
          IF i.rule_id != l_nrule_id_old THEN
            BEGIN
              SELECT wms_rules_s.nextval 
                INTO l_nrule_id 
                FROM dual;
            EXCEPTION
              WHEN OTHERS THEN
                raise_application_error(-20001, SQLERRM);
            END;
          END IF;
          --
          dbms_output.put_line('Vou inserir dados na tabela wms_rules_name ' || i.name);
          --
          INSERT INTO wms_rules_tl
            (rule_id
            ,LANGUAGE
            ,last_updated_by
            ,last_update_date
            ,created_by
            ,creation_date
            ,last_update_login
            ,source_lang
            ,NAME
            ,description)
          VALUES
            (l_nrule_id
            ,i.language
            ,l_nlast_updated_by
            ,l_dlast_update_date
            ,l_ncreated_by
            ,l_dcreation_date
            ,l_nlast_update_login
            ,i.source_lang
            ,i.name
            ,i.description);
          --
          IF i.rule_id != l_nrule_id_old THEN
            FOR x IN ( SELECT * 
                         FROM wms_rules_b@TEDA8i 
                        WHERE rule_id = i.rule_id ) LOOP
              --
              --dbms_output.put_line('Vou inserir dados na tabela wms_rules_b ' || l_nRule_id);
              --
              INSERT INTO wms_rules_b
                (rule_id
                ,last_updated_by
                ,last_update_date
                ,created_by
                ,creation_date
                ,last_update_login
                ,organization_id
                ,type_code
                ,qty_function_parameter_id
                ,enabled_flag
                ,user_defined_flag
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,type_hdr_id
                ,rule_weight
                ,min_pick_tasks_flag
                ,allocation_mode_id
                ,wms_enabled_flag)
              VALUES
                (l_nrule_id
                ,l_nlast_updated_by
                ,l_dlast_update_date
                ,l_ncreated_by
                ,l_dcreation_date
                ,l_nlast_update_login
                ,l_norganization_id
                ,x.type_code
                ,x.qty_function_parameter_id
                ,'N' --x.enabled_flag 
                ,x.user_defined_flag
                ,x.attribute_category
                ,x.attribute1
                ,x.attribute2
                ,x.attribute3
                ,x.attribute4
                ,x.attribute5
                ,x.attribute6
                ,x.attribute7
                ,x.attribute8
                ,x.attribute9
                ,x.attribute10
                ,x.attribute11
                ,x.attribute12
                ,x.attribute13
                ,x.attribute14
                ,x.attribute15
                ,x.type_hdr_id
                ,x.rule_weight
                ,x.min_pick_tasks_flag
                ,x.allocation_mode_id
                ,x.wms_enabled_flag);
              --
              FOR y IN ( SELECT * 
                           FROM wms_restrictions@TEDA8i
                          WHERE rule_id = i.rule_id      ) LOOP
                --
                --  dbms_output.put_line('Vou inserir dados na tabela wms_restrictions ' || l_nRule_id || ' - ' || y.sequence_number);
                --
                INSERT INTO wms_restrictions
                  (rule_id
                  ,sequence_number
                  ,last_updated_by
                  ,last_update_date
                  ,created_by
                  ,creation_date
                  ,last_update_login
                  ,parameter_id
                  ,operator_code
                  ,operand_type_code
                  ,operand_constant_number
                  ,operand_constant_character
                  ,operand_constant_date
                  ,operand_parameter_id
                  ,operand_expression
                  ,operand_flex_value_set_id
                  ,logical_operator_code
                  ,bracket_open
                  ,bracket_close
                  ,attribute_category
                  ,attribute1
                  ,attribute2
                  ,attribute3
                  ,attribute4
                  ,attribute5
                  ,attribute6
                  ,attribute7
                  ,attribute8
                  ,attribute9
                  ,attribute10
                  ,attribute11
                  ,attribute12
                  ,attribute13
                  ,attribute14
                  ,attribute15)
                VALUES
                  (l_nrule_id
                  ,y.sequence_number
                  ,l_nlast_updated_by
                  ,l_dlast_update_date
                  ,l_ncreated_by
                  ,l_dcreation_date
                  ,l_nlast_update_login
                  ,y.parameter_id
                  ,y.operator_code
                  ,y.operand_type_code
                  ,y.operand_constant_number
                  ,y.operand_constant_character
                  ,y.operand_constant_date
                  ,y.operand_parameter_id
                  ,y.operand_expression
                  ,y.operand_flex_value_set_id
                  ,y.logical_operator_code
                  ,y.bracket_open
                  ,y.bracket_close
                  ,y.attribute_category
                  ,y.attribute1
                  ,y.attribute2
                  ,y.attribute3
                  ,y.attribute4
                  ,y.attribute5
                  ,y.attribute6
                  ,y.attribute7
                  ,y.attribute8
                  ,y.attribute9
                  ,y.attribute10
                  ,y.attribute11
                  ,y.attribute12
                  ,y.attribute13
                  ,y.attribute14
                  ,y.attribute15);
              END LOOP; -- y
              --
              IF i.rule_id != l_nrule_id_old THEN
                FOR j IN ( SELECT * 
                             FROM wms_sort_criteria@TEDA8i 
                            WHERE rule_id = i.rule_id       ) LOOP
                  --
                  --  dbms_output.put_line('Vou inserir dados na tabela wms_sort_criteria ' || l_nRule_id || ' - ' || j.sequence_number);
                  --
                  INSERT INTO wms_sort_criteria
                    (rule_id
                    ,sequence_number
                    ,last_updated_by
                    ,last_update_date
                    ,created_by
                    ,creation_date
                    ,last_update_login
                    ,parameter_id
                    ,order_code
                    ,attribute_category
                    ,attribute1
                    ,attribute2
                    ,attribute3
                    ,attribute4
                    ,attribute5
                    ,attribute6
                    ,attribute7
                    ,attribute8
                    ,attribute9
                    ,attribute10
                    ,attribute11
                    ,attribute12
                    ,attribute13
                    ,attribute14
                    ,attribute15)
                  VALUES
                    (l_nrule_id
                    ,j.sequence_number
                    ,l_nlast_updated_by
                    ,l_dlast_update_date
                    ,l_ncreated_by
                    ,l_dcreation_date
                    ,l_nlast_update_login
                    ,j.parameter_id
                    ,j.order_code
                    ,j.attribute_category
                    ,j.attribute1
                    ,j.attribute2
                    ,j.attribute3
                    ,j.attribute4
                    ,j.attribute5
                    ,j.attribute6
                    ,j.attribute7
                    ,j.attribute8
                    ,j.attribute9
                    ,j.attribute10
                    ,j.attribute11
                    ,j.attribute12
                    ,j.attribute13
                    ,j.attribute14
                    ,j.attribute15);
                END LOOP; 
              END IF;
            END LOOP;
          END IF;
          l_nrule_id_old := i.rule_id;
        END LOOP; 
        --
        IF l_nCmt = 500 THEN
          --
          l_nCmt := 0;
          --
          COMMIT;
          --
        END IF;
        --
      END LOOP;
      --
    END LOOP;
  CLOSE c_Orgs;
  --
  COMMIT;
  --
END;
