#!/bin/sh

# nohup sqlplus USERNAME/password@DBNAME @test.sql &

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" ]; then
    echo "参数指定错误，用法:exec_orcl_proc.sh <数据库> <用户> <密码> <调用存储过程语句>"
    exit 2
fi


dbname=$1
dbuser=$2
dbpwd=$3
dbsql=$4

sqlplus ${dbuser}/${dbpwd}@${dbname} @${dbsql}
# db2 connect to ${dbname} user ${dbuser} using ${dbpwd}
# db2 ${dbsql}

if [ ! $? -eq 0 ]; then
   exit 4
fi
