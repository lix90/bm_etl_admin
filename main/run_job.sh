#!/bin/sh

### ----------------------------------------------------------------------
### 参数：
###
### $1-job文件名称  
### $2-batchno批次号
### $3-执行Job序号
### $4-ETL任务类型
### $5-最大重试次数,可选项，如不选默认值为5次
### $6-重试休眠时间，单位：秒，可选项，如不选默认值为12
###
### updated @2017-09-05 14:16:40 by lixiang <alexiangli@outlook.com>
### ----------------------------------------------------------------------

### 路径需要配置：
### $ETLHOME/shell/config/etl_datectl_param
### $ETLHOME/shell/config/etl_job
### binfiledirectory, /.dshome, jobpath

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

if [ -z "$1" ]; then
    exit 1
fi
if [ -z "$2" ]; then
    exit 1
fi
if [ -z "$3" ]; then
    exit 1
fi
if [ -z "$4" ]; then
    exit 1
fi

maxretrycnt=${6:-5}
intervaltime=${7:-12}

locktimeout=300
datectlfile=$ETLHOME/shell/config/etl_datectl_param
jobschfile=$ETLHOME/shell/config/etl_job
binfiledirectory=`cat /.dshome`/bin

lsdate=`date +%Y%m%d_%H%M%S`
jobstarttime=$lsdate
joblist=$jobpath/$1
curjob=$1
batchno=$2
procid=$$
ddflag=$4

# 检查相关文件是否存在
if [ ! -f $joblist ]; then
    print "\n文件$joblist不存在，作业${curjob}启动失败." \
          >>$ETLHOME/etllog/run.err
    exit 2
fi

if [ ! -f $jobrelation ]; then
    print "\n文件$jobrelation不存在，作业${curjob}启动失败." \
          >>$ETLHOME/etllog/run.err
    exit 2
fi

# 创建作业序列执行日志存放目录
if [ ! -d $ETLHOME/etllog/$batchno/${curjob}_$lsdate ]; then
    mkdir -p $ETLHOME/etllog/$batchno/${curjob}_$lsdate
    if [ ! $? -eq 0 ]; then
        print "\n创建目录$ETLHOME/etllog/$batchno/${curjob}_$lsdate失败，作业${curjob}启动失败." \
              >>$ETLHOME/etllog/run.err
        exit 4
    else
        print "$ETLHOME/etllog/$batchno/${curjob}_$lsdate" \
              >> $ETLHOME/etllog/$batchno/runlog.lst
    fi
fi
logpath=$ETLHOME/etllog/$batchno/${curjob}_$lsdate


### ----------------------------------------------------------------------
### 获取run.log文件的写数据锁
### ----------------------------------------------------------------------
getlock(){
    locktime=0
    while :
    do
        mv $ETLHOME/etllog/loglock.lck \
           $ETLHOME/etllog/loglock.lck${procid} \
           2>/dev/null
        
        if [ ! $? -eq 0 ]; then
            sleep 1
            locktime=`expr $locktime + 1`
            if [ $locktime = $locktimeout ]; then
                lsdate22=`date +%Y%m%d_%H%M%S`
                echo "$lsdate22:作业序列${curjob}－作业$jobunit申请写日志锁超时，调度程序出现严重错误."\
                     >>$ETLHOME/etllog/$batchno/joblst.run
                exit 4000
            fi
        else
            break  
        fi
    done
}

### ----------------------------------------------------------------------
### 释放run.log文件的写数据锁
### ----------------------------------------------------------------------
releaselock(){
    
    mv $ETLHOME/etllog/loglock.lck${procid} \
       $ETLHOME/etllog/loglock.lck \
       2>/dev/null

    if [ ! $? -eq 0 ]; then
        lsdate22=`date +%Y%m%d_%H%M%S`
        echo "$lsdate22:作业序列${curjob}－作业$jobunit释放写日志锁超时，调度程序出现严重错误."\
             >>$ETLHOME/etllog/$batchno/joblst.run
        exit 4001
    else
        break  
    fi
}

### ----------------------------------------------------------------------
### 检查作业状态1
### ----------------------------------------------------------------------
checkjobstatus1(){
    
    logfilename="${logfile}_jobstatus"
    ${binfiledirectory}/dsjob \
                       -server ${DSSERVER} \
                       -user ${DSUSER} \
                       -password ${DSPASSWORD} \
                       -jobinfo ${DSPROJECT} ${jobunit} \
                       >> ${logfilename} 
    
    error=`grep "Job Status" ${logfilename}` 
    error=${error##*\(} 
    error=${error%%\)*} 
    
    if [ "${error}" = "1" ]; then
        jobstatus=0
    else
        jobstatus=${error}
    fi
}

