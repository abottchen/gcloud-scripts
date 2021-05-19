#!/bin/bash
sudo yum -y install bash-completion
sudo kubectl completion bash >/etc/bash_completion.d/kubectl
