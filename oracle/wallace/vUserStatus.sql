/* VERIFICA OS USUARIOS QUE ESTÃO EM LOCK OU EXPIRED NO BANCO */
SET LINE 999
COL USERNAME FOR A20
COL ACCOUNT_STATUS FOR A20
SELECT USERNAME, ACCOUNT_STATUS FROM DBA_USERS
WHERE USERNAME like UPPER('%&USER%');
