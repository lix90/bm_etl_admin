#! /bin/sh

###$1-job文件名称  
###$2-batchno 
###$3-执行Job起始序号
###$4-etl type
###$5-执行Job结束序号
###$6-最大重试次数,可选项，如不选默认值为5次
###$7-重试休眠时间，单位：秒，可选项，如不选默认值为12

### ----------------------------------------------------------------------
### 参数检查
### ----------------------------------------------------------------------

if [ -z "$1" ]; then  
   echo "ERROR:PARAM1 MUST SPECIFIED." 
   exit 1
fi
if [ -z "$2" ]; then
   echo "ERROR:PARAM2 MUST SPECIFIED." 
   exit 1
fi
if [ -z "$3" ]; then
   echo "ERROR:PARAM3 MUST SPECIFIED." 
   exit 1
fi
if [ -z "$5" ]; then
   maxjobid=10000
else
   maxjobid=$5
fi  
if [ $3 -gt $maxjobid ]; then
   echo "ERROR:PARAM3 MUST GT PARAM5." 
   exit 1
fi
if [ -z "$6" ]; then
   maxretrycnt=5 
else
   maxretrycnt=$6
fi
if [ -z "$7" ]; then
   intervaltime=12 
else
   intervaltime=$7
fi

locktimeout=300
etltype=$4
if [ "$etltype" == "1" -o -z "$etltype" ]; then
   ddflag=""            
elif [ "$etltype" == "2" ]; then
   ddflag="_onlinedwn"
elif [ "$etltype" == "3" ]; then
   ddflag="_mthend"
elif [ "$etltype" == "4" ]; then
   ddflag="_mthend2"
elif [ "$etltype" == "5" ]; then
   ddflag="_mthend3"
elif [ "$etltype" == "6" ]; then
   ddflag="_daybefore"
elif [ "$etltype" == "7" ]; then
   ddflag="_daybefore2"
elif [ "$etltype" == "8" ]; then
   ddflag="_batchdwn1"
elif [ "$etltype" == "9" ]; then
   ddflag="_batchdwn2"
elif [ "$etltype" == "10" ]; then
   ddflag="_batchdwn3" 
elif [ "$etltype" == "12" ]; then
   ddflag="_realtime_ys"         
fi 
export jobpath=$ETLHOME/shell/job${ddflag}
host=`hostname`

echo "lock">$ETLHOME/etllog/loglock.lck

datectlfile=$ETLHOME/shell/config/etl_datectl_param
jobschfile=$ETLHOME/shell/config/etl_job
binfiledirectory=`cat /.dshome`/bin
lsdate=`date +%Y%m%d_%H%M%S`
jobstarttime=$lsdate
joblist=$jobpath/$1
batchno=$2
curjob=$1
procid=$$


###检查相关文件是否存在
if [ ! -f $joblist ]; then
   print "\n文件$joblist不存在，作业${curjob}启动失败." >>$ETLHOME/etllog/run.err
   exit 2
fi


###创建作业序列执行日志存放目录
if [ ! -d $ETLHOME/etllog/${batchno} ]; then
   mkdir  $ETLHOME/etllog/${batchno}
fi
if [ ! -d $ETLHOME/etllog/${batchno}/${curjob}_$lsdate ]; then
      mkdir  $ETLHOME/etllog/${batchno}/${curjob}_$lsdate/
      if [ ! $? -eq 0 ]; then
         print "\n创建目录$ETLHOME/etllog/${batchno}/${curjob}_$lsdate失败，作业${curjob}启动失败." >>$ETLHOME/etllog/run.err
         exit 4
      else
         print "$ETLHOME/etllog/${batchno}/${curjob}_$lsdate" >> $ETLHOME/etllog/${batchno}/runlog.lst
      fi
fi
logpath=$ETLHOME/etllog/${batchno}/${curjob}_$lsdate


###获得对run.log文件的写数据锁
getlock(){
   locktime=0
   while :
   do
      mv $ETLHOME/etllog/loglock.lck $ETLHOME/etllog/loglock.lck${procid} 2>/dev/null
      if [ ! $? -eq 0 ]; then
         sleep 1
         locktime=`expr $locktime + 1`
         if [ $locktime = $locktimeout ]; then
            lsdate22=`date +%Y%m%d_%H%M%S`
            echo "$lsdate22:作业序列${curjob}－作业$jobunit申请写日志锁超时，调度程序出现严重错误."\
                 >>$ETLHOME/etllog/${batchno}/joblst.run
            exit 4000
         fi
      else
         break  
      fi
   done
}

