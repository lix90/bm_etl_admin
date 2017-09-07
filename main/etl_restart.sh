#!/bin/sh

### 重新启动调度

echo "ETL TO BE RESTART"
echo "PRESS [Y|y] KEY TO CONTINUE, [N|n] KEY TO STOP."
read a

JOBPATH=$TASKPATH/job

case $a in
    Y|y)
        # 调度清单, 如果存在, 清除原来的调度清单文件
        schedule_file=$JOBPATH/schedule$$.lst

        if [ -f $schedule_file ]; then
            rm $schedule_file
        fi

        ## 断点执行作业序列
        # 提示是否从上次失败的作业序列位置开始断点加载
        echo "RESTART FROM LAST FAILED TASK OF CURRENT BATCHNO(Y/N):\c"
        read ans

        if [ -z "$ans" -o "$ans" = "Y" -o "$ans" = "y" ]; then
            # 写重启标识到调度文件
            cat $LOGPATH/restart \
                >$schedule_file
        elif [ "$ans" = "Y" -o "$ans" = "y"]; then
            while :
            do
                # 输入作业序列名
                echo "PLEASE INPUT JOB SEQ NAME(INPUT 0 TO END):"
                read jobfname
                if [ "$jobfname" = "0" ]; then
                    break
                fi
                if [ -f $JOBPATH/$jobfname ]; then
                    # 输入作业序列的开始位置
                    echo "PLEASE INPUT START POSITION OF CURRENT JOB SEQ:"
                    read jobid
                    # 默认位置为1
                    if [ -z "$jobid" ];  then
                        jobid=1
                    fi
                    # 写调度文件
                    echo "$jobfname,$jobid" \
                         >>$schedule_file
                else
                    echo "\nERROR JOB SEQ NAME!"
                fi
            done
        fi

        if [ -f $schedule_file ]; then
            # 打印调度文件
            echo "\nCURRENT JOB SEQ LIST FOR SCHEDULING:\n"
            cat $schedule_file

            echo "\nPRESS [ENTER] KEY TO CONTINUE......\c"
            read key_enter

            # 读取调度文件
            if [ "$key_enter" = "" ]; then
                succjs=""
                while read line
                do
                    jobfname=`echo $line|awk -F ',' '{print $1}'`
                    jobid=`echo $line|awk -F ',' '{print $2}'`
                    if [ -z "$jobfname" ]; then
                        continue
                    fi
                    if [ -z "$succjs" ]; then
                        succjs="${jobfname}+${jobid}"
                    else
                        succjs="${succjs}:${jobfname}+${jobid}"
                    fi
                done < $schedule_file

                ## --------------------------------------------------
                ## 启动任务, 断点加载任务
                ## --------------------------------------------------
                eval ./start_task.sh $succjs 1

                if [ $? -eq 0 ]; then
                    echo "TASK SUBMITTED, PRESS [ENTER] KEY TO CONTINUE......"
                    read key_enter
                else
                    echo "TASK FAIL, PRESS [ENTER] KEY TO CONTINUE......"
                    read key_enter
                fi
            else
                echo "TASK CANCELED, PRESS [ENTER] KEY TO CONTINUE......"
                read key_enter
            fi
            # 清除调度文件
            rm $schedule_file 2>/dev/null
        else
            echo "TASK CANCELED, PRESS [ENTER] KEY TO CONTINUE......"
            read key_enter
        fi
        else
            echo "TASK CANCELED, PRESS [ENTER] KEY TO CONTINUE......"
            read a
        fi
esac
