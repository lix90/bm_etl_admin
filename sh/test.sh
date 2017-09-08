#!/bin/sh

inputfile=$1
inputparam=${2-"parameters"}

helloworld=`cat $inputfile`

echo "TESTING RESULTS:"
echo "$helloworld"
echo ""
echo "BELOW IS PARAMETERS"
echo ""
echo "$inputparam"
