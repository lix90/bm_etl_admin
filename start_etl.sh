#! /bin/sh

### ----------------------------------------------------------------------
### 命令行ETL调度
### - 启动ETL任务
### - 重启ETL任务
### - 监控ETL任务

LOGPATH=$TASKPATH/log
clear

echo ""
echo "          ******************************"
echo "               欢迎使用安正ETL 调度平台"
echo "          ******************************"
echo ""
# echo "          是否需要加载环境变量？[Y|N]"
# echo ""
# read ans

# if [ $ans = "Y" -o $ans = "y" -o $ans = "" ]; then
. $HOME/.envset
# eval $ETLHOME/sh/load_env.sh
# fi
# fi

echo "                    1. 启动"
echo "                    2. 重启"
echo "                    3. 监控"
echo "                    4. 终止"
echo "                    5. 重置"
echo "                    0. 退出"
echo ""
echo "          请输入序号: "

read ans

case $ans in
    1) $ETLHOME/sh/etl_start.sh ;;
    2) $ETLHOME/sh/etl_restart.sh ;;
    3) $ETLHOME/sh/etl_monitor.sh ;;
    4) $ETLHOME/sh/etl_halt.sh ;;
    5) $ETLHOME/sh/etl_reset.sh ;;
    0) if [ -f $LOGPATH/joblstrun.log$$ ]; then
           rm $LOGPATH/joblstrun.log$$
       fi
       exit
       ;;
    *) echo "序号选择出错, 按[ENTER]键继续..."
       read a
       ;;
esac
