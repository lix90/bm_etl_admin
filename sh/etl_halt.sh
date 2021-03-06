#!/bin/sh

## 当用户终止程序，重新启动start_menu
trap "$ETLHOME/start_etl.sh " 2 3

# 中断作业调度
LOGPATH=$TASKPATH/log

echo ""
echo "          ***************"
echo "          即将中断ETL作业"
echo "          ***************"
echo ""
echo "     按[ENTER]键立即中断后续作业"
printf "     或者手动输入需要中断的作业序列名: "
echo ""
read jobname
if [ -z "$jobname" ]; then
    echo "当前作业序列完成后后续作业将被取消."
    jobpos=0
else
    echo "按[ENTER]为作业序号默认为0"
    printf "或者手动输入$jobname的中断作业序号: "
    read jobpos
    if [ -z "$jobpos" ]; then
        jobpos=0
    fi
    echo "在${jobname}的${jobpos}作业完成后，后续作业将被取消."
fi
echo "请按[ENTER]键继续......"
read key_enter

# 将作业序列和作业序号写入中断标识
if [ "$key_enter" = "" ]; then
    echo "$jobname+$jobpos"\
         >>$LOGPATH/halt.flag
    echo "中断作业序列和序号已设定成功, 按[ENTER]键继续......"
    read key_enter
    exit
fi
