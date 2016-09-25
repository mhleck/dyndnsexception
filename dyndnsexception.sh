#!/bin/bash

DNSALLOW_DIR_LIB="/var/lib/dyndnsexception"

if [ ! -d "$DNSALLOW_DIR_LIB" ]; then
  mkdir -p "$DNSALLOW_DIR_LIB"
  if [ ! -d "$DNSALLOW_DIR_LIB" ]; then
    echo "Error creating lib directory."
    exit 1
  fi
fi

function getip {
  IP=$(host "$1" | grep -iE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" |cut -f4 -d' '|head -n 1)
  echo $IP
}

function add_entry {
  echo "Adding entry for $1..."
  touch "$DNSALLOW_DIR_LIB/$1"
  getip $1 > "$DNSALLOW_DIR_LIB/$1"
}

function del_entry {
  echo "Removing entry for $1..."
  rm -rf "$DNSALLOW_DIR_LIB/$1"
}

function update {
  echo "Updating all the things!"
  declare -A hosts
  for file in `ls "$DNSALLOW_DIR_LIB/"`; do
    hosts["$file"]=`cat "$DNSALLOW_DIR_LIB/$file"`
  done
  for host in "${!hosts[@]}"; do echo $host --- ${hosts[$host]}; done
}

function help_message {
  echo "Usage:"
  echo "  dyndnsexception add example.com"
  echo "  dyndnsexception del example.com"
  echo "  dyndnsexception list"
  echo "  dyndnsexception help"
}

if [ -z "$*" ]; then
  update
else
  case "$1" in
    add)
      add_entry "$2"
      ;;
    del)
      del_entry "$2"
      ;;
    list)
      status anacron
      ;;
    help)
      help_message
      ;;
    *)
      echo "Invalid argument(s) provided."
      help_message
  esac
fi
