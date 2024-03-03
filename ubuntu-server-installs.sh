#!/bin/bash

# Summary:
# This is a script that just a bunch of the installs I normally use 
# on ubuntu machines. I got tired of blowing up my VMs and going through
# This manually. I'm wondering at this point if I just use NixOS.

source ~/.bashrc
lf=ubuntu-server-installs.log

############ FUNCTIONS ############
function write_log() {
  local filepath=$1
  local msg=$2
  if [ -z "$1" ]; then
    echo "Error: File path is empty"
    return 1
  fi

  if [ -z "$2" ]; then
    echo "Error: Message is empty"
    return 1
  fi

  my_timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
  echo "${my_timestamp} ${msg}" >> $filepath
}

function install_rust() {
  write_log $lf "------install_rust------"
  local rust_dir=$HOME/.cargo/bin
  local rust_export="export PATH=\$PATH:\$HOME/.cargo/bin"

  if ! [ -f $rust_dir/cargo ]; then
    write_log $lf "INSTALL - Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  else
    write_log $lf "SKIPPING - Rust"
  fi

  # Add to /etc/profile if not exist
  grep -q "${rust_export}" /etc/profile || echo $rust_export >> /etc/profile
}

function install_golang() {
  write_log $lf "------install_golang------"
  local go_version=$1
  local go_path=/usr/local
  local go_verify_path="${go_path}/go/bin"
  local go_file="go${go_version}.linux-amd64.tar.gz"
  local go_url="https://go.dev/dl/${go_file}"
  local go_export="export PATH=\$PATH:$go_verify_path"

  if ! [ -f $go_verify_path/go ]; then
    write_log $lf "INSTALL - Go - Binary not detected"
    curl -LO $go_url
    tar -C /usr/local -xzf $go_file
    rm $go_file
  else
    write_log $lf "SKIPPING - Go - Binary already Exists"
  fi

  write_log $lf  "UPDATE - Adding go to path if not exist"
  grep -q "${go_export}" /etc/profile || echo $go_export >> /etc/profile
}

# Updates the Go version if it was already installed to your choice
# change_golang_version "1.21.X"
function change_golang_version() {
  write_log $lf "------change_golang_version------"
  local target_version=$1
  local go_path=/usr/local
  local go_verify_path="${go_path}/go/bin"
  local go_file="go${target_version}.linux-amd64.tar.gz"
  local go_url="https://go.dev/dl/${go_file}"

  local go_version_installed=$($go_verify_path/go version | grep -c "$target_version")
  echo $go_version_installed
  # We only want to do this if it couldn't find the version and Go wasn't installed
  if [ $go_version_installed -eq 0 ] && [ -f $go_verify_path/go ]; then
      write_log $lf "UPDATE - Go - Install new target version $target_version"
      rm -rf $go_path/go
      curl -LO $go_url
      tar -C /usr/local -xzf $go_file
      rm $go_file
  else
      write_log $lf "SKIPPING - Target Go$target_version Already Version Installed"
  fi
}

function install_kubectl () {
  write_log $lf "------install_kubectl------"
  if ! [ -f /usr/local/bin/kubectl  ]; then
    write_log $lf "INSTALL - Kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
  else
    write_log $lf "SKIPPING - Kubectl already installed"
    echo $(kubectl version)
  fi
}

function install_dotnet() {
  write_log $lf "------install_dotnet------"
  # 8.0, 6.0 etc
  local version=$1
  local dotnet_version_installed=$(apt list dotnet-sdk-8.0 | grep "installed"| grep -c $version)

  if [ $dotnet_version_installed -eq 0 ];
  then
    write_log $lf "Install - Dotnet ${version}"
    declare msrepo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
    wget https://packages.microsoft.com/config/ubuntu/$msrepo_version/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt update -y
    sudo apt install dotnet-sdk-$version -y
  else
    write_log $lf "SKIPPING - Dotnet ${version} already installed"
    echo $(dotnet --list-sdks)
  fi
}

function install_terraform() {
  write_log $lf "------install_terraform------"
  if [[ $(apt list terraform | grep -c "installed") -le 0 ]];then
    write_log $lf "INSTALL - Terraform"
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update -y
    sudo apt install terraform -y
  else
    write_log $lf "SKIPPING - Terraform installed"
    echo $(terraform -version)
  fi
}

function install_ansible() {
  write_log $lf "------install_ansible------"
  if [[ $( apt list ansible | grep -c "installed") -le 0 ]];
  then
    write_log $lf "INSTALL - Ansible"
    sudo apt install software-properties-common
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt install ansible
  else
    write_log $lf  "SKIPPING - ansible installed"
    echo $(ansible -version)
  fi
}

function install_standard_apt_pkg() {
  write_log $lf "------install_standard_apt_pkg------"
  packages=(
  "curl"
  "jq"
  "wget"
  "default-jre"
  "python-pip3"
  "gnupg software-properties-common"
  "software-properties-common"
  )

  for pkg in "${packages[@]}";
  do
      write_log $lf "INSTALL DEFAULT APT PACKAGES - ${pkg}"
      sudo apt install -y $pkg
  done
}

############ BODY ############
write_log $lf "START Script"

write_log $lf "Running apt update/upgrade"
sudo apt update -y && sudo apt upgrade -y 

install_standard_apt_pkg

# Installs that need APT repos or downloaded binaries
install_rust
install_golang "1.22.0"
# change_golang_version "1.22.0"
install_kubectl
install_dotnet "8.0"
install_terraform
install_ansible

write_log $lf "END Script"