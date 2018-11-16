#!/bin/bash
if [ -z "$1" ]; then
    echo "No .env argument supplied. Exiting"
    exit 1
fi
if [ ! -f "$1" ]; then
    echo "$1 is not a file. Exiting"
    exit 1
fi

# oddly bash refused to run on file `.env` so copy it to a temp file first
FILE=/tmp/$$
cp $1 $FILE
awk "BEGIN {FS = \"=\" ; print \"apiVersion: v1\nkind: Secret\nmetadata:\n  name: $NAME\nstringData:\"} NF==2 && \$1 !~ /#.*/ && \$2 !~ /^$/{print \"  \" \$1 \": \x22\" \$2 \"\x22\"}" $FILE | sed 's/""/"/g' | oc create -f -
rm $FILE
