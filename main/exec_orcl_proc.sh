#!/bin/sh

# nohup sqlplus USERNAME/password@DBNAME @test.sql &

if [ -z "$1"]; then
    echo "参数指定错误，用法:exec_orcl_proc.sh <调用存储过程语句> [可选：<参数> <数据库> <用户> <密码>]"
    exit 2
fi

dbsql=$1
param=${2:-""}
dbname=${3:-${ORCLNAME}}
dbuser=${4:-${ORCLUSER}}
dbpwd=${5:-${ORCLPWD}}

sqlplus ${param} ${dbuser}/${dbpwd}@${dbname} @${SQLPATH}/${dbsql}
# db2 connect to ${dbname} user ${dbuser} using ${dbpwd}
# db2 ${dbsql}

if [ ! $? -eq 0 ]; then
    exit 4
fi
