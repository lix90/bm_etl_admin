#!/bin/sh

### ----------------------------------------------------------------------
### 参数：
###
### $1-job文件名称, jobfname
### $2-执行Job序号, job ID
### $3-batchno批次号
### $4-最大重试次数,可选项，如不选默认值为5次
### $5-重试休眠时间，单位：秒，可选项，如不选默认值为10秒
###
### updated @2017-09-05 14:16:40 by lixiang <alexiangli@outlook.com>
### ----------------------------------------------------------------------

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

### 环境变量
JOBPATH=$TASKPATH/job
SQLPATH=$TASKPATH/sql

if [ -z "$1" -o -z "$2" -0 -z "$3" ]; then
    printf "\n   用户未指定参数1,2,3\n"
    exit 1
fi

### 参数
# 最大重试次数
maxretrycnt=${4:-5}
# 重试休眠时间
intervaltime=${5:-10}
# 锁定时常
locktimeout=300

# datectlfile是神马文件
# datectlfile=$ETLHOME/config/etl_datectl_param
# jobschfile=$ETLHOME/config/etl_job

# 时间
lsdate=`date +%Y%m%d_%H%M%S`
jobstarttime=$lsdate

# 检查相关文件是否存在
jobfname=$1
jobid=$2
batchno=$3

# 当前作业清单文件
JOBFILE=$JOBPATH/$jobfname # job清单文件
# 当前作业文件名
curjob=$jobfname
# 进程号
procid=$$

if [ ! -f $JOBFILE ]; then
    print "\n文件$JOBFILE不存在，作业${curjob}启动失败." \
          >>$LOGPATH/run.err
    exit 2
fi

# if [ ! -f $jobrelation ]; then
#     print "\n文件$jobrelation不存在，作业${curjob}启动失败." \
    #           >>$LOGPATH/run.err
#     exit 2
# fi

# 创建作业序列执行日志存放目录
if [ ! -d $LOGPATH/$batchno/${curjob}_$lsdate ]; then
    mkdir -p $LOGPATH/$batchno/${curjob}_$lsdate
    if [ ! $? -eq 0 ]; then
        print "\n创建目录$LOGPATH/$batchno/${curjob}_$lsdate失败，作业${curjob}启动失败." \
              >>$LOGPATH/run.err
        exit 4
    else
        print "$LOGPATH/$batchno/${curjob}_$lsdate" \
              >> $LOGPATH/$batchno/runlog.lst
    fi
fi

# logpath=$LOGPATH/$batchno/${curjob}_$lsdate
###encrypt_pwd=`$ETLHOME/shell/crypt.sh ${DSPASSWORD} decrypt`
###DSPASSWORD=$encrypt_pwd

###装载环境变量

# 解密码
# ./decrypt_pwd.sh

