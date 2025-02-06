#!/bin/bash

# Setting up keys for ssh for github and and then remote vscode connection


# Setting up GitHub Keys
github_key_path=~/.ssh/github_rsa
echo $github_key_path
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
