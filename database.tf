########################################################################################################################
########################################################################################################################
## Bloco que define a configuração da instancia do banco de dados
## Neste caso é uma instancia computer que será instalado o PostgreSQL via scritp durante a inicialização do sistema.
# Doc: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
#
# Todos o ${var.*} são variáveis que serão substituidas pelo Terraform no momento da criação da instancia
# Onde * é o nome da variável, exemplo: ${var.name}.
# Todas as variáveis deste projeto estão definidas no arquivo variables.tf, mas também podem ser definidas no aquivo terraform.tfvars e são passadas para o Terraform através do
# comando `terraform apply`, para mais detalhes sobre as variaveis, consulte a documentação https://www.terraform.io/language/values/variables#variable-definitions-tfvars-files
resource "oci_core_instance" "inst_postgresql" {
  availability_domain = lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.OCI_AD - 1], "name") # Define o AD onde a instancia será criada
  compartment_id      = var.compartment_ocid                                                                            # Define o compartamento onde a instancia será criada
  display_name        = "${var.prefix}-vm-database"                                                                     # Define o nome da instancia (no portal)

  agent_config { # Define as configurações dos plugins
    is_management_disabled = "false"
    is_monitoring_disabled = "false"
    plugins_config {
      desired_state = "ENABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "OS Management Service Agent"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Run Command"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }

  shape = var.db_shape # Define o shape da instancia (modelo do hardware)
  shape_config {
    ocpus         = var.db_ocpus  # Define o numero de CPUs da instancia
    memory_in_gbs = var.db_memory # Define a memoria da instancia
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subn_publica.id # Define o subnet onde a instancia será criada
    assign_public_ip = "true"                          # Define se a instancia terá ou não IP publico
    display_name     = "${var.prefix}vnicdb"
    hostname_label   = "${var.prefix}vmdb"
    private_ip       = cidrhost(oci_core_subnet.subn_publica.cidr_block, 10) # Define o IP privado da instancia
  }

  source_details {
    source_id               = var.source_id[var.db_platform] # Define o id da imagem que será utilizada na instancia
    boot_volume_size_in_gbs = 256                            # Define o tamanho do volume de boot da instancia (em GB)
    source_type             = "image"                        # Define o tipo de origem da instancia
  }

  metadata = {
    ssh_authorized_keys = var.ssh_key_pub # Define o ssh public key da instancia
  }

  provisioner "local-exec" { # Define um bloco de provisionamento local
    command = "echo ${self.display_name} ansible_host=${self.public_ip} >> ./ansible/hosts"
    # Grava no arquivo hosts do ansible o nome do host e ip (apenas exemplo)
  }

  provisioner "remote-exec" { # Define um bloco de provisionamento remote-exec (executa um comando na instancia)
    connection {              # Define as configurações de conexão da instancia, necessário para acessar a instancia e executar comandos remotamente
      type        = "ssh"
      host        = self.public_ip            # Coleta o IP publico da instancia durante o provisionamento
      user        = "opc"                     # Define o usuario que será utilizado para acessar a instancia
      private_key = var.ssh_key_priv # Define o arquivo com o private key da instancia (Chave privada da chave publica passada no parametro ssh_authorized_keys)
      agent       = false
    }
    inline = ["sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld" # Lista de comandos de exemplo que serão executados na instancia
    ]
  }

}

########################################################################################################################
########################################################################################################################
## Bloco que cria um disco adicional que será utilizado na instancia de banco de dados
resource "oci_core_volume" "storage_block_postgresql" {
  availability_domain = lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.OCI_AD - 1], "name") # Define o AD onde o volume será criado
  compartment_id      = var.compartment_ocid                                                                            # Define o compartamento onde o volume será criado
  display_name        = "${var.prefix}-vol-postgresql"                                                                  # Define o nome do volume (no portal)
  size_in_gbs         = "256"                                                                                           # Define o tamanho do volume (em GB)
}
########################################################################################################################
########################################################################################################################
## Bloco que conecta o disco criado a instancia de banco de dados
resource "oci_core_volume_attachment" "storage_block_attach_postgresql" {
  attachment_type = "paravirtualized"                           # Define o tipo de conexão do volume com a instancia
  instance_id     = oci_core_instance.inst_postgresql.id        # Define a instancia onde o volume será conectado
  volume_id       = oci_core_volume.storage_block_postgresql.id # Define o volume que será conectado a instancia

  # provisioner "file" {                                            # Define um bloco de provisionamento file (copia um arquivo para a instancia)
  #   source      = "${path.module}/config_files/setup_instance.sh" # Define o arquivo que será copiado para a instancia
  #   destination = "/tmp/setup_instance.sh"                        # Define o caminho onde o arquivo será copiado
  # }

  provisioner "remote-exec" {
    # Quando terminar o attach do disco a instancia, vamos conectar na instancia e executar os comandos de configuração
    # Neste ponto a instancia estará no estado de "RUNNING" e conseguimos realizar todas as configurações necessárias.
    connection { # Define as configurações de conexão da instancia, necessário para acessar a instancia e executar comandos remotamente
      type        = "ssh"
      host        = oci_core_instance.inst_postgresql.public_ip
      user        = "opc"                     # Define o usuario que será utilizado para acessar a instancia
      private_key = var.ssh_key_priv # Define o arquivo com o private key da instancia (Chave privada da chave publica passada no parametro ssh_authorized_keys)
      agent       = false
    }

    inline = [
      "sudo mkdir /pgdata01",                                                               # Cria o diretorio onde o volume será montado
      "sudo mkfs.xfs /dev/sdb",                                                             # Cria o sistema de arquivos do volume
      "sudo mount -t xfs /dev/sdb /pgdata01",                                               # Monta o volume
      "echo '/dev/sdb /pgdata01 xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab", # Adiciona o volume ao fstab
    ]
    on_failure = continue
  }
}
