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
### chmod
chmod +x $ETLHOME/sh/*.sh

### 启动菜单
$ETLHOME/sh/start_menu.sh
