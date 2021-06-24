#!/bin/bash

scp -r ~/dbk/vsphere/.vim $1:.
scp -r ~/dbk/vsphere/bashrc $1:.bashrc
scp -r ~/dbk/vsphere/vimrc $1:.vimrc
scp extra/* $1:.

ssh $1 sudo cp -r ./.vim /root/.vim
ssh $1 'sudo sh -c "cat ~adam/.bashrc >> /root/.bashrc"'
ssh $1 sudo cp .vimrc /root/.vimrc

ssh $1 sudo yum install -y wget strace vim man lsof nmap telnet tree
