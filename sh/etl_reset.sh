#!/bin/sh

clear
LOGPATH=$TASKPATH/log

echo ""
echo "          ******************"
echo "          开始重置ETL调度状态"
echo "          ******************"
echo ""
echo "请确保当前任务全部完成, 按[ENTER]键继续......"
read key_enter

if [ "$key_enter" = "" ]; then 
    if [ -f $LOGPATH/running.flag ]; then
        rm $LOGPATH/running.flag
    fi
    if [ -f $LOGPATH/halt.flag ]; then
        rm $LOGPATH/halt.flag
    fi
    echo "重置调度状态*成功*, 请按[ENTER]键继续......"
    read key_enter
fi

$ETLHOME/start_etl.sh
