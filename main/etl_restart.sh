#!/bin/sh

### 重新启动调度
### 包括以下ETL任务类型:
# 1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN
# 5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON
# 8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)
# 10-BATCH DATADOWN3(AFTER L2CALBAK)

echo "\nETL TO BE RESTART,PRESS [ENTER] KEY TO CONTINUE......\c"
read a
if [ "$a" = "" ]; then

    # 调度清单, 如果存在, 清除原来的调度清单文件
    schedule_file=$ETLHOME/shell/schedule$$.lst

    if [ -f $schedule_file ]; then
        rm $schedule_file
    fi

    # 指导用户选择ETL类型, 默认类型为1-ETL
    echo "\nETL TYPE INCLUDE:1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN"
    echo "                   5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON"
    echo "                   8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)"
    echo "                   10-BATCH DATADOWN3(AFTER L2CALBAK) "
    echo "\nPLEASE SELECT ETL TYPE:\c"
    read etltype

    if [ ! -z "$etltype" -a ! "$etltype" == "1" -a ! "$etltype" == "2" -a ! "$etltype" == "3" -a ! "$etltype" == "4" -a ! "$etltype" == "5" -a ! "$etltype" == "6" -a ! "$etltype" == "7" -a ! "$etltype" == "8" -a ! "$etltype" == "9" -a ! "$etltype" == "10"  ]; then

        echo "ETL TYPE INVALIDATE, TASK CANCELD."
        echo "PRESS ANY KEY TO CONTINUE..."
        read a
    else

        if [ "$etltype" == "1" -o -z "$etltype" ]; then
            ddflag=""
        elif [ "$etltype" == "2" ]; then
            ddflag="_onlinedwn"
        elif [ "$etltype" == "3" ]; then
            ddflag="_mthend"
        elif [ "$etltype" == "4" ]; then
            ddflag="_mthend2"
        elif [ "$etltype" == "5" ]; then
            ddflag="_mthend3"
        elif [ "$etltype" == "6" ]; then
            ddflag="_daybefore"
        elif [ "$etltype" == "7" ]; then
            ddflag="_daybefore2"
        elif [ "$etltype" == "8" ]; then
            ddflag="_batchdwn1"
        elif [ "$etltype" == "9" ]; then
            ddflag="_batchdwn2"
        elif [ "$etltype" == "10" ]; then
            ddflag="_batchdwn3"
        fi

        ## 断点执行作业序列
        # 提示是否从上次失败的作业序列位置开始断点加载
        echo "RESTART FROM LAST FAILED TASK OF CURRENT BATCHNO(Y/N):\c"
        read ans

        # 创建重启的调度为新的调度文件
        if [ -z "$ans" -o "$ans" = "Y" -o "$ans" = "y" ]; then
            cat $ETLHOME/etllog/restart${ddflag} \
                >$schedule_file
        else
            while :
            do
                # 输入作业序列名
                echo "\nPLEASE INPUT JOB SEQ NAME(INPUT 0 TO MEAN END):\c"
                read jblstname
                if [ "$jblstname" = "0" ]; then
                    break
                fi

                if [ -f $ETLHOME/shell/job$ddflag/$jblstname ]; then
                    # 输入作业序列的开始位置
                    echo "\nPLEASE INPUT START POSITION OF CURRENT JOB SEQ:($jblstname) :\c"
                    read jobid

                    # 默认位置为1
                    if [ -z "$jobid" ];  then
                        jobid=1
                    fi

                    # 写调度文件
                    echo "$jblstname,$jobid" \
                         >>$schedule_file
                else
                    echo "\nERROR JOB SEQ NAME!"
                fi
            done
        fi
    fi

    if [ -f $schedule_file ]; then
        # 打印调度文件
        echo "\nCURRENT JOB SEQ LIST FOR SCHEDULE:\n"
        cat $schedule_file

        echo "\nPRESS [ENTER] KEY TO CONTINUE......\c"
        read key_enter

        # 读取调度文件
        if [ "$key_enter" = "" ]; then
            succjs=""
            while read line
            do
                joblstname=`echo $LINE|awk -F ',' '{print $1}'`
                jobid=`echo $LINE|awk -F ',' '{print $2}'`
                if [ -z "$joblstname" ]; then
                    continue
                fi
                if [ -z "$succjs" ]; then
                    succjs="${joblstname}+${jobid}"
                else
                    succjs="${succjs}:${joblstname}+${jobid}"
                fi
            done < $schedule_file

            ## --------------------------------------------------
            ## 启动任务, 断点加载任务
            ## --------------------------------------------------
            eval ./start_task.sh $succjs 1 $etltype

            if [ $? -eq 0 ]; then
                echo "\nTASK SUBMITTED, PRESS [ENTER] KEY TO CONTINUE......\c"
                read key_enter
            else
                echo "\nTASK FAIL, PRESS [ENTER] KEY TO CONTINUE......\c"
                read key_enter
            fi
        else
            echo "\nTASK CANCELED, PRESS [ENTER] KEY TO CONTINUE......\c"
            read key_enter
        fi
        # 清除调度文件
        rm $schedule_file 2>/dev/null
    else
        echo "\nTASK CANCELED, PRESS [ENTER] KEY TO CONTINUE......\c"
        read key_enter
    fi
else
    echo "\nTASK CANCELED, PRESS [ENTER] KEY TO CONTINUE......\c"
    read a
fi
