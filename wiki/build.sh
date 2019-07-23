#!/bin/bash

if [ ! -n "$1" ]; then
echo Lack of parameters. 
exit 1
fi

TOP_DIR=$(pwd)
if [ -e "${TOP_DIR}/json/${1}.json" ]; then
json="${TOP_DIR}/json/${1}.json"
else
echo No find ${1}.json in json file
exit 1
fi

cd ${TOP_DIR}/zh_CN/base

files=$(basename `ls *.mdpp`)
for file in $files
do
    markdown-pp $file.mdpp -f $json -o ${file%*.}.md
done
