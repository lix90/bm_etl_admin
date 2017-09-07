#!/bin/sh

# $1-js_46.def+1, 作业名称加序号, 作业为js_46.def, 序号为1
# $2-0, 调度模式, 0为正常模式

LOGPATH=$TASKPATH/log
if [ ! -d $LOGPATH ]; then
    echo "LOGPATH does not exist, program creates one."
    mkdir $LOGPATH
fi

# 启动作业序列
echo "***************"
echo "ETL TO BE START"
echo "***************"
echo ""
echo "PRESS [Y|y] KEY TO CONTINUE, [N|n] KEY TO CANCEL......"
read a

case $a in
    Y|y)
        echo ""
        echo "PLEASE INPUT JOB RELATION FILE + JOB ID (xxx.rel+1)"
        read jobs
        echo "PLEASE INPUT SCHEDULE MODE TYPE (1-breakpoint; 0-normal)"
        read schmode
        # echo "$jobs $schmode"
        $./start_task.sh $jobs $schmode
        if [ $? -eq 0 ]; then
            echo ""
            echo "TASK *SUBMITTED*!"
            echo "PRESS [ENTER] KEY TO CONTINUE......"
            read key_enter
        else
            echo ""
            echo "TASK *FAILED*!"
            echo ""
            exit
        fi
        ;;
    N|n)
        echo ""
        echo "TASK *CANCELD*!"
        echo ""
        exit
        ;;
esac
