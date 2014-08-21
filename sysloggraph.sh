#!/bin/bash
# Graph a daily count of syslog messages


SCRIPTBASENAME=`basename $0`
TMPFILE=`mktemp /tmp/${SCRIPTBASENAME}.XXXXXX` || error "Error openening temp file"

# Data feed:
# <Count> <Date>
# eg. 42 "Aug 20"
#syslog | cut -c 1-6 | uniq -c > $TMPFILE
#syslog | sed -E '/^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/p' | head -n 10

filterOnlyDates() {
cut -c 1-6 | grep -E '^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ([[:digit:]]+)'
}

#syslog | cut -c 1-6 | grep -E '^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ([[:digit:]]+)'
syslog | filterOnlyDates | uniq -c | awk -F' ' '{ print $1 " " $2 $3; }' > $TMPFILE


cols=$(tput cols);
rows=$(tput lines); let "rows -= 8";
script="set terminal dumb ${cols} ${rows}; "
#The X labels don't print vertically in terminal unfortunately.
#Uncomment the next line and gnuplot will show the chart in a gui window
#script="" 
script="$script set xtics rotate;"
script="$script plot 'FILE' using 1:xtic(2) with impulses title 'syslog messages per day';"

#script="plot 'data-file.dat'"
script="${script/FILE/$TMPFILE}"

gnuplot -persist -e "${script/FILE/$TMPFILE}"

rm $TMPFILE
