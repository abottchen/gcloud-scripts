LABELS="user=adam"
#PROJECT="support-lab-poc"
PROJECT="adam-316219"
TYPE="n2-custom-8-16384"
#TYPE="n2-custom-8-4096"
ZONE="us-west1-b"
DEFAULT_IMAGE="projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20220118"

function usage {
  cat <<EOT
Usage: gc-create.sh -n <instance name> [-l <labelname=value>] [-t <type>] [-p <project>] [-d <size>] [-i image]
EOT
}

while getopts n:l:t:hp:d:i: flag
do
    case "${flag}" in
        n) NAME=${OPTARG};;
        l) LABELS="${LABELS},${OPTARG}";;
        t) TYPE=${OPTARG};;
        p) PROJECT=${OPTARG};;
        d) EXTRADISK=${OPTARG};;
        i) IMAGETXT=${OPTARG};;
        h) usage; exit 0;;
    esac
done

if [ -z $NAME ]; then
  echo "You must specify a name"
  usage
  exit -1
fi

if [ -z ${IMAGETXT} ]; then
  IMAGE=${DEFAULT_IMAGE}
fi

case "${IMAGETXT}" in
    "rhel8") IMAGE="projects/rhel-cloud/global/images/rhel-8-v20220519";;
    "rhel7") IMAGE="projects/rhel-cloud/global/images/rhel-7-v20220126";;
    "ubuntu") IMAGE="projects/ubuntu-os-cloud/global/images/ubuntu-1804-bionic-v20220131";;
    "rocky8") IMAGE="projects/rocky-linux-cloud/global/images/rocky-linux-8-v20220126";;
    "centos") IMAGE="centos-8-v20210721";;
esac

cat <<EOT
NAME=$NAME
LABELS=$LABELS
PROJECT=$PROJECT
TYPE=$TYPE
EXTRADISK=$EXTRADISK
ZONE=${ZONE}
IMAGE=${IMAGE}
EOT

DISK_CMD=""

if [[ -n ${EXTRADISK} ]]; then
  DISK_CMD="--create-disk=mode=rw,size=${EXTRADISK},type=projects/${PROJECT}/zones/${ZONE}/diskTypes/pd-balanced,name=${NAME}-disk-1,device-name=${NAME}-disk-1"
fi

COMMAND="gcloud beta compute --project=${PROJECT} instances create ${NAME} --zone=${ZONE} --machine-type=${TYPE} --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server,https-server,kots --image=${IMAGE} --image-project=centos-cloud --boot-disk-size=200GB --boot-disk-type=pd-standard --boot-disk-device-name=${NAME} ${DISK_CMD} --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any --labels=${LABELS}"

OUTPUT=$(${COMMAND} 2>&1 |tee /dev/tty)

echo "${OUTPUT}" | grep "ERROR"
if [[ $? != 1 ]]; then
  echo ${COMMAND}
  exit -1
fi

HOSTLINE=$(echo $OUTPUT | perl -ne '/projects\/(.*?)\/zones.*?STATUS (.*?) .* (\d+.\d+.\d+.\d+) (\d+.\d+.\d+.\d+) RUNNING/; print "$4 $2.c.$1.internal $2"')
IP=$(echo $HOSTLINE | cut -d" " -f 1)
HOST=$(echo $HOSTLINE | cut -d" " -f 2)

grep $IP /etc/hosts

if [[ $? != 1 ]]; then
  echo "Removing old /etc/hosts entry.  Root password required."
  sudo -E sed -i .bak -e "/$IP/d" /etc/hosts
fi

echo "Adding new host entry: '$HOSTLINE'.  Root password required."
sudo -E bash -c "echo $HOSTLINE >> /etc/hosts"

sleep 10

if [[ -x extra/push-data.sh ]]; then
  extra/push-data.sh $HOST
fi

~/bin/refresh-gcloud-instances.sh
