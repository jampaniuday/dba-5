set serveroutput on
DECLARE 
   v_SegNum VARCHAR2(9);
   v_FreqCount NUMBER;
BEGIN 
FOR i IN 1..30
LOOP
   EXECUTE IMMEDIATE 'SELECT COUNT(DISTINCT SEGMENT'||TO_CHAR(i)||') FROM gl_code_combinations' INTO v_FreqCount ;
   IF v_freqCount <> 0 THEN 
      DBMS_OUTPUT.PUT_LINE( 'SEGMENT'||TO_CHAR(i)||'  Frequency = '||TO_CHAR(v_FreqCount));
   END IF;
 END LOOP;
END;
