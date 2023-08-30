#!/bin/sh

CA_DIR=${CA_DIR:-$HOME/certs}

if [ "$#" -eq 0 ]
then
  echo "Usage: $0 primary-domain { san-domain }\n\nMust supply a domain, and any additional SAN DNS entries you want to add to the cert."
  echo "Examples: \n$0 foo.bar.com # Generates a certificate with a single domain name that it covers."
  echo "$0 \"*.foo.bar.com\" # Generates a wildcard certificate with one SAN DNS entry."
  echo "$0 \"*.foo.bar.com\" \"*.sub.foo.bar.com\" # Generates a wildcard certificate with one SAN DNS entry covering \"*.foo.bar.com\" and one SAN DNS entry covering \"*.sub.foo.bar.com\"."
  exit 1
fi

DOMAIN=$1
HOSTNAME=$(echo $DOMAIN | sed 's/^\([^.]*\)\..*/\1/')
shift

openssl genrsa -out "$CA_DIR/$HOSTNAME.key" 2048
openssl req -new -key "$CA_DIR/$HOSTNAME.key" -out "$CA_DIR/$HOSTNAME.csr" -subj "/CN=$DOMAIN/O=Example/L=Anytown/ST=Indiana/C=US/emailAddress=me@here.com"

cat > "$CA_DIR/$HOSTNAME.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

idx=2
for domain in "$@"; do
  echo DNS.$idx = $domain >> "$CA_DIR/$HOSTNAME.ext"
  let "idx+=1"
done

openssl x509 -req -in "$CA_DIR/$HOSTNAME.csr" -CA "$CA_DIR/localCA.pem" -CAkey "$CA_DIR/localCA.key" -CAcreateserial \
-out "$CA_DIR/$HOSTNAME.crt" -days 825 -sha256 -extfile "$CA_DIR/$HOSTNAME.ext"