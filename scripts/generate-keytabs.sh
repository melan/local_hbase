#!/usr/bin/env bash

DEBUG=${DEBUG:-}

if [ -n "${DEBUG}" ]; then
  set -x
fi

# Constants and initial parameters
BASEDIR=$(dirname $0)
platform=$(uname | tr '[:upper:]' '[:lower:]')

if [[ "${platform}" == "darwin" ]]; then
    READLINK="readlink"
else
    READLINK="readlink -f"
fi

BASEDIR=$(echo "$(cd ${BASEDIR}; pwd)")

link=$(${READLINK} "${BASEDIR}")
if [ -n "${link}" ]; then
    BASEDIR=$(dirname "${link}")
else
    BASEDIR=$(dirname "${BASEDIR}")
fi


set -e

# These two can be overridden by the existing environment
IMAGE=${IMAGE:-melan/kerberos}

KEYTABSDIR=${KEYTABSDIR:-"$BASEDIR/keytabs"}
PRINCIPALDIR=${PRINCIPALDIR:-"$BASEDIR/principal"}
REALM=${REALM:-LOCAL_HBASE}

test -d "${KEYTABSDIR}" && rm -rf "${KEYTABSDIR}"
test -d "${PRINCIPALDIR}" && rm -rf "${PRINCIPALDIR}"

mkdir "${KEYTABSDIR}"
mkdir "${PRINCIPALDIR}"

users=("hbase/hbase|localhbase_hbase_1.localhbase_lh" \
       "HTTP/hbase|localhbase_hbase_1.localhbase_lh" \
       "hbase/hbase-master|localhbase_hbase-master_1.localhbase_lh" \
       "HTTP/hbase-master|localhbase_hbase-master_1.localhbase_lh" \
       "zookeeper/zookeeper|localhbase_zookeeper_1.localhbase_lh" \
       "HTTP/hdfsdata|localhbase_hdfsdata_1.localhbase_lh" \
       "hbase/hdfsdata|localhbase_hdfsdata_1.localhbase_lh" \
       "HTTP/hdfsname|localhbase_hdfsname_1.localhbase_lh" \
       "hbase/hdfsname|localhbase_hdfsname_1.localhbase_lh" \
       zkcli hdfs \
       "kadmin/kerberos|localhbase_kerberos_1.localhbase_lh" \
       "kerberos/kerberos|localhbase_kerberos_1.localhbase_lh" \
       )

docker run \
       -it \
       --rm \
       -v ${KEYTABSDIR}:/etc/keytabs \
       -v ${PRINCIPALDIR}:/etc/krb5kdc \
       -v ${BASEDIR}/kerberos/kdc.conf:/var/kerberos/krb5kdc/kdc.conf:ro \
       -v ${BASEDIR}/kerberos/kadm5.acl:/var/kerberos/krb5kdc/kadm5.acl:ro \
       -v ${BASEDIR}/kerberos/krb5.conf:/etc/krb5.conf:ro \
       -e DEBUG=${DEBUG} \
       -e REALM=${REALM} \
       --hostname kerberos \
       ${IMAGE} \
       generate ${users[@]}