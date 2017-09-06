#!/bin/sh

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
