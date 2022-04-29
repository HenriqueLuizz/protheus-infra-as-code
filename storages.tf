resource "oci_core_volume" "storage_block" {
  count               = var.instances
  availability_domain = var.OCI_AD["AD1"]
  compartment_id      = var.compartment_ocid
  display_name        = "${var.prefix}-vol-instance${count.index}"
  size_in_gbs         = "512"
}

resource "oci_core_volume_attachment" "storage_block_attach" {
  count           = var.instances
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.inst_universototvs[count.index].id
  volume_id       = oci_core_volume.storage_block[count.index].id

  connection {
    type        = "ssh"
    host        = oci_core_instance.inst_universototvs[count.index].public_ip
    user        = "opc"
    private_key = file(var.ssh_private_key)
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /totvs",
      "sudo mkfs.xfs /dev/sdb",
      "sudo mount -t xfs /dev/sdb /totvs",
      "echo '/dev/sdb /totvs xfs defaults,_netdev,nofail 0 2' | sudo tee -a /etc/fstab",
      "sudo wget https://objectstorage.${var.region}.oraclecloud.com${oci_objectstorage_preauthrequest.bucket_preauthenticated_request.access_uri} -O /tmp/protheus_bundle_12.1.33.tar.gz",
      "/bin/bash /tmp/install_protheus.sh"
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