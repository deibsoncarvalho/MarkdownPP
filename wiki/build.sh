#!/bin/bash

if [ ! -n "$1" ]; then
build_target="usage"
else
build_target=$1
fi

TOP_DIR=$(pwd)

function usage(){
    echo "----------USAGE: build.sh modules-----------"
    echo "| default                   show this menu |"
    echo "| clean                clean all .md files |"
    echo "| board name               build .md files |"
    echo "--------------------------------------------"
}

function build_clean(){
    echo clean *.md in zh_CN
    cd ${TOP_DIR}/zh_CN/base && rm *.md && cd -
    echo clean *.md in en
    cd ${TOP_DIR}/en && rm *.md && cd -
}

function build_md(){
    cd ${TOP_DIR}/zh_CN/base
    files=$(ls *.mdpp)
    for file in $files
    do 
        markdown-pp $file -f $json -o ${file%.*}.md
    done

    cd ${TOP_DIR}/en
    files=$(ls *.mdpp)
    for file in $files
    do 
        markdown-pp $file -f $json -o ${file%.*}.md
    done   
}

if [ $build_target == usage ]; then
usage
exit 0
elif [ $build_target == clean ]; then
build_clean
exit 0
elif [ -e "${TOP_DIR}/json/${build_target}.json" ]; then
json="${TOP_DIR}/json/${build_target}.json"
build_md
exit 0
else
echo No such command or no ${build_target}.json in json file
exit 1
fi
