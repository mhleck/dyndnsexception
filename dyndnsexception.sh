#!/bin/bash

LIBDIR="/var/lib/dyndnsexception"
VERBOSE=1

function echo_verbose {
  if [ "$VERBOSE" -eq 1 ]; then
    echo "$1"
  fi
}

if [ ! -d "$LIBDIR" ]; then
  mkdir -p "$LIBDIR"
  if [ ! -d "$LIBDIR" ]; then
    my_log "Error creating lib directory."
    exit 1
  fi
fi

function getip {
  IP=$(host "$1" | grep -iE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" |cut -f4 -d' '|head -n 1)
  echo $IP
}

function add_entry {
  echo "Adding entry for $1..."
  touch "$LIBDIR/$1"
  getip $1 > "$LIBDIR/$1"
}

function del_entry {
  echo "Removing entry for $1..."
  rm -rf "$LIBDIR/$1"
}

function ufw_exist {
  echo_verbose "Checking if $1 exists in UFW"
  return `ufw status | grep "$1" | grep Anywhere | wc -l`
}

function ufw_add {
 if ufw_exist $1 ; then
   echo_verbose "Adding $1 to UFW"
   ufw allow from "$1"
 fi
}

function ufw_del {
 if ufw_exist $1 ; then
   echo_verbose "Deleting $1 from UFW"
   ufw delete allow from "$1"
 fi
}

function update {
  echo_verbose "Updating all the things!"
  declare -A hosts
  for file in `ls "$LIBDIR/"`; do
    hosts["$file"]=`cat "$LIBDIR/$file"`
  done
  for host in "${!hosts[@]}"; do
    echo_verbose $host --- ${hosts[$host]};
    newip=`getip $host`
    if [ "${hosts[$host]}" != "$newip" ]; then
      ufw_del ${hosts[$host]}
    fi
    ufw_add $newip
  done
}

function help_message {
  echo "Usage:"
  echo "  dnsallow add example.com"
  echo "  dnsallow del example.com"
  echo "  dnsallow list"
  echo "  dnsallow help"
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
