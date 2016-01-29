SET pages 56 lines 78 verify off feedback off
START title80 "Redo Latch Statistics"
SPOOL rep_out/rdo_stat
REM
COLUMN name             format a30      heading Name
COLUMN percent          format 999.999  heading Percent
COLUMN total                            heading Total
REM
SELECT l2.NAME,   immediate_gets
                + gets total, immediate_gets "Immediates",
         misses
       + immediate_misses "Total Misses",
       DECODE (
            100.
          * (  GREATEST (  misses
                         + immediate_misses, 1)
             / GREATEST (  immediate_gets
                         + gets, 1)
            ),
          100, 0
       )
             PERCENT
  FROM v$latch l1, v$latchname l2
 WHERE l2.NAME LIKE '%redo%' AND l1.latch# = l2.latch#;
REM
SPOOL OFF
TTITLE OFF
