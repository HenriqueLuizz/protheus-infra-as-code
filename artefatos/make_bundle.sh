#!/bin/bash

BASE_URL='https://MEU_ENDERECO.com/linux/prod/' # Endereço base do repositório de artefatos

helpFunction() {
    echo ""
    echo "Usage: $0 -m MODE 1|2|3|4 [1 - PRIMARY || 2 - SECONDARY || 3 - ALL || 4 - UPDATE BUNDLE ]"
    echo -e "\t-m Mode Execute, default 3 [ALL]"
    exit 1
}

primary() {

    mkdir totvs/tec/dbaccess-secondary
    mkdir totvs/tec/appserver-broker
    mkdir totvs/tec/appserver-compilacao

    cp -v ini/appserver-primary.ini totvs/tec/appserver/appserver.ini

    cp -Rv totvs/tec/dbaccess/* totvs/tec/dbaccess-secondary/
    cp -v ini/dbaccess-primmary.ini totvs/tec/dbaccess/multi/dbaccess.ini
    cp -v ini/dbaccess-secondary.ini totvs/tec/dbaccess-secondary/multi/dbaccess.ini

    cp -Rv totvs/tec/appserver/* totvs/tec/appserver-broker/
    cp -Rv totvs/tec/appserver/* totvs/tec/appserver-compilacao/

    cp -v ini/appserver-broker.ini totvs/tec/appserver-broker/appserver.ini
    cp -v ini/appserver-compilacao.ini totvs/tec/appserver-compilacao/appserver.ini

    rm -rf protheus_bundle_x64-12.1.33.zip

    zip -9rv protheus_bundle_x64-12.1.33.zip totvs
    
    rm -rf totvs/tec/dbaccess-secondary
    rm -rf totvs/tec/appserver-broker
    rm -rf totvs/tec/appserver-compilacao

    # gsutil cp protheus_bundle_x64-12.1.27.zip gs://bmkprotheus/
    oci os object bulk-upload -ns oraclepartnersas -bn protheus-bucket --include 'protheus_bundle_x64-12.1.33.zip' --src-dir .

}

secondary() {
    cp -v ini/appserver-secondary.ini totvs/tec/appserver/appserver.ini
    cp -v ini/dbaccess-secondary.ini totvs/tec/dbaccess/multi/dbaccess.ini

    mv totvs/tec/dbaccess totvs/tec/dbaccess-secondary

    cp -Rv totvs/tec/appserver totvs/tec/appserver02
    mv totvs/tec/appserver totvs/tec/appserver01

    sed -i -e 's/NN/01/g' totvs/tec/appserver01/appserver.ini
    sed -i -e 's/NN/02/g' totvs/tec/appserver02/appserver.ini
    
    rm -rf protheus_bundle_x64-12.1.33-lnx-sec.zip
    
    zip -9rv protheus_bundle_x64-12.1.33-lnx-sec.zip totvs "--exclude=*protheus_data*"

    mv totvs/tec/dbaccess-secondary totvs/tec/dbaccess
    mv totvs/tec/appserver01 totvs/tec/appserver
    rm -rf totvs/tec/appserver02

    # gsutil cp protheus_bundle_x64-12.1.27-lnx-sec.zip gs://bmkprotheus/
    oci os object bulk-upload -ns oraclepartnersas -bn protheus-bucket --include 'protheus_bundle_x64-12.1.33-lnx-sec.zip' --src-dir .
}

update() {
    
    path='totvs_lnx/totvs/tec'
    protheus_path='totvs_lnx/totvs/protheus'

    mkdir -p $path
    mkdir -p $protheus_path

    wget ${BASE_URL}tec/dbaccess/linux/64/next/dbaccess.tar.gz -O ${path}/dbaccess.tar.gz
    wget ${BASE_URL}tec/appserver/harpia/linux/64/next/appserver.tar.gz -O ${path}/appserver.tar.gz
    wget ${BASE_URL}tec/smartclientwebapp/harpia/linux/64/published/smartclientwebapp.tar.gz -O ${path}/webapp.tar.gz

    wget ${BASE_URL}protheus/padrao/published/dicionario/dicionario_de_dados/completo/BRA-DICIONARIOS_COMPL.ZIP -O ${protheus_path}/BRA-DICIONARIOS_COMPL.ZIP
    wget ${BASE_URL}protheus/padrao/published/dicionario/help_de_campo/completo/BRA-HELPS_COMPL.ZIP -O ${protheus_path}/BRA-HELPS_COMPL.ZIP
    wget ${BASE_URL}protheus/padrao/published/dicionario/menus/BRA-MENUS.ZIP -O ${protheus_path}/BRA-MENUS.ZIP

    tar -zxvf ${path}/dbaccess.tar.gz -C ${path}/dbaccess
    tar -zxvf ${path}/appserver.tar.gz -C ${path}/appserver
    tar -zxvf ${path}/webapp.tar.gz -C ${path}/appserver/

    unzip -o ${protheus_path}/BRA-DICIONARIOS_COMPL.ZIP -d ${protheus_path}/protheus_data/systemload/
    unzip -o ${protheus_path}/BRA-HELPS_COMPL.ZIP -d ${protheus_path}/protheus_data/systemload/
    unzip -o ${protheus_path}/BRA-MENUS.ZIP -d ${protheus_path}/protheus_data/system/

    rm -rf ${path}/dbaccess.tar.gz
    rm -rf ${path}/appserver.tar.gz
    rm -rf ${protheus_path}/BRA-DICIONARIOS_COMPL.ZIP
    rm -rf ${protheus_path}/BRA-HELPS_COMPL.ZIP
    rm -rf ${protheus_path}/BRA-MENUS.ZIP
}

while getopts "m:" opt
do
    case "$opt" in
        m ) parameterM="$OPTARG" ;;
        ? ) helpFunction ;;
    esac
done

if [ -z "$parameterM" ] ; then
    echo "Execute mount bundle for primary"
    primary
    echo "Execute mount bundle for secondary"
    secondary
else
    case "$parameterM" in
        1 | PRIMARY | primary | p | P ) primary ;;
        2 | SECONDARY | secondary | s | S ) secondary ;;
        3 | ALL | all | a | A ) primary && secondary ;;
        4 | UPDATE | update | u | U ) update ;;
        ? ) helpFunction
    esac
fi

# oci os object bulk-upload -ns oraclepartnersas -bn protheus-bucket --include '*.zip' --src-dir .