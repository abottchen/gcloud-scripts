#!/bin/bash

#PROJECT="support-lab-poc"
PROJECT="adam-316219"

function usage {
  cat <<EOT
Usage: gc-list.sh [-p <project>]
EOT
}

while getopts hp: flag
do
    case "${flag}" in
        p) PROJECT=${OPTARG};;
        h) usage; exit 0;;
    esac
done

gcloud compute instances list --project=${PROJECT}
