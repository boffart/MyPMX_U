#!/bin/sh
# cat > /persistent/var/lib/asterisk/agi-bin/1C_get_cdr_mysql.sh ; cat >> /persistent/var/lib/asterisk/agi-bin/1C_get_cdr_mysql.sh
################################################################################################################################
# Consume all variables sent by Asterisk
while read VAR && [ "$VAR" != '' ] ; do : ; done
#################################################
filename=`mktemp`;

echo 'GET VARIABLE "v1"'; read chan;
chan=`echo "$chan" | awk -F'[(]|[)]' ' { print $2} '`;
#
echo 'GET VARIABLE "v2"'; read dateStart;
dateStart=`echo "$dateStart" | awk -F'[(]|[)]' ' { print $2} '`;
#
echo 'GET VARIABLE "v3"'; read dateEnd;
dateEnd=`echo "$dateEnd" | awk -F'[(]|[)]' ' { print $2} '`;

echo 'GET VARIABLE "v4"'; read numbers;
numbers=`echo "$numbers" | awk -F'[(]|[)]' ' { print $2} '`;

echo 'GET VARIABLE "user"'; read user;
user=`echo "$user" | awk -F'[(]|[)]' ' { print $2} '`;

echo 'GET VARIABLE "password"'; read password;
password=`echo "$password" | awk -F'[(]|[)]' ' { print $2} '`;
################################################################################################################################

zapros=''; usl='';

i=1
while [ $i -lt 10 ]; do
	NumFilter=`echo "$numbers" | awk ' {print $'"$i"'}' 'NR==1' FS='-'`;
	if [ -z "$NumFilter" ]; then
		break;
	fi
	
	[ -n "$usl" ] && usl="$usl OR" || usl="WHERE ";
	usl="$usl (T_CDR.src = '${NumFilter}' OR T_CDR.dst = '${NumFilter}' OR T_CDR.dst LIKE '%)$NumFilter%' OR T_CDR.src LIKE '%($NumFilter%' OR T_CDR.src LIKE '%$NumFilter(%' OR T_CDR.dst LIKE '%$NumFilter%)')";

	i=`expr $i + 1`;
done

name_cdr_table=`mysql -sse "SHOW DATABASES LIKE 'asteriskcdr'" -u"$user" -p"$password" asteriskcdr`;
name_record_table=`mysql -sse "SHOW DATABASES LIKE 'autorecord'" -u"$user" -p"$password" autorecord`;
tables=`echo "$name_cdr_table$name_record_table"`;

if [ -z "$tables" ]; then
   exit 0;
fi;

if [ "$name_record_table" == 'autorecord' ]; then
	# ANSWERED
	zapros="
	SELECT
	    DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i%S'),
	    T_CDR.src,
	    T_CDR.dst,
	    REVERSE(concat('SIP/',T_CDR.dst,'IAX/',T_CDR.dst,'DAHDI/',T_CDR.dst,DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i'))) AS channel,
	    concat('SIP/',T_CDR.dst,'IAX/',T_CDR.dst,'DAHDI/',T_CDR.dst,T_CDR.datetime) AS dstchannel,
	    T_CDR.duration,
	    'ANSWERED',
	    concat(DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i'),'_',T_CDR.src,'_',T_CDR.dst,'.',T_CDR.dst) AS uniqueid,
		T_CDR.path
	FROM (SELECT *
	      FROM records
	      WHERE
	          datetime BETWEEN '$dateStart' AND '$dateEnd'
	      LIMIT 100)
	AS T_CDR $usl";
	
	mysql -sse "$zapros" -u"$user" -p"$password" autorecord > "$filename";
#mysql -sse "$zapros" -u"$user" -p"$password" autorecord > "/tmp/222.txt";

	zapros="
	SELECT
	    DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i%S'),
	    T_CDR.src,
	    T_CDR.dst,
	    REVERSE(concat('SIP/',T_CDR.src,'IAX/',T_CDR.src,'DAHDI/',T_CDR.src,DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i'))) AS channel,
	    concat('SIP/',T_CDR.dst,'IAX/',T_CDR.dst,'DAHDI/',T_CDR.dst,T_CDR.datetime) AS dstchannel,
	    '0',
	    'NO_ANSWER',
	    concat(DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i'),'_',T_CDR.src,'_',T_CDR.dst,'_NA','.',T_CDR.dst) AS uniqueid,
        ''
	FROM (SELECT *
	      FROM cdr
	      WHERE
	        (datetime BETWEEN '$dateStart' AND '$dateEnd') AND (disposition = 'NO ANSWER' OR disposition = 'BUSY') )
	AS T_CDR $usl";

    mysql -sse "$zapros" -u"$user" -p"$password" asteriskcdr >> "$filename";
    #mysql -sse "$zapros" -u"$user" -p"$password" asteriskcdr >> "/tmp/222.txt";

elif [ "$name_cdr_table" == 'asteriskcdr' ]; then
	zapros="
	SELECT
	    DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i%S'),
	    T_CDR.src,
	    T_CDR.dst,
	    REVERSE(concat('SIP/',T_CDR.dst,'IAX/',T_CDR.dst,'DAHDI/',T_CDR.dst,T_CDR.datetime)) AS channel,
	    concat('SIP/',T_CDR.dst,'IAX/',T_CDR.dst,'DAHDI/',T_CDR.dst,DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i')) AS dstchannel,
	    T_CDR.duration,
	    T_CDR.disposition,
	    concat(DATE_FORMAT(T_CDR.datetime,'%Y%m%d%H%i'),'_',T_CDR.src,'_',T_CDR.dst,'.',T_CDR.dst) AS uniqueid,
	FROM (SELECT *
	      FROM cdr
	      WHERE
	        (datetime BETWEEN '$dateStart' AND '$dateEnd') LIMIT 100)
	AS T_CDR $usl";
	
	mysql -sse "$zapros" -u"$user" -p"$password" asteriskcdr > "$filename";
fi;

################################################################################################################################
kol=`cat "$filename" | wc -l`;
ch=0; kolpack=3;
i=0;result="";
while [ $i -le $kol ]; do
    result=`cat "$filename" | head -n "$i"| tail -n "$kolpack" | sed 's/|/'@.@'/g'| sed 's/[\t]/'@.@'/g'|sed 's/$/...../g'|tr "\n" " "`;
    echo "EXEC UserEvent FromCDR|\"Channel:$chan\"|\"Date:$dateStart\"|\"Lines:$result\"";
    i=`expr $i + $kolpack`;
done
result=`cat "$filename" | head -n "$i"| tail -n "$kolpack" | sed 's/|/'@.@'/g'| sed 's/[\t]/'@.@'/g'|sed 's/$/...../g'|tr "\n" " "`;
echo "EXEC UserEvent FromCDR|\"Channel:$chan\"|\"Date:$dateStart\"|\"Lines:$result\"";

echo "EXEC UserEvent Refresh1CHistory|\"Channel:$chan\"|\"Date:$dateStart\"";
read RESPONSE;

################################################################################################################################

exit 0;