#!/bin/bash


#ping -c 10 twitter.com | awk -F '[ /]' '{ print $7 }' | sed 's/time=//' | gnuplot -persist -e "set terminal dumb 121 28; set yrange[200:400]; plot '-' with impulses title 'Ping (ms)';"

TMPFILE=tmppinggraphfile.tmp
ping "$1" | awk -F '[ /]' '{ sub("time=", "", $7); print $7; fflush() }' > $TMPFILE &
PINGPID=$!

sleep 2 # Wait for some data


script="set terminal dumb 121 28; set yrange[0:1000]; plot 'FILE' with impulses title 'Ping (ms)';"
#gnuplot -persist -e "${script/FILE/$TMPFILE}"

#script="plot 'data-file.dat'"
script="${script/FILE/$TMPFILE}"

mkfifo $$.gnuplot-pipe
gnuplot -p <$$.gnuplot-pipe & pid=$! exec 3>$$.gnuplot-pipe
echo "$script" >&3

running=1
trap 'running=0' SIGINT
#while [[ $running -eq 1 && $(lsof "$1" | wc -l) -gt 0 ]]; do
while [[ $running -eq 1 && $(lsof "$TMPFILE" | wc -l) -gt 0 ]]; do
    echo "replot" >&3
    sleep .5s
done

exec 3>&-
rm $$.gnuplot-pipe
wait $pid



#kill $PINGPID
rm $TMPFILE
