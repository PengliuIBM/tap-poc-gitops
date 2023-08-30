#!/bin/sh

CA_DIR=${CA_DIR:-$HOME/certs}

if [ -f "$FILE" ]; then
    echo "$FILE exists."
fi

openssl genrsa -des3 -out "$CA_DIR/localCA.key" 2048
openssl req -x509 -new -nodes -key "$CA_DIR/localCA.key" -sha256 -days 1825 -out "$CA_DIR/localCA.pem"