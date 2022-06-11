#!/bin/bash

BASE_URL='https://MEU_ENDERECO.com/linux/prod/' # Endereço base do repositório de artefatos
CIDR_BLOCK='10.0.4.0/24'
SERVER_PRIMARY_IP='10.0.4.1'

# Função base, comum para todas as instancias.
base() {
### É apenas um exemplo, porque já está sendo realizado no attach do disk pelo terraform (linha 28, storages.tf)
## Monta o volume de dados
# sudo mkfs -t ext4 /dev/sdb 
# sudo mkdir /totvs
# sudo mount /dev/sdb /totvs
# echo '/dev/sdb /totvs xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab
####
## Configura um usuario protheus
sudo adduser protheus
sudo usermod -aG root protheus
sudo usermod -aG wheel protheus
sudo mkdir -p /home/protheus/.ssh
sudo echo "ssh-rsa AA...ECJJ/E8=" | sudo tee -a /home/protheus/.ssh/authorized_keys
sudo chown -R protheus:protheus /home/protheus/.ssh

## Install programs
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum update -y
sudo yum install -y java-11-openjdk.x86_64 nfs-utils unzip lsof bc tar wget libnsl
sudo yum install -y unixODBC.x86_64 postgresql-odbc.x86_64 libstdc++.i686 libuuid.i686
sudo dnf install -y htop nmon

# ## Configura ODBC Postgresql 
cat <<AUL >> /etc/odbc.ini
[PROTHEUSDEV]
Servername=$POSTGRESQL_SERVER
Username=$POSTGRESQL_USER
Password=$POSTGRESQL_PASSWORD
Database=$POSTGRESQL_DATABASE
Driver=PostgreSQL
Port=5432
ReadOnly=0
MaxLongVarcharSize=2000
UnknownSizes=2
UseServerSidePrepare=1
AUL

## COMPARTILHAMENTO DOS DIRETORIOS
sudo mkdir -p /totvs/protheus/protheus_data
sudo mkdir -p /totvs/arte
sudo mkdir -p /totvs/logs

sudo chmod -R 777 /totvs/protheus/protheus_data
sudo chmod -R 777 /totvs/arte
sudo chmod -R 777 /totvs/logs

}

primaria() {
## COMPARTILHAMENTO DOS DIRETORIOS
sudo systemctl start nfs-server rpcbind
sudo systemctl enable nfs-server rpcbind

sudo echo "/totvs/protheus/protheus_data ${CIDR_BLOCK}(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
sudo echo "/totvs/arte ${CIDR_BLOCK}(rw,sync,no_root_squash)" | sudo tee -a /etc/exports
sudo echo "/totvs/logs ${CIDR_BLOCK}(rw,sync,no_root_squash)" | sudo tee -a /etc/exports

sudo exportfs -r

## Descompacta o pacote baixado da bucket
sudo tar -zxvf /tmp/protheus_bundle_12.1.33.tar.gz -C / # O arquivo protheus_bundle_12.1.33.tar.gz foi baixado na (linha 29, storages.tf)
# wget ${BASE_URL}/license/installer-3.3.3.tar.gz -O /tmp/installer-3.3.3.tar.gz
# wget ${BASE_URL}/dicionario/sxs.zip -O /tmp/sxs.zip
# wget ${BASE_URL}/dicionario/sdf.zip -O /tmp/sdf.zip

## Descompactar os pacotes
# unzip /tmp/sxs.zip -d /totvs/protheus/protheus_data/systemload/
# unzip /tmp/sdf.zip -d /protheus/protheus_data/system/
# sudo tar -zxvf /tmp/installer-3.3.3.tar.gz -C /totvs/licensever/

## Regras do Firewall
sudo firewall-cmd --permanent --add-service mountd
sudo firewall-cmd --permanent --add-service rpc-bind
sudo firewall-cmd --permanent --add-service nfs
sudo firewall-cmd --reload

}

secundaria() {
## COMPARTILHAMENTO DOS DIRETORIOS
mount ${SERVER_PRIMARY_IP}:/totvs/protheus/protheus_data /totvs/protheus/protheus_data
mount ${SERVER_PRIMARY_IP}:/totvs/arte /totvs/arte
mount ${SERVER_PRIMARY_IP}:/totvs/logs /totvs/logs

echo "${SERVER_PRIMARY_IP}:/totvs/protheus/protheus_data /totvs/protheus/protheus_data nfs nosuid,rw,sync,hard,intr 0 0" | sudo tee -a /etc/fstab
echo "${SERVER_PRIMARY_IP}:/totvs/arte /totvs/arte nfs nosuid,rw,sync,hard,intr 0 0" | sudo tee -a /etc/fstab
echo "${SERVER_PRIMARY_IP}:/totvs/logs /totvs/logs nfs nosuid,rw,sync,hard,intr 0 0" | sudo tee -a /etc/fstab

## Downloads de artefatos
wget ${BASE_URL}/bundle/protheus_bundle_12.1.33_sec.tar.gz -O /tmp/protheus_bundle_12.1.33.tar.gz
# wget ${BASE_URL}/appserver/appserver.tar.gz -O /tmp/appserver.tar.gz
# wget ${BASE_URL}/dbaccess/dbaccess.tar.gz -O /tmp/dbaccess.tar.gz
# wget ${BASE_URL}/dbaccess/dbapi.tar.gz -O /tmp/dbapi.tar.gz
# wget ${BASE_URL}/rpo/tttm120.rpo -O /tmp/tttm120.rpo

## Descompactar os pacotes
# tar -zxvf /tmp/appserver.tar.gz -C /totvs/tec/appserver/
# tar -zxvf /tmp/dbaccess.tar.gz -C /totvs/tec/dbaccess/
# mv /tmp/tttm120.rpo /totvs/protheus/apo/tttm120.rpo
}

database() {
sudo yum update -y
# sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-aarch64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql12-server
sudo dnf install -y postgresql12.aarch64 postgresql12-contrib.aarch64 postgresql12-devel.aarch64 postgresql12-libs.aarch64 postgresql12-llvmjit.aarch64 postgresql12-pltcl.aarch64 postgresql12-server.aarch64
sudo systemctl enable postgresql-12
sudo systemctl start postgresql-12

sudo mkdir -p pgsql/12/data
sudo mkdir -p /pgdata01/tablespace
sudo chown -R postgres:postgres /pgdata01/
sudo /usr/pgsql-12/bin/postgresql-12-setup initdb

# sudo sed /var/lib/pgsql/12/data/pg_hba.conf -i -e 's/local   all             all                                     peer/local   all             all                                     trust/g'
# sudo sed /var/lib/pgsql/12/data/postgresql.conf -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g"
}

helpFunction() {
    echo ""
    echo "Usage: $0 -m MODE 1|2 [1 - PRIMARY || 2 - SECONDARY]"
    echo -e "\t-m Mode Execute, default 2 [SECONDARY]"
    exit 1
}

while getopts "m:" opt
do
    case "$opt" in
        m ) parameterM="$OPTARG" ;;
        ? ) helpFunction ;;
    esac
done

if [ -z "$parameterM" ] ; then
    echo "Executa a configuração da instancia secundaria"
    base && secundaria
else
    case "$parameterM" in
        1 | PRIMARY | primary | p | P ) base && primaria ;;
        2 | SECONDARY | secondary | s | S ) base && secundaria ;;
        3 | DATABASE | database | db | DB ) database ;;
        ? ) helpFunction
    esac
fi







