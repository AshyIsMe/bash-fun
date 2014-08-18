#!/bin/bash

error(){
  echo "$1"
  exit 1
}

usage (){
  error "Usage: pingtest.sh twitter.com"
}

if [ $# -ne 1 ]; then
  usage
fi


# simple_curses.sh from: https://code.google.com/p/bashsimplecurses/
BASE=$( cd $(dirname $0) ; pwd -P )
source ${BASE}/bashsimplecurses-read-only/simple_curses.sh

SCRIPTBASENAME=`basename $0`

DOMAIN="$1"
TMPFILE=`mktemp /tmp/${SCRIPTBASENAME}.XXXXXX` || error "Error openening temp file"
ping -n "$DOMAIN" | awk -F '[ /]' '!/PING/{ sub(".*time=", "", $7); print $7; fflush() }' > $TMPFILE &
#( ping -n $DOMAIN | sed -un 's/^.*time=\([[:digit:]]\+\).*$/\1/p' > $TMPFILE ) &
PINGPID=$!

sleep 2 # Wait for some data


cols=$(tput cols);
rows=$(tput lines); let "rows -= 8";
script="set terminal dumb ${cols} ${rows}; set yrange[0:1000]; plot 'FILE' with impulses title 'Ping (ms)';"
#gnuplot -persist -e "${script/FILE/$TMPFILE}"

#script="plot 'data-file.dat'"
script="${script/FILE/$TMPFILE}"


#Fifo method of redrawing
######################################################################
#mkfifo $$.gnuplot-pipe
#gnuplot -p <$$.gnuplot-pipe & pid=$! exec 3>$$.gnuplot-pipe
#echo "$script" >&3

#running=1
#trap 'running=0' SIGINT
##while [[ $running -eq 1 && $(lsof "$1" | wc -l) -gt 0 ]]; do
#while [[ $running -eq 1 && $(lsof "$TMPFILE" | wc -l) -gt 0 ]]; do
    #echo "replot" >&3
    #sleep .5s
#done

#exec 3>&-
#rm $$.gnuplot-pipe
#wait $pid
######################################################################


#AA TODO: Need to chain this with the simple_curses.sh on_kill func
on_kill(){
    echo "Removing tmp files"
    rm -rf $TMPFILE
    exit 0
}
trap on_kill SIGINT SIGTERM


main(){
  TMPGRAPH=`mktemp /tmp/${SCRIPTBASENAME}.XXXXXX` || error "Error openening temp file"
  window "$DOMAIN Ping Graph" "red"
  addsep
  gnuplot -persist -e "${script/FILE/$TMPFILE}" > "$TMPGRAPH"
  cat "$TMPGRAPH"
  endwin
  rm $TMPGRAPH
}
main_loop 1
