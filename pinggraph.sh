#!/bin/bash

usage (){
  echo "Usage: pingtest.sh twitter.com"
  exit 1
}

if [ $# -ne 1 ]; then
  usage
  exit 1
fi


# simple_curses.sh from: https://code.google.com/p/bashsimplecurses/
. `dirname $0`/bashsimplecurses-read-only/simple_curses.sh


DOMAIN="$1"
TMPFILE=tmppinggraphfile.tmp
ping "$DOMAIN" | awk -F '[ /]' '{ sub("time=", "", $7); print $7; fflush() }' > $TMPFILE &
PINGPID=$!

sleep 2 # Wait for some data


script="set terminal dumb 80 40; set yrange[0:1000]; plot 'FILE' with impulses title 'Ping (ms)';"
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
  TMPGRAPH=tmpgraph.tmp
  window "$DOMAIN Ping Graph"
  addsep
  gnuplot -persist -e "${script/FILE/$TMPFILE}" > "$TMPGRAPH"
  cat "$TMPGRAPH"
  endwin
  rm $TMPGRAPH
}
main_loop 1
