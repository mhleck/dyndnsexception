#!/bin/bash

LIBDIR="/var/lib/dyndnsexception"
DEBUG=0

function echo_debug {
  if [ "$DEBUG" -eq 1 ]; then
    echo "$1"
  fi
}

if [ ! -d "$LIBDIR" ]; then
  mkdir -p "$LIBDIR"
  if [ ! -d "$LIBDIR" ]; then
    my_log "Error creating lib directory."
    exit 1
  else
    chmod -R 0700 /var/lib/dyndnsexception
  fi
fi

function getip {
  IP=$(host "$1" | grep -iE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | cut -f4 -d' '| head -n 1)
  echo $IP
}

function add_entry {
  IP=`getip "$1"`
  if [ -z $IP ]; then
    echo_debug "Skipping $1, error resolving IP for hostname."
  else
    echo_debug "Adding entry for $1 ($IP)."
    touch "$LIBDIR/$1"
    echo "$IP" > "$LIBDIR/$1"
    ufw_add "$IP"
  fi
}

function del_entry {
  IP=`cat "$LIBDIR/$1"`
  echo_debug "Removing entry for $1 ($IP)."
  rm -rf "$LIBDIR/$1"
  ufw_del "$IP"
}

function ufw_exist {
  #echo_debug "Checking if $1 exists in UFW"
  status=`ufw status | grep "$1" | grep Anywhere | wc -l`
  if [ $status -gt 0 ]; then
    echo "true"
  else
    echo "false"
  fi
}

function ufw_add {
  UFWRULEEXISTS=`ufw_exist "$1"`
  if [ "$UFWRULEEXISTS" != "true" ] ; then
    echo_debug "Adding $1 to UFW"
    ufw allow from "$1"
  fi
}

function ufw_double_check {
  declare -A hosts
  for file in `ls "$LIBDIR/"`; do
    hosts["$file"]=`cat "$LIBDIR/$file"`
  done
  RETURNVALUE="false"
  for host in "${!hosts[@]}"; do
    if [ "$1" == "${hosts[$host]}" ]; then
      RETURNVALUE="true"
    fi
  done
  echo "$RETURNVALUE"
}

function ufw_del {
  UFWDOUBLE=`ufw_double_check "$1"`
  if [ "$UFWDOUBLE" == "true" ]; then
    echo_debug "Not removing $1 from UFW, another entry shares the same IP."
  else
    UFWRULEEXISTS=`ufw_exist "$1"`
    if [ "$UFWRULEEXISTS" == "true" ] ; then
      echo_debug "Deleting $1 from UFW"
      ufw delete allow from "$1"
    fi
  fi
}

function update {
  echo_debug "Updating all the things!"
  declare -A hosts
  for file in `ls "$LIBDIR/"`; do
    hosts["$file"]=`cat "$LIBDIR/$file"`
  done
  for host in "${!hosts[@]}"; do
    echo_debug $host --- ${hosts[$host]};
    newip=`getip "$host"`
    if [ "${hosts[$host]}" != "$newip" ]; then
      ufw_del ${hosts[$host]}
    fi
    ufw_add $newip
  done
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
