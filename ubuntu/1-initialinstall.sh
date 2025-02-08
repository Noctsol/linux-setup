#!/bin/bash

# Pretty much the first stuff I need to get up and running

echo "> Running through apt installs"
# Run through any updates pending on new installs
sudo apt update && and sudo apt upgrade
# Enable SSH, and xrdp for remote development
# Curl cause its used everywhere
# Snapd cause to install certain things like vscode
sudo apt install -y openssh-server \
    snapd \
    xrdp \
	curl \
    build-essential  \
    procps \
    file \
    git

echo "---------------"
echo "> Installing VS code via snadp"
sudo snap install --classic code # or code-insiders


echo "---------------"
# Installing zsh
if zsh --version &> /dev/null;
then
     echo "> SKIP: zsh already installed"
else
     echo "> Installing zsh"
     sudo apt install zsh
     sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi


echo "---------------"
echo "> Installing Atuin"
atuin_filepath="/home/$USER/.atuin/bin/atuin"
echo $atuin_filepath
if [ -f $atuin_filepath ];
then
    echo "- SKIP: Atuin already installed"
else
    echo "- Installing Atuin"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | bash
fi


echo "---------------"
echo "- Setting up github SSH key"

# Setting up GitHub Keys
github_key_path=~/.ssh/github_rsa
if [ ! -f $github_key_path ];
then
    echo "- Generating GitHub SSH key"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_rsa -N ""
else
    echo "- $github_key_path already exists - continuing"
fi

# Directions
echo "- Add this to your GitHub SSH Keys"
cat ~/.ssh/github_rsa.pub
# Command to start the ssh agent ( this will get appended to your rc file later)
if [ -n "$SSH_AGENT_PID" ] && ps -p "$SSH_AGENT_PID" > /dev/null 2>&1;
then
    echo "- ssh-agent is already running - no action taken"
else
    echo "- starting ssh-agent"
    eval `ssh-agent -s`
	echo "- adding github key"
	ssh-add ~/.ssh/github_rsa
fi


echo "---------------"
echo "- Setting up vscode remote SSH"
# # Setting up keys for remote SSH
vscode_key_path=~/.ssh/vscode_${HOSTNAME}
if [ ! -f $vscode_key_path ];
then
    echo "- Generating $vscode_key_path"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/vscode_${HOSTNAME} -N ""
    cat ~/.ssh/vscode_${HOST}.pub >> ~/.ssh/authorized_keys
else
    echo "- $vscode_key_path already exists - continuing"
fi

# Printing out directions for me in the future
file_addon="Host $HOSTNAME\n
\tHostName $HOSTNAME\n
\tUser $USER\n
\tPreferredAuthentications publickey\n
\tIdentityFile \"C:/Users/Noctsol/.ssh/vscode_${HOSTNAME}\""

echo "- Download $vscode_key_path and add the key to C:\Users\Noctsol\.ssh\config on your windows machine"
echo "- On your windows machine, it should look like this:"
echo -e $file_addon


echo "---------------"
echo "> Appending contents to .zshrc file"
script_path="$(realpath "$0")"
script_directory_path=$(dirname "$script_path")
ref_path="$script_directory_path/ref"
rc_addons_txt="$ref_path/rcfileappends.txt"

# echo "Script is located at: $script_path"
# echo $script_directory_path
# echo $ref_path
# echo $rc_addons_txt

if grep -Fxq -f $rc_addons_txt ~/.zshrc; then
    echo "- SKIP: Contents already added"
else
    echo "- Adding contents of $rc_addons_txt to ~/.zshrc"
    cat $rc_addons_txt >> ~/.zshrc
fi

echo "---------------"
echo "> Installing brew"
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ];
then
    echo "- SKIP: Brew already installed"
else
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo export PATH=$PATH:/opt/homebrew/bin >> ~/.zshrc
    echo >> /home/ubuntuuser/.zshrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/ubuntuuser/.zshrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi


echo "---------------"
echo "Attention: Restart your session so that changes take place"
