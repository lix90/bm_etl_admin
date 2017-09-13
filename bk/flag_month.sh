#!/bin/sh

echo "\nPLEASE INPUT MONTH END FLAG（Y-MONTH END N-NOT MONTH END）:\c"
read ans
if [ "$ans" = "Y" -o "$ans" = "y" ]; then
    touch $ETLHOME/etllog/monthend.flag
    echo "\nMONTH END FLAG:Y."
else
    if [ -f $ETLHOME/etllog/monthend.flag ]; then
        rm $ETLHOME/etllog/monthend.flag
    fi
    echo "\nMONTH END FLAG:N."
fi
echo "\nPRESS ENTER KEY TO CONTINUE......\c"
read key_enter
