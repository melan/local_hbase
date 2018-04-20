#!/usr/bin/env bash

DEBUG=${DEBUG:-}
REALM=${REALM:-EXAMPLE_COM}

if [ -n "${DEBUG}" ]; then
  set -x
fi

serve() {
  cp -f "/etc/krb5kdc/.k5.${REALM}" "/var/kerberos/krb5kdc/.k5.${REALM}"

  /usr/sbin/krb5kdc
  /usr/sbin/kadmind -r ${REALM}

  while true; do sleep 10; done
}

serve_fork() {
  /usr/sbin/krb5kdc
  /usr/sbin/kadmind
}

generate_keytabs() {
  users=( "$@" )

  /usr/sbin/kdb5_util create -s -P password -r "${REALM}"

  serve_fork

  # Create service users
  for u in "${users[@]}"; do
    keytab_name=$(echo "$u" | tr '/' '_')
    keytab_id="${u}"
    host_keytab_id=""
    host_keytab_name=""
    alt_host=""
    alt_host_keytab_id=""
    alt_keytab_id=""

    if [[ "${u}" =~ "/" ]]; then
      host=$(echo "${u}" | cut -d '/' -f 2-)
      user=$(echo "${u}" | cut -d '/' -f 1)

      if [[ "${host}" =~ "|" ]]; then
        alt_host=$(echo "${host}" | cut -d '|' -f 2)
        alt_keytab_id="${user}/${alt_host}"
        host=$(echo "${host}" | cut -d '|' -f 1)
      fi

      keytab_name="${user}_${host}"
      keytab_id="${user}/${host}"

      host_keytab_id="host/${host}"
      host_keytab_name="host_${host}"

      if [ ! -f "/etc/keytabs/${host_keytab_name}.keytab" ]; then
        /usr/sbin/kadmin.local -q "addprinc -randkey ${host_keytab_id}@${REALM}"
        /usr/sbin/kadmin.local -q "xst -norandkey -k /etc/keytabs/${host_keytab_name}.keytab ${host_keytab_id}"

        if [ -n "${alt_host}" ]; then
          alt_host_keytab_id="host/${alt_host}"
          /usr/sbin/kadmin.local -q "addprinc -randkey ${alt_host_keytab_id}@${REALM}"
        fi
      fi
    fi

    /usr/sbin/kadmin.local -q "addprinc -randkey ${keytab_id}@${REALM}"

    if [ -n "${alt_keytab_id}" ]; then
      /usr/sbin/kadmin.local -q "addprinc -randkey ${alt_keytab_id}@${REALM}"
    fi

    /usr/sbin/kadmin.local -q "xst -norandkey -k /etc/keytabs/${keytab_name}.keytab ${keytab_id} ${alt_keytab_id} ${host_keytab_id} ${alt_host_keytab_id}"
  done

  cp "/var/kerberos/krb5kdc/.k5.${REALM}" "/etc/krb5kdc/.k5.${REALM}"
}

case $1 in
  generate)
  shift
  generate_keytabs $@
  ;;
  serve)
  shift
  serve $@
  ;;
  *)
  echo Unknown command $1
  exit 1
esac