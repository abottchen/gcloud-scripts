#!/bin/bash

PROJECT="adam-316219"
ZONE="us-west1-b"

function usage {
  cat <<EOT
Usage: gk-destroy.sh -c <cluster name>
EOT
}

while getopts c:h flag
do
    case "${flag}" in
        c) CLUSTER=${OPTARG};;
        h) usage; exit 0;;
    esac
done

if [ -z $CLUSTER ]; then
  echo "ERROR: You must specify a cluster name"
  usage
  exit -1
fi

cat <<EOT
CLUSTER=$CLUSTER
PROJECT=$PROJECT
EOT

gcloud container clusters delete --project ${PROJECT} --zone=${ZONE} ${CLUSTER}
