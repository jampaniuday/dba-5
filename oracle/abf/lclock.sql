select
     p.inst_id,
     status||decode(lockwait,null,' ','-lck') status,
     sid||' - '||s.serial# sessionid,
     substr(osuser,1,10)  "OS user",
     substr(s.username,1,10) "ORA USER",
     machine,
     spid    "SO Process",
     process "Ora pid",
     s.program||action||module program
    from
    gv$process p,
    gv$session s
  where
        p.inst_id=s.inst_id and
         p.addr=s.paddr
        --status in ('ACTIVE' ,'KILLED')
and s.sid in ( select s.sid
     from v$session s, v$session_wait w where w.sid = s.sid and
      w.event like 'library cache %'
)       --s.username is not null
order by 2
/
