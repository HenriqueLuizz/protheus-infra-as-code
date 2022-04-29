#!/bin/bash

sudo yum update -y
# sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-aarch64/pgdg-redhat-repo-latest.noarch.rpm
# sudo dnf -qy module disable postgresql
# sudo dnf install -y postgresql12-server
# sudo dnf install -y postgresql12.aarch64 postgresql12-contrib.aarch64 postgresql12-devel.aarch64 postgresql12-libs.aarch64 postgresql12-llvmjit.aarch64 postgresql12-pltcl.aarch64 postgresql12-server.aarch64
# sudo systemctl enable postgresql-12
# sudo systemctl start postgresql-12

# sudo mkdir -p pgsql/12/data
# sudo mkdir -p /pgdata01/tablespace
# sudo chown -R postgres:postgres /pgdata01/
# sudo /usr/pgsql-12/bin/postgresql-12-setup initdb

# sudo sed /var/lib/pgsql/12/data/pg_hba.conf -i -e 's/local   all             all                                     peer/local   all             all                                     trust/g'
# sudo sed /var/lib/pgsql/12/data/postgresql.conf -i -e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g"

# sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# sudo yum install -y htop
