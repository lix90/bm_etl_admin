#!/bin/sh

###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
### 参数：
###
### $1-作业序列文件名
### $2-作业序号
### $3-批次号
### $4-最大重试次数,可选项，如不选默认值为5次
### $5-重试休眠时间，单位：秒，可选项，如不选默认值为10秒
###
### updated @2017-09-12 13:51:42 by lixiang <alexiangli@outlook.com>
###<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

### 参数检查
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "用户未指定参数1,2,3"
    exit 1
fi

JOBNAME=$1
JOBID=$2
BATCHNO=$3

LOGPATH=$TASKPATH/log # 日志文件路径
RUNLOG=$LOGPATH/$BATCHNO/run.log # 运行日志
JOBLSTLOG=$LOGPATH/$BATCHNO/joblst.run # 作业序列日志
SCHLOG=$LOGPATH/$BATCHNO/schedule.log # 调度日志
JOBRELF=$TASKPATH/job/js.rel # 作业关系文件
SCRIPTPATH=$TASKPATH/script # 脚本文件路径
JOBPATH=$TASKPATH/job # 作业文件路径
JOBFILE=$JOBPATH/$JOBNAME # 当前作业序列文件
CURJOB=$JOBNAME # 当前作业文件名

MAXRETRY=${4:-5} # 最大重试次数
INTERVAL=${5:-10} # 重试休眠时间
LCKTIMEOUT=100 # 锁定时长
PROCID=$$ # 进程号

NOW=`date +%Y%m%d_%H%M%S`
JOBSTARTTIME=$NOW

if [ ! -f $JOBFILE ]; then
    echo "文件$JOBFILE不存在，作业${CURJOB}启动失败." \
         >>$LOGPATH/err.log
    exit 2
fi

if [ ! -f $JOBRELF ]; then
    echo "文件$JOBRELF不存在，作业${CURJOB}启动失败." \
         >>$LOGPATH/err.log
    exit 2
fi

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
            if [ $locktime = $LCKTIMEOUT ]; then
                lsdate22=`date +%Y%m%d_%H%M%S`
                echo "$lsdate22:作业序列${CURJOB}－作业$JOBUNIT申请写日志锁超时，调度程序出现严重错误."\
                     >>$JOBLSTLOG
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
             >>$JOBLSTLOG
        exit 4001
    else
        break
    fi
}

decrypt_pwd(){

    initfile=/home/`whoami`/.profile
    inittmpfile=${initfile}_$$
    if [ ! -f $initfile ]; then
        echo "初始化文件$initfile 不存在."
        exit 1000
    fi

    cat $initfile|awk '(!($0 ~ /admin.sh/)) {print $0}'>$inittmpfile

    chmod 755 $inittmpfile
    . $inittmpfile
    rm $inittmpfile
    
    ## 环境变量文件
    cfgfile=/home/`whoami`/.envset
    if [ ! -f $cfgfile ]; then
        echo "ETL配置文件$cfgfile不存在."
        exit 1000
    fi

    ## 读取环境变量文件
    passstr='PWD|PASSWORD'
    cryptstr=`cat $cfgfile | grep $passstr`

    while read line
    do
        decryptstr=""
        id=1
        while :
        do
            #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            # 密码为空，跳出当前循环
            # 否则，执行解密
            # 密码为明文，直接使用
            # 密码为变量，后台获取密码
            #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            itemvalstr1=`echo $line|awk -F = '{print $1}'`
            itemvalstr2=`echo $line|awk -F = '{print $2}'`
            if [ -z "$itemvalstr2" ]; then
                id=`expr $id + 1` 
                continue
            else
                envflag=`echo $itemvalstr2|awk '$1 ~/[\$]/ {print 1}'`
                if [ -z "$envflag" ]; then
                    decrypt_pwd=`eval $ETLHOME/sh/crypt.sh $itemvalstr2 decrypt`
                    decryptstr="export ${itemvalstr1}=$decrypt_pwd" 
                    decryptstr2="export ${itemvalstr1}_cur=$decrypt_pwd"
                else
                    decryptstr="export ${itemvalstr1}=$itemvalstr2"
                    decryptstr2="export ${itemvalstr1}_cur=$itemvalstr2"
                fi
            fi
            id=`expr $id + 1`
        done

        # 导出密码变量
        eval "$decryptstr"
        eval "$decryptstr2"

        # 如果密码为空
        itemvar="\$${itemvalstr1}"
        decryval=`eval echo $itemvar`
        if [ ! -z "$itemvalstr2" -a -z "${decryval}" ]; then
            echo "ERROR: 缺少${itemvalstr1}.">>$LOGPATH/run.err
            echo "ERROR: 导入密文失败，调度终止.">>$LOGPATH/run.err
            starttime=`date +%Y%m%d_%H%M%S` 
            # get_lock      
            echo "$BATCHNO:${CURJOB}:0:$starttime:$starttime:失败:$JOBID"\
                 >>$RUNLOG 
            # release_lock
            exit 1010  
        fi
    done<$cryptstr
}

