#!/bin/sh
# sh /persistent/var/lib/asterisk/agi-bin/1C_get_fax_history.sh /tmp/tmp_fax_123.txt 2013-01-01 2013-09-01 asteriskcdr ast_mysql_user ast_mysql_password

# System(mysql -sse 'SELECT a.datetime,a.src,a.dst,a.lastdata,a.lastdata,a.lastapp from (SELECT * from cdr where calldate BETWEEN ${QUOTE(${date1})} AND ${QUOTE(${date2})}) AS a WHERE  a.lastapp="SendFAX" OR a.lastapp="ReceiveFAX"' -u${user} -p${password} ${dbname}>${tmp_dir}/${UNIQUEID})

zapros=''; usl='';

filename=$1;
dateStart=$2;
dateEnd=$3;
dbname=$4
user=$5;
password=$6;

# ANSWERED
zapros="
SELECT
    DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i%S'),
    T_CDR.src,
    T_CDR.dst,
    T_CDR.lastdata,
    RIGHT(T_CDR.lastdata,32),
    T_CDR.lastapp
FROM (SELECT *
      FROM cdr
      WHERE
          datetime BETWEEN '$dateStart' AND '$dateEnd'
      LIMIT 100)
AS T_CDR
WHERE  T_CDR.lastapp='SendFAX' OR T_CDR.lastapp='ReceiveFAX'";

mysql -sse "$zapros" -u"$user" -p"$password" "$dbname" > "$filename";