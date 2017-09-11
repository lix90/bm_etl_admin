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

### 参数检查
###=========

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "用户未指定参数1,2,3"
    exit 1
fi

JOBNAME=$1
JOBID=$2
BATCHNO=$3

LOGPATH=$TASKPATH/log
JOBPATH=$TASKPATH/job
JOBREFL=$TASKPATH/job/js.rel
SQLPATH=$TASKPATH/sql
MAXRETRY=${4:-5} # 最大重试次数
INTERVAL=${5:-10} # 重试休眠时间
LCKTIMEOUT=100 # 锁定时长
JOBFILE=$JOBPATH/$JOBNAME # 当前作业清单文件
CURJOB=$JOBNAME # 当前作业文件名
PROCID=$$ # 进程号

NOW=`date +%Y%m%d_%H%M%S`
JOBSTARTTIME=$NOW

if [ ! -f $JOBFILE ]; then
    echo "文件$JOBFILE不存在，作业${CURJOB}启动失败." \
         >>$LOGPATH/err.log
    exit 2
fi

# if [ ! -f $JOBRELF ]; then
#     print "\n文件$JOBRELF不存在，作业${CURJOB}启动失败." \
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
             >>$LOGPATH/$BATCHNO/runlog.lst
    fi
fi

get_lock(){

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
}

release_lock(){
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
}

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

            # if [ -f $LOGPATH/$BATCHNO/run.log ]; then
            # touch $LOGPATH/$BATCHNO/run.log
            # fi
            # 运行中日志
            # get_lock
            echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:运行中:$JOBID"\
                 >>$LOGPATH/$BATCHNO/run.log 
            echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$starttime:运行中:$JOBID"\
                 >>$LOGPATH/$BATCHNO/run.log 
            # release_lock

            ##------------------------------------------------------------
            ## 正式调用sql存储过程
            ##------------------------------------------------------------
            if [ -z "${paramlist}" ]; then
                $ETLHOME/sh/exec_orcl_proc.sh $sqlfile
                # $ETLHOME/sh/test.sh $sqlfile
            else
                $ETLHOME/sh/exec_orcl_proc.sh $sqlfile ${paramlist}
                # $ETLHOME/sh/test.sh $sqlfile ${paramlist}
            fi

            # 执行完后日志
            jobstatus=$?
            endtime=`date +%Y%m%d_%H%M%S`
            if [ $jobstatus -eq 0 ]; then 
                # get_lock
                echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:成功:$JOBID"\
                     >>$LOGPATH/$BATCHNO/run.log 
                # release_lock
            else 
                # get_lock
                 
                echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:失败:$JOBID"\
                     >>$LOGPATH/$BATCHNO/run.log 
                # release_lock
                runstatus=$JOBID
            fi
        else
            # 文件不存在日志
            jobstatus=999
            endtime=`date +%Y%m%d_%H%M%S` 
            # get_lock
                
            echo "$BATCHNO:${CURJOB}:$jobunit:$endtime:$endtime:文件不存在:$JOBID"\
                 >>$LOGPATH/$BATCHNO/run.log 
            # release_lock
            runstatus=$JOBID
        fi

        # 作业执行成功跳出作业
        if [ "$runstatus" = "0" ]; then
            break
            # 重试超过次数，同样跳出循环
        elif [ $trycnt -gt $MAXRETRY ]; then
            # 重试日志
            endtime=`date +%Y%m%d_%H%M%S`
            # get_lock
                
            echo "${BATCHNO}:${CURJOB}:$jobunit:$starttime:$endtime:重试次数超过${MAXRETRY}:$JOBID" \
                 >>$LOGPATH/$BATCHNO/run.log
            echo "${BATCHNO}:${CURJOB}:$jobunit:$starttime:$endtime:失败:$JOBID" \
                 >>$LOGPATH/$BATCHNO/run.log 
            # release_lock
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
                # get_lock
                
                echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:用户中断:$JOBID" \
                     >>$LOGPATH/$BATCHNO/run.log 
                # release_lock
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
    # get_lock
                
    echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:成功:0" \
         >>$LOGPATH/$BATCHNO/run.log 
    # release_lock
else 
    # get_lock
                
    echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:失败:$JOBID" \
         >>$LOGPATH/$BATCHNO/run.log 
    # release_lock
