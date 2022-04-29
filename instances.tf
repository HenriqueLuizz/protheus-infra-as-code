##
## TFORM - VMs Secundarias 
## Define o numero de VMs através da variável INSTANCES.
##

resource "oci_core_instance" "inst_universototvs" {
  count               = var.instances
  availability_domain = var.OCI_AD["AD1"]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-inst-app-${count.index}"

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

  shape = var.shape
  shape_config {
    ocpus         = var.ocpus
    memory_in_gbs = var.memory
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subn_publica.id
    assign_public_ip = "true"
    display_name     = "${var.prefix}vnicinst${count.index}"
    hostname_label   = "${var.prefix}vminst${count.index}"
    private_ip       = cidrhost(oci_core_subnet.subn_publica.cidr_block, 100 + count.index)
  }

  source_details {
    source_id               = var.source_id["X86_64_7.9"]
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
    source      = "${path.module}/config_files/install_protheus.sh"
    destination = "/tmp/install_protheus.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/totvsappserver.sh"
    destination = "/tmp/totvsappserver.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/totvsdbaccess.sh"
    destination = "/tmp/totvsdbaccess-sec.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/start.sh"
    destination = "/tmp/start.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/stop.sh"
    destination = "/tmp/stop.sh"
  }

  # provisioner "file" {
  #   source      = "${path.module}/artefatos/protheus_bundle_12.1.33.tar.gz"
  #   destination = "/tmp/protheus_bundle_12.1.33.tar.gz"
  # }

  provisioner "remote-exec" {
    inline = ["sudo systemctl stop firewalld",
      "sudo systemctl disable firewalld"
    ]
  }
}
