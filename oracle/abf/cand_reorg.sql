select seg.owner
      ,seg.segment_name
      ,seg.tablespace_name
      ,tab.num_rows
      ,tab.avg_row_len
      ,tab.blocks
      ,round((avg_row_len*num_rows)/1024/1024,2) "Tamanho Calculado MB"
      ,round( seg.bytes/1024/1024,2) "Tamanho ocupado"
      ,round((seg.bytes/1024/1024) - ((avg_row_len*num_rows)/1024/1024),2) "Diferenca"
      ,round(tab.num_rows/ tab.blocks,2) "Linhas por Bloco"
      ,tab.chain_cnt
      ,tab.last_analyzed
      ,round((seg.bytes/1024/1024) / ((avg_row_len*num_rows)/1024/1024),2) "Vezes Maior"
      ,round(tab.blocks*8096/1024/1024,2) "Size Blk (8k)/MB"
      ,round((seg.bytes/1024/1024)-(tab.blocks*8096/1024/1024),2) "Tamanho Ocupado | Size Blk"
from dba_tables tab
    ,dba_segments seg
where seg.segment_type='TABLE'
and seg.owner= tab.owner
and seg.segment_name= tab.table_name
and tab.table_name in (select segment_name
                        from (select bytes/1024/1024 byte, segment_name
                                from dba_segments
                                where segment_type='TABLE'
                                and owner  not in ('SYS','SYSTEM')
                                order by 1 desc) 
                        where rownum <=40
                        and byte >=20)
order by "Diferenca" desc
        ,tab.last_analyzed desc
        ,"Tamanho ocupado" desc;
