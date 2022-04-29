##
## TFORM - VMs Secundarias 
## Define o numero de VMs através da variável INSTANCES.
##

resource "oci_core_instance" "inst_postgresql" {
  availability_domain = var.OCI_AD["AD1"]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-vm-database"

  agent_config {
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

  shape = var.db_shape
  shape_config {
    ocpus         = var.db_ocpus
    memory_in_gbs = var.db_memory
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subn_publica.id
    assign_public_ip = "true"
    display_name     = "${var.prefix}vnicdb"
    hostname_label   = "${var.prefix}vmdb"
    private_ip       = cidrhost(oci_core_subnet.subn_publica.cidr_block, 10)
  }

  source_details {
    source_id               = var.source_id["aarch64"]
    boot_volume_size_in_gbs = 256
    source_type             = "image"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_file_public_key)
  }

  provisioner "local-exec" {
    command = "sleep 30"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "opc"
    private_key = file(var.ssh_private_key)
    agent       = false
  }

  provisioner "file" {
    source      = "${path.module}/config_files/install_postgresql.sh"
    destination = "/tmp/install_postgresql.sh"
  }

  provisioner "remote-exec" {
    inline = ["sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld"
    ]
  }
}

resource "oci_core_volume" "storage_block_postgresql" {
  availability_domain = var.OCI_AD["AD1"]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-vol-postgresql"
  size_in_gbs         = "256"
}

# Conecta secondary_block0
resource "oci_core_volume_attachment" "storage_block_attach_postgresql" {
  count           = var.instances
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.inst_postgresql.id
  volume_id       = oci_core_volume.storage_block_postgresql.id

  connection {
    type        = "ssh"
    host        = oci_core_instance.inst_postgresql.public_ip
    user        = "opc"
    private_key = file(var.ssh_private_key)
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /pgdata01",
      "sudo mkfs.xfs /dev/sdb",
      "sudo mount -t xfs /dev/sdb /pgdata01",
      "echo '/dev/sdb /pgdata01 xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
      "/bin/bash /tmp/install_postgresql.sh"
    ]
  }
}
