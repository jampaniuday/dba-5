select owner, object_name, object_type, status from dba_objects where lower(object_name) = lower('&obj') and owner = '&owner';