### ----------------------------------------------------------------------
### 检查执行作业状态2
### ----------------------------------------------------------------------
checkjobstatus2(){
    
    jobwaiting=`grep "Waiting for job..." $1` 
    endtime=`date +%Y%m%d_%H%M%S`
    if [ "${jobwaiting}" != "Waiting for job..." ]; then
        jobstatus=-1 
    else
        jobstatus=1
    fi
    
    ${binfiledirectory}/dsjob \
                       -server ${DSSERVER} \
                       -user ${DSUSER} \
                       -password ${DSPASSWORD} \
                       -jobinfo ${DSPROJECT} ${jobunit} \
                       >> $1
    
    error=`grep "Job Status" $1` 
    error=${error##*\(} 
    error=${error%%\)*} 
    
    if [ "${jobstatus}" != "1" ]; then
        jobstatus=-1
    else
        if [ "${error}" = "1" -o "${error}" = "2" ]; then
            jobstatus=0
        else
            jobstatus=${error}
        fi
        if [ ! "${error}" = "1" ]; then
            ${binfiledirectory}/dsjob \
                               -server ${DSSERVER} \
                               -user ${DSUSER} \
                               -password ${DSPASSWORD} \
                               -logsum ${DSPROJECT} ${jobunit} \
                               >> $1
        fi
    fi
}

### ----------------------------------------------------------------------
### 解密
### > 初始化 .profile
### > 从 .envset中读取密码
### ----------------------------------------------------------------------
decrypt_pwd(){

    # 初始化文件
    initfile=/home/`whoami`/.profile
    inittmpfile=${initfile}_$$
    if [ ! -f $initfile ]; then
        echo "初始化文件$initfile 不存在."
        exit 1000
    fi
    cat $initfile|awk '(!($0 ~ /admin.sh/)) {print $0}'\
                      >$inittmpfile
    chmod 755 $inittmpfile
    . $inittmpfile
    rm $inittmpfile

    # 环境配置文件
    cfgfile=/home/`whoami`/.envset
    if [ ! -f $cfgfile ]; then
        echo "ETL配置文件$cfgfile不存在."
        exit 1000
    fi

    while read line
    do
        if [ -z "$line"  ]; then 
            continue;
        fi
        cryptstr=`echo $line|awk '(($2 ~ /PWD/) || ($2 ~ /PASSWORD/))  {print $0}'`
        if [ -z "$cryptstr" ]; then
            continue;
        fi
        decryptstr=""
        id=1
        
        while :
        do
            itemstr=`echo $cryptstr|awk -v itemid=$id '{print $itemid}'`
            if [ -z "$itemstr" ]; then
                break
            else
                itemvalstr1=`echo $itemstr|awk -F = '{print $1}'`
                itemvalstr2=`echo $itemstr|awk -F = '{print $2}'`
                if [ -z "$itemvalstr2" ]; then
                    id=`expr $id + 1`
                    continue
                else
                    itemvalstr1_cur="\$${itemvalstr1}_cur"
                    decryptstr="${itemvalstr1}=${itemvalstr1_cur}"
                fi   
            fi
            id=`expr $id + 1`
        done
        eval "$decryptstr"
        itemvar="\$${itemvalstr1}"
        decryval=`eval echo $itemvar`
        
        if [ ! -z "${itemvalstr2}" -a -z "${decryval}"  ]; then
            echo "ERROR:${itemvalstr1} value missing."
            echo "ERROR:Load Encrypt Information fail,Job Interrupt."
            starttime=`date +%Y%m%d_%H%M%S`
            # 获取写日志锁
            getlock      
            print "$batchno:${curjob}:0:$starttime:$starttime:失败:$jobid" >>$ETLHOME/etllog/$batchno/run.log
            # 释放写日志锁
            releaselock
            exit 1001
        fi
    done<$cfgfile
}

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

    print "$batchno:${curjob}:$jobunit:$starttime:$starttime:等待运行:$jobid" >>$ETLHOME/etllog/$batchno/run.log

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
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid" >>$ETLHOME/etllog/$batchno/run.log 

    # 释放写日志锁
    releaselock
    logfilename=${logfile}_runstatus

    # 获取写日志锁
    getlock
    print "$batchno:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid" >>$ETLHOME/etllog/$batchno/run.log 

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

