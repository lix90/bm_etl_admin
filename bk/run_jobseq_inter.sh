#!/bin/sh

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
