#!/bin/sh

### ----------------------------------------------------------------------
### 解密
### > 初始化 .profile
### > 从 .envset中读取密码
### ----------------------------------------------------------------------

# 初始化文件

initfile=/home/`whoami`/.profile
inittmpfile=${initfile}_$$
if [ ! -f $initfile ]; then
    echo "初始化文件$initfile 不存在."
    exit 1000
fi
cat $initfile| `awk '(!($0 ~ /admin.sh/)) {print $0}'`\
                   >$inittmpfile
chmod 755 $inittmpfile
. $inittmpfile
rm $inittmpfile

# 环境配置文件
cfgfile=/home/`whoami`/.envset
if [ ! -f $cfgfile ]; then
    echo "ETL配置文件$cfgfile不存在."
    exit 1000
fi

while read line
do
    if [ -z "$line"  ]; then
        continue;
    fi
    cryptstr=`echo $line|awk '(($2 ~ /PWD/) || ($2 ~ /PASSWORD/))  {print $0}'`
    if [ -z "$cryptstr" ]; then
        continue;
    fi
    decryptstr=""
    id=1

    while :
    do
        itemstr=`echo $cryptstr|awk -v itemid=$id '{print $itemid}'`
        if [ -z "$itemstr" ]; then
            break
        else
            itemvalstr1=`echo $itemstr|awk -F = '{print $1}'`
            itemvalstr2=`echo $itemstr|awk -F = '{print $2}'`
            if [ -z "$itemvalstr2" ]; then
                id=`expr $id + 1`
                continue
            else
                itemvalstr1_cur="\$${itemvalstr1}_cur"
                decryptstr="${itemvalstr1}=${itemvalstr1_cur}"
            fi
        fi
        id=`expr $id + 1`
    done
    eval "$decryptstr"
    itemvar="\$${itemvalstr1}"
    decryval=`eval echo $itemvar`

    if [ ! -z "${itemvalstr2}" -a -z "${decryval}"  ]; then
        echo "ERROR:${itemvalstr1} value missing."
        echo "ERROR:Load Encrypt Information fail,Job Interrupt."
        starttime=`date +%Y%m%d_%H%M%S`
        # 获取写日志锁
        getlock
        print "$batchno:${curjob}:0:$starttime:$starttime:失败:$jobid" >>$ETLHOME/etllog/$batchno/run.log
        # 释放写日志锁
        releaselock
        exit 1001
    fi
done<$cfgfile
