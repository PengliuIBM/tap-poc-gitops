# Relocated Install with Private CAs for TAP 1.5

## Assumptions
This cluster configuration is a single cluster install of TAP suitable for POCs.
This configuration assumes:
- A Linux jumpbox/bastion that:
  - can access the public internet
  - can access your Kubernetes Cluster
  - can access your OCI image repository
  - has Docker installed
- You will relocate images for the PoC to a private registry
- Two repositories are created on your Git server under the user account to be used for GitOps:
  - tap-gitops
  - spring-sensors
- The private OCI registry and Git Server are covered by certificates signed by a private CA
- HTTPS with Basic Authentication to access Git
- An IP to use for the platform ingress controller
- The platform IP registered as a wildcard DNS entry for the domain you wish to use for the platform
- A certificate (and cooresponding key) with a SAN entry for the wildcard DNS entry you have chosen for the platform

For the following languages, the configuration assumes:
- Java
  - Private Maven Repository that mirrors Maven Central, and optionally requires Basic Authentication
    - This repository should allow passive loading of resources, or have the artifacts listed in the "spring-sensors-deps.txt" file pre-loaded.
  - JDK 17

## Prior to PoC
- Download this repo to a tar.gz file and place it up on OneDrive so that your PoC attendees can download it as their gitops-repo starting point.

## Before you install
- Concatenate all CA and Intermediate CA certificates in PEM format that need to be trusted into a single file named trusted-ca-certs.pem
  - ```
      -----BEGIN CERTIFICATE-----
      certificate1Data
      -----END CERTIFICATE-----

      -----BEGIN CERTIFICATE-----
      certificate2Data
      -----END CERTIFICATE-----
      ...
    ```
- Set environment variables
  - 
      # Needs to be a full path
      export TRUSTED_CA_CERTS_FILE="$HOME/localCA.pem"
      export TANZUNET_REGISTRY_USERNAME='cdelashmutt@vmware.com'
      export TANZUNET_REGISTRY_PASSWORD='12345'
      export INSTALL_REGISTRY_HOSTNAME=registry.mac.grogscave.net:8443
      export INSTALL_REGISTRY_USERNAME='reguser'
      export INSTALL_REGISTRY_PASSWORD='regpassword'
      # This variable should include the scheme, hostname and port of the Git server for your tap-gitops and spring-sensors repos
      export GIT_HOST='https://gitea.mac.grogscave.net:3000'
      # Account that can write to gitops repo
      export GIT_USERNAME='gitea_admin'
      export GIT_PASSWORD='gitea_admin'
      export MAVEN_WORKLOAD_USERNAME='mavenuser'
      export MAVEN_WORKLOAD_PASSWORD='mavenpassword'
      # This URL needs to point to the top of the mirror of Maven Central
      export MAVEN_URL='https://reposilite.mac.grogscave.net:3001/releases'
      # Account that can read git app source repos
      export GIT_WORKLOAD_USERNAME='gitea_admin'
      export GIT_WORKLOAD_PASSWORD='gitea_admin'
      ### Probably don't need to edit these
      export TRUSTED_CA_CERTS="$(cat $TRUSTED_CA_CERTS_FILE)"
      export SOPS_AGE_KEY=$(cat ~/.age/key.txt)
      export SOPS_AGE_RECIPIENTS=$(echo "$AGE_KEY" | grep "# public key: " | sed 's/# public key: //')
      export TAP_VERSION=1.5.0
      export TAP_PKGR_REPO=$INSTALL_REGISTRY_HOSTNAME/tap/tap-packages
- Copy age key 
  - `cp age-key/key.txt into ~/.age/key.txt`
- TKG and TMC Attached Clusters already have Cluster Essentials installed, but you need to install it for other situations.
  - You will need download this package for the CLIs, even if it is already installed.
  - https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.5/cluster-essentials/deploy.html
  - Also, you will need to trust the CA used for the registry that the TAP image bundles have been relocated to.  Check to see if the kapp-controller-config Secret in the same namespace as kapp (TKG=tkg-system and TMC=tanzu-system) already has the ca in the "caCerts" value.  If not, create the secret if necessary and add it per https://carvel.dev/kapp-controller/docs/v0.43.2/controller-config/#controller-configuration-spec.
  - ```
      kubectl create namespace kapp-controller
      kubectl create secret generic kapp-controller-config --namespace kapp-controller --from-literal caCerts="$TRUSTED_CA_CERTS"
      
      IMGPKG_REGISTRY_HOSTNAME=registry.tanzu.vmware.com \
      IMGPKG_REGISTRY_USERNAME=$TANZUNET_REGISTRY_USERNAME \
      IMGPKG_REGISTRY_PASSWORD=$TANZUNET_REGISTRY_PASSWORD \
      imgpkg copy \
        -b registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:79abddbc3b49b44fc368fede0dab93c266ff7c1fe305e2d555ed52d00361b446 \
        --to-tar cluster-essentials-bundle-1.5.0.tar \
        --include-non-distributable-layers
      
      imgpkg copy \
        --tar cluster-essentials-bundle-1.5.0.tar \
        --to-repo $INSTALL_REGISTRY_HOSTNAME/tap/cluster-essentials-bundle \
        --include-non-distributable-layers \
        --registry-ca-cert-path $TRUSTED_CA_CERTS_FILE

      INSTALL_BUNDLE=$INSTALL_REGISTRY_HOSTNAME/tap/cluster-essentials-bundle@sha256:79abddbc3b49b44fc368fede0dab93c266ff7c1fe305e2d555ed52d00361b446 \
      ./install.sh
    ```

