#!/bin/sh

### ----------------------------------------------------------------------
### 参数：
###
### $1-作业序列文件名
### $2-作业序号
### $3-批次号
### $4-最大重试次数,可选项，如不选默认值为5次
### $5-重试休眠时间，单位：秒，可选项，如不选默认值为10秒
###
### updated @2017-09-05 14:16:40 by lixiang <alexiangli@outlook.com>
### ----------------------------------------------------------------------

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

### 环境变量
LOGPATH=$TASKPATH/log
JOBPATH=$TASKPATH/job
SQLPATH=$TASKPATH/sql

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "用户未指定参数1,2,3"
    exit 1
fi

### 参数
# 最大重试次数
MAXRETRY=${4:-5}
# 重试休眠时间
INTERVAL=${5:-10}
# 锁定时常
LCKTIMEOUT=300

# datectlfile是神马文件
# datectlfile=$ETLHOME/config/etl_datectl_param
# jobschfile=$ETLHOME/config/etl_job

# 时间
NOW=`date +%Y%m%d_%H%M%S`
JOBSTARTTIME=$NOW

# 检查相关文件是否存在
JOBNAME=$1
JOBID=$2
BATCHNO=$3

# 当前作业清单文件
JOBFILE=$JOBPATH/$JOBNAME
# 当前作业文件名
CURJOB=$JOBNAME
# 进程号
PROCID=$$

if [ ! -f $JOBFILE ]; then
    echo "文件$JOBFILE不存在，作业${CURJOB}启动失败." \
         >>$LOGPATH/err.log
    exit 2
fi

# if [ ! -f $jobrelation ]; then
#     print "\n文件$jobrelation不存在，作业${CURJOB}启动失败." \
    #           >>$LOGPATH/err.log
#     exit 2
# fi

# 创建作业序列执行日志存放目录
if [ ! -d $LOGPATH/$BATCHNO/${CURJOB}_$NOW ]; then
    mkdir -p $LOGPATH/$BATCHNO/${CURJOB}_$NOW
    if [ ! $? -eq 0 ]; then
        echo "创建目录$LOGPATH/$BATCHNO/${CURJOB}_$NOW失败，作业${CURJOB}启动失败." \
             >>$LOGPATH/err.log
        exit 4
    else
        echo "$LOGPATH/$BATCHNO/${CURJOB}_$NOW" \
             >> $LOGPATH/$BATCHNO/runlog.lst
    fi
fi

