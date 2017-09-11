#!/bin/sh

inputfile=$1
inputparam=${2-"parameters"}

helloworld=`cat $inputfile`

cat <<EOF>$TASKPATH/log/test_is_success
TESTING RESULTS:
$helloworld
BELOW IS PARAMETERS
$inputparam
EOF
