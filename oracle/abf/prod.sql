select substr(APPLICATION_NAME,1,45)NAME,
       substr(PATCH_LEVEL,1,15)PATCH_LEVEL,
       STATUS,
       Source_lang
   from fnd_application_tl a,
        FND_PRODUCT_INSTALLATIONS b
   where a.APPLICATION_ID =  b.APPLICATION_ID
   and PATCH_LEVEL like upper('%&1%')
   order by 2
/
