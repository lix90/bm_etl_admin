#!/bin/sh

curjob=$1
jobunit=$2
batchno=$3

locktime=0
while :
do
    mv $LOGPATH/loglock.lck \
       $LOGPATH/loglock.lck${procid} \
       2>/dev/null

    if [ ! $? -eq 0 ]; then
        sleep 1
        locktime=`expr $locktime + 1`
        if [ $locktime = $locktimeout ]; then
            lsdate22=`date +%Y%m%d_%H%M%S`
            echo "$lsdate22:作业序列${curjob}－作业$jobunit申请写日志锁超时，调度程序出现严重错误."\
                 >>$LOGPATH/$batchno/joblst.run
            exit 4000
        fi
    else
        break
    fi
done
