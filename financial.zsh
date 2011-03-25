emulate -L zh

# Simple financial organizer

folder="finances"
format=$(date +"%Y-%m")
monthpath=$HOME/${folder}/${format}
expenses=${monthpath}/out
revenues=${monthpath}/in
cron=""
spec=""
amount=""

addExpense(){
  checkfolder
  parseoptions $@
  case $? in
      0) : ;;
      1) return 1 ;;
      2) interactive ;;
  esac
  writedata ${expenses}
}

addRevenue(){
  checkfolder
  parseoptions $@
  case $? in
      0) : ;;
      1) return 1 ;;
      2) interactive ;;
  esac
  writedata ${revenues}
}

showFinancialPosition(){
   local totalIn totalOut total
   checkfolder
   totalIn=$(cat ${revenues} | awk -F ";" '{SUM += $3} END {print SUM}')
   totalOut=$(cat ${expenses} | awk -F ";" '{SUM += $3} END {print SUM}')
   total=$((${totalIn:-0} - ${totalOut:-0}))
   printf "Revenues: %.2f\nExpenses: %.2f\nTotal:    %.2f\n" "$totalIn" "$totalOut" "$total"
   unset totalIn totalOut total
}

parseoptions(){
  if [[ -z $* ]]; then
      return 2
  fi
  while getopts "c:s:a:d:" option
  do
      case $option in
              c) if [ ! -f ${monthpath}/cron ]; then
                      cron=$OPTARG
                      touch ${monthpath}/cron
                 else
                      return 1
                 fi ;;
              s) spec=$OPTARG ;;
              a) amount=$OPTARG ;;
              d) date=$OPTARG ;;
              *) return 1 ;;
      esac
  done
  if [[ -z cron &&  (-z $spec || -z $amount) ]]; then
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
      echo ${date:-$(date +"%d. %H:%M")}\;${line} >> $1
  done < ${cron:-=($(echo ${spec}\;${amount})}
}
