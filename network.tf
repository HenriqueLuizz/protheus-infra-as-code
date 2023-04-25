########################################################################################################################
## Bloco responsável por criar a virtual cloud network
## Aqui definido o cidr, o nome da vcn e o compartimento onde será criado.
resource "oci_core_vcn" "vcn_universototvs" {
  #Required
  cidr_block     = "10.0.0.0/16"        # Cidr da vcn
  compartment_id = var.compartment_ocid # Compartimento onde será criado
  #Optional
  display_name = "vcn_universo"
  dns_label    = "vcnuniverso"
}
########################################################################################################################
########################################################################################################################
resource "oci_core_nat_gateway" "nat_gateway" {
  display_name   = "${var.prefix}natgateway"
  compartment_id = var.compartment_ocid              # Compartimento onde será criado
  vcn_id         = oci_core_vcn.vcn_universototvs.id # Vcn onde será criado
}
########################################################################################################################
########################################################################################################################
resource "oci_core_internet_gateway" "internetgateway1" {
  display_name   = "internetgateway1"
  compartment_id = var.compartment_ocid              # Compartimento onde será criado
  vcn_id         = oci_core_vcn.vcn_universototvs.id # Vcn onde será criado
}
########################################################################################################################
########################################################################################################################
resource "oci_core_route_table" "routetable1" {
  display_name   = "routetable1"
  compartment_id = var.compartment_ocid              # Compartimento onde será criado
  vcn_id         = oci_core_vcn.vcn_universototvs.id # Vcn onde será criado

  route_rules { # Criando uma rota para a vcn
    destination        = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.internetgateway1.id
  }
}

resource "oci_core_route_table" "routetable2" {
  display_name   = "${var.prefix}routetable2"
  compartment_id = var.compartment_ocid              # Compartimento onde será criado
  vcn_id         = oci_core_vcn.vcn_universototvs.id # Vcn onde será criado

  route_rules { # Criando uma rota para a vcn
    destination        = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
}
########################################################################################################################
########################################################################################################################
## Bloco responsável por criar a subnet na virtual cloud network
## Aqui definido o cidr da subnet, o nome da subnet, o compartimento e a vcn criada anteriormente.
resource "oci_core_subnet" "subn_privada" {
  #Required
  display_name               = "subn_privada"
  dns_label                  = "subnprivada"
  cidr_block                 = "10.0.3.0/24"                             # Cidr da subnet
  compartment_id             = var.compartment_ocid                      # Compartimento onde será criada a subnet
  vcn_id                     = oci_core_vcn.vcn_universototvs.id         # Id da vcn criada anteriormente
  prohibit_public_ip_on_vnic = "true"                                    # Proibi as vnics de receber ip público
  route_table_id             = oci_core_route_table.routetable1.id       # Id da rota criada anteriormente
  security_list_ids          = [oci_core_security_list.security_list.id] # Id da segurança criada anteriormente
}

resource "oci_core_subnet" "subn_publica" {
  #Required
  display_name               = "subn_publica"
  dns_label                  = "subnpublica"
  cidr_block                 = "10.0.4.0/24"                             # Cidr da subnet
  compartment_id             = var.compartment_ocid                      # Compartimento onde será criada a subnet
  vcn_id                     = oci_core_vcn.vcn_universototvs.id         # Id da vcn criada anteriormente
  prohibit_public_ip_on_vnic = "false"                                   # Permite as vnics de receber ip público
  route_table_id             = oci_core_route_table.routetable1.id       # Id da rota criada anteriormente
  security_list_ids          = [oci_core_security_list.security_list.id] # Id da segurança criada anteriormente
}
########################################################################################################################
########################################################################################################################
resource "oci_core_security_list" "security_list" {
  display_name   = "Security List com Regras TForm"
  compartment_id = var.compartment_ocid              # Compartimento onde será criada a lista de segurança
  vcn_id         = oci_core_vcn.vcn_universototvs.id # Id da vcn criada anteriormente

  egress_security_rules {          # Regra de autorização do tráfego de saida 
    destination      = "0.0.0.0/0" # Aceita todos os ips de destino
    protocol         = "all"       # Aceita todos os protocolos
    destination_type = "CIDR_BLOCK"
  }

  # Regra apenas para exemplo, não deve ser utilizada em ambientes reais
  ingress_security_rules {  # Regra de autorização do tráfego de entrada
    protocol  = "all"       # Aceita todos os protocolos
    source    = "0.0.0.0/0" # Aceita todos os ips de origem
    stateless = false
  }
}
########################################################################################################################
