#! /bin/sh

### ----------------------------------------------------------------------
### 命令行ETL调度
### - 启动ETL任务
### - 重启ETL任务
### - 监控ETL任务

LOGPATH=$TASKPATH/log

trap "$ETLHOME/sh/start_menu.sh " 2 3
clear

echo "                      安正ETL控制台调度工具 V3.0alpha"
echo "                         1. 启动ETL任务"
echo "                         2. 重启ETL任务"
echo "                         3. 监控ETL任务"
echo "                         4. 终止ETL任务"
echo "                         0. 推出ETL控制台"
echo "                      请输入序号: "

read ans
clear

case $ans in
    1) $ETLHOME/sh/etl_start.sh ;;
    2) $ETLHOME/sh/etl_restart.sh ;;
    3) $ETLHOME/sh/etl_monitor.sh ;;
    4) $ETLHOME/sh/etl_halt.sh ;;
    0) if [ -f $LOGPATH/joblstrun.log$$ ]; then
           rm $LOGPATH/joblstrun.log$$
       fi
       exit
       ;;
    *) echo "序号选择出错, 按[ENTER]键继续..."
       read a
       $ETLHOME/start.sh
       ;;
esac

