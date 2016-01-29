COLUMN NAME   FORMAT A30
COLUMN RATIO1  FORMAT 999.9999
COLUMN RATIO2  FORMAT 999.9999
SET PAGES 58 NEWPAGE 0
TTITLE left _date center 'Latch Contention Report' skip 2
SELECT a.NAME, 100. * b.sleeps / b.gets ratio1,
         100.
       * b.immediate_misses
       / DECODE ((  b.immediate_misses
                  + b.immediate_gets
                 ), 0, 1) ratio2
  FROM v$latchname a, v$latch b
 WHERE a.latch# = b.latch# AND b.sleeps > 0;
CLEAR columns
TTITLE off
SET pages 22
