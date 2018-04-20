#!/bin/bash

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
export OUTDIR=${OUTDIR:-"$BASEDIR/certs"}

SERVICES=(zookeeper hbase hdfs thrift)
MTLS_CLIENTS=()

DEV_CONFIG="$BASEDIR/scripts/certs.cnf"
CERT_COUNTRY="US"
CERT_STATEPROV="Florida"
CERT_LOCALITY="Tampa"
CERT_ORG="HBase"
CERT_ORG_UNIT="Local"
CA_BASE_FILENAME="ca"
SERVER_BASE_FILENAME="server"
CLIENT_BASE_FILENAME="client"
DEV_CERT_PASSWORD="secret"
INFO_COLOUR='\033[1;32m' # Light Green.
NC='\033[0m' # No Color.
OPENSSL=${OPENSSL:-$(which openssl)}

echo "Using OpenSSL $(${OPENSSL} version) from ${OPENSSL}"

function echoInfo() {
	text="$1"
	echo -e "${INFO_COLOUR}${text}${NC}"
}

function createKeyAndCerts() {
	BASE_FILENAME="$1"
	HOSTNAME="$2"
	OU="$3"
	USAGE="$4"

	if [[ ! -e "$OUTDIR/$BASE_FILENAME-key.pem" ]]; then
		echoInfo "Creating a key and signing request for the server."
		echo "$CERT_COUNTRY
$CERT_STATEPROV
$CERT_LOCALITY
$CERT_ORG
$OU
$HOSTNAME
" |
		env HOSTNAME="$HOSTNAME" ${OPENSSL} req -new -nodes -days 365 -keyout "$OUTDIR/$BASE_FILENAME-key.pem" -out "$OUTDIR/$BASE_FILENAME-req.pem" -config "$DEV_CONFIG"
		echo ""
		rm -f "$OUTDIR/$BASE_FILENAME-cert.pem"
	fi

	if [[ ! -e "$OUTDIR/$BASE_FILENAME-cert.pem" ]]; then
		echoInfo "Having the CA sign the $BASE_FILENAME CSR."
		env HOSTNAME="$HOSTNAME" ${OPENSSL} ca -updatedb -batch -days 365 -extensions "$USAGE" -keyfile "$OUTDIR/$CA_BASE_FILENAME-key.pem" -key "$DEV_CERT_PASSWORD" -cert "$OUTDIR/$CA_BASE_FILENAME-cert.pem" -out "$OUTDIR/$BASE_FILENAME-cert.pem" -config "$DEV_CONFIG" -infiles "$OUTDIR/$BASE_FILENAME-req.pem"

		echoInfo "Verifying the $BASE_FILENAME cert file."
		${OPENSSL} x509 -in "$OUTDIR/$BASE_FILENAME-cert.pem" -text -noout

		echoInfo "Creating the PKCS12 file using the $BASE_FILENAME private key, the $BASE_FILENAME public cert and the CA cert."
		${OPENSSL} pkcs12 -export -in "$OUTDIR/$BASE_FILENAME-cert.pem" -inkey "$OUTDIR/$BASE_FILENAME-key.pem" -certfile "$OUTDIR/$CA_BASE_FILENAME-cert.pem" -name "$BASE_FILENAME" -out "$OUTDIR/$BASE_FILENAME-cert.p12" -passout "pass:$DEV_CERT_PASSWORD"
		rm -f "$OUTDIR/$BASE_FILENAME-keystore.jks"

		echoInfo "Verifying the $BASE_FILENAME PKCS12 file."
		${OPENSSL} pkcs12 -info -noout -in "$OUTDIR/$BASE_FILENAME-cert.p12" -passin "pass:$DEV_CERT_PASSWORD"

		echoInfo "Creating the $BASE_FILENAME JKS store."
		keytool -importkeystore -v -deststorepass "$DEV_CERT_PASSWORD" -destkeypass "$DEV_CERT_PASSWORD" -destkeystore "$OUTDIR/$BASE_FILENAME-keystore.jks" -srckeystore "$OUTDIR/$BASE_FILENAME-cert.p12" -srcstoretype PKCS12 -srcstorepass "$DEV_CERT_PASSWORD" -alias "$BASE_FILENAME"

		echoInfo "Verifying the $BASE_FILENAME JKS store."
		keytool -list -v -keystore "$OUTDIR/$BASE_FILENAME-keystore.jks" -storepass "$DEV_CERT_PASSWORD"
	fi
}

