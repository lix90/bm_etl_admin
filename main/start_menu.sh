#! /bin/sh

trap "rm $ETLHOME/shell/schedule*.lst 2>/dev/null;./start_menu.sh " 2 3
clear

echo "\n\n                      CITICPRU ETL ADIMIN DESKTOP V2.3\n"

echo "                         1. ONLINE DATADOWN"
echo "                         2. MONTH END DATADOWN"
echo "                         3. ETL START"
echo "                         4. ETL RESTART"
echo "                         5. RUN SPECIAL JOB"
echo "                         6. ETL ONWATCH"
echo "                         7. STOP SCHEDULE     "
echo "                         8. RESET SCHEDULE STATUS "
echo "                         9. SET MONTH END FLAG"
echo "                         10.BORUNTIME MONITOR"
echo "                         11.BATCH DATADOWN1(AFTER LnCVIPLTS)"
echo "                         12.BATCH DATADOWN2(AFTER L2AQSPRDAT)"
echo "                         13.BATCH DATADOWN3(AFTER L2CALBAK)"
echo "                         14.EXECUTE JOBSEQ SCRIPT"
echo "                         0. EXIT"
echo "\n                    INPUT MENUITEM ID: \c"

read ans
clear

### --------------------------------------------------
### 在线/联机文件下载
### --------------------------------------------------

if [ "$ans" = "1" ]; then
    echo "\n联机文件下载即将开始,按回车键确认......\c"
    read a
    if [ "$a" = "" ]
    then
        $ETLHOME/shell/start_task.sh 0 js_2501.def+1 2
        if [ $? -eq 0 ]; then
            echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        else
            echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi
    else
        echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
    fi


    ### --------------------------------------------------
    ### 月结数据下载
    ### --------------------------------------------------

elif [ "$ans" = "2" ]; then
    echo "\nMONTH END DATADOWN TO BE START,PRESS ENTER KEY TO CONTINUE......\c"
    read a
    if [ "$a" = "" ]
    then
        $ETLHOME/shell/start_task.sh 0 js_4001.def+1 3
        if [ $? -eq 0 ]; then
            echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        else
            echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi
    else
        echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
    fi

    ### --------------------------------------------------
    ### 启动ETL
    ### --------------------------------------------------

elif [ "$ans" = "3" ]; then
    echo "\nETL TO BE START,PRESS ENTER KEY TO CONTINUE......\c"
    read a
    if [ "$a" = "" ]
    then

        $ETLHOME/shell/start_task.sh 0 js_46.def+1 1

        if [ $? -eq 0 ]; then
            echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        else
            echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi

    else
        echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
    fi

    ### --------------------------------------------------
    ### 重启ETL
    ### --------------------------------------------------

