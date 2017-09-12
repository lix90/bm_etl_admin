#!/bin/sh

INTERVAL=10
LOGPATH=$TASKPATH/log

lastest_batchno=`ls -l $LOGPATH | awk '{print $9}' | sort -n | grep '[0-9]_[0-9]' | tail -n 1`

echo ""
echo "请输入需要监控的作业批次号:"
echo "最新批次号为：$lastest_batchno"
echo "批次号从$TASKHOME/log获取"
echo ""
read tmpbatchno

if [ -z "$tmpbatchno" ]; then
    batchno=$lastest_batchno
else
    batchno=$tmpbatchno
fi

logfile=$LOGPATH/$batchno/run.log
jklogfile=$LOGPATH/joblstrun.log$$
rm ${jklogfile} 2>/dev/null
touch $jklogfile

if [ -f $logfile ]; then

    clear
    rowcnt=0;
    maxrowcnt=1;
    logtmpfile="$LOGPATH/logtmpfile$$"

    while :
    do
        clear
        rowcnt=`wc -l $logfile | awk '{print $1}'`
        tail -n +$maxrowcnt $logfile>$logtmpfile
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
        echo ""
        echo "作业状态:"
        echo ""
        echo "作业序列名     作业     状态     开始时间     结束时间     作业序号"
        echo "------------------------------------------------------------"
        awk -F : 'BEGIN {OFS=" ";} $3=="成功"  {print $1,$2,$3,$4,$5,$6} ' $jklogfile |tail -20
        awk -F : 'BEGIN {OFS=" ";} $3=="用户中断"  {print $1,$2,$3,$4,$5,$6} ' $jklogfile
        awk -F : 'BEGIN {OFS=" ";} $3=="失败" {print $1,$2,$3,$4,$5,$6} ' $jklogfile
        awk -F : 'BEGIN {OFS=" ";} $3=="等待运行" {print $1,$2,$3,$4,$5,$6} ' $jklogfile
        awk -F : 'BEGIN {OFS=" ";} $3=="运行中" {print $1,$2,$3,$4,$5,$6} ' $jklogfile

        waitjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="等待运行" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        runjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="运行中" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        failjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="失败" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        succjobcnt=`awk -F : 'BEGIN {OFS="	";} $3=="成功" || $3=="用户中断" {print $1,$2,$3,$4,$5,$6} ' $jklogfile|wc -l`
        echo "------------------------------------------------------------"
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
        echo "------------------------------------------------------------"
        echo "按0键退出..."
        read k
        if [ $k = "0" ]; then
            exit
        else
            sleep $INTERVAL
        fi
    done
else
    echo "输入的批次号$batchno有误."
    echo "请按任意键继续......"
    read a
fi
