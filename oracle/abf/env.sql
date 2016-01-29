define _editor=vi
clear columns
select distinct sid from v$mystat;
set serveroutput on size 1000000 lines 500 head on pages 50 feed on
