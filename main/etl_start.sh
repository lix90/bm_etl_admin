#!/bin/sh

# $1-js_46.def+1, 作业名称加序号, 作业为js_46.def, 序号为1
# $2-0, 调度模式, 0为正常模式
# $3-1, 批次类型, 1为ETL

job_name=$1

echo "\nETL TO BE START,PRESS ENTER KEY TO CONTINUE......\c"
read a
if [ "$a" = "" ]; then
    $ETLHOME/shell/start_task.sh $job_name
    if [ $? -eq 0 ]; then
        echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c"
        read key_enter
    else
        echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c"
        read key_enter
    fi
else
    echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c"
    read a
fi
