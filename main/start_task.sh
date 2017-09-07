#! /bin/sh

### $1-作业序列名称+job序号：多个作业序列间用':'分隔
### $2-调度模式：1－断点加载 0-正常调度, 默认为零
### $3-是否装载环境变量（可选项）

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

# 批次号为时间

# 作业序列名称
jobs=$1
jobrel=`awk -F + '{print $1}' $jobs`
jobid=`awk -F + '{print $2}' $jobs`
# 调度模式
schmode=$2
# 批次类型
# etl_type=${3:-1}
# 装载环境变量
setenv=${3:-1}

# 检查作业参数
if [ -z "$jobs" -o -z "$jobrel" -o -z "$jobid" ]; then
    printf "ERROR:未指定待执行作业序列及JOB顺序号（参数1）.\n"
    exit 3
fi

# 检查批次参数
if [ "$schmode" = "0" -o "$schmode" = "1" ]; then
    printf "当前调度主服务器：$(hostname)\n"
else
    printf "ERROR:参数2取值$schmode无效，合法参数为1-断点加载 0-正常调度.\n"
    exit 2
fi

# 装载环境变量
if [ "$setenv" = "1" ]; then 
    . "/home/$(whoami)/.envset"
fi

# 任务文件
LOGPATH=$TASKPATH/log
JOBPATH=$TASKPATH/job
RELPATH=$TASKPATH/rel
SQLPATH=$TASKPATH/sql
RELFILE=$RELPATH/$jobrel

# 加锁
echo "lock" > $LOGPATH/loglock.lck

### --------------------------------------------------
### 调度开始
### --------------------------------------------------

# 断点加载模式
if [ "$schmode" = "1" ]; then

    # 读取上次正常加载的批次号
    # 批次号命名
    if [ -f $LOGPATH/batchno.cfg ]; then
        batchno=`awk '{print $1}' $LOGPATH/batchno.cfg`
    else
        # 如果找不到上次加载的批次号则无法启动断点加载
        # 断点文件命名
        printf "文件$LOGPATH/batchno.cfg不存在，无法断点加载.\n"
        exit 4
    fi
else
    # 新建批次号
    batchno=`date +%Y%m%d_%H%M%S`
fi

# 清除该批次号关系文件
eval rm -r $LOGPATH/${batchno}/relation* 2>/dev/null

# 获取当前系统日期
lsdate=`date +%Y%m%d_%H%M%S`

# 创建程序运行标志文件，以防止调度再次被触发
if [ -f $LOGPATH/running.flag ]; then
    printf "当前已有调度任务在运行，无法重复启动调度任务.\n"
    exit 9
else
    echo "running" >$LOGPATH/running.flag
fi

# 删除调度错误日志文件
if [ -f $LOGPATH/run.err ]; then
    rm $LOGPATH/run.err
fi

# 删除强制中断文件
if [ -f $LOGPATH/halt.flag ]; then
    rm $LOGPATH/halt.flag
fi

# 清除调度控制文件
# ----
# 问题
# ----
schedulefile=`awk -F : '{print $1 "+" $2}' $jobrelation | awk -F + -v joblist=$1 '{x=NF;while (x>0) {if ($x == joblist) {print $1} else {print ""};x-=1;}}'`
echo $schedulefile

if [ ! -z "$schedulefile" -a -d $LOGPATH/$batchno/$schedulefile ]; then
    rm  $LOGPATH/$batchno/$schedulefile
fi

# 创建当前批次日志目录
if [ ! -d $LOGPATH/$batchno ]; then
    mkdir $LOGPATH/$batchno
    if [ ! $? -eq 0 ]; then
        echo "\n创建目录$LOGPATH/$batchno失败，调度启动失败." \
             >$LOGPATH/run.err
        exit 4
    fi
fi

# 根据加载类型初始化模块调度日志文件
if [ "$schmode" = "0" ]; then
    printf "\n******正常加载起始时间:$lsdate******\n" \
           >>$LOGPATH/$batchno/schedule.log
else
    printf "\n******断点加载起始时间:$lsdate******\n" \
           >>$LOGPATH/$batchno/schedule.log
fi

# 装载环境变量, why
# . ./load_env.sh
# if [ ! $? -eq 0 ]; then
#     printf "\n$lsdate : 装载环境变量失败，无法继续启动调度任务.\n" \
    #            >>$LOGPATH/$batchno/schedule.log
#     exit 1001
# fi

### --------------------------------------------------
### 提交主调度程序
### --------------------------------------------------

## 记录当前批次号,供断点加载模式使用
echo $batchno > $LOGPATH/batchno.cfg
## 重新开启（x=1）作业序列
# 计数器
x=1

## 调度待执行作业序列
while :
do
    ## 读取作业序列 
    # 执行项目 = 作业列表名+作业ID
    execitem=`echo $jobs | awk -F ':' -v itemid=$x '{print $itemid}'`
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
        printf "\n未给$jblstname指定执行JOB顺序号.\n" \
               >>$LOGPATH/$batchno/schedule.log
        exit 5
    fi
    
    ## 调度当前作业序列 
    lsdate=`date +%Y%m%d_%H%M%S`

    # 提交job
    ./submit_job.sh $jblstname $jobid $batchno

    if [ $? -eq 0 ]; then
        echo "$batchno:$jblstname:$jobid:$lsdate:调度成功" \
             >>$LOGPATH/$batchno/schedule.log
    else
        echo "$batchno:$jblstname:$jobid:$lsdate:调度失败" \
             >>$LOGPATH/$batchno/schedule.log
    fi

    x=`expr $x + 1`
    
done


