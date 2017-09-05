#!/bin/sh

### $1-作业序列名称，例如js_46.def
### $2-批次号
### $3-作业序列起始位置
### $4-ETL任务类型

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

if [ -z "$1" ]
then
    printf "未指定要执行的JOB序列名称.\n" >>$ETLHOME/etllog/run.err
    exit 1
fi
if [ -z "$2" ] 
then
   printf "未指定执行批次号.\n" >>$ETLHOME/etllog/run.err
   exit 1
fi
if [ -z "$3" ] 
then
   printf "未指定执行序列起始JOB位置.\n" >>$ETLHOME/etllog/run.err
   exit 1
fi

if [ -z "$4" ] 
then
   printf "未指定ETL任务类型.\n" >>$ETLHOME/etllog/run.err
   exit 1
fi

# 获取当前系统日期
lsdate=`date +%Y%m%d_%H%M%S`

## 以后台异步方式提交主调度程序
joblstname=$1
batchno=$2
jobid=$3
ddflag=$4

# 批次日志目录不存在则创建批次目录
if [ ! -d $ETLHOME/etllog/$batchno ]
   then
      mkdir $ETLHOME/etllog/$batchno/
      if [ ! $? -eq 0 ]
      then
         echo "\n创建目录$ETLHOME/etllog/$batchno失败，JOB序列$joblstname启动失败." >>$ETLHOME/etllog/run.err
         exit 4
      fi
   fi   

eval nohup $ETLHOME/shell/run_job.sh $joblstname $batchno $jobid ${ddflag} >> $ETLHOME/etllog/$batchno/joblst.run &

# 获取本次提交程序的进程号
if [ $? -eq 0 ]; then
   progid=$!
   #记录本次提交程序的进程号
   echo "$joblstname,$progid" >>$ETLHOME/etllog/$batchno/joblst.pid 
   exit 0
else
   echo "\n调起JOB序列$joblstname失败." >>$ETLHOME/etllog/run.err
   exit 2
fi

  
