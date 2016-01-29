DECLARE
      l_return VARCHAR2(1000);
BEGIN  

for i in 2..5 
loop
  cll_f255_utils_pkg.notification_purge ( p_status => i
          , p_isv_name => null
                                        , p_start_date => TO_DATE('01-jan-2012')
                                        , p_end_date => TO_DATE('28-sep-2012')
                                        , p_return => l_return);

  DBMS_OUTPUT.PUT_LINE('API message - status ' || i ||': '||l_return);
end loop;
END;
/
