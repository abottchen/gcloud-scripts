#!/bin/bash

LABELS="user=adam"
PROJECT="adam-316219"
ZONE="us-west1-b"
NUM="1"

function usage {
  cat <<EOT
Usage: gk-create.sh -c <cluster name> [-l <labelname=value>] [-p <project>] [-n <number of nodes>]
EOT
}

while getopts c:l:hp:n: flag
do
    case "${flag}" in
        c) CLUSTER=${OPTARG};;
        l) LABELS="${LABELS},${OPTARG}";;
        p) PROJECT=${OPTARG};;
        n) NUM=${OPTARG};;
        h) usage; exit 0;;
    esac
done

if [ -z $CLUSTER ]; then
  echo "You must specify a cluster name"
  usage
  exit -1
fi

cat <<EOT
CLUSTER=$CLUSTER
LABELS=$LABELS
PROJECT=$PROJECT
NUM=$NUM
EOT

gcloud container clusters create ${CLUSTER} --labels=${LABELS} --project=${PROJECT} --release-channel None --machine-type e2-custom-6-16384 --zone=${ZONE} --num-nodes ${NUM} --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --no-enable-autoupgrade --no-enable-autorepair