exec_shell(){
    
    runstatus=0
    starttime=`date +%Y%m%d_%H%M%S`  
    if [ -f $shellfile -a -x $shellfile ]; then
        jobendtime=`date +%Y%m%d_%H%M%S`

        # 获取写日志锁
        getlock
        print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid" \
              >>$ETLHOME/etllog/$batchno/run.log 
        print "$batchno:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid" \
              >>$ETLHOME/etllog/$batchno/run.log  

        # 释放写日志锁
        releaselock
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
}


###encrypt_pwd=`$ETLHOME/shell/crypt.sh ${DSPASSWORD} decrypt`
###DSPASSWORD=$encrypt_pwd
###顺序执行当前作业序列中的JOB
jobid=$3

###装载环境变量

# 解密码
decrypt_pwd

runstatus=0
while :
do
    # 顺序读取作业序列中每一job
    jobunit=`awk -F : -v jobid=$jobid '$1==jobid {print $2}' $joblist`
    if [ -z "$jobunit" ]; then
        break
    fi
    jobtype=`awk -F : -v jobid=$jobid '$1==jobid {print $5}' $joblist`
    if [ -f $jobschfile ]; then
        scheduleflag=`awk -F : -v jobname=$jobunit '$1==jobname {print $2}' $jobschfile` 
    fi
    if [ -f $ETLHOME/etllog/monthend.flag ]; then
        scheduleflag=1
    fi    

    if [ ${scheduleflag:=1} -eq 0 ]; then
        starttime=`date +%Y%m%d_%H%M%S`
        # 获取写日志锁
        getlock      
        print "$batchno:${curjob}:$jobunit:$starttime:$starttime:本次不需调度，跳过此作业:$jobid" \
              >>$ETLHOME/etllog/$batchno/run.log
        # 释放写日志锁
        releaselock
        jobid=`expr $jobid + 1` 
        continue;
    fi
    
    paramlist=`awk -F : -v jobid=$jobid '$1==jobid {print $3}' $joblist`
    ###encrypt_pwd "$paramlist"
    ###paramlist=$encryptstr
    
    if [ "$jobtype" = "dsjob" ]; then
        ctlid=`awk -F : -v jobid=$jobid '$1==jobid {print $4}' $joblist` 
        
        # 读取当前待执行JOB对应的加载日期范围
        if [ ! $ctlid -eq 0 ]; then
            jb_startdate=`awk -F : -v ctlid=$ctlid '$1==ctlid {print $2}' $datectlfile`
            jb_enddate=`awk -F : -v ctlid=$ctlid '$1==ctlid {print $3}' $datectlfile`
            paramlist="$paramlist -param v_jb_startdate=$jb_startdate -param v_jb_enddate=$jb_enddate"
        fi
        
        lsdate=`date +%Y%m%d_%H%M%S`
        logfile=$logpath/${jobunit}_$lsdate
        seqcnt=1

        while :
        do
            exec_dsjob 
            if [ "$runstatus" = "0"  ]; then
                break
            elif [ $seqcnt -gt $maxretrycnt ]; then
                starttime=`date +%Y%m%d_%H%M%S`
                # 获取写日志锁
                getlock      
                print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:重试次数超过${maxretrycnt}:$jobid" \
                      >>$ETLHOME/etllog/$batchno/run.log
                print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:失败:$jobid" \
                      >>$ETLHOME/etllog/$batchno/run.log
                # 释放写日志锁
                releaselock
                break
            else
                seqcnt=`expr $seqcnt + 1`
                sleep $intervaltime
            fi
        done 
    elif [ "$jobtype" = "shell" ]; then
        shellfile=$ETLHOME/shell/$jobunit
        seqcnt=1

        while :
        do
            exec_shell 
            if [ "$runstatus" = "0"  ]; then
                break
            elif [ $seqcnt -gt $maxretrycnt ]; then
                starttime=`date +%Y%m%d_%H%M%S`

                # 获取写日志锁
                getlock      
                print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:重试次数超过${maxretrycnt}:$jobid" \
                      >>$ETLHOME/etllog/$batchno/run.log
                print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:失败:$jobid" \
                      >>$ETLHOME/etllog/$batchno/run.log
                # 释放写日志锁
                releaselock           
                break
            else
                seqcnt=`expr $seqcnt + 1`
                sleep $intervaltime
            fi
        done      
    fi
    
    if [ ! "$runstatus" = "0"  ]; then
        print "${curjob},$jobid" >$ETLHOME/etllog/restart${ddflag}
        break
    else 
        jobid=`expr $jobid + 1`

        # 用户设置了强制中断标志
        if [ -f $ETLHOME/etllog/halt${ddflag}.flag ]; then
            jobunit=`awk -F : -v jobid=$jobid '$1==jobid {print $2}' $joblist`
            haltjspos1=`awk -F : ' { if ($1 == "") {print 1}}' $ETLHOME/etllog/halt${ddflag}.flag`
            haltjspos2=`awk -F : -v jobseq=$curjob ' { if ($1 == jobseq) {print $2}}' $ETLHOME/etllog/halt${ddflag}.flag`
            
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
                getlock
                print "$batchno:${curjob}:$jobunit:$starttime:$endtime:用户中断:$jobid" \
                      >>$ETLHOME/etllog/$batchno/run.log
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
    getlock
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:成功:0" \
          >>$ETLHOME/etllog/$batchno/run.log
    ###释放写日志锁
    releaselock
