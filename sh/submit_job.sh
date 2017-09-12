#!/bin/sh

### $1-作业序列名称，例如js_46.def
### $2-作业序号
### $3-批次号

### --------------------------------------------------
### 参数检查
### --------------------------------------------------
LOGPATH=$TASKPATH/log

if [ -z "$1" ]; then
    echo "未指定要执行的JOB序列名称." \
         >>$LOGPATH/run.err
    exit 1
fi
if [ -z "$2" ]; then
    echo "未指定执行批次号." \
         >>$LOGPATH/run.err
    exit 1
fi
if [ -z "$3" ]; then
    echo "未指定执行序列起始JOB位置." \
         >>$LOGPATH/run.err
    exit 1
fi

# 获取当前系统日期
lsdate=`date +%Y%m%d_%H%M%S`

# 以后台异步方式提交作业
jobname=$1
jobid=$2
batchno=$3

## 后台运行作业
eval nohup $ETLHOME/sh/run_job.sh \
     $jobname $jobid $batchno \
     >> $LOGPATH/$batchno/joblst.run &
# $ETLHOME/sh/run_job.sh \
    #     $jobname $batchno $jobid \
    #     >> $LOGPATH/$batchno/joblst.run

# 获取本次提交程序的进程号, 用于后续杀进程
if [ $? -eq 0 ]; then
    progid=$!
    # 记录本次提交程序的进程号
    echo "$jobname,$progid" \
         >>$LOGPATH/$batchno/joblst.pid
    exit 0
else
    echo "调起JOB序列$jobname失败." \
         >>$LOGPATH/err.log
    exit 2
fi
