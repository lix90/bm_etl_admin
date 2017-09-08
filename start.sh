#!/bin/sh

# while :
# do
#     if [ -z $TASKPATH ]; then
#         echo "PLEASE INPUT TASKPATH:"
#         read TASKPATH
#         echo "TASKPATH IS: $TASKPATH"
#         echo "PLEASE PRESS [ENTER] KEY TO CONTINUE..."
#         echo enter_key
#     else
#         break
#     fi
# done

# if [ ! -d "$TASKPATH" ]; then
#     echo "ERROR: TASKPATH IS NOT LEGAL."
#     exit
# fi

# export TASKPATH

### 初始变量
INTERVAL=${1:-10}

### chmod
chmod +x ./sh/*.sh

### 启动菜单
./sh/start_menu.sh $INTERVAL

