#!/bin/bash

NS=$1
PG_ENV_USER=$2
PG_ENV_PASSWD=$3
PG_POD_NAME=$4
PG_DB_NAME=$5

export $(xargs <../.env)
export KUBECONFIG=${HOME}/PROM-K3S-${ENV}/kubeconfig.yaml

KEY_FILE=${HOME}/secrets/sa.json
PG_USER=${!PG_ENV_USER}
PG_PASSWORD=${!PG_ENV_PASSWD}

SQL_NAME=${NS}.pgsql-dump-${PG_DB_NAME}.sql
DB_PASSWD=${MARIADB_ROOT_PASSWORD}
BK_CMD="mysqldump -u ${PG_USER} --password=${PG_PASSWORD} ${PG_DB_NAME} > /tmp/${SQL_NAME}"

### pgdump ###
kubectl exec -it -n ${NS} ${PG_POD_NAME} -- /bin/bash -c "${BK_CMD}"
kubectl cp ${NS}/${PG_POD_NAME}:/tmp/${SQL_NAME} ./${SQL_NAME}

### gcloud auth ###
echo "##### Activating Gcloud service account ####"
gcloud auth activate-service-account --key-file=${KEY_FILE}

### gsutil cp ###
echo "##### Copying backup files to cloud storage ####"
TS=$(date +%Y%m%d_%H%M%S)
UPLOAD_SQL_FILE=${SQL_NAME}.${TS}
BUCKET=gs://prom-backup/${ENV}/
TMP_TEMPLATE=/tmp/${SQL_NAME}.json

mv ${SQL_NAME} ${UPLOAD_SQL_FILE}
gsutil cp ${UPLOAD_SQL_FILE} ${BUCKET}

### slack notify ###
cat << EOF > ${TMP_TEMPLATE}
{
    "text": "Done uploading files [${UPLOAD_SQL_FILE}]\n"
}
EOF
curl -X POST -H 'Content-type: application/json' --data "@${TMP_TEMPLATE}" ${SLACK_URI}

### cleanup ###
echo "##### Remove local uploaded files ####"
rm ${UPLOAD_SQL_FILE} ${TMP_TEMPLATE}

echo "##### Done ####"
