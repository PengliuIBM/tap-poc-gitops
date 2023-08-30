#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function not_found {
  message=${1:-not found}
  printf "${RED}$message${NC}"
}

function found {
  message=${1:-found}
  printf "${GREEN}$message${NC}"
}

function checkImage {
  if resolved=$(imgpkg tag resolve -i $INSTALL_REGISTRY_HOSTNAME$INSTALL_REGISTRY_REPO_PREFIX/tap/$1 --registry-ca-cert-path $TRUSTED_CA_CERTS_FILE); then
    found
    printf " $resolved\n"
  else
    printf "not found\n"
  fi
}

printf "\---=== Tanzu Prequisite Valiadator ===---/\n"

printf "== Registry Image Checks ==\n"
printf "Checking for Tanzu Application Platform bundle..."
checkImage tap-packages:$TAP_VERSION
printf "Checking for Tanzu Build Service Full Dependencies..."
checkImage tbs-full-deps:1.10.8
printf "Checking for ubi-minimal..."
checkImage pipeline/ubi-minimal:8.7
printf "Checking for maven..."
checkImage pipeline/maven:3.6-openjdk-17
printf "Checking for gradle..."
checkImage pipeline/gradle:8.1-jdk17
printf "Checking for grype-db-server..."
checkImage grype-db-server:latest

printf "\n== Git Repo Checks ==\n"
printf "Checking current repo's remote and credentials allow read..."
git_remote="$(git remote get-url origin)"
git_scheme="$(awk -F '://' '{print $1}' <<< $git_remote)"
git_host_path="$(awk -F '://' '{print $2}' <<< $git_remote)"
if ! git ls-remote $git_scheme'://'$GIT_USERNAME:$GIT_PASSWORD@$git_host_path > /dev/null; then
  not_found "failed. "
  printf "Check your GIT_USERNAME, GIT_PASSWORD, GIT_HOST, and TRUSTED_CA_CERTS_FILE to ensure everything is correct.\n"
else
  found "success.\n"
fi
printf "Checking for spring-sensors repo and git workload credentials..."
git_host_user="$(awk -F '/tap-gitops' '{print $1}' <<< $git_host_path)"
if ! git ls-remote $git_scheme'://'$GIT_WORKLOAD_USERNAME:$GIT_WORKLOAD_PASSWORD@$git_host_user/spring-sensors > /dev/null; then
  not_found "failed. "
  printf "Check that you have added the spring-sensors project under your git user and check GIT_WORKLOAD_USERNAME, GIT_WORKLOAD_PASSWORD, GIT_HOST, and TRUSTED_CA_CERTS_FILE to ensure everything is correct.\n"
else
  found "success.\n"
fi

printf "\n== Cluster Checks ==\n"
printf "Checking kubectl connectivity..."
if ! kubectl cluster-info > /dev/null; then
  not_found "failed. "
  printf "Check that you have added the spring-sensors project under your git user and check GIT_WORKLOAD_USERNAME, GIT_WORKLOAD_PASSWORD, GIT_HOST, and TRUSTED_CA_CERTS_FILE to ensure everything is correct.\n"
else
  found "success"
  printf ".  Current context is $(kubectl config current-context).\n"
fi

printf "Checking for kapp-controller and secretgen-controller in cluster...\n"
kubectl get pods -l "app in (kapp-controller,secretgen-controller)" --ignore-not-found=true -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name --no-headers=true -A

#printf "Checking for kapp-controller caCerts trust..."
#found_certs=$(k get secret kapp-controller-config -n $kapp_namespace -o jsonpath=".data.caCerts" | base64 -d)
#if [[ "$found_certs" -eq "$TRUSTED_CA_CERTS" ]]; then
#  found "matches"
#else
#  not_found "no-match"
#fi