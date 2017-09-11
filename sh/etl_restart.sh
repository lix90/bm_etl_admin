#!/bin/sh

## 当用户终止程序，重新启动start_menu
trap "$ETLHOME/sh/start_menu.sh " INT TERM EXIT

echo ""
echo "          ***************"
echo "          即将重启ETL任务"
echo "          ***************"
echo ""
echo "     按[Y|y]键继续，按[N|n]键终止."
read a

JOBPATH=$TASKPATH/job
LOGPATH=$TASKPATH/log

case $a in
    Y|y)
        # 调度清单, 如果存在, 清除原来的调度清单文件
        schedule_file=$JOBPATH/schedule$$

        if [ -f $schedule_file ]; then
            rm $schedule_file
        fi

        ## 断点执行作业序列
        # 提示是否从上次失败的作业序列位置开始断点加载
        echo "是否从最近一次失败作业的批次号重启[Y|N]:"
        read ans

        ## 将重启调度文件名和作业序号写入调度文件
        if [ -z "$ans" -o "$ans" = "Y" -o "$ans" = "y" ]; then
            # 写重启标识到调度文件
            cat $LOGPATH/restart.flag \
                >$schedule_file
        elif [ "$ans" = "N" -o "$ans" = "n"]; then
            while :
            do
                # 输入作业序列名
                echo "请输入作业序列名（按0键终止）:"
                read jobfname
                if [ "$jobfname" = "0" ]; then
                    break
                fi
                if [ -f $JOBPATH/$jobfname ]; then
                    # 输入作业序列的开始位置
                    echo "请输入作业序列编号（按回车键序列号默认为1）:"
                    read jobid
                    # 默认位置为1
                    if [ -z "$jobid" ];  then
                        jobid=1
                    fi
                    # 将序列文件和序列编号写入调度文件，以逗号分隔
                    echo "$jobfname,$jobid" \
                         >>$schedule_file
                else
                    echo "ERROR: 错误的调度序列文件!"
                fi
            done
        fi

        ## 读取新创建的调度文件，获取重新调度的作业序列信息
        if [ -f $schedule_file ]; then
            # 打印调度文件
            echo "当前作业序列为:"
            cat $schedule_file

            echo "按[ENTER]键继续......"
            read key_enter

            # 从调度文件中读取调度作业序列和编号
            if [ "$key_enter" = "" ]; then
                succjs=""
                while read line
                do
                    jobfname=`echo $line | awk -F ',' '{print $1}'`
                    jobid=`echo $line | awk -F ',' '{print $2}'`
                    if [ -z "$jobfname" ]; then
                        continue
                    fi
                    if [ -z "$succjs" ]; then
                        succjs="${jobfname}+${jobid}"
                    else
                        succjs="${succjs}:${jobfname}+${jobid}"
                    fi
                done < $schedule_file


                ## 启动任务, 断点加载任务
                ##===================
                eval $ETLHOME/sh/start_task.sh $succjs 1

                if [ $? -eq 0 ]; then
                    echo "作业*提交*, 按[ENTER]键继续......"
                    read key_enter
                else
                    echo "作业*失败*, 按[ENTER]键继续......"
                    read key_enter
                fi
            else
                echo "作业*取消*, 按[ENTER]键继续......"
                read key_enter
            fi
            # 清除调度文件
            rm $schedule_file 2>/dev/null
        else
            echo "作业*取消*, 按[ENTER]键继续......"
            read key_enter
        fi
        ;;

    N|n)
        echo "作业*取消*, 按[ENTER]键继续......"
        read a
        ;;
esac