# remove current certs if folder exists
if [ -d "${OUTDIR}" ]; then
  rm -rf "${OUTDIR}"
fi

# Ensure required files and directories exist.
mkdir -p "$OUTDIR"
! [ -e "$OUTDIR/serial" ] && echo "100001" > "$OUTDIR/serial"
! [ -e "$OUTDIR/certindex.txt" ] && touch "$OUTDIR/certindex.txt"
! [ -e "$OUTDIR/password" ] && echo "$DEV_CERT_PASSWORD" > "$OUTDIR/password"
! [ -e "$OUTDIR/password.properties" ] && echo "passwd=$DEV_CERT_PASSWORD" > "$OUTDIR/password.properties"

# Create the Certificate Authority root certificiate.
if [[ ! -e "$OUTDIR/$CA_BASE_FILENAME-key.pem" || ! -e "$OUTDIR/$CA_BASE_FILENAME-cert.pem" ]]; then
	echoInfo "Creating a CA by creating a root certificate."
		echo "$CERT_COUNTRY
$CERT_STATEPROV
$CERT_LOCALITY
$CERT_ORG
$CERT_ORG_UNIT
HBase Local Dev
" |
	env HOSTNAME=localhost ${OPENSSL} req -new -x509 -extensions v3_ca -days 36500 -keyout "$OUTDIR/$CA_BASE_FILENAME-key.pem" -out "$OUTDIR/$CA_BASE_FILENAME-cert.pem" -config "$DEV_CONFIG" -passout "pass:$DEV_CERT_PASSWORD"
	echo ""
	rm -f "$OUTDIR/$SERVER_BASE_FILENAME-truststore.jks"
fi

# Create Trust store
if [[ ! -e "$OUTDIR/$SERVER_BASE_FILENAME-truststore.jks" ]]; then
  echoInfo "Creating the TrustStore from the PKCS12 file."
  keytool -importcert -v -trustcacerts -noprompt -keystore "$OUTDIR/$CA_BASE_FILENAME-truststore.jks" -storepass "$DEV_CERT_PASSWORD" -file "$OUTDIR/$CA_BASE_FILENAME-cert.pem" -alias "$CA_BASE_FILENAME-cert"

  echoInfo "Verifying the TrustStore."
  keytool -list -v -keystore "$OUTDIR/$CA_BASE_FILENAME-truststore.jks" -storepass "$DEV_CERT_PASSWORD"
fi

# Create the client's certs.
createKeyAndCerts "$CLIENT_BASE_FILENAME" "client" "${CERT_ORG_UNIT}" usr_cert

for service in "${SERVICES[@]}"; do
  TARGET_HOSTNAME="${service}"
  SERVER_BASE_FILENAME="${service}-server"

  # Create the server's cert
  createKeyAndCerts "$SERVER_BASE_FILENAME" "$TARGET_HOSTNAME" "${CERT_ORG_UNIT}" server_cert
done

for client in "${MTLS_CLIENTS[@]}"; do
  TARGET_HOSTNAME="${client}"
  SERVER_BASE_FILENAME="${client}-mtls-client"

  # Create the client's MTLS cert
  createKeyAndCerts "$SERVER_BASE_FILENAME" "$TARGET_HOSTNAME" "${CERT_ORG_UNIT}-mtls" usr_cert
done
