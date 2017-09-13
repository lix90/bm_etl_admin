#!/bin/sh

### ----------------------------------------------------------------------
### 执行dsjob：
###
### > 获取写日志锁：getlock
### > 释放写日志锁：releaselock
### > 重置作业状态：checkjobstatus1
### > 重置作业
### > 执行作业
### ----------------------------------------------------------------------
exec_dsjob(){

    runstatus=0
    starttime=`date +%Y%m%d_%H%M%S`

    # 获取写日志锁
    getlock

    print "$batchno:${curjob}:$jobunit:$starttime:$starttime:等待运行:$jobid" \
          >>$ETLHOME/etllog/$batchno/run.log

    # 释放写日志锁
    releaselock

    # Reset JOB
    # 检查作业状态
    checkjobstatus1

    if [  $jobstatus -eq 3 -o  $jobstatus -eq 97 ]; then
        logfilename=${logfile}_reset
        # 通过dsjob重置作业
        eval ${binfiledirectory}/dsjob \
             -server ${DSSERVER} \
             -user ${DSUSER} \
             -password ${DSPASSWORD} \
             -run -mode RESET \
             -wait ${paramlist} ${DSPROJECT} ${jobunit} \
             2>&1 > ${logfilename}
        endtime=`date +%Y%m%d_%H%M%S`
        # 写日志
        if [ ! $? -eq 0 ]; then
            # 获取写日志锁
            getlock
            print "$batchno:${curjob}:$jobunit:$starttime:$endtime:RESET Failure:$jobid" \
                  >>$ETLHOME/etllog/$batchno/run.log
            # 释放写日志锁
            releaselock
            runstatus=$jobid
        else
            # 获取写日志锁
            getlock
            print "$batchno:${curjob}:$jobunit:$starttime:$endtime:RESET Successful:$jobid" \
                  >>$ETLHOME/etllog/$batchno/run.log
            # 释放写日志锁
            releaselock
        fi
    fi

    # 执行JOB
    jobendtime=`date +%Y%m%d_%H%M%S`

    # 获取写日志锁
    getlock
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid" \
          >>$ETLHOME/etllog/$batchno/run.log

    # 释放写日志锁
    releaselock
    logfilename=${logfile}_runstatus

    # 获取写日志锁
    getlock
    print "$batchno:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid" \
          >>$ETLHOME/etllog/$batchno/run.log

    # 释放写日志锁
    releaselock

    # 执行作业
    eval ${binfiledirectory}/dsjob \
         -server ${DSSERVER} \
         -user ${DSUSER} \
         -password ${DSPASSWORD} \
         -run -wait ${paramlist} ${DSPROJECT} ${jobunit} \
         2>&1 > ${logfilename}

    # 检查作业状态
    checkjobstatus2 ${logfilename}
    endtime=`date +%Y%m%d_%H%M%S`

    # 写日志
    if [ ! $jobstatus -eq 0 ]; then
        # 获取写日志锁
        getlock
        print "$batchno:${curjob}:$jobunit:$starttime:$endtime:失败:$jobid" \
              >>$ETLHOME/etllog/$batchno/run.log
        # 释放写日志锁
        releaselock
        runstatus=$jobid
    else
        # 获取写日志锁
        getlock
        print "$batchno:${curjob}:$jobunit:$starttime:$endtime:成功:$jobid" \
              >>$ETLHOME/etllog/$batchno/run.log
        # 释放写日志锁
        releaselock
    fi
}