###释放run.log文件的写数据锁
releaselock(){
  mv $ETLHOME/etllog/loglock.lck${procid} $ETLHOME/etllog/loglock.lck 2>/dev/null
  if [ ! $? -eq 0 ]; then
     lsdate22=`date +%Y%m%d_%H%M%S`
     echo "$lsdate22:作业序列${curjob}－作业$jobunit释放写日志锁超时，调度程序出现严重错误."\
          >>$ETLHOME/etllog/${batchno}/joblst.run
     exit 4001
  else
     break  
  fi
}


###检查JOB状态
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

###检查执行JOB的状态
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

###此函数作废
encrypt_pwd(){
   cryptstr=$1
   id=1
   encryptstr=""
   while :
   do
      itemstr=`echo $cryptstr|awk -v itemid=$id '{print $itemid}'`
      if [ -z "$itemstr" ]; then
         break
      else
         itemvalstr1=`echo $itemstr|awk -F = '{print $1}'`
         itemvalstr2=`echo $itemstr|awk -F = '{print $2}'`
         if [ -z "$itemvalstr2" ]; then
            encryptstr="$encryptstr $itemstr"
            id=`expr $id + 1`
            continue
         else
            encrypt_flag=`echo $itemvalstr1|awk  '($1 ~ /pwd/) || ($1 ~ /password/) {print 1}'`
            if [ ! -z "$encrypt_flag" ]; then
               itemvalstr2=`eval echo $itemvalstr2`
               encrypt_pwd=`$ETLHOME/shell/crypt.sh $itemvalstr2 decrypt` 
               encryptstr="$encryptstr $itemvalstr1=$encrypt_pwd"
            else
               encryptstr="$encryptstr $itemstr"
            fi
         fi   
      fi
      id=`expr $id + 1`
   done
}


exec_dsjob(){
   runstatus=0
   starttime=`date +%Y%m%d_%H%M%S` 
   ##获取写日志锁
   getlock        
   print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:等待运行:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
   ###释放写日志锁
   releaselock
   
   ##Reset JOB    
   checkjobstatus1
   if [  $jobstatus -eq 3 -o  $jobstatus -eq 97 ]; then
      logfilename=${logfile}_reset
      eval ${binfiledirectory}/dsjob -server ${DSSERVER} -user ${DSUSER} -password ${DSPASSWORD} -run -mode RESET -wait ${paramlist} ${DSPROJECT} ${jobunit} 2>&1 > ${logfilename}
      endtime=`date +%Y%m%d_%H%M%S`
      if [ ! $? -eq 0 ]; then
         ##获取写日志锁
         getlock
         print "${batchno}:${curjob}:$jobunit:$starttime:$endtime:RESET Failure:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
         ###释放写日志锁
         releaselock
         runstatus=$jobid
      else
         ##获取写日志锁
         getlock
         print "${batchno}:${curjob}:$jobunit:$starttime:$endtime:RESET Successful:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
         ###释放写日志锁
         releaselock
      fi
   fi
   
   
   ###执行JOB
   if [ "$runstatus" = "0" ]; then
      
      jobendtime=`date +%Y%m%d_%H%M%S`
      ##获取写日志锁
      getlock
      print "${batchno}:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid" >>$ETLHOME/etllog/${batchno}/run.log 
      ###释放写日志锁
      releaselock
      logfilename=${logfile}_runstatus
      ##print "eval ${binfiledirectory}/dsjob -server ${DSSERVER} -user ${DSUSER} -password ${DSPASSWORD} -run -wait ${paramlist} ${DSPROJECT} ${jobunit}"
      ##获取写日志锁
      getlock
      print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid" >>$ETLHOME/etllog/${batchno}/run.log 
      ###释放写日志锁
      releaselock 
      eval ${binfiledirectory}/dsjob -server ${DSSERVER} -user ${DSUSER} -password ${DSPASSWORD} -run -wait ${paramlist} ${DSPROJECT} ${jobunit} 2>&1 > ${logfilename}
      checkjobstatus2 ${logfilename}
      endtime=`date +%Y%m%d_%H%M%S`
      if [ ! $jobstatus -eq 0 ]; then
         ##获取写日志锁
         getlock
         print "${batchno}:${curjob}:$jobunit:$starttime:$endtime:失败:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
         ###释放写日志锁
         releaselock
         runstatus=$jobid
      else
         ##获取写日志锁
         getlock
         print "${batchno}:${curjob}:$jobunit:$starttime:$endtime:成功:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
         ###释放写日志锁
         releaselock
      fi
   fi
}

