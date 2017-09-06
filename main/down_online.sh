#!/bin/sh

echo "\n联机文件下载即将开始,按回车键确认......\c"
read a
if [ "$a" = "" ]
then
    ./start_task.sh 0 js_2501.def+1 2
    if [ $? -eq 0 ]; then
        echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
    else
        echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
    fi
else
    echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
fi
