# protheus-infra-as-code

> Projeto com Terraform para subir um ambiente Protheus

Este projeto está organizado de forma simples para estudo e primeiro contato com a ferramenta.

Neste repositório contém:
    - Modelo de script para gerar o pacote da estrutura do ambiente Protheu
    - Modelo de criação de bucket e upload de arquivos
    - Modelo de criação de vcn, subnet, nat gateway, internet gateway, route table, security list
    - Modelo de criação de storage e attach
    - Modelo de criação de instance

---

## Infra as Code (IaC)

> A infraestrutura como código (IaC) é como uma receita de bolo, escrevemos uma série de passos necessários para que uma determinada tarefa seja completada.

Podemos dizer que o Terraform é atualmente uma das ferramentas mais utilizadas e recomendadas para realizar o deploy de infraestrutura em nuvem. O Terraform combinado com o Ansible vira uma ferramenta extremamente poderosa para construir ambiente e configurar toda a arquitetura.

- <a href="https://www.terraform.io/downloads" target="_blank">Terraform</a> - <a href="https://github.com/hashicorp/terraform#readme" target="_blank">Git</a>

- <a href="https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html" target="_blank">Ansible</a> - <a href="https://github.com/ansible/ansible#readme" target="_blank">Git</a>

Neste projeto temos o Terraform que através de um provider (e quando digo provider pode ser qualquer um provider, pois o terraform possui diversos provider como GCP, AWS, Azure, OCI e até mesmo VMware.) que são pontos de configuração que define onde vai ser construído a sua infraestrutura.

- <a href="https://registry.terraform.io/browse/providers" target="_blank">Providers</a>

Uma vez que você escolheu qual vai ser o seu _provider_, já pode começar a nossa receita de bolo.

Para este ambiente vamos construir uma instância de aplicação, uma instância com banco de dados (PostgreSQL), uma bucket e toda a rede com a sua virtual cloud network (VCN).

no arquivo ```providers.tf```

```hcl
terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "4.79.0"
    }
  }
}

provider "oci" {
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}
```

```sh
variable tenancy_ocid {}
variable user_ocid {}
variable fingerprint {}
variable private_key_path {}
variable compartment_ocid {}
```

Estamos subindo apenas uma instância de aplicação mas poderia ser N servidores de aplicação, optamos por seguir o desenho mais simples para facilitar no estudo.
O banco de dados está sendo instalado em um servidor instanciado, mas poderia ser facilmente construído como um banco de dados RDS, ADB, DBSystem, etc...

Também vamos precisar de um repositório de artefatos que aqui é uma bucket, mas pode ser um servidor de arquivos ou um ponto comum de acesso com todos os artefatos.

> E é a partir daqui que vai entender a importância de ter um ambiente normalizado. Porque quanto mais normalizado e organizado os seus artefatos e arquivos de configuração (como appserver.ini, dbaccess.ini, smartclient.ini) melhor.

Não posso deixar de falar que é fortemente recomendado gerenciar os seus scripts e arquivos do terraform .tf com um versionador como o git.

### A construção

_Dando continuidade… vamos ver a construção do ambiente propriamente dito._

Deploy
…

```instances.tf``` Neste aquivo está toda a configuração para construir o servidor, conforme a documentação o [provider](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance)

Pontos de destaque no ```instances.tf``` (Pulo do gato!)

```hcl
  count               = var.instances # Variável de controle, define o número de instâncias que serão construídas com estas mesmas configurações.
  ...
  agent_config {
    ...
    # Caso esteja utilizando o provider OCI recomendo os plugins, configurados aqui.
  }
  ...
```

```hcl
  create_vnic_details {
    ...
    private_ip       = cidrhost(oci_core_subnet.subn_publica.cidr_block, 100 + count.index)
    
    # private_ip     = cidrhost(10.0.2.0/26, 100 + count.index)
    # Definir o ip de forma dinâmica a quando se utiliza construir mais de um servidor com as mesmas configurações.
  }
  ...
```

```hcl
metadata = {
    ssh_authorized_keys = file(var.ssh_file_public_key)
    # Adiciona uma chave pública para acessar o servidor via ssh
  }

  # Faz a conexão no servidor que está sendo construído.
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "opc"
    private_key = file(var.ssh_private_key)
    agent       = false
  }

  # Como o "provisioner" é possível realizar algumas configurações do servidor copiando para dentro da máquina
  # um script ou até mesmo os artefatos da aplicação.
  # Lembrete: Evite de transferir arquivos grandes, pois pode sobrecarregar o processo de construção
  # fazendo com que eleve o tempo do deploy do terraform

  # Parâmetro:
  # file - Transfere um arquivo para o servidor
  # local-exec - Executa um ou mais comandos local
  # remote-exec - Executa um ou mais comandos dentro do servidor

  #  provisioner "file" {
  #    source      = "${path.module}/config_files/setup_app.sh"
  #    destination = "/tmp/setup_app.sh"
  #  }

  # provisioner "file" {
  #   source      = "${path.module}/artefatos/protheus_bundle_12.1.33.tar.gz"
  #   destination = "/tmp/protheus_bundle_12.1.33.tar.gz"
  # }

 
  # provisioner "remote-exec" {
  #  inline = ["sudo systemctl stop firewalld",
  #    "sudo systemctl disable firewalld"
  #  ]
  # }
 }

```

---

Com o comando ```terraform plan``` será exibido um plano de tudo que será executado, neste momento podemos verificar os recursos que serão adicionados, alterados e removidos. Caso exista erro na lógica ou configuração do recurso ele será exibido neste ponto.

Com o retorno de sucesso do ```terraform plan```, podemos seguir para o ```terraform apply```.

Quando executamos o ```terraform apply``` é executado novamente a verificação do plano, e neste ponto é importante verificar o que está sendo alterado, removido e até mesmo adicionado.

>_Pode parecer desnecessário e repetitivo, mas após digitar ```yes``` no input abaixo ele vai executar todo aquele plano no provider que foi configurado. Caso algo seja alterado no cloud provider ou até mesmo no código neste meio tempo pode gerar complicações se passar despercebido uma ```destroy``` de um recurso que não deveria ser removido._

Agora o Terraform vai se comunicar com o provider e vai enviar as requisições, em poucos instantes já é possível verificar que começou a aparecer os recursos.

---

Lembra que eu comentei que o Terraform constrói e o Ansible configura, pois bem o Terraform também pode configurar, mas ele não foi feito para isso, então só fazemos isso quando é preciso, como por exemplo configurar um disco adicional que está sendo acoplado na instância ou quando é um projeto é simples no ponto de vista do IaC.

Também podemos cair nesta exceção quando o conceito de infraestrutura como código está sendo visto pela primeira vez, pois normalmente a curva de aprendizado de uma ferramenta é maior comparado a curva de tentar aprender duas ferramentas em paralelo.

Então aqui nós injetamos um script dentro da máquina logo após a inicialização, no exato momento quando o provider nos fala que o recurso está liberado e vamos rodas algumas coisas como atualização do SO, baixar os artefatos da bucket, enfim tudo aquilo que é necessário ser feito para deixar a instância pronta para usar.

_Então aqui nos resta esperar e ir buscar um café e esperar a máquina fazer o trabalho dela._


---

### E o Ansible?

Em breve vou subir em uma nova branch o mesmo projeto com o Ansible.