elif [ "$ans" = "4" ]; then
    echo "\nETL TO BE RESTART,PRESS ENTER KEY TO CONTINUE......\c"
    read a
    if [ "$a" = "" ]
    then
        schedule_file=$ETLHOME/shell/schedule$$.lst
        if [ -f $schedule_file ]; then
            rm $schedule_file
        fi

        echo "\nETL TYPE INCLUDE:1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN"
        echo "                   5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON"
        echo "                   8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)"
        echo "                   10-BATCH DATADOWN3(AFTER L2CALBAK) "
        echo "\nPLEASE SELECT ETL TYPE:\c"
        read etltype
        if [ ! -z "$etltype" -a ! "$etltype" == "1" -a ! "$etltype" == "2" -a ! "$etltype" == "3" -a ! "$etltype" == "4" -a ! "$etltype" == "5" -a ! "$etltype" == "6" -a ! "$etltype" == "7" -a ! "$etltype" == "8" -a ! "$etltype" == "9" -a ! "$etltype" == "10"  ]; then
            echo "ETL TYPE INVALIDATE,TASK CANCELD,PRESS ANY KEY TO CONTINUE..."
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

            ### 提示是否从上次失败的作业序列位置开始断点加载
            echo "RESTART FROM LAST FAILED TASK OF CURRENT BATCHNO(Y/N):\c"
            read ans

            if [ -z "$ans" -o "$ans" = "Y" -o "$ans" = "y" ]; then
                cat $ETLHOME/etllog/restart${ddflag}>$schedule_file
            else
                while :
                do
                    #input job
                    echo "\nPLEASE INPUT JOB SEQ NAME(INPUT 0 TO MEAN END):\c"
                    read jblstname
                    if [ "$jblstname" = "0" ]; then
                        break
                    fi
                    if [ -f $ETLHOME/shell/job$ddflag/$jblstname ]; then
                        #input job 顺序号
                        echo "\nPLEASE INPUT JOB START POSITION OF CURRENT JOB SEQ:($jblstname) :\c"
                        read jobid
                        if [ -z "$jobid" ];  then
                            jobid=1
                        fi
                        #write schedule file
                        echo "$jblstname,$jobid" >>$schedule_file
                    else
                        echo "\nERROR JOB SEQ NAME!"
                    fi
                done
            fi
        fi

        if [ -f $schedule_file ]; then
            echo "\nCURRENT JOB SEQ LIST FOR SCHEDULE:\n"
            cat $schedule_file

            echo "\nPRESS ENTER KEY TO CONTINUE......\c"
            read key_enter
            if [ "$key_enter" = "" ]
            then
                succjs=""
                while read LINE
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

                eval $ETLHOME/shell/start_task.sh 1 $succjs $etltype
                if [ $? -eq 0 ]; then
                    echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
                else
                    echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
                fi
            else
                echo "\nTASK CANCELED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
            fi
            rm $schedule_file 2>/dev/null
        else
            echo "\nTASK CANCELED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi
    else
        echo "\nTASK CANCELED,PRESS ENTER KEY TO CONTINUE......\c";read a
    fi

    ### --------------------------------------------------
    ### 特殊作业（RUN SPECIAL JOB）
    ### --------------------------------------------------

elif [ "$ans" = "5" ]; then
    schedule_file=$ETLHOME/shell/schedule$$.lst
    if [ -f $schedule_file ]; then
        rm $schedule_file
    fi
    echo "\nETL TYPE INCLUDE:1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN"
    echo "                   5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON"
    echo "                   8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)"
    echo "                   10-BATCH DATADOWN3(AFTER L2CALBAK)"
    echo "\nPLEASE SELECT ETL TYPE:\c"
    read etltype
    if [ ! -z "$etltype" -a ! "$etltype" == "1" -a ! "$etltype" == "2" -a ! "$etltype" == "3" -a ! "$etltype" == "4" -a ! "$etltype" == "5" -a ! "$etltype" == "6" -a ! "$etltype" == "7" -a ! "$etltype" == "8" -a ! "$etltype" == "9" -a ! "$etltype" == "10" ]; then
        echo "ETL TYPE INVALIDATE,TASK CANCELD,PRESS ANY KEY TO CONTINUE..."
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
        while :
        do
            #input job
            echo "\nPLEASE INPUT JOB SEQ NAME(INPUT 0 TO MEAN END):\c"
            read jblstname
            if [ "$jblstname" = "0" ]; then
                break
            fi
            if [ -f $ETLHOME/shell/job$ddflag/$jblstname ]; then
                #input job 顺序号
                echo "\nPLEASE INPUT JOB START POSITION OF CURRENT JOB SEQ:($jblstname) :\c"
                read jobid
                if [ -z "$jobid" ];  then
                    jobid=1
                fi
                #write schedule file
                echo "$jblstname,$jobid\n" >>$schedule_file
            else
                echo "\nERROR JOB SEQ NAME!"
            fi
        done

        if [ -f $schedule_file ]; then
            echo "\nCURRENT JOB SEQ LIST FOR SCHEDULE:\n"
            cat $schedule_file

            echo "\nPRESS ENTER KEY TO CONTINUE......\c"
            read key_enter
            if [ "$key_enter" = "" ]
            then
                succjs=""
                while read LINE
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

                echo "PLEASE INPUT SCHEDULE MODE[STEP:SUCCEED]:\c"
                read  schmode
                $ETLHOME/shell/start_task.sh 0 ${succjs} $etltype
                if [ $? -eq 0 ]; then
                    if [ -z "${schmode}" -o "${schmode}" = "STEP" ]; then
                        echo ":0">> $ETLHOME/etllog/halt.flag
                    fi
                    echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read a
                else
                    echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
                fi
            else
                echo "\nTASK CANCELED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
            fi
            rm $schedule_file 2>/dev/null
        else
            echo "\nTASK CANCELED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi
    fi

    ### --------------------------------------------------
    ### 监控ETL
    ### --------------------------------------------------

