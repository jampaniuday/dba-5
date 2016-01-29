select owner, segment_name, bytes/1024/1024 from dba_segments where segment_name = '&seg'
/
