SELECT s.sid, s.serial#, s.username, s.program, i.block_changes, p.spid, s.osuser
FROM v$session s, v$sess_io i, v$process p
WHERE s.sid = i.sid
and s.paddr = p.addr
and s.sid = &sid
ORDER BY 5 desc, 1, 2, 3, 4;
