#!/bin/sh

## 当用户终止程序，重新启动start_menu
trap "$ETLHOME/start_etl.sh " 2 3
clear

LOGPATH=$TASKPATH/log
if [ ! -d $LOGPATH ]; then
    echo "日志路径不存在, 程序将自动创建."
    mkdir $LOGPATH
fi

clear
# 启动作业序列
echo "          ***************"
echo "          即将启动ETL 任务"
echo "          ***************"
echo ""
echo "     按[Y|y]键继续, 按[N|n]键取消......"
read a

case $a in

    Y|y|"") JOBRELF=$TASKPATH/job/js.rel
            ## 默认从头跑js.rel文件
            clear
            if [ -f $JOBRELF ]; then

                echo ""
                echo "已找到作业序列关系文件$JOBRELF"
                echo "是否从头执行作业序列？"
                echo ""
                echo "[Y|y]: 从头执行作业序列"
                echo "[N|n]: 从特定作业开始执行作业序列"
                echo ""
                read ans

                case $ans in

                    Y|y|"") clear
                            echo ""
                            echo "即将从头开始执行作业序列"
                            echo ""
                            jobname=`cat $JOBRELF|grep '^relation'|head -n 1|awk -F : '{print $2}'`
                            jobid=1
                            echo "即将从$jobname+$jobid开始调度作业序列"
                            echo "请按[ENTER]键继续......"
                            echo ""
                            read enter_key

                            $ETLHOME/sh/start_task.sh "$jobname+$jobid" 0

                            ;;

                    N|n) echo ""
                         echo "请输入作业序列文件和序号, 必须包含序列文件和序号."
                         echo "  格式为: <*.job>+<jobid>"
                         echo "     例如:"
                         echo "     n01.job+1"
                         # echo "     n01.job+1:n02.job+1"
                         read jobplusid
                         echo "请指定调用模式 (1-断点模式; 0-正常模式)."
                         read schmode

                         # echo "$jobs $schmode"
                         $ETLHOME/sh/start_task.sh $jobplusid $schmode
                         ;;
                esac

                if [ $? -eq 0 ]; then
                    echo ""
                    echo "任务 *提交*!"
                    echo "按[ENTER]键继续......"
                    echo ""
                    read key_enter
                    exit
                else
                    echo ""
                    echo "任务 *失败*!"
                    echo ""
                    exit
                fi
            else
                echo ""
                echo "ERROR: 未找到作业序列关系文件。"
                echo "按[ENTER]键退出......"
                echo ""
                read key_enter
                exit
            fi
            ;;
    N|n)
        echo ""
        echo "任务 *取消*!"
        echo ""
        exit
        ;;
    *) exit;;
esac

$ETLHOME/start_etl.sh
