#!/bin/sh

runstatus=0
starttime=`date +%Y%m%d_%H%M%S`

if [ -f $shellfile -a -x $shellfile ]; then

    jobendtime=`date +%Y%m%d_%H%M%S`

    # 获取写日志锁
    ./getlock.sh
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid" \
          >>$etllogpath/$batchno/run.log
    print "$batchno:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid" \
          >>$etllogpath/$batchno/run.log

    # 释放写日志锁
    ./release_lock.sh
    if [ -z "${paramlist}" ]; then
        $shellfile
    else
        $shellfile ${paramlist}
    fi

    jobstatus=$?
    endtime=`date +%Y%m%d_%H%M%S`
    if [ $jobstatus -eq 0 ]; then
        # 获取写日志锁
        getlock
        print "$batchno:${curjob}:$jobunit:$starttime:$endtime:成功:$jobid" \
              >>$ETLHOME/etllog/$batchno/run.log
        # 释放写日志锁
        releaselock
    else
        # 获取写日志锁
        getlock
        print "$batchno:${curjob}:$jobunit:$starttime:$endtime:失败:$jobid" \
              >>$ETLHOME/etllog/$batchno/run.log
        # 释放写日志锁
        releaselock
        runstatus=$jobid
    fi
else
    jobstatus=999
    endtime=`date +%Y%m%d_%H%M%S`
    # 获取写日志锁
    getlock
    print "$batchno:${curjob}:$jobunit:$starttime:$endtime:文件不存在或不可执行:$jobid" \
          >>$ETLHOME/etllog/$batchno/run.log
    # 释放写日志锁
    releaselock
    runstatus=$jobid
fi