runstatus=0
while :
do
    # 顺序读取作业序列中每个作业
    # 第2列为任务, *.sql
    jobunit=`awk -F : -v jobid=$jobid '$1==jobid {print $2}' $JOBFILE`
    if [ -z "$jobunit" ]; then
        break
    fi
    
    # 第5列为任务类型
    # 目前还未根据任务类型调用不同作业
    # jobtype=`awk -F : -v jobid=$jobid '$1==jobid {print $5}' $JOBFILE`
    # 从jobschfile重读取scheduleflag
    # if [ -f $jobschfile ]; then
    #     scheduleflag=`awk -F : -v jobname=$jobunit '$1==jobname {print $2}' $jobschfile`
    # fi
    # 月结标识
    # if [ -f $LOGPATH/monthend.flag ]; then
    #     scheduleflag=1
    # fi
    # if [ ${scheduleflag:=1} -eq 0 ]; then
    #     starttime=`date +%Y%m%d_%H%M%S`
    #     # 获取写日志锁
    #     ./get_lock.sh
    #     print "$batchno:${curjob}:$jobunit:$starttime:$starttime:本次不需调度，跳过此作业:$jobid" \
        #           >>$LOGPATH/$batchno/run.log
    #     # 释放写日志锁
    #     ./release_lock.sh

    #     # 以作业序号递增执行
    #     jobid=`expr $jobid + 1` 
    #     continue;
    # fi
    
    # 第3列为参数
    paramlist=`awk -F : -v jobid=$jobid '$1==jobid {print $3}' $JOBFILE`
    ###encrypt_pwd "$paramlist"
    ###paramlist=$encryptstr

    ## sql脚本文件路径
    sqlfile=$SQLPATH/$jobunit

    # 计数器
    seqcnt=1

    while :
    do
        
        ## ------------------------------------------------------------
        ## execute sql script
        ## ------------------------------------------------------------
        runstatus=0
        starttime=`date +%Y%m%d_%H%M%S`
        
        if [ -f $sqlfile -a -x $sqlfile ]; then

            jobendtime=`date +%Y%m%d_%H%M%S`

            # 获取写日志锁
            ./getlock.sh $curjob $jobunit $batchno
            print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid"\
                  >>$LOGPATH/$batchno/run.log
            print "$batchno:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid"\
                  >>$LOGPATH/$batchno/run.log

            # 释放写日志锁
            ./release_lock.sh $curjob $jobunit $batchno $procid
            if [ -z "${paramlist}" ]; then
                ./exec_orcl_proc.sh $sqlfile
            else
                ./exec_orcl_proc.sh $sqlfile ${paramlist}
            fi

            # 获取最近的作业状态
            jobstatus=$?

            endtime=`date +%Y%m%d_%H%M%S`
            if [ $jobstatus -eq 0 ]; then
                # 获取写日志锁
                ./get_lock.sh $curjob $jobunit $batchno
                print "$batchno:${curjob}:$jobunit:$starttime:$endtime:成功:$jobid"\
                      >>$LOGPATH/$batchno/run.log
                # 释放写日志锁
                ./release_lock.sh $curjob $jobunit $batchno $procid
            else
                # 获取写日志锁
                ./get_lock.sh $curjob $jobunit $batchno
                print "$batchno:${curjob}:$jobunit:$starttime:$endtime:失败:$jobid"\
                      >>$LOGPATH/$batchno/run.log
                # 释放写日志锁
                ./release_lock.sh $curjob $jobunit $batchno $procid
                runstatus=$jobid
            fi
        else
            jobstatus=999
            endtime=`date +%Y%m%d_%H%M%S`

            # 获取写日志锁
            ./get_lock.sh $curjob $jobunit $batchno
            print "$batchno:${curjob}:$jobunit:$starttime:$endtime:文件不存在或不可执行:$jobid"\
                  >>$LOGPATH/$batchno/run.log
            # 释放写日志锁
            ./release_lock.sh $curjob $jobunit $batchno $procid
            runstatus=$jobid
        fi
        # 如果成功，则跳出循环
        if [ "$runstatus" = "0" ]; then
            break
            # 重试超过次数，则跳出循环
        elif [ $seqcnt -gt $maxretrycnt ]; then
            starttime=`date +%Y%m%d_%H%M%S`

            # 获取写日志锁
            ./get_lock.sh $curjob $jobunit $batchno
            print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:重试次数超过${maxretrycnt}:$jobid" \
                  >>$LOGPATH/$batchno/run.log
            print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:失败:$jobid" \
                  >>$LOGPATH/$batchno/run.log
            # 释放写日志锁
            ./release_lock.sh $curjob $jobunit $batchno $procid
            break
        else
            # 重新执行作业
            seqcnt=`expr $seqcnt + 1`
            sleep $intervaltime
        fi
    done

    # 如果状态未成功，那么写入重启ETL标识
    if [ ! "$runstatus" = "0"  ]; then
        print "${curjob},$jobid" \
              >$LOGPATH/restart.flag
        break
    else
        # 否则，进行下一步作业，即序号加1
        jobid=`expr $jobid + 1`

        # 用户设置了强制中断标识
        if [ -f $LOGPATH/halt.flag ]; then

            # 获取中断作业位置
            jobunit=`awk -F : -v jobid=$jobid '$1==jobid {print $2}' $JOBFILE`
            haltjspos1=`awk -F : '{ if ($1 == "") {print 1}}' $LOGPATH/halt.flag`
            haltjspos2=`awk -F : -v jobseq=$curjob ' { if ($1 == jobseq) {print $2}}' $LOGPATH/halt.flag`
            
            if [ ! -z "$haltjspos1" ]; then
                haltflag=1
            elif [ -z "$haltjspos1" -a ! -z "$haltjspos2" -a  $jobid -gt $haltjspos2 ]; then
                haltflag=1
            else
                haltflag=0
            fi
            if [ "$haltflag" = "1" ]; then
                runstatus=$jobid
                # 获取写日志锁
                ./get_lock.sh $curjob $jobunit $batchno
                print "$batchno:${curjob}:$jobunit:$starttime:$endtime:用户中断:$jobid" \
                      >>$LOGPATH/$batchno/run.log
                # 释放写日志锁
                ./release_lock.sh $curjob $jobunit $batchno $procid
                break
            fi
        fi
    fi
done

### ----------------------------------------------------------------------
### 输出当前作业序列日志
### ----------------------------------------------------------------------
jobendtime=`date +%Y%m%d_%H%M%S`
if [ $runstatus -eq 0 ]; then
    ##获取写日志锁
    ./get_lock.sh $curjob $jobunit $batchno
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:成功:0" \
          >>$LOGPATH/$batchno/run.log
    ###释放写日志锁
    ./release_lock.sh $curjob $jobunit $batchno $procid
else
    ##获取写日志锁
    ./get_lock.sh $curjob $jobunit $batchno
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:失败:$jobid" \
          >>$LOGPATH/$batchno/run.log
    ###释放写日志锁
    ./release_lock.sh $curjob $jobunit $batchno $procid
fi
