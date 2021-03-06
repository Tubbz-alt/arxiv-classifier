#!/bin/bash


source config.sh

if [ ! %1 ]
then
    echo "Must pass image URL as first parm"
    exit 1
fi


gcloud container images describe %1

if [ %! ]
then
    echo "No image found for %1"
    gcloud container images list
    exit 1
fi

set -ef
TEMPLATE="classifier-template-$(date +%Y%M%d-%H%M%S)"

#### UPDATE PROCESS ####

# create a new template with a new name
gcloud compute instance-templates create-with-container $TEMPLATE \
       --machine-type e2-medium \
       --tag=allow-classifier-health-check \
       --container-image $IMAGE_URL

# change the template of the instance group
gcloud compute instance-groups managed set-instance-template $CLASSIFIER_MIG \
       --template=$TEMPLATE \
       --zone=$ZONE

# start a rolling update of the instance group
gcloud compute instance-groups managed rolling-action start-update $CLASSIFIER_MIG \
       --version template=$TEMPLATE \
       --max-surge 4 \
       --zone=$ZONE