##----------------------------------------------------------------------
## 作业循环开始
## 从作业序号开始进行迭代，有5次尝试机会
##----------------------------------------------------------------------
runstatus=0
while :
do
    ##------------------------------------------------------------
    ## 读取作业
    ## 作业序列命名规则
    ## <JOBID>:<SQL>:<PARAMETERS>
    ## 1:script.sql:
    ##------------------------------------------------------------ 
    jobunit=`awk -F : -v JOBID=$JOBID '$1==JOBID {print $2}' $JOBFILE`
    sqlfile=$SQLPATH/$jobunit 
    paramlist=`awk -F : -v JOBID=$JOBID '$1==JOBID {print $3}' $JOBFILE` 
    if [ -z "$jobunit" ]; then
        break
    fi

    # 尝试次数计数器
    trycnt=1
    # 尝试执行作业循环开始，如果成功或者失败超过次数则跳出循环
    while :
    do 
        # 初始化作业状态
        runstatus=0
        # 作业开始时间
        starttime=`date +%Y%m%d_%H%M%S` 
        if [ -f $sqlfile ]; then 
            jobendtime=`date +%Y%m%d_%H%M%S`

            # 运行中日志 
            $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO $PROCID $LCKTIMEOUT 
            echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:运行中:$JOBID"\
                 >>$LOGPATH/$BATCHNO/run.log 
            echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$starttime:运行中:$JOBID"\
                 >>$LOGPATH/$BATCHNO/run.log 
            $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID

            ##------------------------------------------------------------
            ## 正式调用sql存储过程
            ##------------------------------------------------------------
            if [ -z "${paramlist}" ]; then
                # ./exec_orcl_proc.sh $sqlfile
                $ETLHOME/sh/test.sh $sqlfile
            else
                # ./exec_orcl_proc.sh $sqlfile ${paramlist}
                $ETLHOME/sh/test.sh $sqlfile ${paramlist}
            fi

            # 执行完后日志
            jobstatus=$?
            endtime=`date +%Y%m%d_%H%M%S`
            if [ $jobstatus -eq 0 ]; then 
                $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO $PROCID $LCKTIMEOUT
                echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:成功:$JOBID"\
                     >>$LOGPATH/$BATCHNO/run.log 
                $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID
            else 
                $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO $PROCID $LCKTIMEOUT 
                echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:失败:$JOBID"\
                     >>$LOGPATH/$BATCHNO/run.log 
                $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID
                runstatus=$JOBID
            fi
        else
            # 文件不存在日志
            jobstatus=999
            endtime=`date +%Y%m%d_%H%M%S` 
            $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO $PROCID $LCKTIMEOUT
            echo "$BATCHNO:${CURJOB}:$jobunit:$endtime:$endtime:文件不存在:$JOBID"\
                 >>$LOGPATH/$BATCHNO/run.log 
            $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID
            runstatus=$JOBID
        fi

        # 作业执行成功跳出作业
        if [ "$runstatus" = "0" ]; then
            break
            # 重试超过次数，同样跳出循环
        elif [ $trycnt -gt $MAXRETRY ]; then
            # 重试日志
            endtime=`date +%Y%m%d_%H%M%S`
            $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO $PROCID $LCKTIMEOUT
            echo "${BATCHNO}:${CURJOB}:$jobunit:$starttime:$endtime:重试次数超过${MAXRETRY}:$JOBID" \
                 >>$LOGPATH/$BATCHNO/run.log
            echo "${BATCHNO}:${CURJOB}:$jobunit:$starttime:$endtime:失败:$JOBID" \
                 >>$LOGPATH/$BATCHNO/run.log 
            $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID
            break
        else
            # 执行作业序号加一，执行下一作业
            trycnt=`expr $trycnt + 1`
            sleep $INTERVAL
        fi
    done

    ##----------------------------------------------------------------------
    ## 重启和中断操作
    ##----------------------------------------------------------------------
    # 如果状态未成功，那么写入重启标识
    # 之后，运行etl_restart.sh进行重启
    if [ ! "$runstatus" = "0"  ]; then
        echo "${CURJOB},$JOBID" \
             >$LOGPATH/restart.flag
        break
    else
        # 否则，进行下一步作业，即序号加1
        JOBID=`expr $JOBID + 1`

        # 如果用户强制中断
        # 中断标识在哪里写入的？
        # 中断标识由etl_halt.sh写入
        # 写入规则为：
        # <作业文件名>:<作业序号>

        if [ -f $LOGPATH/halt.flag ]; then
            ## 获取中断作业位置
            # 获取下一步作业文件名
            jobunit=`awk -F : -v JOBID=$JOBID '$1==JOBID {print $2}' $JOBFILE`
            # 如果作业名为空，位置则为1
            haltpos1=`awk -F : '{ if ($1 == "") {print 1}}' $LOGPATH/halt.flag`
            # 如果中断作业名为当前已运行作业，中断位置为中断标识文件第2列指定序号
            haltpos2=`awk -F : -v jobseq=$CURJOB ' { if ($1 == jobseq) {print $2}}' $LOGPATH/halt.flag`
            
            if [ ! -z "$haltpos1" -a ! -z "$haltpos2" -a $JOBID -gt $haltpos2 ]; then
                runstatus=$JOBID
                # 中断日志
                $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO $PROCID $LCKTIMEOUT
                echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:用户中断:$JOBID" \
                     >>$LOGPATH/$BATCHNO/run.log 
                $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID
                break
            fi
        fi
    fi
done

##----------------------------------------------------------------------
## 输出当前作业序列日志
##----------------------------------------------------------------------
jobendtime=`date +%Y%m%d_%H%M%S`
if [ $runstatus -eq 0 ]; then
    $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO
    echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:成功:0" \
         >>$LOGPATH/$BATCHNO/run.log 
    $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID
else 
    $ETLHOME/sh/get_lock.sh $CURJOB $jobunit $BATCHNO
    echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:失败:$JOBID" \
         >>$LOGPATH/$BATCHNO/run.log 
    $ETLHOME/sh/release_lock.sh $CURJOB $jobunit $BATCHNO $PROCID
fi

rm $TASKPATH/log/running.flag
