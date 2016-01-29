SET VERIFY OFF FEEDBACK OFF
SET PAGES 58
SET LINES 79
TTITLE left _date center 'Area Of Contention Report' skip 2
SELECT   CLASS, SUM (COUNT) total_waits, SUM (TIME) total_time
    FROM v$waitstat
GROUP BY CLASS;
SET verify on feedback on pages 22 lines 80
TTITLE off
