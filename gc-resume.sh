#PROJECT="support-lab-poc"
PROJECT="adam-316219"

function usage {
  cat <<EOT
Usage: gc-resume.sh -n <instance name> [-p <project>]
EOT
}

while getopts n:h:p: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        p) PROJECT=${OPTARG};;
        h) usage; exit 0;;
    esac
done

if [ -z $NAME ]; then
  echo "You must specify a name"
  usage
  exit -1
fi

cat <<EOT
NAME=$NAME
PROJECT=$PROJECT
EOT

LIST=$(gcloud compute instances list --project=${PROJECT})
LINE=$(echo "${LIST}" | egrep -e "^${NAME}\s")
ZONE=$(echo ${LINE} | cut -d" " -f 2)

OUTPUT=$(gcloud beta compute instances resume ${NAME} --project=${PROJECT} --zone=${ZONE} 2>&1 |tee /dev/tty)

echo "${OUTPUT}" | grep "ERROR"
if [[ $? != 1 ]]; then
    exit -1
fi

LIST=$(gcloud compute instances list --project=${PROJECT})

LINE=$(echo "${LIST}" | egrep -e "^${NAME}\s")

echo $LINE

IP=$(echo ${LINE} | perl -ne '/\d\s+?(\d+.\d+.\d+.\d+)\s*?[A-Z]*$/; print "$1\n"')

HOSTLINE="${IP} ${NAME}.c.${PROJECT}.internal ${NAME}"

grep $IP /etc/hosts

if [[ $? != 1 ]]; then
  echo "Removing old /etc/hosts entry.  Root password required."
  sudo -E sed -i .bak -e "/$IP/d" /etc/hosts
fi

echo "Adding new host entry: '$HOSTLINE'.  Root password required."
sudo -E bash -c "echo $HOSTLINE >> /etc/hosts"
