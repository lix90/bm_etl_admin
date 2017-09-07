#!/bin/sh

jobrelation="./rel/n01.rel"

# _job=`awk -F : '{print $1 "+" $2}' $jobrelation`
# _sch=`awk -F + -v joblist=$1 '{print $1}'`
schedulefile=`
awk -F : '{print $1 "+" $2}' $jobrelation |
awk -F + -v joblist=$1 '{
x=NF;
while (x>0) {
if ($x == joblist){
print $1
} else {
print ""
};
x-=1;
}
}'`
echo $schedulefile
# echo ${_job}