elif [ "$ans" = "6" ]; then
    echo "\nETL TYPE INCLUDE:1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN"
    echo "                   5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON"
    echo "                   8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)"
    echo "                   10-BATCH DATADOWN3(AFTER L2CALBAK) ,12-YS PERF REAL TIME ETL"
    echo "\nPLEASE SELECT ETL TYPE:\c"
    read etltype

    if [ ! -z "$etltype" -a ! "$etltype" == "1" -a ! "$etltype" == "2" -a ! "$etltype" == "3" -a ! "$etltype" == "4" -a ! "$etltype" == "5" -a ! "$etltype" == "6" -a ! "$etltype" == "7" -a ! "$etltype" == "8" -a ! "$etltype" == "9" -a ! "$etltype" == "10" -a ! "$etltype" == "12" ]; then
        echo "ETL TYPE INVALIDATE,TASK CANCELD,PRESS ANY KEY TO CONTINUE..."
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
        elif [ "$etltype" == "12" ]; then
            ddflag="_realtime_ys"
        fi
        ### 监控作业
        ./monitor_job.sh batchno${ddflag}.cfg $interval_time
    fi

    ### --------------------------------------------------
    ### 终止调度
    ### --------------------------------------------------

elif [ "$ans" = "7" ]; then
    echo "\nETL TYPE INCLUDE:1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN"
    echo "                   5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON"
    echo "                   8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)"
    echo "                   10-BATCH DATADOWN3(AFTER L2CALBAK) "
    echo "\nPLEASE SELECT ETL TYPE:\c"
    read etltype

    if [ ! -z "$etltype" -a ! "$etltype" == "1" -a ! "$etltype" == "2" -a ! "$etltype" == "3" -a ! "$etltype" == "4" -a ! "$etltype" == "5" -a ! "$etltype" == "6" -a ! "$etltype" == "7" -a ! "$etltype" == "8" -a ! "$etltype" == "9" -a ! "$etltype" == "10" ]; then
        echo "ETL TYPE INVALIDATE,TASK CANCELD,PRESS ANY KEY TO CONTINUE..."
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
        echo "INPUT JOBSEQ NAME(DEFAULT:IMMEDIATELY):\c"
        read jsname
        if [ -z "$jsname" ]; then
            echo "\nAFTER CURRENT JOBSEQ FINISHED,SUCCEEDING JOB TO BE CANCELD."
            jspos=0
        else
            echo "INPUT JOBSEQ POSITION OF $jsname (DEFAULT:0):\c"
            read jspos
            if [ -z "$jspos" ]; then
                jspos=0
            fi
            echo "\nAFTER STEP $jspos OF ${jsname}  FINISHED,SUCCEEDING JOB TO BE CANCELD."
        fi
        echo "\nPRESS ENTER KEY TO CONTINUE......\c"
        read key_enter
        if [ "$key_enter" = "" ]; then
            echo "$jsname:$jspos">> $ETLHOME/etllog/halt${ddflag}.flag
            echo "\nSET INTERRUPT FLAG SUCCESSFUL."
            echo "\nPRESS ANY KEY TO CONTINUE......\c"
            read key_enter
        fi
    fi

    ### --------------------------------------------------
    ### 重置调度
    ### --------------------------------------------------
