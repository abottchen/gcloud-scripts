#!/bin/bash

scp -r ~/.vim $1:.
scp -r ~/bashrc $1:.bashrc
scp -r ~/.vimrc $1:.vimrc
scp extra/* $1:.

ssh $1 sudo cp -r ~adam/.vim /root/.vim
ssh $1 'sudo sh -c "cat ~adam/.bashrc >> /root/.bashrc"'
ssh $1 sudo cp .vimrc /root/.vimrc

if ssh $1 grep Ubuntu /etc/os-release 2>&1 > /dev/null; then
  ssh $1 sudo apt -y --fix-broken install
  ssh $1 sudo apt-get update -y
  ssh $1 sudo apt-get install -y nfs-common libnfsidmap2 libtirpc3 rpcbind keyutils libtirpc-common jq
else
  ssh $1 sudo yum install -y wget strace vim man lsof nmap telnet tree
fi
