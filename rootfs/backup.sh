#!/bin/bash

#GPG passphrade
export PASSPHRASE=${BACKUP_GPG_PASSPHRASE}
#S3 credentials
export AWS_ACCESS_KEY_ID=${BACKUP_AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${BACKUP_AWS_ACCESS_KEY}
#Bucket
#export URL=s3://s3-eu-central-1.amazonaws.com/rebox.backup.revault.ch/backups/rebox-infra/

BACKUP_TARGET_URL=${BACKUP_TARGET_URL}
BACKUP_FULL_IF_OLDER_THEN=${BACKUP_FULL_IF_OLDER_THEN:-1M}
BACKUP_REMOVE_OLDER_THEN=${BACKUP_REMOVE_OLDER_THEN:-3M}
BACKUP_ROOT=${BACKUP_ROOT:-/}
BACKUP_INCLUDE_PATTERN=${BACKUP_INCLUDE_PATTERN:-/}
BACKUP_EXCLUDE_PATTERN=${BACKUP_INCLUDE_PATTERN:-**}

#DUP="duplicity --s3-use-new-style --s3-european-buckets "
DUP="duplicity"
if [[ "${URL}" =~ s3://.* ]]; then
    DUP="${DUP} --s3-use-new-style "
fi
if [[ "${URL}" =~ s3://.*-eu-.* ]]; then
    DUP="${DUP} --s3-european-buckets "
fi
if [[ "${BACKUP_GPG_KEY_ID}" != "" ]]; then
    DUP="${DUP} --encrypt-key ${BACKUP_GPG_KEY_ID} "
fi

backup() {
    # doing a monthly full backup (1M)
    # exclude /var/tmp from the backup
    ${DUP} --full-if-older-than ${BACKUP_FULL_IF_OLDER_THEN} \
           --include "${BACKUP_INCLUDE_PATTERN}" \
           --exclude "${BACKUP_EXCLUDE_PATTERN}" \
           "${BACKUP_ROOT}" "${BACKUP_TARGET_URL}"
    # cleaning the remote backup space (deleting backups older than 3 months)
    ${DUP} remove-older-than ${BACKUP_REMOVE_OLDER_THEN} --force "${BACKUP_TARGET_URL}"
}

help() {
    echo "$0 [backup | restore <target dir> | status]"
    exit 1
}
cleanup() {
   ${DUP} cleanup --force ${BACKUP_TARGET_URL}
}
status() {
    ${DUP} collection-status ${BACKUP_TARGET_URL}
}
restore() {
    TARGET_DIR=${1}
    if [ "${TARGET_DIR}" == "" ]; then
        help
    fi
    duplicity ${BACKUP_TARGET_URL} ${TARGET_DIR}
}
if [ "" == "$1" ]; then
    help
else
    $@
fi;