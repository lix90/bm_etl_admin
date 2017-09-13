#!/bin/sh

echo "\nMONTH END DATADOWN TO BE START,PRESS ENTER KEY TO CONTINUE......\c"
read a
if [ "$a" = "" ]
then
    ./start_task.sh 0 js_4001.def+1 3
    if [ $? -eq 0 ]; then
        echo "\nTASK SUBMITTED,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
    else
        echo "\nTASK FAIL,PRESS ENTER KEY TO CONTINUE......\c";read key_enter
    fi
else
    echo "\nTASK CANCELD，PRESS ENTER KEY TO CONTINUE......\c";read a
fi
