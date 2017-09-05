#! /bin/sh

### $1-调度模式：1－断点加载 0-正常调度
### $2-作业序列名称+job序号：多个作业序列间用':'分隔
### $3-批次类型：
###
### 1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN
### 5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON
### 8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)
### 10-BATCH DATADOWN3(AFTER L2CALBAK) ,12-YS PERF REAL TIME ETL
###
### 默认值为1
### $4-是否装载环境变量（可选项）

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

if [ "$1" = "0" -o "$1" = "1" ]
   then
      printf "当前调度主服务器：$host\n"
   else
      printf "ERROR:参数1取值$1无效，1-断点加载 0-正常调度.\n"
      exit 2
   fi

if [ -z "$2" ]; then
    printf "ERROR:未指定待执行作业序列及JOB顺序号（参数2）.\n"
    exit 3
fi

etltype=$3
if [ -z "$etltype" -o "$etltype" = "1" ]; then
   ddflag=""
elif [ "$etltype" = "2" ]; then
   ddflag="_onlinedwn"
elif [ "$etltype" = "3" ]; then
   ddflag="_mthend"
elif [ "$etltype" = "4" ]; then
   ddflag="_mthend2"
elif [ "$etltype" = "5" ]; then
   ddflag="_mthend3"
elif [ "$etltype" = "6" ]; then
   ddflag="_daybefore"
elif [ "$etltype" = "7" ]; then
   ddflag="_daybefore2"
elif [ "$etltype" = "8" ]; then
   ddflag="_batchdwn1"
elif [ "$etltype" = "9" ]; then
   ddflag="_batchdwn2"
elif [ "$etltype" = "10" ]; then
   ddflag="_batchdwn3"
else
   printf "ERROR:参数3取值($etltype)无效.\n"
   exit 4
fi

if [ ! -z "$4" ]; then
   homepath=/home/`whoami`
   envsetfile=${homepath}/.envset
   . ${envsetfile}
fi
export jobrelation=$ETLHOME/shell/${ddflag}/js_relation.def
export jobpath=$ETLHOME/shell/${ddflag}
host=`hostname`

# 加锁
echo "lock">$ETLHOME/etllog/loglock.lck

### --------------------------------------------------
### 调度开始
### --------------------------------------------------

# 断点加载模式
if [ "$1" = "1" ]; then
    # 读取上次正常加载的批次号   
    if [ -f $ETLHOME/etllog/batchno${ddflag}.cfg ]; then
        batchno=`awk '{print $1}' $ETLHOME/etllog/batchno${ddflag}.cfg`
    else
        # 如果找不到上次加载的批次号则无法启动断点加载    
        printf "文件$ETLHOME/etllog/batchno${ddflag}.cfg不存在，无法断点加载.\n"
        exit 4
    fi   
    # 正常加载模式
else
    batchno=`date +%Y%m%d_%H%M%S`   
fi

# 清除该批次号关系文件
eval rm -r $ETLHOME/etllog/${batchno}/relation* 2>/dev/null

# 获取当前系统日期
lsdate=`date +%Y%m%d_%H%M%S`

# 创建程序运行标志文件，以防止调度再次被触发
if [ -f $ETLHOME/etllog/running${ddflag}.flag ]; then
   printf "当前已有调度任务在运行，无法重复启动调度任务.\n"
   exit 9
else
    echo "running" >$ETLHOME/etllog/running${ddflag}.flag
fi

# 删除调度错误日志文件
if [ -f $ETLHOME/etllog/run.err ] 
then
    rm $ETLHOME/etllog/run.err
fi

# 删除强制中断文件
if [ -f $ETLHOME/etllog/halt${ddflag}.flag ] 
then
    rm $ETLHOME/etllog/halt${ddflag}.flag
fi

# 清除调度控制文件
schedulefile=`awk -F : '{print $1 "+" $2}' $jobrelation | awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $1} else {print ""};x-=1;}}'`
echo $schedulefile

if [ ! -z "$schedulefile" -a -d $ETLHOME/etllog/$batchno/$schedulefile ]; then
    rm  $ETLHOME/etllog/$batchno/$schedulefile
fi

# 创建当前批次日志目录
if [ ! -d $ETLHOME/etllog/$batchno ]; then
   mkdir $ETLHOME/etllog/$batchno
   if [ ! $? -eq 0 ]; then
      echo "\n创建目录$ETLHOME/etllog/$batchno失败，调度启动失败." >$ETLHOME/etllog/run${ddflag}.err
      exit 4
   fi      
fi

# 根据加载类型初始化模块调度日志文件
if [ "$1" = "0" ]
then
   printf "\n******正常加载起始时间:$lsdate******\n" >>$ETLHOME/etllog/$batchno/schedule.log
else
   printf "\n******断点加载起始时间:$lsdate******\n" >>$ETLHOME/etllog/$batchno/schedule.log
fi

# 装载环境变量
. $ETLHOME/shell/load_env.sh
if [ ! $? -eq 0 ]; then
   printf "\n$lsdate : 装载环境变量失败，无法继续启动调度任务.\n" >>$ETLHOME/etllog/$batchno/schedule.log
   exit 1001
fi

### --------------------------------------------------
### 提交主调度程序
### --------------------------------------------------

## 记录当前批次号,供断点加载模式使用
echo $batchno>$ETLHOME/etllog/batchno${ddflag}.cfg
x=1
## 调度待执行作业序列   
while :
do
    ## 读取作业序列（通过awk文本处理）
    # 执行项目
    execitem=`echo $2 | awk -F ':' -v itemid=$x '{print $itemid}'`
    # 作业列表名
    jblstname=`echo $execitem | awk -F '+' '{print $1}'`
    # 作业ID
    jobid=`echo $execitem | awk -F '+' '{print $2}'`

    ## 如果遇到空的作业序列，当前调度结束
    if [ -z "$jblstname" ]; then
       break;
    fi

    ## 必须指定待执行作业序列的执行JOB顺序号
    if [ -z "$jobid" ]; then
       printf "\n未给$jblstname指定执行JOB顺序号.\n" >>$ETLHOME/etllog/$batchno/schedule.log
       exit 5
    fi
    
    ## 调度当前作业序列 
    lsdate=`date +%Y%m%d_%H%M%S`
    # 提交js
    $ETLHOME/shell/submit_js.sh $jblstname $batchno $jobid ${ddflag}
    if [ $? -eq 0 ]; then
       echo "$batchno:$jblstname:$jobid:$lsdate:调度成功" >>$ETLHOME/etllog/$batchno/schedule.log
    else
       echo "$batchno:$jblstname:$jobid:$lsdate:调度失败" >>$ETLHOME/etllog/$batchno/schedule.log
    fi
    x=`expr $x + 1` 
done


