#!/bin/bash
source ~/.bashrc

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

logf=ubuntu-server-installs.log

write_log $logf "START Script"

write_log $logf "Running apt update/upgrade"
sudo apt update -y && sudo apt upgrade -y 

packages=(
"curl"
"jq"
"wget"
"default-jre"
"python-pip3"
"gnupg software-properties-common"
"software-properties-common"
"golang"
)


for pkg in "${packages[@]}";
do
    write_log $logf "INSTALL DEFAULT APT PACKAGES - ${pkg}"
    sudo apt install -y $pkg
done

###### NON DEFAULT APT INSTALLS ######

# Rust - Silent Install
if [[ $(rustc --version | grep -c "rust") -le 0 ]];
then
  write_log $logf "INSTALL - Rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  write_log $logf "SKIPPING - Rust already installed"
  echo $(rustc --version)
  echo $(cargo version)
fi


# kubectl
if ! [ -f /usr/local/bin/kubectl  ]; then
  write_log $logf "INSTALL - Kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
else
  write_log $logf "SKIPPING - Kubectl already installed"
  echo $(rustc --version)
  echo $(kubectl version)
fi


# # dotnet-8
if [[ $(dotnet --list-sdks| grep -c "8") -le 0 ]];
then
  write_log $logf "Install - Dotnet 8"
  declare repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
  wget https://packages.microsoft.com/config/ubuntu/$repo_version/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  rm packages-microsoft-prod.deb
  sudo apt update -y
  sudo apt install dotnet-sdk-8.0 -y
else
  write_log $logf "SKIPPING - Dotnet 8 already installed"
  echo $(dotnet --list-sdks)
fi

# terraform
if [[ $(terraform -version | grep -c "Terraform") -le 0 ]];
then
  write_log $logf "INSTALL - Terraform"
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
  write_log $logf "SKIPPING - Terraform installed"
  echo $(terraform -version)
fi


# ansible
if [[ $( ansible --version | grep -c core) -le 0 ]];
then
  write_log $logf "INSTALL - Ansible"
  sudo apt install software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt install ansible
else
  write_log $logf  "SKIPPING - ansible installed"
  echo $(ansible -version)
fi

write_log $logf "END Script"