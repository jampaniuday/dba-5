col sid for 9999
col user_name for a10
col os_id for 99999
col machine_name for a15
col logon_time for a30

select * from 
(select b.sid sid,
        decode(b.username,null,e.name,b.username) user_name,
        d.spid os_id,
        b.machine machine_name,
        to_char(logon_time,'dd-mon-yy hh:mi:ss pm') logon_time,
        (sum(decode(c.name,'physical reads',value,0))+
        sum(decode(c.name,'physical writes',value,0))+
        sum(decode(c.name,'physical writes direct',value,0))+
        sum(decode(c.name,'physical writes direct (lob)',value,0))+
        sum(decode(c.name,'physical reads direct (lob)',value,0))+
        sum(decode(c.name,'physical reads direct',value,0))) total_physical_io,
        (sum(decode(c.name,'db block gets',value,0))+
        sum(decode(c.name,'db block changes',value,0))+
        sum(decode(c.name,'consistent changes',value,0))+
        sum(decode(c.name,'consistent gets',value,0))) total_logical_io,
        (sum(decode(c.name,'session pga memory',value,0)) +
        sum(decode(c.name,'session uga memory',value,0))) total_memory_usage,
        sum(decode(c.name,'parse count (total)',value,0)) parses,
        sum(decode(c.name,'cpu used by this session',value,0)) total_cpu,
        sum(decode(c.name,'parse time cpu',value,0)) parse_cpu,
        sum(decode(c.name,'recursive cpu usage',value,0)) recursive_cpu,
        sum(decode(c.name,'cpu used by this session',value,0)) -
        sum(decode(c.name,'parse time cpu',value,0))-
        sum(decode(c.name,'recursive cpu usage',value,0)) other_cpu,
        sum(decode(c.name,'sorts (disk)',value,0)) disck_sorts,
        sum(decode(c.name,'sorts (memory)',value,0)) memory_sorts,
        sum(decode(c.name,'sorts (rows)',value,0)) rows_sorts,        
        sum(decode(c.name,'user commits',value,0)) commits,        
        sum(decode(c.name,'user rollbacks',value,0)) rollbacks,        
        sum(decode(c.name,'execute count',value,0)) executions
from    sys.v$sesstat a,
        sys.v$session b,
        sys.v$statname c,
        sys.v$process d,
        sys.v$bgprocess e
where a.statistic# = c.statistic#                     
and   b.sid = a.sid
and   d.addr = b.paddr
and   e.paddr (+) = b.paddr
and   c.name in ('physical reads',
                 'physical writes',
                 'physical writes direct',
                 'physical writes direct (lob)',
                 'physical reads direct (lob)',
                 'physical reads direct',
                 'db block gets',
                 'db block changes',
                 'consistent changes',
                 'consistent gets',
                 'session pga memory',
                 'session uga memory',
                 'parse count (total)',
                 'cpu used by this session',
                 'parse time cpu',
                 'recursive cpu usage',
                 'cpu used by this session',
                 'parse time cpu',
                 'recursive cpu usage',
                 'sorts (disk)',
                 'sorts (memory)',
                 'sorts (rows)',
                 'user commits',
                 'user rollbacks',
                 'execute count')
group by b.sid,
         d.spid,
         decode(b.username,null,e.name,b.username),
         b.machine,to_char(logon_time,'dd-mon-yy hh:mi:ss pm')
order by 6 desc)
where rownum < 21;                          
