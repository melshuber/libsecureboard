#! /bin/bash

# files in example-certs have been generated by
#
# see post_install.cmake for examples

set -e

DAYS=7300
VERBOSE=0
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ROOTSUBJ="/C=EX/ST=Example State/O=Example Company/CN=rootca.example-company.com.ex"
DEVSUBJ="/C=AT/O=YourComp/UO=any"

usage() {
    echo "Usage $0 [-g] -r <root_ca> -d <device_ca> [-c <device-cn>]"
    echo
    echo "  -g if present generate a new self signed root_CA"
    echo "  -r name (prefix) of the root CA to use/generate"
    echo "  -d device certificate to generate"
    echo "  -c device CN entry"
    exit 1
}

gen_root() {
#	-newkey ec:<(openssl ecparam -name prime256v1)
    CF=$1
    openssl \
	req \
	-days $DAYS \
	-config $DIR/../tools/openssl.cnf \
	-newkey ec:$DIR/../tools/prime256v1.pem \
	-sha256 -new -nodes -x509 \
	-subj "/C=AT/O=example-company/CN=SB-Root-CA" \
	-keyout $CF-key.pem \
	-out $CF.pem

    test $VERBOSE -eq 1 && \
	openssl x509 -in $CF.pem -noout -text
}

gen_device() {
    # Generated Certificate
    CF=$1
    # Issuing Authority
    CA=$2

    openssl \
	req \
	-config $DIR/../tools/openssl.cnf \
	-newkey ec:$DIR/../tools/prime256v1.pem \
	-sha256 -new -nodes \
	-subj "$DEVSUBJ" \
	-keyout $CF-key.pem -out $CF-csr.pem
    openssl \
	x509 \
	-req \
	-sha256 \
	-days $DAYS \
	-in $CF-csr.pem \
	-CA $CA.pem \
	-CAkey $CA-key.pem \
	-extfile $DIR/../tools/device.ext \
	-CAcreateserial \
	-outform DER \
	-out $CF.der
    rm $CF-csr.pem
    
    test $VERBOSE -eq 1 && \
	openssl x509 -in $CF.der -inform DER -noout -text
}

GENROOT=0
unset ROOTNAME
unset DEVNAME

while getopts "c:r:d:gv" o; do
    case "$o" in
	v)
	    VERBOSE=1
	    ;;
	g)
	    GENROOT=1
	    ;;
	d)
	    DEVNAME=$OPTARG
	    ;;
	r)
	    ROOTNAME=$OPTARG
	    ;;
	c)
	    DEVSUBJ="/C=AT/O=example-company/CN=$OPTARG"
	    ;;
	*)
	    usage
	    ;;
    esac
done

if [ -z "$ROOTNAME" ] ; then
   usage
fi

if [ -z "$DEVNAME" ] ; then
   usage
fi

if [ "$GENROOT" -eq "1" ]; then
    gen_root $ROOTNAME
fi

gen_device $DEVNAME $ROOTNAME
