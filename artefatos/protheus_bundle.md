# Script modelo para criar o pacote do ambiente

Script modelo utilizado para montar o pacote com a estrutura do ambiente protheus
 que será carregado para cada servidor.

``` sh
#!/bin/bash

protheus_bundle='protheus_bundle_x64-12.1.33-lnx'

helpFunction() {
    echo ""
    echo "Usage: $0 -m MODE 1|2|3 [1 - PRIMARY || 2 - SECONDARY || 3 - ALL]"
    echo -e "\t-m Mode Execute, default 3 [ALL]"
    exit 1
}

primary() {
    # Monta a estrutura de diretórios dos artefatos
    mkdir totvs/tec/dbaccess-secondary
    mkdir totvs/tec/appserver-broker
    mkdir totvs/tec/appserver-compilacao

    # Copia o appserver.ini default
    cp -v ini/appserver-primary.ini totvs/tec/appserver/appserver.ini

    # Copia o dbaccess.ini default
    cp -Rv totvs/tec/dbaccess/* totvs/tec/dbaccess-secondary/
    cp -v ini/dbaccess-primmary.ini totvs/tec/dbaccess/dbaccess.ini
    cp -v ini/dbaccess-secondary.ini totvs/tec/dbaccess-secondary/dbaccess.ini

    # Copia os binários para os seus respectivos diretórios
    cp -Rv totvs/tec/appserver/* totvs/tec/appserver-broker/
    cp -Rv totvs/tec/appserver/* totvs/tec/appserver-compilacao/

    # Copia os appserver.ini default do broker e do compilação
    cp -v ini/appserver-broker.ini totvs/tec/appserver-broker/appserver.ini
    cp -v ini/appserver-compilacao.ini totvs/tec/appserver-compilacao/appserver.ini

    # Remove pacote compactado existente
    rm -rf ${protheus-bundle}-top-bra.zip

    # Compacta o diretório /totvs via zip
    zip -9rv ${protheus-bundle}-top-bra.zip totvs
    
    # Remove diretórios auxiliares do processo de geração do pacote
    rm -rf totvs/tec/dbaccess-secondary
    rm -rf totvs/tec/appserver-broker
    rm -rf totvs/tec/appserver-compilacao

    ## Carrega o pacote para a bucket pré configurada (Exemplo Local, OCI cli e GCP cli)
    # scp ${protheus-bundle}-top-bra.zip <SERVIDOR_DE_ARQUIVOS>:/artefatos-prothues/

    ## https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.8.0/oci_cli_docs/cmdref/os/object/put.html
    oci os object bulk-upload -ns <object_storage_namespace> -bn artefatos-protheus --include "${protheus-bundle}-top-bra.zip" --src-dir .
    
    ## https://cloud.google.com/storage/docs/gsutil/commands/cp
    # gsutil cp ${protheus-bundle}-top-bra.zip gs://artefatos-prothues/
}

secondary() {

    ## Copia os appserver.ini e dbaccess.ini
    cp -v ini/appserver-secondary.ini totvs/tec/appserver/appserver.ini
    cp -v ini/dbaccess-secondary.ini totvs/tec/dbaccess/dbaccess.ini

    ## Renomeia o diretório do dbaccess 
    mv totvs/tec/dbaccess totvs/tec/dbaccess-secondary

    ## Cria uma cópia do appserver (para ambientes com 2 appservers por servidor)
    cp -Rv totvs/tec/appserver totvs/tec/appserver02
    mv totvs/tec/appserver totvs/tec/appserver01

    ## Renomeia as tags dentro do appserver.ini para 01 e 02, essa tag serve para diferenciar 
    ## os nomes dos serviços, porta do serviço e arquivos de log.
    sed -i -e 's/NN/01/g' totvs/tec/appserver01/appserver.ini
    sed -i -e 's/NN/02/g' totvs/tec/appserver02/appserver.ini
    
    ## Remove pacote exitente
    rm -rf protheus_bundle_x64-12.1.33-lnx-sec.zip
    
    ## Compacta o diretório /totvs sem o diretório protheus_data via zip
    zip -9rv protheus_bundle_x64-12.1.33-lnx-sec.zip totvs "--exclude=*protheus_data*"

    ## Renomei o nome dos diretórios para o default
    mv totvs/tec/dbaccess-secondary totvs/tec/dbaccess
    mv totvs/tec/appserver01 totvs/tec/appserver

    ## Remove o diretório auxiliar do ambiente de geração do pacote
    rm -rf totvs/tec/appserver02

    ## Carrega o pacote para a bucket pré configurada (Exemplo Local, OCI cli e GCP cli)
    # scp protheus_bundle_x64-12.1.33-lnx-sec.zip <SERVIDOR_DE_ARQUIVOS>:/artefatos-prothues/

    ## https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.8.0/oci_cli_docs/cmdref/os/object/put.html
    # oci os object bulk-upload -ns oraclepartnersas -bn artefatos-protheus --include 'protheus_bundle_x64-12.1.33-lnx-sec.zip' --src-dir .

    
    ## https://cloud.google.com/storage/docs/gsutil/commands/cp
    # gsutil -o GSUtil:parallel_composite_upload_threshold=512M \
    # -o "GSUtil:parallel_process_count=12" \
    # -o "GSUtil:parallel_thread_count=10" \
    # cp protheus_bundle_x64-12.1.33-lnx-sec.zip gs://artefatos-protheus/

}


update() {

    ## Define o caminho raiz dos diretórios de binário e protheus
    path='/Users/henriqueluiz/Projects/bmk-terraform/totvs_lnx/totvs/tec'
    protheus_path='/Users/henriqueluiz/Projects/bmk-terraform/totvs_lnx/totvs/protheus'

    ## Baixa os os binários para os respectivos diretórios
    wget https://MEU_ENDERECO.com/linux/prod/dbaccess/dbaccess.tar.gz -O ${path}/dbaccess.tar.gz
    wget https://MEU_ENDERECO.com/linux/prod/appserver/appserver.tar.gz -O ${path}/appserver.tar.gz
    wget https://arte.engpro.totvs.com.br/tec/smartclientwebapp/harpia/linux/64/published/smartclientwebapp.tar.gz -O ${path}/webapp.tar.gz
    wget https://MEU_ENDERECO.com/linux/prod/rpo/tttm120.rpo -O ${protheus_path}/apo/tttm120.rpo

    wget https://MEU_ENDERECO.com/linux/prod/dicionario/completo/BRA-DICIONARIOS_COMPL.ZIP -O ${protheus_path}/BRA-DICIONARIOS_COMPL.ZIP
    wget https://MEU_ENDERECO.com/linux/prod/dicionario/completo/BRA-HELPS_COMPL.ZIP -O ${protheus_path}/BRA-HELPS_COMPL.ZIP
    wget https://MEU_ENDERECO.com/linux/prod/dicionario/menus/BRA-MENUS.ZIP -O ${protheus_path}/BRA-MENUS.ZIP

    ## Descompacta os artefatos nos respectivos diretórios.
    tar -zxvf ${path}/dbaccess.tar.gz -C ${path}/dbaccess
    tar -zxvf ${path}/appserver.tar.gz -C ${path}/appserver
    tar -zxvf ${path}/webapp.tar.gz -C ${path}/appserver/

    unzip -o ${protheus_path}/BRA-DICIONARIOS_COMPL.ZIP -d ${protheus_path}/protheus_data/systemload/
    unzip -o ${protheus_path}/BRA-HELPS_COMPL.ZIP -d ${protheus_path}/protheus_data/systemload/
    unzip -o ${protheus_path}/BRA-MENUS.ZIP -d ${protheus_path}/protheus_data/system/

    ## Remove os arquivos auxiliares
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
```
