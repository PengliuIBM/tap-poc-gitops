# TAP PoC GitOps Starters
This repo contains starter folders for opinionated PoC installs of TAP.

The idea is that Tanzu SEs download this repo as an archive that they can provide to PoC participants, modify a few configuration files, check those files into their Git server, and deploy with the deploy script.

Each cluster config includes a README.md that captures all the assumptions and prerequisites needed before install.

## Helper Container Image
This repo also definition for a container image that includes all the utilities you need for installing Tanzu Application Platform, plus a few extra to make working with Kubernetes a little easier.

This image includes:
* `git, curl, nano, vim, direnv, jq, bind-tools, openssl`
* The ZSH shell and Oh-My-ZSH with Powerline
* A copy of this repository
* The Tanzu Network CLI, `pivnet`
* kubectl
* k9s
* kubectx and kubens
* The Tanzu CLI
* Carvel Tools - `ytt`, `kapp`, `kbld`, and `imgpkg`
* The Tanzu Cluster Essentials install script

### Internet Connected Container Engine
Ideally, the machine you run this container image on is able to reach the public internet, as well as the cluster you wish to install Tanzu Application Server on.  If this is the case, you can just run this container image using the following command:
`docker run -it --name tap-poc-gitops tap-poc-gitops`

### Airgapped Container Engine
If your machine is isolated from the internet, then you can execute the following command from an internet connected machine:
`docker pull tap-poc-gitops && docker export --output="tap-poc-gitops.tar" tap-poc-gitops`

Then you can move the `tap-poc-gitops.tar` file over to the isolated machine with Docker installed, and run the following command to import the image:
`docker import tap-poc-gitops.tar`

Now you can run the container image as above:
`docker run -it --name tap-poc-gitops tap-poc-gitops`

### Using the container
#### Detach and re-attach
You can detach your terminal session from the container by pressing `Ctrl-p` then `Ctrl-q` and then container will remain running.

Later, you can re-attach to the terminal session with the following command:
`docker attach tap-poc-gitops`

#### Installing TAP
1. If you are installing to vSphere with Tanzu not attached to Tanzu Mission Control, then you will need to install the vSphere Plugin for kubectl:
   1. First, run the `trust_vcenter_ca` command and pass the FQDN or IP of your vCenter server.
   2. Next, run the `install_vsphere_plugin` command and pass the link copied from the namespace page from vCenter.  It will be in the form of `https://hostname-or-ip`.
2. Edit the `~/.envrc` file with a text editor to set all the environment variables for your specific environment.
3. Run `direnv allow` to allow the variables to be set for your session.
4. Now, change directories to the cluster config directory with `cd tap-poc-gitops/clusters/relocated-install-private-ca-1.5`
5. Validate your configuration with `tanzu-sync/scripts/validate-setup.sh`.
   1. If you see problems, go back and correct the values in your `/.envrc` file, re-run `direnv allow` and then try to validate again.
6. Next, run `tanzu-sync/scripts/configure.sh`.
7. Kick off the install process with `tanzu-sync/scripts/deploy.sh`.