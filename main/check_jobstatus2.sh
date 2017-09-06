#!/bin/sh

jobwaiting=`grep "Waiting for job..." $1`
endtime=`date +%Y%m%d_%H%M%S`
if [ "${jobwaiting}" != "Waiting for job..." ]; then
    jobstatus=-1
else
    jobstatus=1
fi

${binfiledirectory}/dsjob \
                   -server ${DSSERVER} \
                   -user ${DSUSER} \
                   -password ${DSPASSWORD} \
                   -jobinfo ${DSPROJECT} ${jobunit} \
                   >> $1

error=`grep "Job Status" $1`
error=${error##*\(}
error=${error%%\)*}

if [ "${jobstatus}" != "1" ]; then
    jobstatus=-1
else
    if [ "${error}" = "1" -o "${error}" = "2" ]; then
        jobstatus=0
    else
        jobstatus=${error}
    fi
    if [ ! "${error}" = "1" ]; then
        ${binfiledirectory}/dsjob \
                           -server ${DSSERVER} \
                           -user ${DSUSER} \
                           -password ${DSPASSWORD} \
                           -logsum ${DSPROJECT} ${jobunit} \
                           >> $1
    fi
fi
