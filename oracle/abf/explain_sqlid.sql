SELECT *
FROM table(DBMS_XPLAN.DISPLAY_CURSOR('&sql_id',0));

