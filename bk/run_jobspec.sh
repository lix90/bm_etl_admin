#!/bin/sh

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
            $ETLHOME/shell/start_task.sh ${succjs} 0 $etltype
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
