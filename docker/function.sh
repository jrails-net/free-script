#!/bin/bash

echo 'loading function.sh'
source /etc/profile

function error_exit {
  echo "$1" 1>&2
  exit 1
}

function string_replace {
  echo "${1/\*/$2}"
}