elif [ "$ans" = "8" ]; then
    echo "\nETL TYPE INCLUDE:1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN"
    echo "                   5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON"
    echo "                   8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)"
    echo "                   10-BATCH DATADOWN3(AFTER L2CALBAK) "
    echo "\nPLEASE SELECT ETL TYPE:\c"
    read etltype

    if [ ! -z "$etltype" -a ! "$etltype" == "1" -a ! "$etltype" == "2" -a ! "$etltype" == "3" -a ! "$etltype" == "4" -a ! "$etltype" == "5" -a ! "$etltype" == "6" -a ! "$etltype" == "7" -a ! "$etltype" == "8" -a ! "$etltype" == "9" -a ! "$etltype" == "10"  ]; then
        echo "ETL TYPE INVALIDATE,TASK CANCELD,PRESS ANY KEY TO CONTINUE..."
        read a
    else

        if [ -z "$etltype" ]; then
            ddflag="all"
        elif [ "$etltype" == "1" ]; then
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

        echo "\nRESET SCHEDULE STATUS STARTTING，PLEASE MAKE SURE CURRENT TASKS ALL FINISHED."
        echo "\nPRESS ENTER KEY TO CONTINUE......\c"
        read key_enter

        if [ "$key_enter" = "" ]; then
            if [ "$ddflag" = "all" ]; then
                rm $ETLHOME/etllog/running*.flag
                rm $ETLHOME/etllog/halt*.flag
            else
                if [ -f $ETLHOME/etllog/running${ddflag}.flag ]; then
                    rm $ETLHOME/etllog/running${ddflag}.flag
                fi;
                if [ -f $ETLHOME/etllog/halt${ddflag}.flag ]; then
                    rm $ETLHOME/etllog/halt${ddflag}.flag
                fi;
            fi
            echo "\nRESET SCHEDULE STATUS SUCCESSFUL."
            echo "\nPRESS ENTER KEY TO CONTINUE......\c"
            read key_enter
        fi
    fi

    ### --------------------------------------------------
    ### 月结
    ### --------------------------------------------------
elif [ "$ans" = "9" ]; then
    echo "\nPLEASE INPUT MONTH END FLAG（Y-MONTH END N-NOT MONTH END）:\c"
    read ans
    if [ "$ans" = "Y" -o "$ans" = "y" ]; then
        touch $ETLHOME/etllog/monthend.flag
        echo "\nMONTH END FLAG:Y."
    else
        if [ -f $ETLHOME/etllog/monthend.flag ]; then
            rm $ETLHOME/etllog/monthend.flag
        fi
        echo "\nMONTH END FLAG:N."
    fi
    echo "\nPRESS ENTER KEY TO CONTINUE......\c"
    read key_enter

    ### --------------------------------------------------
    ###
    ### --------------------------------------------------
elif [ "$ans" = "10" ]; then
    while :
    do
        clear
        echo "\n-------------------------------BORUNTIME RUNNING STATUS----------------------------------------\n"
        ##echo "TASKNAME                            BATCHNO/BEGINTIME               SCHEDULED/COMPLETED/RUNNING/PENDING/FAILED"
        ##${WORKPATH}/boruntime/monitor.sh 24|grep -i `date +%Y%m%d`
        ${WORKPATH}/boruntime/monitor.sh 24
        echo "\n-----------------------------------------------------------------------------------------------\n"
        echo "PRESS CTRL+C KEY TO STOP..."
        sleep 30
    done
    echo "\nPRESS ENTER KEY TO CONTINUE......\c"
    read key_enter

    ### --------------------------------------------------
    ### BATCH DATADOWN1
    ### --------------------------------------------------
elif [ "$ans" = "11" ]; then
    echo "\nBATCH DATADOWN1(AFTER LnPSARERPT) TO BE START,PRESS ENTER KEY TO CONTINUE......\c"
    read a
    if [ "$a" = "" ]
    then
        $ETLHOME/shell/start_task.sh 0 js_1.def+1 8
        if [ $? -eq 0 ]; then
            echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        else
            echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi
    else
        echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
    fi

    ### --------------------------------------------------
    ### BATCH DATADOWN2
    ### --------------------------------------------------
elif [ "$ans" = "12" ]; then
    echo "\nBATCH DATADOWN2(AFTER L2AQSPRDAT) TO BE START,PRESS ENTER KEY TO CONTINUE......\c"
    read a
    if [ "$a" = "" ]
    then
        $ETLHOME/shell/start_task.sh 0 js_2.def+1 9
        if [ $? -eq 0 ]; then
            echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        else
            echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi
    else
        echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
    fi

    ### --------------------------------------------------
    ### BATCH DATADOWN3
    ### --------------------------------------------------
