#!/bin/sh

# 中断作业调度

echo "INPUT JOBSEQ NAME(DEFAULT:IMMEDIATELY):"
read jobname
if [ -z "$jobname" ]; then
    echo "AFTER CURRENT JOBSEQ FINISHED, SUCCEEDING JOB TO BE CANCELD."
    jobpos=0
else
    echo "INPUT JOBSEQ POSITION OF $jobname (DEFAULT:0):"
    read jobpos
    if [ -z "$jobpos" ]; then
        jobpos=0
    fi
    echo "AFTER STEP $jobpos OF ${jobname} FINISHED, SUCCEEDING JOB TO BE CANCELD."
fi
echo "PRESS ENTER KEY TO CONTINUE......"
read key_enter
if [ "$key_enter" = "" ]; then
    echo "$jobname:$jobpos"\
         >> $LOGPATH/halt.flag
    echo "SET INTERRUPT FLAG SUCCESSFUL."
    echo "PRESS ANY KEY TO CONTINUE......"
    read key_enter
fi
