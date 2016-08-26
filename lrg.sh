#!/bin/bash
# LRG: Low Rent Gaurd
# Executes a file when it changes

### Set initial time of file
LTIME=`stat -f "%c" $1`

EXECUTABLE="${2:-$1}"

while true
do
   ATIME=`stat -f "%c" $1`

   if [[ "$ATIME" != "$LTIME" ]]
   then
       echo "$1 changed. Executing $EXECUTABLE."
       $EXECUTABLE
       LTIME=$ATIME
   fi

   sleep 0.5
done
