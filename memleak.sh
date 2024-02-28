#!/bin/bash

# 颜色样式定义
RESET="\e[0m"
BOLD="\e[1m"
UNDERLINE="\e[4m"
BLINK="\e[5m"
REVERSE="\e[7m"

# 文字颜色定义
BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"

# 函数：显示彩色文本
color_text() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

function check_nmt() {
  pid=$1
  cmdline_file="/proc/$pid/cmdline"

  if [ ! -e $cmdline_file ]; then
      echo "PID $pid 不存在"
      exit 1
  fi

  cmdline=$(tr '\0' ' ' < $cmdline_file)

  if [[ $cmdline =~ NativeMemoryTracking=([^[:space:]]+) ]]; then
      tracking_value="${BASH_REMATCH[1]}"
      echo "PID $pid 的启动命令行中包含 NativeMemoryTracking，值为: $tracking_value"
  else
      echo "PID $pid 的启动命令行中不包含 NativeMemoryTracking"
  fi

  # 检查是否包含 "detail"，如果没有则报错
  if [[ ! $cmdline =~ detail ]]; then
      echo "错误：启动命令行中未包含 'detail'"
      exit 1
  fi
}

function clean() {
    rm -f ./nmt.txt
    rm -f ./pmap.txt
}

function show() {
    pid=$1
    check_nmt $pid
    #echo success
    pmap -x $pid > ./pmap.txt

    # 生成nmt
    user=$(ps -o user= -p $pid | awk '{print $1}')
    echo "PID $pid 的启动用户是: $user"
    sudo -u $user jcmd $pid VM.native_memory detail > ./nmt.txt


    default_thr=65536
    thr="${2:-$default_thr}"
    # 遍历在pmap中出现，但是nmt中没有出现的行
    while IFS= read -r line && IFS= read -r next_line; do
      # 初始化一个标志变量，表示是否所有行都不包含字符串A
      all_lines_not_contain_a=true
      if [[ $line != 000* ]]; then
        continue
      fi
      if [[ $next_line != 000* ]]; then
        continue
      fi
      if [[ $line == *.* ]]; then
        continue
      fi
      if [[ $next_line == *.* ]]; then
        continue
      fi

      num1=$(echo $line | awk '{print $2}')
      num2=$(echo $next_line | awk '{print $2}')
      sum=$(expr "$num1" + "$num2")
      if [ "$sum" -lt $thr ]; then
        continue
      fi

      pmap_entry=$(echo $line | awk '{print $1}')
      if ! grep -q "$pmap_entry" "./nmt.txt"; then
          color_text "$RED$BOLD" "$line"         
          color_text "$GREEN$BOLD" "$next_line"
      fi
    done < './pmap.txt'
}

# 1:pid 2:addr
function do_dump() {
  cat /proc/$1/maps | grep -Fv ".so" | grep " 0 " | awk '{print $1}' | grep $2 | ( IFS="-"
  while read a b; do
    dd if=/proc/$1/mem bs=$( getconf PAGESIZE ) iflag=skip_bytes,count_bytes \
    skip=$(( 0x$a )) count=$(( 0x$b - 0x$a )) of="$1_mem_$a.bin"
    color_text "$GREEN$BOLD" "Dump文件已输出至: ./$1_mem_$a.bin"  
  done )
}

# addr
function dump() {
    pid=$1
    addr=$(echo "$2" | sed 's/^0*//')
    do_dump "$pid" "$addr"
}

cmd=$1
if [ "$1" = "show" ]; then
  show $2 $3
elif [ "$1" = "dump" ]; then
  dump $2 $3
else
  echo "Usage:"
  echo "显示可能出现内存泄漏的地址块:"
  echo "$0 show pid"
  echo "dump内存到当前目录下:"
  echo "$0 dump pid addr"
  echo ""
  color_text "$GREEN" "star me at https://github.com/hengyoush/JavaMemLeak :)"
fi
