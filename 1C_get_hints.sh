#!/bin/sh
# cat > /var/lib/asterisk/agi-bin/1C_get_hints.sh; cat >> /var/lib/asterisk/agi-bin/1C_get_hints.sh
# /var/lib/asterisk/agi-bin/1C_get_hints.sh
# Consume all variables sent by Asterisk
while read VAR && [ "$VAR" != '' ] ; do : ; done

# get var chan
echo 'GET VARIABLE "v1"'; 
read RESPONSE;
# parse respose
chan=`echo "$RESPONSE" | awk -F'[(]|[)]' ' { print $2} '`;

monitor_pwd=`mysql -sse "select PASSWORD from pwdsettings where name='monitor';" -u1cuser -p1csecret MyPBX`;
echo "EXEC UserEvent AsteriskSettings|\"DialplanVer:1.0.0.6\"|\"FaxSendUrl:NO\"|\"autoanswernumber:*04\"|\"statistic:monitor:$monitor_pwd\"|\"Channel:$chan\"";
read RESPONSE;

tmp_file=`date +%s`;
tmp_file=`echo "/tmp/$tmp_file"`;
asterisk -rx"core show hints" | awk -F'[ ]*[:]?[ ]+' ' {print $2 "@.@" $3 "@.@" $4 } ' > "$tmp_file";
kol=`cat "$tmp_file" | wc -l`;

echo "EXEC UserEvent HintsStart|\"channel:$chan\"";
read RESPONSE;

ch=0; kolpack=10;
i=0;result="";
while [ $i -le $kol ]; do        
	i=`expr $i + 1`;
    ch=`expr $ch + 1`;
        
	# get row from file 
	tmpstr=`cat "$tmp_file" | head -n "${i}"| tail -n 1`;
        
	if [ $ch = $kolpack ]; then
		echo "EXEC UserEvent RowsHint|\"Channel:$chan\"|\"Lines:$result\"";
		result=''; ch=0;
	else
		result=`echo "$result.....$tmpstr"`;
	fi
done

if [ "$result" != '' ]; then
	echo "EXEC UserEvent RowsHint|\"Channel:$chan\"|\"Lines: $result\"";
	result=''; ch=0;
fi

echo "EXEC UserEvent HintsEnd|\"Channel:$chan\"";
read RESPONSE;