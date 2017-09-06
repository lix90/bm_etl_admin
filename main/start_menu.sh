#! /bin/sh

### ----------------------------------------------------------------------
### 命令行ETL调度
### - 启动ETL任务
### - 重启ETL任务
### - 运行特定的作业

start_menu() {

    trap "rm $ETLHOME/shell/schedule*.lst 2>/dev/null;start_menu" 2 3
    clear

    echo "\n\n                      BM ETL ADMIN DESKTOP V3.0\n"

    echo "                         1. ETL START"
    echo "                         2. ETL RESTART"
    echo "                         3. RUN SPECIAL JOB"
    echo "                         4. ETL ONWATCH"
    echo "                         5. STOP SCHEDULE"
    echo "                         6. RESET SCHEDULE STATUS"
    echo "                         7. SET MONTH END FLAG"
    echo "                         8.EXECUTE JOBSEQ SCRIPT"
    echo "                         0. EXIT"
    echo "\n                    INPUT MENUITEM ID: \c"

    read ans
    clear

    case $ans in
        1) ./etl_start.sh
           ;;
        2) ./etl_restart.sh
           ;;
        3) ./run_jobspec.sh
           ;;
        4) ./etl_monitor.sh
           ;;
        5) ./sch_stop.sh
           ;;
        6) ./sch_reset.sh
           ;;
        7) ./flag_month.sh
           ;;
        8) ./run_jobseq_inter.sh
           ;;
        0) if [ -f $ETLHOME/etllog/joblstrun.log$$ ]; then
               rm $ETLHOME/etllog/joblstrun.log$$
           fi
           exit
           ;;
        *) echo "\nERROR CHOICE, PRESS ENTER KEY TO CONTINUE......\c"
           read a
           ;;
    esac

    start_menu
}

start_menu
