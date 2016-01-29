select distinct usr.user_name
  ,usr.description
  ,resp.responsibility_name
from FND_USER_RESP_GROUPS urep
  ,FND_RESPONSIBILITY_TL resp
  ,FND_USER usr
where urep.end_date      is null
and usr.end_date         is null
--and usr.user_id           >1094
--and usr.user_id not      in (1116,1238,1239,1240,1241,1242,1278,1960,2073, 1740,3612,3613,1,6,5,0,1030,1031,1007)
and urep.user_id          =usr.user_id
and urep.responsibility_id=resp.responsibility_id
and resp.responsibility_name='System Administrator'
order by 1
/
