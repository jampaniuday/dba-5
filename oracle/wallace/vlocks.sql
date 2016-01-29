select sid, status, username, osuser, program, blocking_session blocking, event from v$session
 where blocking_session is not null;