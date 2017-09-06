#!/bin/sh

mv $etllogpath/loglock.lck${procid} \
   $etllogpath/loglock.lck \
   2>/dev/null

if [ ! $? -eq 0 ]; then
    lsdate22=`date +%Y%m%d_%H%M%S`
    echo "$lsdate22:作业序列${curjob}－作业$jobunit释放写日志锁超时，调度程序出现严重错误."\
         >>$etllogpath/$batchno/joblst.run
    exit 4001
else
    break
fi
