#!/bin/sh

trap "$ETLHOME/sh/start_menu.sh " 2 3

LOGPATH=$TASKPATH/log

##logfile=$LOGPATH/run.log
echo ""
echo "请输入需要监控的作业批次号:"
echo "例如：20150115_091314"
echo "批次号从$TASKHOME/log获取"
echo ""
read batchno

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
        rowcnt=`wc -l $logfile | awk '{print $1}'`
        tail +$maxrowcnt $logfile>$logtmpfile
        while read line
        do
            if [ -z "$line"  ]; then
                continue;
            fi
            # 第3列为作业名
            jobname=`echo $line|awk  -F : '{print $3}'`
            # 第2列为作业序列名
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

        echo "运行结果: 等待中:${waitjobcnt}，运行中:${runjobcnt}，成功:${succjobcnt}，失败:${failjobcnt}"
        if [ $waitjobcnt -eq 0 -a $runjobcnt -eq 0 ]; then
            echo "运行结果: 已完成..."
            if [ -f $LOGPATH/running.flag  ]; then
                rm $LOGPATH/running.flag
            fi
            rm $jklogfile 2>/dev/null
            maxrowcnt=1
        else
            echo "运行结果: 运行中..."
        fi
        echo "--------------------------------------------------------------------------------------------"
        echo "按CTRL+C键退出..."
        sleep $interval_time
    done
else
    echo "输入的批次号$batchno有误."
    echo "请按任意键继续......"
    read a
fi
