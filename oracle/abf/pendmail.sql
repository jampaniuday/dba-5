sELECT count(*) "Email's Pendentes"
    FROM APPLSYS.AQ$WF_NOTIFICATION_OUT WNO
    WHERE
          WNO.MSG_STATE = 'READY' -- prontos para enviar
       AND WNO.ENQ_TIME > TRUNC(SYSDATE-1)
         AND WNO.CORR_ID != 'APPS:ALR%'
    ORDER BY ENQ_TIME DESC
/
