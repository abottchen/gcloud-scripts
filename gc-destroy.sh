#!/bin/bash

#PROJECT="support-lab-poc"
PROJECT="adam-316219"

function usage {
  cat <<EOT
Usage: gc-destroy.sh -n <instance name> [-p <project>]
EOT
}

while getopts n:p:h flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        p) PROJECT=${OPTARG};;
        h) usage; exit 0;;
    esac
done

if [ -z $NAME ]; then
  echo "ERROR: You must specify an instance name"
  usage
  exit -1
fi

cat <<EOT
NAME=$NAME
PROJECT=$PROJECT
EOT

LIST=$(gcloud compute instances list --project=${PROJECT})

LINE=$(echo "${LIST}" | egrep -e "^${NAME}\s")

# Don't know if this is possible, but I don't want to delete multiple things
if [[ $(echo "${LINE}" | wc -l ) -gt 1 ]]; then
  echo "ERROR: Multiple instances matching that name.  Cowarding out"
  exit -1
elif [[ -z ${LINE} ]]; then
  echo "ERROR: No instance named '${NAME}' found"
  exit -1
fi

echo $LINE

ZONE=$(echo ${LINE} | cut -d" " -f 2)
IP=$(echo ${LINE} | perl -ne '/\d\s+?(\d+.\d+.\d+.\d+)\s*?[A-Z]*$/; print "$1\n"')

OUTPUT=$(gcloud beta compute instances delete ${NAME} --project=${PROJECT} --zone=${ZONE} 2>&1 |tee /dev/tty)

echo "${OUTPUT}" | grep "ERROR"
if [[ $? != 1 ]]; then
  exit -1
fi

if [[ ${IP} ]]; then
  # Don't know if this is possible, but I don't want to delete multiple things
  if [[ $(grep ${IP} /etc/hosts | wc -l ) -gt 1 ]]; then
    echo "ERROR: Multiple host entries found matching '${IP}'.  Cowarding out on hosts update"
    exit
  fi
  
  if [[ ${IP} ]]; then
    grep $IP /etc/hosts
    if [[ $? != 1 ]]; then
      echo "Removing old /etc/hosts entry for ${IP}.  Root password required."
      sudo -E sed -i .bak -e "/$IP/d" /etc/hosts
    fi
  fi
fi
