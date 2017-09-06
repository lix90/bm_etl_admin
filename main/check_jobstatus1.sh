#!/bin/sh

logfilename="${logfile}_jobstatus"
${binfiledirectory}/dsjob \
                   -server ${DSSERVER} \
                   -user ${DSUSER} \
                   -password ${DSPASSWORD} \
                   -jobinfo ${DSPROJECT} ${jobunit} \
                   >> ${logfilename}

error=`grep "Job Status" ${logfilename}`
error=${error##*\(}
error=${error%%\)*}

if [ "${error}" = "1" ]; then
    jobstatus=0
else
    jobstatus=${error}
fi
