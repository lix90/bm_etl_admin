#!/bin/sh

CURJOB=$1
JOBUNIT=$2
BATCHNO=$3
PROCID=$4
LCKTIMEOUT=$5

LOGPATH=$TASKPATH/log

locktime=0
while :
do
    mv $LOGPATH/lock.lck \
       $LOGPATH/lock.lck${PROCID} \
       2>/dev/null

    if [ ! $? -eq 0 ]; then
        sleep 1
        locktime=`expr $locktime + 1`
        if [[ $locktime -gt $LCKTIMEOUT ]]; then
            lsdate22=`date +%Y%m%d_%H%M%S`
            echo "$lsdate22:作业序列${CURJOB}－作业$JOBUNIT申请写日志锁超时，调度程序出现严重错误."\
                 >>$LOGPATH/$BATCHNO/joblst.run
            exit 4000
        fi
    else
        break
    fi
done
