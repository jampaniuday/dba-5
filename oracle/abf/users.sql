select 
     a.user_name "LOGIN" , 
     b.first_name ||' ' || b.last_name "NOME" , 
     b.national_identifier "CPF", 
     a.email_address "EMAIL" ,
     a.last_logon_date "ÚTIMO ACESSO" ,
     a.end_date "DATA INATIVAÇO" ,
    case 
     when a.end_date is null or trunc(a.end_date) >= SYSDATE then 'ATIVO' 
     when trunc(a.end_date) < SYSDATE then 'INATIVO' 
    end STATUS 
from fnd_user a, 
     per_all_people_f b
where 
    a.person_party_id = b.party_id
and a.email_address like '%@abril%'
and b.national_identifier is not null
order by a.user_name;
/
