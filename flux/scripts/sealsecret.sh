#!/bin/bash

MASTERKEY=$1
SECRET=$2
KEY=$3
VALUE=$4
EPOCH=`date +%s`

echo "PEM-File   = '$MASTERKEY'"
echo "KEY        = '$KEY'"
echo "VALUE      = '$VALUE'"
echo ""
echo "Yaml       = ${KEY}_${EPOCH}.yaml"
echo "Sealed YML = ${KEY}_${EPOCH}.sealed.yaml"


kubectl -n apps create secret generic $SECRET --from-literal=$KEY=$VALUE --dry-run=client -o yaml > "${KEY}_${EPOCH}.yaml"

kubeseal --cert $MASTERKEY --format yaml <${KEY}_${EPOCH}.yaml >${KEY}_${EPOCH}.sealed.yaml
cat ${KEY}_${EPOCH}.sealed.yaml

echo ""
echo "------------------------------"
echo "Insert the following secret as an encryptedSecret to your release yaml"
echo "------------------------------"
yq e .spec.encryptedData ${KEY}_${EPOCH}.sealed.yaml