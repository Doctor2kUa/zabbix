#!/bin/bash

ZHOST="my-rabbit"
ZSERVER="zabbix_yourhost"
ZPORT="10051"

#cat /etc/zabbix/scripts/q.list
echo > /etc/zabbix/scripts/q.list
truncate -s 0 /etc/zabbix/scripts/zsender.log
#truncate -s 0 /etc/zabbix/scripts/zamqp_vhosts.list
truncate -s 0 /etc/zabbix/scripts/zamqp_queues.list
truncate -s 0 /etc/zabbix/scripts/zamqp_data.list
cat /dev/null > /etc/zabbix/scripts/zamqp_data.list

#/opt/rabbitmq/sbin/rabbitmqctl list_vhosts | grep -v "Listing vhosts " | grep -v "done." >> /etc/zabbix/scripts/zamqp_vhosts.list

#for VHOST in `cat /etc/zabbix/scripts/zamqp_vhosts.list`;
#do
/opt/rabbitmq/sbin/rabbitmqctl list_queues --quiet --no-table-headers | awk '{print $1 ":" $2}' >> /etc/zabbix/scripts/zamqp_queues.list
#done

JSONSTREAM="{ \"data\":[ "

for QUEUE in `cat /etc/zabbix/scripts/zamqp_queues.list`;
do
IFS=':' read -a MQARG <<< "$QUEUE"
JSONSTREAM="$JSONSTREAM{ \"{#QUEUENAME}\":\"${MQARG[0]}\" }, "
echo $ZHOST amqp.queue.count[${MQARG[0]}] ${MQARG[1]} >> /etc/zabbix/scripts/zamqp_data.list
done

JSONSTREAM="$JSONSTREAM{ \"{#QUEUENAME}\":\"ALLQUEUES\" } ]}"
#JSONSTREAM="$JSONSTREAM ]}"

cat << EOF
EOF

#printf '%s\n'  $JSONSTREAM
#printf '%s'  $JSONSTREAM
#zabbix_sender -vv -z $ZSERVER  -i /etc/zabbix/scripts/zamqp_data.list >> /etc/zabbix/scripts/zsender.log 2>&1
#zabbix_sender -vv -z $ZSERVER  -i /etc/zabbix/scripts/zamqp_data.list


#echo "- hw.serial.number 1287872261 SQ4321ASDF" | zabbix_sender -c /usr/local/etc/zabbix_agentd.conf -T -i -




zabbix_sender -z $ZSERVER -s $ZHOST -k amqp.discovery -o "$(echo -e $JSONSTREAM)"


JSONSTREAM="{ \"request\":\"sender data\", \"data\":[ "
comacount=`cat /etc/zabbix/scripts/zamqp_queues.list|wc -l`

echo $comacount
COMA=","
linecount=1


echo "===start inline read==="
rm /etc/zabbix/scripts/data1.json
cat /etc/zabbix/scripts/zamqp_queues.list|while read qline
do

if [[ $comacount -eq $linecount ]]
then
COMA=""
#echo "COMA"
fi


queue=`echo $qline|awk -F ":" '{print $1}'`
cnt=`echo $qline|awk -F ":" '{print $2}'`
#JSONSTREAM="$JSONSTREAM{ \"host\":\"${ZHOST}\", \"key\":\"key.[${queue}]\", \"value\":\"${cnt}\" }${COMA} "
JSONSTREAM="$JSONSTREAM{ \"key\":\"key.[${queue}]\", \"value\":\"${cnt}\" }${COMA} "
#echo $queue $cnt
echo $JSONSTREAM > tmp.json

#echo $linecount

echo $ZHOST key.[${queue}] ${cnt} >> /etc/zabbix/scripts/data1.json

let linecount=linecount+1
done


cat tmp.json
JSONSTREAM=`cat tmp.json`
JSONSTREAM="$JSONSTREAM  ]}"

#JSONSTREAM="$JSONSTREAM{ \"{#QUEUENAME}\":\"ALLQUEUES\" } ]}"
echo $JSONSTREAM > /etc/zabbix/scripts/data.json

#zabbix_sender -z $ZSERVER -s $ZHOST -k amqp.discovery1 -o "$(echo -e $JSONSTREAM)"
zabbix_sender -vv -z $ZSERVER -i /etc/zabbix/scripts/data1.json

