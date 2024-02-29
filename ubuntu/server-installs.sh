# #!/bin/bash
packages=(
"curl"
"jq"
"wget"
"default-jre"
"python-pip3"
"gnupg software-properties-common"
)

sudo apt update -y && sudo apt upgrade -y 


for pkg in "${packages[@]}";
do
    sudo apt install -y $pkg

done

###### NON DEFAULT APT INSTALLS ######
# todo IF
# golang
if [[ $(go version | grep -c "go version") -le 0 ]];
then
    echo "Install - Golang"
    go_version="1.22.0"
    go_tar="go${go_version}.linux-amd64.tar.gz"
    curl -OL https://golang.org/dl/$go_tar
    rm -rf /usr/local/go && tar -C /usr/local -xzf $go_tar
    echo "PATH=$PATH:/usr/local/go/bin" >> /etc/profile
    export PATH=/usr/local/go/bin/:$PATH
    rm $go_tar
else
    echo "SKIPPING - go already installed"
    echo $(go version)
fi

# Rust - Silent Install
if [[ $(rustc --version | grep -c "rust") -le 0 ]];
then
    echo "Install - Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "SKIPPING - Rust already installed"
    echo $(rustc --version)
    echo $(cargo version)
fi


# kubectl
if ! [ -f /usr/local/bin/kubectl  ]; then
    echo "Install - Kubectl"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
else
    echo "SKIPPING - Kubectl already installed"
    echo $(rustc --version)
    echo $(kubectl version)
fi


# # dotnet-8
if [[ $(dotnet --list-sdks| grep -c "dotnet") -le 0 ]];
then
    echo "Install - Dotnet 8"
    declare repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
    wget https://packages.microsoft.com/config/ubuntu/$repo_version/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt update -y
    sudo apt install dotnet-sdk-8.0 -y
else
    echo "SKIPPING - Dotnet 8 already installed"
    echo $(dotnet --list-sdks)
fi

# terraform
if [[ $(terraform -version | grep -c "Terraform") -le 0 ]];
then
    echo "Install - Terraform"
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
    echo "SKIPPING - Terraform installed"
    echo $(terraform -version)
fi