else
    ##获取写日志锁
    getlock
    print "$batchno:${curjob}:0:$jobstarttime:$jobendtime:失败:$jobid" \
          >>$ETLHOME/etllog/$batchno/run.log
    ###释放写日志锁
    releaselock
fi

### ----------------------------------------------------------------------
### 检查后续作业执行条件是否满足
### ----------------------------------------------------------------------
job_pre=""
job_pre=`awk -F : '{print $2}' $jobrelation |awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $0;break;};x-=1;}}'`
job_succ=""
jobrela=""

jobrela=`awk -F : '{print $1 "+" $2}' $jobrelation |awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $1;break;} ;x-=1;}}'`
if [ ! -z "$jobrela" ];then
    job_succ=`awk -F : -v jobrela=$jobrela '$1==jobrela {print $3}' $jobrelation`
else
    job_succ=""
fi

### ----------------------------------------------------------------------
### 判断是否存在后续作业
### ----------------------------------------------------------------------
if [ ! -z "$job_succ" ];then
    itemid=1
    succflag=1
    while :
    do
        job_pre_item=`print $job_pre|awk -F + -v itemid=$itemid '{print $itemid}'`
        if [ -z "$job_pre_item" ]; then
            break;
        fi
        
        joblststatus=`awk -F : -v job_pre_item=$job_pre_item '$2 == job_pre_item && $3 == 0  {jobstatus=$7;next;} END {print jobstatus}' $ETLHOME/etllog/$batchno/run.log`
        if [ -z "$joblststatus" ]; then
            succflag=0
            break;
        fi
        if [ ! $joblststatus -eq 0 ]; then
            succflag=0
            break;
        fi
        itemid=`expr $itemid + 1`   
    done
    
    ###后续作业执行条件满足，调度后续作业
    schedulefile=`awk -F : '{print $1 "+" $2}' $jobrelation |awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $1;break;};x-=1;}}'`
    ####临时增加，忽略错误作业
    #####
    ###succflag=1
    #####正式上线需要去掉
    if [ $succflag -eq 1 ]; then
        if [ ! -d $ETLHOME/etllog/$batchno/$schedulefile ]; then
            mkdir $ETLHOME/etllog/$batchno/$schedulefile
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
                    
                    $ETLHOME/shell/submit.sh ${job_succ_item} $batchno $jobid \
                                             >>$ETLHOME/etllog/$batchno/joblst.run
                    if [ $? -eq 0 ]; then
                        print "$batchno:$job_succ_item:$lsdate:调度成功" \
                              >>$ETLHOME/etllog/$batchno/schedule.log
                    else
                        print "$batchno:$job_succ_item:$lsdate:调度失败" \
                              >>$ETLHOME/etllog/$batchno/schedule.log
                    fi   
                    
                    itemid=`expr $itemid + 1`
                done
            else
                print "$batchno:$curjob:$lsdate:后续作业序列已被调度,忽略后续调度" \
                      >>$ETLHOME/etllog/$batchno/schedule.log
            fi
        else
            print "$batchno:$curjob:$lsdate:后续作业序列已被其他作业调度,后续调度取消" \
                  >>$ETLHOME/etllog/$batchno/schedule.log
        fi
    else
        print "$batchno:$curjob:$lsdate:后续作业序列调度条件不满足，后续调度不能执行" \
              >>$ETLHOME/etllog/$batchno/schedule.log
    fi
else
    print "$batchno:$curjob:$lsdate:无后续作业序列" \
          >>$ETLHOME/etllog/$batchno/schedule.log
    if [ -f $ETLHOME/etllog/running.flag ]; then
        rm $ETLHOME/etllog/running.flag
    fi
fi