elif [ "$ans" = "13" ]; then
    echo "\nBATCH DATADOWN3(AFTER L2CALBAK) TO BE START,PRESS ENTER KEY TO CONTINUE......\c"
    read a
    if [ "$a" = "" ]
    then
        $ETLHOME/shell/start_task.sh 0 js_6.def+1 10
        if [ $? -eq 0 ]; then
            echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        else
            echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
        fi
    else
        echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
    fi

    ### --------------------------------------------------
    ### 临时
    ### --------------------------------------------------
elif [ "$ans" = "14" ]; then
    echo "INPUT JOBSEQ SCRIPT FILE:\c"
    read jbseqname
    if [ -z "$jbseqname" ]; then
        echo "ERROR: NO SPECIFY JOBSEQ SCRIPT FILE."
    else
        echo "INPUT $jbseqname START POSITION:\c"
        read sjobid
        if [ -z "$sjobid" ]; then
            echo "ERROR: NO SPECIFY $jbseqname START POSITION."
        else
            echo "INPUT $jbseqname END POSITION(DEFAULT:NO LIMIT):\c"
            read ejobid
            echo "ETL TYPE INCLUDE:1-ETL,2-ONLINE DATADOWN,3-MONTH END DATADOWN,4-MONTH(19) END2 DATADOWN"
            echo "                   5-MONTH(1) END3 DATADOWN,6-DAY BEFORE DATADOWN,7-DAY BEFORE2 DATADWON"
            echo "                   8-BATCH DATADOWN1(AFTER LnCVIPLTS),9-BATCH DATADOWN2(AFTER L2AQSPRDAT)"
            echo "                   10-BATCH DATADOWN3(AFTER L2CALBAK)"
            echo "PLEASE SELECT ETL TYPE:\c"
            read etltype
            if [ ! -z "$etltype" -a ! "$etltype" == "1" -a ! "$etltype" == "2" -a ! "$etltype" == "3" -a ! "$etltype" == "4" -a ! "$etltype" == "5" -a ! "$etltype" == "6" -a ! "$etltype" == "7" -a ! "$etltype" == "8" -a ! "$etltype" == "9" -a ! "$etltype" == "10"  ]; then
                echo "ETL TYPE INVALIDATE,TASK CANCELD,PRESS ANY KEY TO CONTINUE..."
                read a
            else
                if [ -z "$etltype" ]; then
                    etltype=1
                fi
                if [ "$etltype" == "1"  ]; then
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
                echo "START A NEW BATCH(Y/N):\c"
                read newbatch
                if [ "$newbatch" = "Y" -o -z "$newbatch" ]; then
                    batchno=`date +%Y%m%d_%H%M%S`
                else
                    batchno=`cat $ETLHOME/etllog/batchno${ddflag}.cfg`
                fi
                echo "CURRENT BATCHNO:$batchno"

                $ETLHOME/shell/run_jobseq.sh $jbseqname $batchno $sjobid $etltype $ejobid |tee  $ETLHOME/etllog/nohup.out

                if [ $? -eq 0 ]; then
                    echo "EXECUTE $jbseqname SUCCESSFUL."
                else
                    echo "EXECUTE $jbseqname FAIL."
                fi
            fi
        fi
    fi
    echo "\nPRESS ENTER KEY TO CONTINUE...\c";read a
    ###elif [ "$ans" = "14" ]; then
    ###  etlrunstatus batchno.cfg

    ### --------------------------------------------------
    ### 清除日志
    ### --------------------------------------------------
elif [ "$ans" = "0" ]; then
    if [ -f $ETLHOME/etllog/joblstrun.log$$ ]; then
        rm $ETLHOME/etllog/joblstrun.log$$
    fi
    exit
else
    echo "\nERROR CHOICE, PRESS ENTER KEY TO CONTINUE......\c";read a
fi

### 重新启动菜单
./start_menu.sh