- Relocate TAP deps
  - imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.5.0 --to-repo $INSTALL_REGISTRY_HOSTNAME/tap/tap-packages
- Relocate TBS dependencies
  - imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:1.10.8 --to-repo $INSTALL_REGISTRY_HOSTNAME/tap/tbs-full-deps
- Relocate GitOps namespace images
  - imgpkg copy -i registry.access.redhat.com/ubi8/ubi-minimal:8.7 --to-repo $INSTALL_REGISTRY_HOSTNAME/tap/pipeline/ubi-minimal
  - imgpkg copy -i maven:3.6-openjdk-17 --to-repo $INSTALL_REGISTRY_HOSTNAME/tap/pipeline/maven
  - imgpkg copy -i gradle:8.1-jdk17 --to-repo $INSTALL_REGISTRY_HOSTNAME/tap/pipeline/gradle
- Relocate Grype DB Server Image
  - imgpkg copy -i ghcr.io/cdelashmutt-pivotal/grype-db-server:latest --to-repo $INSTALL_REGISTRY_HOSTNAME/tap/grype-db-server
- Clone the tap-gitops and spring-sensors repos you created for the PoC on to the jumpbox/bastion.
- Expand tap-poc-gitops.tar.gz file into the root of your tap-gitops clone.
  - tar xvf ~/Downloads/tap-poc-gitops-main.tar.gz --strip-components=1 -C tap-gitops
- Commit and push
  - git add . && git commit -m "Initial Commit" && git push
- Expand spring-sensors-main.tar.gz to the spring-sensors clone.
  - tar xvf ~/Downloads/spring-sensors-main.tar.gz --strip-components=1 -C spring-sensors
- Commit and push
  - git add . && git commit -m "Initial Commit" && git push

## Setting up GitOps
- `cd clusters/relocated-install-private-ca-1.5`
  - `tanzu-sync/scripts/configure.sh`
  - Edit the "CHANGEME" values in `cluster-config/values/tap-values.yaml`
  - Edit all the data in `cluster-config/values/tap-sensitive-values.sops.yaml`
    - sops `cluster-config/values/tap-sensitive-values.sops.yaml`
  - Edit the `namespace-provisioner/gitops-install/desired-namespaces.yaml` to point to the relocated testing image locations.
  - Ensure you are targeted at the proper cluster with `kubectl config current-context`
  - `tanzu-sync/scripts/deploy.sh`

## Post Install
- Load your cert and key for the platform
  - Start with self-signed:
    ```
    kubectl create -f- <<EOF
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: tap-wildcard
      namespace: tap-install
    spec:
      commonName: "*.127-0-0-1.nip.io"
      dnsNames:
      - "*.127-0-0-1.nip.io"
      duration: 2160h0m0s
      issuerRef:
        kind: ClusterIssuer
        name: tap-ingress-selfsigned
      privateKey:
        algorithm: RSA
        encoding: PKCS1
        size: 2048
      renewBefore: 360h0m0s
      secretName: tap-wildcard
      subject:
        organizations:
        - vmware
    EOF
    ```
  - Replace with their cert
    ```
    kubectl delete certificate tls tap-wildcard -n tap-install
    kubectl create secret tls tap-wildcard -n tap-install --cert=path/to/cert/file --key=path/to/key/file
    ```
  - Remove the sample workload from your repo if you like:
    ```
    rm cluster-config/dependent-resources/sample-workload.yaml
    ```
    - Then commmit and push to have it removed

## Simulating Enterprise Services with Docker Compose
If you want to simulate an air-gapped environment, you can run a local registry, Maven repo, and git server and use those to install with.

- Add 3 entries to your /etc/hosts file (or register in DNS) for the 3 services that you'll be running:
  - `registry.<some-domain>`
  - `gitea.<some-domain>`
  - `reposilite.<some-domain>`
  - NOTE: To install across mulitple machines, you'll need register the routable address for the machine running docker-compose so that other machines can reach it, and match the domain name of the generated certs.
- Copy the `local-setup` directory to your home directory.
- Run the `certs/create-ca.sh` to create your own local CA for signing certs.
- Run the `certs/create-cert.sh` script to create certificates for each of the domains you created above:
  - `create-cert.sh registry.<some-domain>`
  - `create-cert.sh gitea.<some-domain>`
  - `create-cert.sh reposilite.<some-domain>`
- Start up the services
  - `docker-compose -f $HOME/tap-poc-services/docker-compose.yml up -d`