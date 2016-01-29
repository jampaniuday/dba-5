col table_name for a30
col owner for a15
accept vUser prompt 'Informar o nome do usuario para analise: '

select rp.grantee, rp.default_role, rp.granted_role, rsp.privilege
from dba_role_privs rp, role_sys_privs rsp
where rp.grantee='&vUser'
and rp.granted_role=rsp.role(+)
order by 1,2,3,4;

select rp.grantee, rp.default_role, rp.granted_role, rtp.privilege, rtp.owner, rtp.table_name
from dba_role_privs rp, role_tab_privs rtp
where rp.grantee='&vUser'
and rp.granted_role=rtp.role(+)
order by 1,2,3,4,5,6;

select rp.grantee, rp.default_role, rp.granted_role, rrp.granted_role role_granted_role
from dba_role_privs rp, role_role_privs rrp
where rp.grantee='&vUser'
and rp.granted_role=rrp.granted_role
order by 1,2,3,4;

select grantee, privilege
from dba_sys_privs
where grantee='&vUser'
--or grantee in (select granted_role from dba_role_privs where grantee='&vUser')
order by 1,2;

select grantee, owner, table_name, privilege
from dba_tab_privs
where grantee='&vUser'
--or grantee in (select granted_role from dba_role_privs where grantee='&vUser')
order by 1,2,3;

undefine vUser
