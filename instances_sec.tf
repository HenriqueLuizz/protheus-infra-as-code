########################################################################################################################
########################################################################################################################
## Bloco que define a configuração da instancia de aplicação
## Neste caso é uma instancia computer que será configurado a aplicação secundaria.
# Doc: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
#
# Todos o ${var.*} são variáveis que serão substituidas pelo Terraform no momento da criação da instancia
# Onde * é o nome da variável, exemplo: ${var.name}.
# Todas as variáveis deste projeto estão definidas no arquivo variables.tf, mas também podem ser definidas no aquivo terraform.tfvars e são passadas para o Terraform através do
# comando `terraform apply`, para mais detalhes sobre as variaveis, consulte a documentação https://www.terraform.io/language/values/variables#variable-definitions-tfvars-files
########################################################################################################################
resource "oci_core_instance" "inst_universototvs_secundaria" {
  count               = var.sec_instances                             # Quantidade de instancias a serem criadas
  availability_domain = var.OCI_AD["AD1"]                             # Define o AD onde será criada a instancia
  compartment_id      = var.compartment_ocid                          # Define o compartamento onde será criada a instancia
  display_name        = "${var.prefix}-inst-sec-${count.index}"         # Define o nome da instancia

  agent_config {                                                        # Define as configurações do agente
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

  shape = var.sec_shape                                                           # Define o shape da instancia (modelo do hardware)
  shape_config {
    ocpus         = var.sec_ocpus                                                 # Define o numero de CPUs da instancia
    memory_in_gbs = var.sec_memory                                                # Define a memoria da instancia
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subn_publica.id                        # Define o subnet onde a instancia será criada
    assign_public_ip = "true"                                                 # Define se a instancia terá ou não IP publico
    display_name     = "${var.prefix}vnicsec${count.index}"
    hostname_label   = "${var.prefix}vmsec${count.index}"
    private_ip       = cidrhost(oci_core_subnet.subn_publica.cidr_block, 150 + count.index)  # Define o IP privado da instancia
  }

  source_details {
    source_id               = var.source_id["X86_64_7.9"]                     # Define o id da imagem que será utilizada na instancia
    boot_volume_size_in_gbs = 64                                              # Define o tamanho do volume de boot da instancia (em GB)
    source_type             = "image"                                         # Define o tipo de origem da instancia
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_file_public_key)                         # Define o ssh public key da instancia
  }

  provisioner "local-exec" {                                                  # Define um bloco de provisionamento local
    command = "sleep 30"                                                      # Define o comando que será executado (apenas exemplo)
  }

  connection {                                                                # Define as configurações de conexão da instancia, necessário para acessar a instancia e executar comandos remotamente
    type        = "ssh"
    host        = self.public_ip                                              # Coleta o IP publico da instancia durante o provisionamento
    user        = "opc"                                                       # Define o usuario que será utilizado para acessar a instancia
    private_key = file(var.ssh_private_key)                                    # Define o arquivo com o private key da instancia (Chave privada da chave publica passada no parametro ssh_authorized_keys)
    agent       = false
  }

  provisioner "remote-exec" {                                                 # Define um bloco de provisionamento remote-exec (executa um comando na instancia)
    inline = ["sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld"                                       # Lista de comandos de exemplo que serão executados na instancia
    ]
  }
}
########################################################################################################################
########################################################################################################################
## Bloco que cria um disco adicional que será utilizado na instancia de aplicação
resource "oci_core_volume" "storage_block_sec" {
  count               = var.sec_instances
  availability_domain = var.OCI_AD["AD1"]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-vol-instance${count.index}"
  size_in_gbs         = "512"
}

########################################################################################################################
########################################################################################################################
## Bloco que conecta o disco criado a instancia de aplicação
resource "oci_core_volume_attachment" "storage_block_attach_sec" {
  count           = var.sec_instances
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.inst_universototvs_secundaria[count.index].id
  volume_id       = oci_core_volume.storage_block_sec[count.index].id
  
  # Quando terminar o attach do disco a instancia, vamos conectar na instancia e executar os comandos de configuração
  # Neste ponto a instancia estará no estado de "RUNNING" e conseguimos realizar todas as configurações necessárias.
  connection {
    type        = "ssh"
    host        = oci_core_instance.inst_universototvs[count.index].public_ip
    user        = "opc"
    private_key = file(var.ssh_private_key)
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/config_files/setup_instance.sh"
    destination = "/tmp/setup_instance.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /totvs",
      "sudo mkfs.xfs /dev/sdb",
      "sudo mount -t xfs /dev/sdb /totvs",
      "echo '/dev/sdb /totvs xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
      "/bin/bash /tmp/setup_instance.sh secondary"
    ]
  }

  ## Apenas para attachment do tipo ISCSI  (attachment_type = "iscsi")
  # provisioner "remote-exec" {
  #     inline = [
  #       "sudo iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}",
  #       "sudo iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic",
  #       "sudo iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l"
  #     ]
  # }
}
