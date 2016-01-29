select OWNER,NAME, to_char(LAST_REFRESH,'dd-mon-yy:hh24:mi:ss') from dba_snapshot_refresh_times
	where NAME like 'CONSOLIDADO_%';
