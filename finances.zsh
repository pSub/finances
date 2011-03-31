#!/bin/zsh
# Simple financial organizer

folder="finances"
format=$(date +"%Y-%m")
monthpath=$HOME/${folder}/${format}
expenses=${monthpath}/out
revenues=${monthpath}/in
modes=(in out show)
dateformat="%d. %H:%M"
cron=""
spec=""
amount=""
file=""


finances(){
  checkfolder
  parseoptions $@
  case $? in
      0) : ;;
      1) exit 1 ;;
      2) interactive ;;
  esac

  case $mode in
      "in") writedata ${revenues} ;;
      "out") writedata ${expenses} ;;
      "show") show ;;
  esac
}

show(){
   local totalIn totalOut total
   totalIn=$(cat ${revenues} | awk -F ";" '{SUM += $3} END {print SUM}')
   totalOut=$(cat ${expenses} | awk -F ";" '{SUM += $3} END {print SUM}')
   total=$((${totalIn:-0} - ${totalOut:-0}))
   printf "Revenues: %.2f\nExpenses: %.2f\nTotal:    %.2f\n" "$totalIn" "$totalOut" "$total"
   unset totalIn totalOut total
}

parseoptions(){
  argnum=$#
  while getopts "c:s:a:d:f:" option
  do
      case $option in
              c) cron=true;
                 file=$OPTARG ;;
              f) file=$OPTARG ;;
              s) spec=$OPTARG ;;
              a) amount=$OPTARG ;;
              d) date=$OPTARG ;;
              *) return 1 ;;
      esac
  done
  shift $(($OPTIND - 1))

  if [[ ${${modes[(r)$1]}:+1} -eq 1 ]]; then
        mode=$1
  else
        return 1
  fi

  if [[ $mode != "show" ]] && [ $(($argnum - 1)) -eq 0 ]; then
        return 2
  fi
  
  if $cron &&  [ ! -f ${monthpath}/cron-$1 ]; then
        touch ${monthpath}/cron-$1
  else
        return 1
  fi
  return 0
}

interactive(){
    echo -n "Description: "
    read spec
    echo -n "Amount: "
    read amount
    echo -n "Date (optional): "
    read date
}

checkfolder(){
  if [[ ! -d ${monthpath} ]]; then
    mkdir -p ${monthpath}
    touch ${expenses}
    touch ${revenues}
  fi
}

writedata(){
  while read line; do
      echo ${date:-$(date +${dateformat})}\;${line} >> $1
  done < ${file:-=($(echo ${spec}\;${amount})}
}
