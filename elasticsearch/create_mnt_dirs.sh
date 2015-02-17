#!/bin/bash
set -uef -o pipefail

mkdir /mnt/elasticsearch
chown elasticsearch:elasticsearch /mnt/elasticsearch
sudo -u elasticsearch mkdir -p /mnt/elasticsearch/{data,work,logs}
