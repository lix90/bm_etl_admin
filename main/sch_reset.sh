#!/bin/sh

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
