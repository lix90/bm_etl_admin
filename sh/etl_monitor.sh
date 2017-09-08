#!/bin/sh

trap "./start_menu.sh " 2 3

##logfile=$LOGPATH/run.log
echo "PLEASE INPUT BATCHNO:"
read batchno

LOGPATH=$TASKPATH/log

logfile=$LOGPATH/$batchno/run.log
jklogfile=$LOGPATH/joblstrun.log$$
rm ${jklogfile} 2>/dev/null
touch $jklogfile

if [  -f $logfile ]; then
    clear
    rowcnt=0;
    maxrowcnt=1;
    logtmpfile="$LOGPATH/logtmpfile$$"

    while :
    do
        clear
        rowcnt=`wc -l $logfile|awk '{print $1}'`
        tail +$maxrowcnt $logfile>$logtmpfile
        while read line
        do
            if [ -z "$line"  ]; then
                continue;
            fi
            jobname=`echo $line|awk  -F : '{print $3}'`
            joblstname=`echo $line|awk  -F : '{print $2}'`
            if [  "$jobname" = "0" ]; then
                continue;
            fi
            if [ -f $jklogfile ]; then
                tjflag=`awk -F: -v jobname=$jobname '$2==jobname {print 1}' $jklogfile `
            else
                tjflag=""
            fi
            jobstatus=`awk -F : -v jobname=$jobname 'BEGIN {OFS=":";} $3 == jobname {jobstatus=$6;starttime=$4;endtime=$5;jobid=$7;next;} END {print jobstatus,starttime,endtime,jobid;}' $logfile`
            joblogrec="$joblstname:$jobname:$jobstatus"
            if [ -z "$tjflag"  ]; then
                echo "$joblogrec">>$jklogfile
            elif [ ! $maxrowcnt -eq 1 ]; then
                awk -F : -v jobname=$jobname '$2 != jobname {print $0}' $jklogfile > ${jklogfile}_$$
                rm $jklogfile
                mv ${jklogfile}_$$ $jklogfile
                echo "$joblogrec">>$jklogfile
            fi
        done<$logtmpfile
        ###rowcnt=`wc -l $logtmpfile|awk '{print $1}'`
        rm $logtmpfile
        if [ $rowcnt -lt 50 ]; then
            maxrowcnt=2
        else
            maxrowcnt=`expr $rowcnt - 30`
        fi
        echo "JOBSEQ          JOB                     STATUS  STARTTIME       ENDTIME         POSITION"
        echo "--------------------------------------------------------------------------------------------"
        awk -F : 'BEGIN {OFS="	";} $3=="成功"  {print $1,$2,$3,$4,$5,$6} ' $jklogfile |tail -20
        awk -F : 'BEGIN {OFS="	";} $3=="用户中断"  {print $1,$2,$3,$4,$5,$6} ' $jklogfile
        awk -F : 'BEGIN {OFS="	";} $3=="失败" {print $1,$2,$3,$4,$5,$6} ' $jklogfile
        awk -F : 'BEGIN {OFS="	";} $3=="等待运行" {print $1,$2,$3,$4,$5,$6} ' $jklogfile
        awk -F : 'BEGIN {OFS="	";} $3=="运行中" {print $1,$2,$3,$4,$5,$6} ' $jklogfile

        waitjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="等待运行" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        runjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="运行中" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        failjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="失败" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        succjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="成功" || $3=="用户中断" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        echo "--------------------------------------------------------------------------------------------"
        waitjobcnt=$waitjobcnt
        runjobcnt=$runjobcnt
        failjobcnt=$failjobcnt
        succjobcnt=$succjobcnt

        echo "RUNNING RESULT：WAITING:${waitjobcnt}，RUNNING:${runjobcnt}，SUCCESS:${succjobcnt}，FAIL:${failjobcnt}"
        if [ $waitjobcnt -eq 0 -a $runjobcnt -eq 0 ]; then
            echo "RUNNING STATUS：FINISHED."
            if [ -f $LOGPATH/running.flag  ]; then
                rm $LOGPATH/running.flag
            fi
            rm $jklogfile 2>/dev/null
            maxrowcnt=1
        else
            echo "RUNNING STATUS：RUNNNING..."
        fi
        echo "--------------------------------------------------------------------------------------------"
        echo "PRESS CTRL+C KEY TO STOP..."
        sleep $interval_time
    done
else
    echo "input batchno $batchno invalid."
    echo "PRESS ANY KEY TO CONTINUE..."
    read a
fi