fi

### 检查后续作业执行条件是否满足
###=========================
# $JOBRELF
# job_pre="" # 前面的作业
# 获取前续作业逻辑
# 1. 读取关系文件中以:分隔的第二列
# 2. 通过当前作用序列名判断出前续作业
# job_pre=`awk -F : '{print $2}' $JOBRELF | awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $0;break;};x-=1;}}'`
# 改写的获取前续作业逻辑
job_pre=`awk -f : '{print $2}' $JOBRELF | grep $JOBNAME`
job_succ=`cat $JOBRELF | grep $JOBNAME | tail -n 1 | awk -f ':' 'print $3'`

# job_succ=""
# jobrela=""

# 找到js relation
# jobrela=`cat $JOBRELF | grep $JOBNAME | tail -n 1 | awk -F ':' '{print $1}'`
# jobrela=`awk -F : '{print $1 "+" $2}' $JOBRELF |awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $1;break;} ;x-=1;}}'`
# if [ ! -z "$jobrela" ];then
#     # 找到后续作业
#     job_succ=`cat $JOBRELF | grep $JOBNAME | tail -n 1 | awk -f ':' 'print $3'`
#     # job_succ=`awk -F : -v jobrela=$jobrela '$1==jobrela {print $3}' $JOBRELF`
# else
#     job_succ=""
# fi

### 判断是否存在后续作业
if [ ! -z "$job_succ" ]; then
    itemid=1
    succflag=1
    while :
    do
        job_pre_item=`print $job_pre | awk -F + -v itemid=$itemid '{print $itemid}'`
        if [ -z "$job_pre_item" ]; then
            break;
        fi
        # 判断作业状态, 如果作业成功, 则进行后续作业
        joblststatus=`awk -F : -v job_pre_item=$job_pre_item '$2 == job_pre_item && $3 == 0  {jobstatus=$7;next;} END {print jobstatus}' $LOGPATH/$batchno/run.log`
        if [ -z "$joblststatus" -o ! $joblststatus -eq 0 ]; then
            succflag=0
            break;
        fi
        itemid=`expr $itemid + 1`   
    done
    
    ###后续作业执行条件满足，调度后续作业
    schedulefile=`awk -F : '{print $1 "+" $2}' $JOBRELF |awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $1;break;};x-=1;}}'`
    ####临时增加，忽略错误作业
    #####
    ###succflag=1
    #####正式上线需要去掉
    if [ $succflag -eq 1 ]; then
        if [ ! -d $LOGPATH/$batchno/$schedulefile ]; then
            mkdir $LOGPATH/$batchno/$schedulefile
            if [ $? -eq 0 ]; then
                itemid=1
                while :
                do
                    job_succ_item=""
                    job_succ_item=`print $job_succ|awk -F '|' -v itemid=$itemid '{print $itemid}'`
                    if [ -z "$job_succ_item" ]; then
                        break;
                    fi
                    lsdate=`date +%Y%m%d_%H%M%S`                  
                    
                    jobid=1
                    
                    $ETLHOME/shell/submit.sh ${job_succ_item} $batchno $jobid >>$LOGPATH/$batchno/joblst.run
                    if [ $? -eq 0 ]; then
                        print "$batchno:$job_succ_item:$lsdate:调度成功" >>$LOGPATH/$batchno/schedule.log
                    else
                        print "$batchno:$job_succ_item:$lsdate:调度失败" >>$LOGPATH/$batchno/schedule.log
                    fi
                    itemid=`expr $itemid + 1`
                done
            else
                print "$batchno:$curjob:$lsdate:后续作业序列已被调度,忽略后续调度" >>$LOGPATH/$batchno/schedule.log
            fi
        else
            print "$batchno:$curjob:$lsdate:后续作业序列已被其他作业调度,后续调度取消" >>$LOGPATH/$batchno/schedule.log
        fi
    else
        print "$batchno:$curjob:$lsdate:后续作业序列调度条件不满足，后续调度不能执行" >>$LOGPATH/$batchno/schedule.log
    fi   
else
    print "$batchno:$curjob:$lsdate:无后续作业序列" >>$LOGPATH/$batchno/schedule.log
    if [ -f $LOGPATH/running.flag ]; then
        rm $LOGPATH/running.flag 
    fi  
fi   
