#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace
if kubectl get ns tap-install; then
  echo "Tap Install Namespace already exists"
else
  kubectl create ns tap-install
fi
ytt -f tanzu-sync/scripts/pre-namespace-provisioner-secrets --data-values-file sensitive-values.sh.stdout=<(tanzu-sync/scripts/secret-sensitive-values.sh)| kubectl apply -f - 
kapp deploy -a tanzu-sync \
  -f <(ytt -f tanzu-sync/app/config \
           -f cluster-config/config/tap-install/.tanzu-managed/version.yaml \
           --data-values-file tanzu-sync/app/values/ \
           --data-values-file sensitive-values.sh.stdout=<(tanzu-sync/scripts/sensitive-values.sh) \
      ) $@
