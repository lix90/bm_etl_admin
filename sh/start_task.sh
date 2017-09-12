#! /bin/sh

### $1-作业序列名称+job序号：多个作业序列间用':'分隔
### $2-调度模式：1－断点加载 0-正常调度, 默认为零
### $3-是否装载环境变量（可选项）

### --------------------------------------------------
### 参数检查
### --------------------------------------------------

# 批次号为时间

# 作业序列名称
# 作业序列名=<作业文件名>+<作业序号>:<作业文件名>+<作业序号>:...
JOBPLUSID=$1
# echo "$JOBPLUSID"
# 调度模式
SCHMODE=$2
# 装载环境变量
SETENV=${3:-1}

# 任务文件
LOGPATH=$TASKPATH/log
JOBPATH=$TASKPATH/job
SQLPATH=$TASKPATH/sql
JOBRELF=$JOBPATH/js.rel

# 检查作业参数
if [ -z "$JOBPLUSID" ]; then
    echo "ERROR:未指定待执行作业序列及作业序号（参数1)."
    exit 3
fi

# 检查批次参数
if [ "$SCHMODE" = "0" -o "$SCHMODE" = "1" ]; then
    echo "当前调度主服务器：$(hostname)"
else
    echo "ERROR:参数2取值$SCHMODE无效，合法参数为1-断点加载 0-正常调度."
    exit 2
fi

# 装载环境变量
# . $ETLHOME/sh/load_env.sh

# 加锁
echo "lock" > $LOGPATH/lock.lck

###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
### 调度开始
###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# 断点加载模式
if [ "$SCHMODE" = "1" ]; then

    # 读取上次正常加载的批次号
    # 批次号命名
    # 批次号在start_task.sh写入
    if [ -f $LOGPATH/batchno.flag ]; then
        BATCHNO=`awk '{print $1}' $LOGPATH/batchno.flag`
    else
        # 如果找不到上次加载的批次号则无法启动断点加载
        # 断点文件命名
        echo "文件$LOGPATH/batchno.flag不存在，无法断点加载."
        exit 4
    fi
else
    # 新建批次号
    BATCHNO=`date +%Y%m%d_%H%M%S`
fi

# 清除该批次号关系文件
# eval rm -r $LOGPATH/$BATCHNO/relation* 2>/dev/null

# 获取当前系统日期
NOW=`date +%Y%m%d_%H%M%S`

# 创建程序运行标志文件，以防止调度再次被触发
if [ -f $LOGPATH/running.flag ]; then
    printf "当前已有调度任务在运行，无法重复启动调度任务.\n"
    exit 9
else
    echo "running" >$LOGPATH/running.flag
fi

# 删除调度错误日志文件
if [ -f $LOGPATH/err.log ]; then
    rm $LOGPATH/err.log
fi
if [ -f $LOGPATH/halt.flag ]; then
    rm $LOGPATH/halt.flag
fi

##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## 此处代码的目的是清除作为调度锁的文件目录
# schedulefile=`cat "$JOBRELF" | grep "$JOBNAME" | tail -n 1 | awk -F ':' '{print $1}'`
# echo $schedulefile
# if [ ! -z "$schedulefile" -a -d $LOGPATH/$BATCHNO/$schedulefile ]; then
# rm  $LOGPATH/$BATCHNO/$schedulefile
# fi
##<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

## 创建当前批次日志目录
if [ ! -d $LOGPATH/$BATCHNO ]; then
    mkdir $LOGPATH/$BATCHNO
    if [ ! $? -eq 0 ]; then
        echo "创建目录$LOGPATH/$BATCHNO失败，调度启动失败." \
             >$LOGPATH/err.log
        exit 4
    fi
fi

## 根据加载类型初始化模块调度日志文件
if [ "$SCHMODE" = "0" ]; then
    echo "******正常加载起始时间:$NOW******" \
         >>$LOGPATH/$BATCHNO/schedule.log
else
    echo "******断点加载起始时间:$NOW******" \
         >>$LOGPATH/$BATCHNO/schedule.log
fi


###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## 提交主调度程序
## 记录当前批次号,供断点加载模式使用
echo $BATCHNO > $LOGPATH/batchno.flag

## 重新开启（x=1）作业序列
# <作业文件名>+<作业序号>:<作业文件名>+<作业序号>
# 计数器
x=1

## 调度待执行作业序列
while :
do
    ## 读取作业序列 
    # 执行项目 = 作业列表名+作业ID
    execitem=`echo "$JOBPLUSID" | awk -F : -v i=$x '{print $i}'` 
    # 作业列表名
    jobname=`echo "$execitem" | awk -F '+' '{print $1}'` 
    # 作业ID
    jobid=`echo "$execitem" | awk -F '+' '{print $2}'`

    ## 如果遇到空的作业序列，当前调度结束
    if [ -z "$jobname" -o "$jobname" == "" ]; then 
        break 
    fi

    ## 必须指定待执行作业序列的执行JOB顺序号
    if [ -z "$jobid" ]; then
        echo "未给$jobname指定执行JOB顺序号." \
             >>$LOGPATH/$BATCHNO/schedule.log 
        exit 5
    fi
    
    ## 调度当前作业序列 
    NOW=`date +%Y%m%d_%H%M%S`

    # 提交job
    $ETLHOME/sh/submit_job.sh $jobname $jobid $BATCHNO

    if [ $? -eq 0 ]; then
        echo "$BATCHNO:$jobname:$jobid:$NOW:调度成功" \
             >>$LOGPATH/$BATCHNO/schedule.log
    else
        echo "$BATCHNO:$jobname:$jobid:$NOW:调度失败" \
             >>$LOGPATH/$BATCHNO/schedule.log
        exit 6
    fi

    x=`expr $x + 1` 
    
done
