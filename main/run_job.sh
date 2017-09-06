#!/bin/sh

### ----------------------------------------------------------------------
### 参数：
###
### $1-job文件名称, joblstname
### $2-batchno批次号
### $3-执行Job序号, job ID
### $4-最大重试次数,可选项，如不选默认值为5次
### $5-重试休眠时间，单位：秒，可选项，如不选默认值为12
###
### updated @2017-09-05 14:16:40 by lixiang <alexiangli@outlook.com>
### ----------------------------------------------------------------------

### 路径需要配置：
### $ETLHOME/shell/config/etl_datectl_param
### $ETLHOME/shell/config/etl_job

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

if [ -z "$1" -o -z "$2" -0 -z "$3" ]; then
    printf "\n   用户未指定参数1,2,3\n"
    exit 1
fi

# 最大重试次数
maxretrycnt=${4:-5}
# 重试休眠时间
intervaltime=${5:-12}
# 锁定时常
locktimeout=300

# datectlfile是神马文件
datectlfile=$ETLHOME/config/etl_datectl_param
jobschfile=$ETLHOME/config/etl_job

# 时间
lsdate=`date +%Y%m%d_%H%M%S`
jobstarttime=$lsdate

# 检查相关文件是否存在
joblstname=$1
batchno=$2
jobid=$3
joblist=$JOBPATH/$joblstname # job清单文件
curjob=$joblstname
procid=$$

if [ ! -f $joblist ]; then
    print "\n文件$joblist不存在，作业${curjob}启动失败." \
          >>$etllogpath/run.err
    exit 2
fi

if [ ! -f $jobrelation ]; then
    print "\n文件$jobrelation不存在，作业${curjob}启动失败." \
          >>$ETLHOME/etllog/run.err
    exit 2
fi

# 创建作业序列执行日志存放目录
if [ ! -d $etllogpath/$batchno/${curjob}_$lsdate ]; then
    mkdir -p $etllogpath/$batchno/${curjob}_$lsdate
    if [ ! $? -eq 0 ]; then
        print "\n创建目录$etllogpath/$batchno/${curjob}_$lsdate失败，作业${curjob}启动失败." \
              >>$etllogpath/run.err
        exit 4
    else
        print "$etllogpath/$batchno/${curjob}_$lsdate" \
              >> $etllogpath/$batchno/runlog.lst
    fi
fi
logpath=$etllogpath/$batchno/${curjob}_$lsdate

###encrypt_pwd=`$ETLHOME/shell/crypt.sh ${DSPASSWORD} decrypt`
###DSPASSWORD=$encrypt_pwd

###顺序执行当前作业序列中的JOB
jobid=$3


###装载环境变量


# 解密码
./decrypt_pwd.sh

runstatus=0
while :
do
    # 顺序读取作业序列中每个作业
    # 第2列为任务
    jobunit=`awk -F : -v jobid=$jobid '$1==jobid {print $2}' $joblist`
    if [ -z "$jobunit" ]; then
        break
    fi
    # 第5列为任务类型
    jobtype=`awk -F : -v jobid=$jobid '$1==jobid {print $5}' $joblist`
    # 从jobschfile重读取scheduleflag
    if [ -f $jobschfile ]; then
        scheduleflag=`awk -F : -v jobname=$jobunit '$1==jobname {print $2}' $jobschfile`
    fi
    if [ -f $etllogpath/monthend.flag ]; then
        scheduleflag=1
    fi
    if [ ${scheduleflag:=1} -eq 0 ]; then
        starttime=`date +%Y%m%d_%H%M%S`
        # 获取写日志锁
        ./get_lock.sh
        print "$batchno:${curjob}:$jobunit:$starttime:$starttime:本次不需调度，跳过此作业:$jobid" \
              >>$etllogpath/$batchno/run.log
        # 释放写日志锁
        ./release_lock.sh
        jobid=`expr $jobid + 1` 
        continue;
    fi
    # 第3列为参数
    paramlist=`awk -F : -v jobid=$jobid '$1==jobid {print $3}' $joblist`
    ###encrypt_pwd "$paramlist"
    ###paramlist=$encryptstr

    ## shell脚本文件路径
    shellfile=$ETLHOME/shell/$jobunit
    # 计数器
    seqcnt=1

    while :
    do 

        runstatus=0
        starttime=`date +%Y%m%d_%H%M%S`

        if [ -f $shellfile -a -x $shellfile ]; then

            jobendtime=`date +%Y%m%d_%H%M%S`

            # 获取写日志锁
            ./getlock.sh
            print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid"\
                  >>$etllogpath/$batchno/run.log
            print "$batchno:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid"\
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
                ./get_lock.sh 
                print "$batchno:${curjob}:$jobunit:$starttime:$endtime:成功:$jobid"\
                      >>$etllogpath/$batchno/run.log
                # 释放写日志锁
                ./release_lock.sh 
            else
                # 获取写日志锁
                ./get_lock.sh 
                print "$batchno:${curjob}:$jobunit:$starttime:$endtime:失败:$jobid"\
                      >>$etllogpath/$batchno/run.log
                # 释放写日志锁
                ./release_lock.sh 
                runstatus=$jobid
            fi
        else
            jobstatus=999
            endtime=`date +%Y%m%d_%H%M%S`
            # 获取写日志锁
            ./get_lock.sh 
            print "$batchno:${curjob}:$jobunit:$starttime:$endtime:文件不存在或不可执行:$jobid"\
                  >>$etllogpath/$batchno/run.log
            # 释放写日志锁
            ./release_lock.sh 
            runstatus=$jobid
        fi
        
        if [ "$runstatus" = "0" ]; then
            break
        elif [ $seqcnt -gt $maxretrycnt ]; then
            starttime=`date +%Y%m%d_%H%M%S`

            # 获取写日志锁
            ./get_lock.sh
            print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:重试次数超过${maxretrycnt}:$jobid" \
                  >>$etllogpath/$batchno/run.log
            print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:失败:$jobid" \
                  >>$etllogpath/$batchno/run.log
            # 释放写日志锁
            ./release_lock.sh 
            break
        else
            seqcnt=`expr $seqcnt + 1`
            sleep $intervaltime
        fi
    done 
    
    if [ ! "$runstatus" = "0"  ]; then
        print "${curjob},$jobid" >$etllogpath/restart
        break
    else 
        jobid=`expr $jobid + 1`

        # 用户设置了强制中断标志
        if [ -f $etllogpath/halt.flag ]; then
            jobunit=`awk -F : -v jobid=$jobid '$1==jobid {print $2}' $joblist`
            haltjspos1=`awk -F : '{ if ($1 == "") {print 1}}' $etllogpath/halt.flag`
            haltjspos2=`awk -F : -v jobseq=$curjob ' { if ($1 == jobseq) {print $2}}' $etllogpath/halt.flag`
            
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
                ./get_lock.sh 
                print "$batchno:${curjob}:$jobunit:$starttime:$endtime:用户中断:$jobid" \
                      >>$etllogpath/$batchno/run.log
                # 释放写日志锁
                releaselock
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
    ./get_lock.sh 
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:成功:0" \
          >>$etllogpath/$batchno/run.log
    ###释放写日志锁
    ./release_lock.sh 
else
    ##获取写日志锁
    ./get_lock.sh 
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:失败:$jobid" \
          >>$etllogpath/$batchno/run.log
    ###释放写日志锁
    ./release_lock.sh 
fi