exec_shell(){
    runstatus=0
    starttime=`date +%Y%m%d_%H%M%S`  
    if [ -f $shellfile -a -x $shellfile ]; then
       jobendtime=`date +%Y%m%d_%H%M%S`
       ##获取写日志锁
       getlock
       print "${batchno}:${curjob}:0:$jobstarttime:$jobendtime:运行中:$jobid" >>$ETLHOME/etllog/${batchno}/run.log 
       print "${batchno}:${curjob}:$jobunit:$starttime:$starttime:运行中:$jobid" >>$ETLHOME/etllog/${batchno}/run.log  
       ###释放写日志锁
       releaselock
       if [ -z "${paramlist}" ]; then
          $shellfile
       else
          $shellfile ${paramlist}
       fi
       jobstatus=$?
       endtime=`date +%Y%m%d_%H%M%S`
       if [ $jobstatus -eq 0 ]; then
          ##获取写日志锁
          getlock
          print "${batchno}:${curjob}:$jobunit:$starttime:$endtime:成功:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
          ###释放写日志锁
          releaselock
       else
          ##获取写日志锁
          getlock
          print "${batchno}:${curjob}:$jobunit:$starttime:$endtime:失败:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
          ###释放写日志锁
          releaselock
          runstatus=$jobid
       fi
    else
       jobstatus=999
       endtime=`date +%Y%m%d_%H%M%S`
       ##获取写日志锁
       getlock
       print "${batchno}:${curjob}:$jobunit:$starttime:$endtime:文件不存在或不可执行:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
       ###释放写日志锁
       releaselock
       runstatus=$jobid
    fi
}

###顺序执行当前作业序列中的JOB
jobid=$3

###装载环境变量
. $ETLHOME/shell/load_env.sh
if [ ! $? -eq 0 ]; then
   starttime=`date +%Y%m%d_%H%M%S`
   ##获取写日志锁
   getlock      
   print "${batchno}:${curjob}:0:$starttime:$starttime:失败:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
   ###释放写日志锁
   releaselock
   exit 1001
fi
###encrypt_pwd=`$ETLHOME/shell/crypt.sh ${DSPASSWORD} decrypt`
###DSPASSWORD=$encrypt_pwd


while :
do
    ##如果当前执行JOB对应的序号大于执行截止JOB序号则退出执行
    if [ $jobid -gt $maxjobid ]; then
       break
    fi
    ###顺序读取作业序列中每一job
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
       ##获取写日志锁
       getlock      
       print "${batchno}:$curjob:$jobunit:$starttime:$starttime:本次不需调度，跳过此作业:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
       ###释放写日志锁
       releaselock
       jobid=`expr $jobid + 1`
       continue;
    fi
    
    paramlist=`awk -F : -v jobid=$jobid '$1==jobid {print $3}' $joblist`
    ###encrypt_pwd "$paramlist"
    ###paramlist=$encryptstr
    
    if [ "$jobtype" = "dsjob" ]; then
        ctlid=`awk -F : -v jobid=$jobid '$1==jobid {print $4}' $joblist` 
        
        ###读取当前待执行JOB对应的加载日期范围
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
              ##获取写日志锁
              getlock      
              print "${batchno}:$curjob:$jobunit:$starttime:$starttime:重试次数超过${maxretrycnt}:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
              print "${batchno}:$curjob:$jobunit:$starttime:$starttime:失败:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
              ###释放写日志锁
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
              ##获取写日志锁
              getlock      
              print "${batchno}:$curjob:$jobunit:$starttime:$starttime:重试次数超过${maxretrycnt}:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
              print "${batchno}:$curjob:$jobunit:$starttime:$starttime:失败:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
              ###释放写日志锁
              releaselock           
              break
           else
              seqcnt=`expr $seqcnt + 1`
              sleep $intervaltime
           fi
        done      
        
    fi
    if [ ! "$runstatus" = "0"  ]; then
       print "$curjob,$jobid" >$ETLHOME/etllog/restart${ddflag}
       break
    else 
       jobid=`expr $jobid + 1`
    fi
done
###print "runst:$runstatus"
###输出当前作业序列日志
jobendtime=`date +%Y%m%d_%H%M%S`
if [ $runstatus -eq 0 ]; then
   ##获取写日志锁
   getlock
   print "${batchno}:$curjob:0:$jobstarttime:$jobendtime:成功:0" >>$ETLHOME/etllog/${batchno}/run.log
   ###释放写日志锁
   releaselock
   exit 0
else
   ##获取写日志锁
   getlock
   print "${batchno}:$curjob:0:$jobstarttime:$jobendtime:失败:$jobid" >>$ETLHOME/etllog/${batchno}/run.log
   ###释放写日志锁
   releaselock
   exit 100
fi