### SQL*PLUS 作业类型执行函数
exec_sqlplus(){

    echo "run exec_sqlplus"
    # 初始化作业状态
    runstatus=0
    # 作业开始时间
    starttime=`date +%Y%m%d_%H%M%S` 
    if [ -f $scriptfile ]; then 
        jobendtime=`date +%Y%m%d_%H%M%S`
        # 运行中日志
        # get_lock
        echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:运行中:$JOBID"\
             >>$RUNLOG 
        echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$starttime:运行中:$JOBID"\
             >>$RUNLOG 
        # release_lock

        ##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        ## 正式调用sql存储过程 
        if [ ! -z "${paramlist}" ]; then
            # $ETLHOME/sh/run_sqlplus.sh $scriptfile ${paramlist}
            $ETLHOME/sh/test.sh $scriptfile ${paramlist}
        else
            # $ETLHOME/sh/run_sqlplus.sh $scriptfile
            $ETLHOME/sh/test.sh $scriptfile
        fi
        ##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

        ## 执行完后日志
        jobstatus=$?
        endtime=`date +%Y%m%d_%H%M%S`
        if [ $jobstatus -eq 0 ]; then 
            # get_lock
            echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:成功:$JOBID"\
                 >>$RUNLOG 
            # release_lock
        else 
            # get_lock
            
            echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:失败:$JOBID"\
                 >>$RUNLOG 
            # release_lock
            runstatus=$JOBID
        fi
    else
        # 文件不存在日志
        jobstatus=999
        endtime=`date +%Y%m%d_%H%M%S` 
        # get_lock
        
        echo "$BATCHNO:${CURJOB}:$jobunit:$endtime:$endtime:文件不存在:$JOBID"\
             >>$RUNLOG 
        # release_lock
        runstatus=$JOBID
    fi
}

##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## 作业循环开始
## 从作业序号开始进行迭代，有5次尝试机会
## 经过作业序列关系文件，这里起到断点执行作用
##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

## 装载环境变量
# decrypt_pwd

