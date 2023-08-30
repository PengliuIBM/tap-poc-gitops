FROM alpine:3.18 as fetch
RUN apk --no-cache --update add git binutils
RUN wget https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1 \
 -O /tmp/pivnet \
 && install -s -p -m 755 /tmp/pivnet /usr/local/bin/pivnet
RUN wget https://github.com/romkatv/gitstatus/releases/download/v1.5.4/gitstatusd-linux-x86_64.tar.gz \
 -O /tmp/gitstatusd-linux-x86_64.tar.gz && tar xzf /tmp/gitstatusd-linux-x86_64.tar.gz -C /tmp \
 && install -D -s -p -m 755 /tmp/gitstatusd-linux-x86_64 /root/.cache/gitstatus/gitstatusd-linux-x86_64
RUN wget https://dl.k8s.io/release/v1.25.9/bin/linux/amd64/kubectl \
 -O /tmp/kubectl && install -s -p -m 755 /tmp/kubectl /usr/local/bin/kubectl
RUN wget https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz \
 -O /tmp/k9s_Linux_amd64.tar.gz && tar xzf /tmp/k9s_Linux_amd64.tar.gz -C /tmp \
 && install -D -s -p -m 755 /tmp/k9s /usr/local/bin/k9s
RUN --mount=type=secret,id=PIVNET_TOKEN export TANZU_CLI_NO_INIT=true \
 && pivnet login --api-token=$(cat /run/secrets/PIVNET_TOKEN) \
 && pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.5.0' --product-file-id=1446073 -d=/tmp \
 && tar -xvf /tmp/tanzu-framework-linux-amd64-v0.28.1.1.tar -C /tmp \
 && install -D -s -p -m 755 /tmp/cli/core/v0.28.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu \
 && mkdir -p /root/.oh-my-zsh/custom/completions \
 && tanzu completion zsh > /root/.oh-my-zsh/custom/completions/_tanzu \
 && tanzu plugin install --local /tmp/cli all
RUN --mount=type=secret,id=PIVNET_TOKEN pivnet login --api-token=$(cat /run/secrets/PIVNET_TOKEN) \
 && pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version='1.5.0' --product-file-id=1460876 -d=/tmp \
 && mkdir /tmp/cluster-essentials \
 && tar -xvf /tmp/tanzu-cluster-essentials-linux-amd64-1.5.0.tgz -C /tmp/cluster-essentials \
 && for file in $(ls /tmp/cluster-essentials | grep -v sh$) ; do install -D -s -p -m 755 /tmp/cluster-essentials/$file /usr/local/bin/$file ; done
RUN git clone --depth 1 https://github.com/ahmetb/kubectx --branch v0.9.4 /tmp/kubectx \
 && cp /tmp/kubectx/kube* /usr/local/bin

FROM alpine:3.18
RUN apk add --update --no-cache git curl zsh gcompat \
  nano vim direnv jq less unzip bind-tools openssl ca-certificates ncurses
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -x -p aws -p azure -p gcloud -p git -p kubectl -p oc
COPY --link --from=fetch /usr/local/bin/pivnet /usr/local/bin/pivnet
COPY --link --from=fetch /root/.cache/gitstatus/gitstatusd-linux-x86_64 /root/.cache/gitstatus/gitstatusd-linux-x86_64
COPY --link --from=fetch /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --link --from=fetch /usr/local/bin/k9s /usr/local/bin/k9s
COPY --link --from=fetch /usr/local/bin/kubectx /usr/local/bin/kubectx
COPY --link --from=fetch /usr/local/bin/kubens /usr/local/bin/kubens
COPY --link --from=fetch /root/.oh-my-zsh/custom/completions/* /root/.oh-my-zsh/custom/completions/
COPY --link --from=fetch /usr/local/bin/tanzu /usr/local/bin/tanzu
COPY --link --from=fetch /root/.cache /root/.cache
COPY --link --from=fetch /root/.local/share/tanzu-cli /root/.local/share/tanzu-cli
COPY --link --from=fetch /root/.config/tanzu /root/.config/tanzu
COPY --link --from=fetch /usr/local/bin/ytt /usr/local/bin/ytt
COPY --link --from=fetch /usr/local/bin/kapp /usr/local/bin/kapp
COPY --link --from=fetch /usr/local/bin/kbld /usr/local/bin/kbld
COPY --link --from=fetch /usr/local/bin/imgpkg /usr/local/bin/imgpkg
COPY --link --from=fetch /tmp/cluster-essentials/*sh /root/cluster-essentials/
COPY --link . /root/tap-poc-gitops
COPY /build/files /
WORKDIR /root
CMD ["/bin/zsh"]
#vsphere kubectl plugin
#- curl -L https://${VSPHERE_IP}/wcp/plugin/linux-amd64/vsphere-plugin.zip -o /tmp/vsphere-plugin.zip
