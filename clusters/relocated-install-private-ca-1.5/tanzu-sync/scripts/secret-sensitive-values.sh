#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

function usage() {
  >&2 cat << EOF
$0 :: configure tap install for use with internal maven and git across all namespace provisioner namespaces" 
 
Environment Variables:
- MAVEN_WORKLOAD_USERNAME   -- username of account with at least read access to maven
- MAVEN_WORKLOAD_PASSWORD   -- password of maven account
- MAVEN_URL                 -- URL of Maven Repo
- GIT_WORKLOAD_USERNAME     -- Username with at least read only access to git
- GIT_WORKLOAD_PASSWORD     -- password with at least read only access to git
- GIT_HOST                  -- Git Hostname
- JAVA_TRUSTSTORE_PASSWORD  -- Password to use when creating jks default("t@pJav@34")

EOF
}

error_msg="Expected env var to be set, but was not."
: "${MAVEN_WORKLOAD_USERNAME?$error_msg}"
: "${MAVEN_WORKLOAD_PASSWORD?$error_msg}"
: "${MAVEN_URL?$error_msg}"
: "${GIT_WORKLOAD_USERNAME?$error_msg}"
: "${GIT_WORKLOAD_PASSWORD?$error_msg}"
: "${GIT_HOST?$error_msg}"

JAVA_TRUSTSTORE_PASSWORD=${JAVA_TRUSTSTORE_PASSWORD:-t@pJav@34}

# pass in the multi-line strings as a data-values file as it properly
# escapes the multi-line values.

sensitive_secret_values=$(cat << EOF
---
secrets:
  maven:
    url: "${MAVEN_URL}" 
    username: "${MAVEN_WORKLOAD_USERNAME}"
    password: "${MAVEN_WORKLOAD_PASSWORD}"
  git:
    username: "${GIT_WORKLOAD_USERNAME}"  
    password: "${GIT_WORKLOAD_PASSWORD}"
    host: "${GIT_HOST}"
  javatrust:
    password: "${JAVA_TRUSTSTORE_PASSWORD}"  
EOF
)

# Do not display sensitive values to the terminal.
if [[ -t 1 ]]; then
  >&2 echo "Sensitive values are present; will be used by ./tanzu-sync/scripts/deploy.sh"
else
  echo "${sensitive_secret_values}"
fi
