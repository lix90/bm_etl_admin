#! /bin/sh

###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
### 该脚本用于获取密码
### 1. 如果环境变量中包含有密码字段 'PWD' 或者 'PASSWORD'
###    并且不为空，那么使用指定的密码
### 2. 如果密码字段的值为变量，则自动从后台读取密码
###>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

LOGPATH=$TASKPATH/log

## 环境变量文件
cfgfile=/home/`whoami`/.envset
if [ ! -f $cfgfile ]; then
   echo "ETL配置文件$cfgfile不存在."
   exit 1000
fi

## 读取环境变量文件
# passstr='PWD|PASSWORD'
cryptstr=`cat $cfgfile | grep 'PWD|PASSWORD'`

while read line
do
    decryptstr=""
    id=1
    while :
    do
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        # 密码为空，跳出当前循环
        # 否则，执行解密
        # 密码为明文，直接使用
        # 密码为变量，后台获取密码
        #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        itemvalstr1=`echo $line|awk -F = '{print $1}'`
        itemvalstr2=`echo $line|awk -F = '{print $2}'`
        if [ -z "$itemvalstr2" ]; then
            id=`expr $id + 1` 
            continue
        else
            envflag=`echo $itemvalstr2|awk '$1 ~/[\$]/ {print 1}'`
            if [ -z "$envflag" ]; then
                decrypt_pwd=`eval $ETLHOME/sh/crypt.sh $itemvalstr2 decrypt`
                decryptstr="export ${itemvalstr1}=$decrypt_pwd" 
                decryptstr2="export ${itemvalstr1}_cur=$decrypt_pwd"
            else
                decryptstr="export ${itemvalstr1}=$itemvalstr2"
                decryptstr2="export ${itemvalstr1}_cur=$itemvalstr2"
            fi
        fi
        id=`expr $id + 1`
    done

    # 导出密码变量
    eval "$decryptstr"
    eval "$decryptstr2"

    # 如果密码为空
    itemvar="\$${itemvalstr1}"
    decryval=`eval echo $itemvar`
    if [ ! -z "$itemvalstr2" -a -z "${decryval}" ]; then
        echo "ERROR: 缺少${itemvalstr1}.">>$LOGPATH/run.err
        echo "ERROR: 导入密文失败，调度终止.">>$LOGPATH/run.err 
        exit 1010  
    fi
done<cat $cryptstr