runstatus=0
while :
do
    ##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ## 读取作业
    ## 作业序列命名规则
    ## <JOBID>:<SQL>:<PARAMETERS>
    ## 1:script.sql:
    ##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    jobunit=`awk -F : -v i=$JOBID '$1==i {print $2}' $JOBFILE`
    scriptfile=$SCRIPTPATH/$jobunit
    paramlist=`awk -F : -v i=$JOBID '$1==i {print $3}' $JOBFILE`
    jobtype=`awk -F : -v i=$JOBID '$1==i {print $4}' $JOBFILE`
    echo "$jobtype"

    if [ -z "$jobunit" ]; then
        break
    fi

    ### 判断作业类型
    if [ $jobtype == "sqlplus" ]; then

        echo "sqlplus"
        # 尝试次数计数器
        trycnt=1
        # 尝试执行作业循环开始，如果成功或者失败超过次数则跳出循环
        while :
        do
            # 执行sqlplus作业
            exec_sqlplus
            
            # 作业执行成功跳出作业
            if [ "$runstatus" = "0" ]; then
                break
                # 重试超过次数，同样跳出循环
            elif [ $trycnt -gt $MAXRETRY ]; then
                # 重试日志
                endtime=`date +%Y%m%d_%H%M%S`
                # get_lock
                
                echo "${BATCHNO}:${CURJOB}:$jobunit:$starttime:$endtime:重试次数超过${MAXRETRY}:$JOBID" \
                     >>$RUNLOG
                echo "${BATCHNO}:${CURJOB}:$jobunit:$starttime:$endtime:失败:$JOBID" \
                     >>$RUNLOG 
                # release_lock
                break
            else
                # 执行作业序号加一，执行下一作业
                trycnt=`expr $trycnt + 1`
                sleep $INTERVAL
            fi
        done 
    else
        # echo ""
        # echo "$jobtype 暂时不支持，请向开发者提任务类型调度需求。"
        # echo ""
        # exit
        continue
    fi
    
    ##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ## 重启和中断操作
    ##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    # 如果状态未成功，那么写入重启标识
    # 之后，运行etl_restart.sh进行重启
    if [ ! "$runstatus" = "0"  ]; then
        echo "${CURJOB}+$JOBID" \
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
            jobunit=`awk -F : -v i=$JOBID '$1==i {print $2}' $JOBFILE`
            # 如果作业名为空，位置则为1
            haltpos1=`awk -F '+' '$1 == "" {print 1}' $LOGPATH/halt.flag`
            # 如果中断作业名为当前已运行作业，中断位置为中断标识文件第2列指定序号
            haltpos2=`awk -F '+' -v i=$CURJOB '$1 == i {print $2}' $LOGPATH/halt.flag`
            
            if [ ! -z "$haltpos1" -a ! -z "$haltpos2" -a $JOBID -gt $haltpos2 ]; then
                runstatus=$JOBID
                # 中断日志
                # get_lock
                echo "$BATCHNO:${CURJOB}:$jobunit:$starttime:$endtime:用户中断:$JOBID" \
                     >>$RUNLOG 
                # release_lock
                break
            fi
        fi
    fi
done

##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## 输出当前作业序列日志
##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
jobendtime=`date +%Y%m%d_%H%M%S`
if [ $runstatus -eq 0 ]; then
    # get_lock
    echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:成功:0" \
         >>$RUNLOG
    # release_lock
else 
    # get_lock
    echo "$BATCHNO:${CURJOB}:0:$JOBSTARTTIME:$jobendtime:失败:$JOBID" \
         >>$RUNLOG 
    # release_lock
fi

##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## 判断后续作业，并执行后续作业
##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

job_pre=""
job_succ=""

### 原来的代码逻辑（孙总）
# jobrela=""
# job_pre="" # 前面的作业
# 原来的获取前续作业代码逻辑（孙总）
# 1. 读取关系文件中以:分隔的第二列
# 2. 通过当前作用序列名判断出前续作业
# job_pre=`awk -F : '{print $2}' $JOBRELF | awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $0;break;};x-=1;}}'`
# jobrela=`cat $JOBRELF | grep $JOBNAME | tail -n 1 | awk -F ':' '{print $1}'`
# jobrela=`awk -F : '{print $1 "+" $2}' $JOBRELF |awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $1;break;} ;x-=1;}}'`
# if [ ! -z "$jobrela" ];then
#     # 找到后续作业
#     job_succ=`cat $JOBRELF | grep $JOBNAME | tail -n 1 | awk -f ':' 'print $3'`
#     # job_succ=`awk -F : -v jobrela=$jobrela '$1==jobrela {print $3}' $JOBRELF`
# else
#     job_succ=""
# fi

