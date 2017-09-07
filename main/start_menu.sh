#! /bin/sh

### ----------------------------------------------------------------------
### 命令行ETL调度
### - 启动ETL任务
### - 重启ETL任务
### - 监控ETL任务

JOBPATH=$TASKPATH/job
LOGPATH=$TASKPATH/log

if [ ! -d $LOGPATH ]; then
    echo "$LOGPATH DOES NOT EXIST, PROGRAM CREATES ONE."
    mkdir $LOGPATH
fi

trap "rm $JOBPATH/schedule*.lst 2>/dev/null;./start_menu.sh " 2 3
clear

echo "                      BM ETL ADMIN DESKTOP V3.0"
echo "                         1. ETL START"
echo "                         2. ETL RESTART"
echo "                         3. ETL MONITOR"
echo "                         0. EXIT"
echo "                      INPUT MENUITEM ID: "

read ans
clear

case $ans in
    1) ./etl_start.sh
       ;;
    2) ./etl_restart.sh
       ;;
    3) ./etl_monitor.sh
       ;;
    0) if [ -f $LOGPATH/joblstrun.log$$ ]; then
           rm $LOGPATH/joblstrun.log$$
       fi
       exit
       ;;
    *) echo "ERROR CHOICE, PRESS ENTER KEY TO CONTINUE......"
       read a
       ;;
esac

