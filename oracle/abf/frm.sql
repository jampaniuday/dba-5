SELECT   NVL (username, 'SYS-BKGD') username, sess.SID, round(SUM(VALUE)/1024/1024) sess_mem, sess.module,sess.action, sess.inst_id, sess.status
FROM gv$session sess, gv$sesstat stat, gv$statname NAME
WHERE 1=1
AND sess.SID = stat.SID
AND stat.statistic# = NAME.statistic#
AND NAME.NAME LIKE 'session % memory'
--and sess.action like 'FRM%' -- forms
--and sess.module like '%RAIZ%CPR%'
GROUP BY username, sess.SID, sess.module, sess.inst_id, sess.status,sess.action
order by 3 desc
;
