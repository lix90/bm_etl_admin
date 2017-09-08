#!/bin/sh

# $1-js_46.def+1, 作业名称加序号, 作业为js_46.def, 序号为1
# $2-0, 调度模式, 0为正常模式

LOGPATH=$TASKPATH/log
if [ ! -d $LOGPATH ]; then
    echo "日志路径不存在, 程序将自动创建."
    mkdir $LOGPATH
fi

# 启动作业序列
echo "***************"
echo "即将启动ETL 任务"
echo "***************"
echo ""
echo "按[Y|y]键继续, 按[N|n]键取消......"
read a

case $a in
    Y|y)
        echo ""
        echo "请输入作业序列文件和序号, 必须包含序列文件和序号."
        echo "格式为: <*.job>+<jobid>:..."
        echo "例如:"
        echo "script01.job+1"
        echo "script01.job+1:script02.job+1"
        read jobs
        echo "请指定调用模式 (1-断点模式; 0-正常模式)."
        read schmode
        # echo "$jobs $schmode"
        $ETLHOME/sh/start_task.sh $jobs $schmode
        if [ $? -eq 0 ]; then
            echo ""
            echo "任务 *提交*!"
            echo "按 [ENTER] 键继续......"
            read key_enter
        else
            echo ""
            echo "任务 *失败*!"
            echo ""
            # 如果失败, 则删除运行日志
            rm $TASKPATH/log/running.flag
            exit
        fi
        ;;
    N|n)
        echo ""
        echo "任务 *取消*!"
        echo ""
        exit
        ;;
esac
