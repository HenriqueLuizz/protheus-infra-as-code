#!/bin/bash

## Monta os diretorios
# mkfs -t ext4 /dev/sdb 
# mkdir /totvs
# mount /dev/sdb /totvs

## Descompacta o pacote baixado da bucket
sudo tar -zxvf /tmp/protheus_bundle_12.1.33.tar.gz -C /

## Configura um usuario xpto
sudo adduser xpto
sudo usermod -aG root xpto
sudo usermod -aG wheel xpto
sudo mkdir -p /home/xpto/.ssh
sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDYTgy+GKCOoqwcz3XO23mrD4khasz0cLy8LQFnd3MjSEcZ3pXK/YCDFYqFknao/\
H4vvexW3gcxKLi/71nAdHwV8YwJr7l1t1l3avdQwO6KdnlfsSvd2X89SWljcq393+f5BleS9ZXnmvdF75lZPS6OHgfdxWktJTxSphudpOMA8iNXJs\
E2xQijlZ35qizg3gkuCYuD3HDcTXvDXjUZK4bGiAnGEPFef+6zLx431+GQTjigrUCdAYQaWlcxiNq/u/dvouHyPAmu7fJ47qReExlcqHEhLJUey5e\
HuowSEv9mDtkAyJXysLarO5N3NkT4C4LDoM/aS4RVfB+iBdY4Cu0v0FeAgq9wMyVVRItNbNVq6EVmA3aQe5FYG2G7bIT1L6XxPefcIekQPpUfZhIVd\
hu2t6MXbbJfD2PI40nIH42A9T1hvPxTys/9NXnX1iZvnWdOucpBldvwLw0WCcQqj244mkpHpxGd/BOqA5p8/XptxhWH3wJiWa2URu4BECJJ/E8= \
" >> /home/xpto/.ssh/authorized_keys

sudo chown -R xpto:xpto /home/xpto/.ssh

## Install programs
sudo yum update -y
# sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
# sudo dnf update -y
sudo yum install -y java-11-openjdk.x86_64 nfs-utils unzip lsof bc tar wget libnsl
sudo yum install -y unixODBC.x86_64 postgresql-odbc.x86_64 libstdc++.i686 libuuid.i686
sudo dnf install -y htop nmon


## Downloads de artefatos
# wget https://MEU_ENDERECO.com/linux/prod/appserver/appserver.tar.gz -O /tmp/appserver.tar.gz
# wget https://MEU_ENDERECO.com/linux/prod/dbaccess/dbaccess.tar.gz -O /tmp/dbaccess.tar.gz
# wget https://MEU_ENDERECO.com/linux/prod/dbaccess/dbapi.tar.gz -O /tmp/dbapi.tar.gz
# wget https://MEU_ENDERECO.com/linux/prod/rpo/tttm120.rpo -O /tmp/tttm120.rpo
# wget https://MEU_ENDERECO.com/linux/prod/dicionario/sxs.zip -O /tmp/sxs.zip
# wget https://MEU_ENDERECO.com/linux/prod/dicionario/sdf.zip -O /tmp/sdf.zip
# wget https://MEU_ENDERECO.com/linux/prod/license/installer-3.3.3.tar.gz -O /tmp/installer-3.3.3.tar.gz

## COMPARTILHAMENTO DOS DIRETORIOS
# sudo mkdir -p /totvs/protheus/protheus_data
# sudo mkdir -p /totvs/arte
# sudo mkdir -p /totvs/logs

# sudo chmod -R 777 /totvs/protheus/protheus_data
# sudo chmod -R 777 /totvs/arte
# sudo chmod -R 777 /totvs/logs

# sudo systemctl start nfs-server rpcbind
# sudo systemctl enable nfs-server rpcbind

# sudo echo "/totvs/protheus/protheus_data 10.0.4.0/24(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
# sudo echo "/totvs/arte 10.0.4.0/24(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
# sudo echo "/totvs/logs 10.0.4.0/24(rw,sync,no_root_squash)" | sudo tee -a /etc/exports

# sudo exportfs -r

## Descompactar os pacotes
# tar -zxvf /tmp/appserver.tar.gz -C /totvs/tec/appserver/
# tar -zxvf /tmp/dbaccess.tar.gz -C /totvs/tec/dbaccess/
# unzip /tmp/sxs.zip -d /totvs/protheus/protheus_data/systemload/
# unzip /tmp/sdf.zip -d /protheus/protheus_data/system/
# mv /tmp/tttm120.rpo /totvs/protheus/apo/tttm120.rpo
# sudo tar -zxvf /tmp/installer-3.3.3.tar.gz -C /totvs/licensever/


## Regras do Firewall
# sudo firewall-cmd --permanent --add-service mountd
# sudo firewall-cmd --permanent --add-service rpc-bind
# sudo firewall-cmd --permanent --add-service nfs
# sudo firewall-cmd --reload

# ## Configura ODBC Postgresql 
cat <<AUL >> /etc/odbc.ini
[PROTHEUSDEV]
Servername=10.0.4.5
Username=postgres
Password=$POSTGRES_PASSWORD
Database=protheusdev
Driver=PostgreSQL
Port=5432
ReadOnly=0
MaxLongVarcharSize=2000
UnknownSizes=2
UseServerSidePrepare=1
AUL

