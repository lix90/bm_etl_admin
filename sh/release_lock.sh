#!/bin/sh

CURJOB=$1
jobunit=$2
BATCHNO=$3
PROCID=$4

LOGPATH=$TASKPATH/log

mv $LOGPATH/lock.lck${PROCID} \
   $LOGPATH/lock.lck \
   2>/dev/null

if [ ! $? -eq 0 ]; then
    lsdate22=`date +%Y%m%d_%H%M%S`
    echo "$lsdate22:作业序列${CURJOB}－作业$jobunit释放写日志锁超时，调度程序出现严重错误."\
         >>$LOGPATH/$BATCHNO/joblst.run
    exit 4001
else
    break
fi