## 获取前续作业序列和后续作业序列（李想，2017-09-12 09:34:39）
echo "get job_pre & job_succ"
echo "jobrelation file is $JOBRELF"
job_pre=`awk -F : '{print $2}' $JOBRELF|grep $JOBNAME`
job_succ=`cat $JOBRELF|grep $JOBNAME|awk -F ':' '{print $3}'|tail -n 1`

echo "this is job_pre $job_pre"
echo "this is job_secc $job_secc"

## 判断是否存在后续作业
if [ ! -z "$job_succ" ]; then

    itemid=1
    succflag=1

    ## 循环判断前续作业是否成功完成
    while :
    do
        job_pre_item=`echo $job_pre | awk -F + -v i=$itemid '{print $i}'`
        if [ -z "$job_pre_item" ]; then
            break;
        fi
        # 判断前续作业是否完成，全部判断成功则进行后续作业
        joblststatus=`awk -F : -v i=$job_pre_item '$2 == i && $3 == 0 {jobstatus=$7;next;} END {print jobstatus}' $RUNLOG`
        # 如果作业未完成或者未成功，则不进行后续作业
        if [ -z "$joblststatus" -o ! $joblststatus -eq 0 ]; then
            succflag=0
            break;
        fi
        itemid=`expr $itemid + 1`   
    done
    
    ## 后续作业执行条件满足，调度后续作业
    ## 用来创建调度文件夹，该文件夹用途是作为调度锁功能，只允许一个作业创建文件夹
    schedulefile=`cat "$JOBRELF" | grep "$JOBNAME" | tail -n 1 | awk -F ':' '{print $1}'`
    # 李想，2017-09-12 09:57:09 

    # 临时增加，忽略错误作业 
    # succflag=1 ##正式上线需要去掉
    
    if [ $succflag -eq 1 ]; then
        if [ ! -d $LOGPATH/$BATCHNO/$schedulefile ]; then
            mkdir $LOGPATH/$BATCHNO/$schedulefile
            if [ $? -eq 0 ]; then
                ## 循环执行后续作业
                itemid=1
                while :
                do
                    job_succ_item=""
                    job_succ_item=`echo $job_succ | awk -F '|' -v i=$itemid '{print $i}'`
                    if [ -z "$job_succ_item" ]; then
                        break;
                    fi

                    lsdate=`date +%Y%m%d_%H%M%S`                  
                    
                    jobid=1

                    ## 提交作业
                    $ETLHOME/sh/submit_job.sh \
                        ${job_succ_item} \
                        $jobid \
                        $BATCHNO \
                        >>$JOBLSTLOG

                    if [ $? -eq 0 ]; then
                        echo "$BATCHNO:$job_succ_item:$lsdate:调度成功" \
                             >>$SCHLOG
                    else
                        echo "$BATCHNO:$job_succ_item:$lsdate:调度失败" \
                             >>$SCHLOG
                    fi
                    itemid=`expr $itemid + 1`
                done
            else
                echo "$BATCHNO:$CURJOB:$lsdate:后续作业序列已被调度,忽略后续调度" \
                     >>$SCHLOG
            fi
        else
            ## 创建文件夹可作业调度锁
            echo "$BATCHNO:$CURJOB:$lsdate:后续作业序列已被其他作业调度,后续调度取消" \
                 >>$SCHLOG
        fi
    else
        echo "$BATCHNO:$CURJOB:$lsdate:后续作业序列调度条件不满足，后续调度不能执行" \
             >>$SCHLOG
    fi
else 
    echo "$BATCHNO:$CURJOB:$lsdate:无后续作业序列" >>$SCHLOG
    if [ -f $LOGPATH/running.flag ]; then
        rm $LOGPATH/running.flag 
    fi
fi   
