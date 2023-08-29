#!/bin/bash

SRC_FILE=.env
DST_FILE=addons/initial-secrets.yaml
SECRET=initial-secret
TMP_FILE=/tmp/${SECRET}.tmp

cat <<END > "${TMP_FILE}"
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET}
type: Opaque
data:
END

cat ${SRC_FILE} | while read line
do
  regex="^(.+?)=(.+)$"
  if [[ $line =~ $regex ]]; then

    KEY=$(echo -e "$line" | perl -0777 -ne 'print $1 if /^(.+?)=(.+)$/')
    VALUE=$(echo -e "$line" | perl -0777 -ne 'print $2 if /^(.+?)=(.+)$/')

    echo "  ${KEY}: $(echo -n "${VALUE}" | base64 -w0)" >> ${TMP_FILE}
  fi
done

export $(xargs <.env)

SRC_FILE=00-configs/konga-users.cfg
CFG_FILE=konga-users.cfg
cp ${SRC_FILE} ${CFG_FILE}
sed -i "s#<<KONGA_ADMIN_USER>>#${KONGA_ADMIN_USER}#g" ${CFG_FILE}
sed -i "s#<<KONGA_ADMIN_PASSWD>>#${KONGA_ADMIN_PASSWD}#g" ${CFG_FILE}
echo "  KONGA_USERS_CONFIG: $(cat "${CFG_FILE}" | base64 -w0)" >> ${TMP_FILE}

SRC_FILE=00-configs/konga-nodes.cfg
CFG_FILE=konga-nodes.cfg
cp ${SRC_FILE} ${CFG_FILE}
echo "  KONGA_NODES_CONFIG: $(cat "${CFG_FILE}" | base64 -w0)" >> ${TMP_FILE}

KEY_FILE=.gar-sa.json
echo "  GAR_PASSWORD: $(cat "${KEY_FILE}" | base64 -w0)" >> ${TMP_FILE}

GCS_FTP_SA=../secrets/gcs-ftp.json
echo "  GCS_FTP_SA: $(cat "${GCS_FTP_SA}" | base64 -w0)" >> ${TMP_FILE}

SFTP_SSH_PRIVATE_KEY=../secrets/sftp_id_rsa
echo "  SFTP_SSH_PRIVATE_KEY: $(cat "${SFTP_SSH_PRIVATE_KEY}" | base64 -w0)" >> ${TMP_FILE}

SFTP_USERS_CFG=../secrets/sftp_users.cfg
echo "  SFTP_USERS_CFG: $(cat "${SFTP_USERS_CFG}" | base64 -w0)" >> ${TMP_FILE}


SETTING_FILE=.appsetting-promrub-scb.json
echo "  APP_SETTING_SCB: $(cat "${SETTING_FILE}" | base64 -w0)" >> ${TMP_FILE}

SETTING_FILE=.appsetting-promjodd-carpark.json
echo "  APP_SETTING_CARPARK_API: $(cat "${SETTING_FILE}" | base64 -w0)" >> ${TMP_FILE}

SFTP_HOOK_AUTH_FILE=sftp-hook-basic-auth.txt
./initial-basic-auth.sh ../secrets/sftp-hook-basic-auth.cfg ${SFTP_HOOK_AUTH_FILE}
echo "  SFTP_HOOK_AUTH_FILE: $(cat "${SFTP_HOOK_AUTH_FILE}" | base64 -w0)" >> ${TMP_FILE}


cp ${TMP_FILE} ${DST_FILE}
