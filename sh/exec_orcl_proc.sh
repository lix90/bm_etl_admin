#!/bin/sh

#./exec_orcl_proc.sh $1

# nohup sqlplus USERNAME/password@DBNAME @test.sql &

if [ -z "$1"]; then
    echo "参数指定错误，用法:"
    echo "exec_orcl_proc.sh <调用存储过程语句> [可选：<主机IP> <数据库> <用户> <密码> <参数>]"
    exit 2
fi

job_sql=$1
db_host=${2:-${DBHOST}}
db_name=${3:-${DBNAME}}
db_user=${4:-${DBUSER}}
db_pwd=${5:-${DBPWD}}
db_param=${2:-""}

sqlplus \
    ${db_user}/${db_pwd}@${db_host}/${db_name} \
    @${job_sql} ${db_param}

if [ ! $? -eq 0 ]; then
    exit 4
fi
