#!/bin/bash

# Pretty much the first stuff I need to get up and running

# Run through any updates pending on new installs
sudo apt update && and sudo apt upgrade

# Enable SSH, and xrdp for remote development
# Curl cause its used everywhere
# Snapd cause to install certain things like vscode
sudo apt install -y openssh-server \
     snapd \
     xrdp \
	 curl

sudo snap install --classic code # or code-insiders