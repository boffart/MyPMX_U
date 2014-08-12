#!/bin/sh
# cat > /persistent/var/lib/asterisk/agi-bin/1C_get_recording_file.sh ; cat >> /persistent/var/lib/asterisk/agi-bin/1C_get_recording_file.sh
# Consume all variables sent by Asterisk
while read VAR && [ "$VAR" != '' ] ; do : ; done

echo 'GET VARIABLE "v1"'; read chan;
chan=`echo "$chan" | awk -F'[(]|[)]' ' { print $2} '`;

echo 'GET VARIABLE "v3"'; read recordingfile;
recordingfile=`echo "$recordingfile" | awk -F'[(]|[)]' ' { print $2} '`;
monitor_path="/media/ysDisk_1/autorecords/$recordingfile.wav";

if [ -f "$monitor_path" ]; then
	echo "EXEC UserEvent StartDownloadRecord|\"Channel:$chan\"|\"FileName:$recordingfile\"";
	read RESPONSE;
	exit 0;
else

	echo 'GET VARIABLE "v2"'; read uniqueid1c;
	uniqueid1c=`echo "$uniqueid1c" | awk -F'[(]|[)]' ' { print $2} '`;
	
	echo 'GET VARIABLE "user"'; read user;
	user=`echo "$user" | awk -F'[(]|[)]' ' { print $2} '`;
	
	echo 'GET VARIABLE "password"'; read password;
	pass=`echo "$password" | awk -F'[(]|[)]' ' { print $2} '`;
	
	#/*
	# "SELECT path 
	#  FROM   records 
	#  WHERE  DATE_FORMAT(datetime,\"%Y%m%d%H%i\")=\""$1"\" 
	#         AND src=\""$2"\" 
	#         AND dst=\""$3"\"  "	
	#*/
	
	zapros=`echo "$uniqueid1c" | awk -F'_' ' { print "SELECT path FROM records WHERE DATE_FORMAT(datetime,\"%Y%m%d%H%i\")=\""$1"\" AND src=\""$2"\" AND dst=\""$3"\"  " } '`;
	
	recordingfile=`mysql -sse "$zapros" -u"$user" -p"$pass" autorecord`;
	monitor_path="/media/ysDisk_1/autorecords/$recordingfile";
fi

if [ -f "$monitor_path" ]; then
	echo "EXEC UserEvent StartDownloadRecord|\"Channel:$chan\"|\"FileName:$recordingfile\"";
	read RESPONSE;
	exit 0;
else
	echo "EXEC UserEvent FailDownloadRecord|\"Channel:$chan\"|\"uniqueid1c:$uniqueid1c\"|\"recordingfile:$monitor_path\"";
	read RESPONSE;
	exit 0;
fi
