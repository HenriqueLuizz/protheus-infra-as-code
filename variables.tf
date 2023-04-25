## Variáveis de controle
variable prefix { default = "prod" }

## Variáveis da instancia aplicação
variable instances { default = 1 }
variable shape { default = "VM.Standard.A1.Flex" }
variable ocpus { default = 2 }
variable memory { default = 16 }
variable platform { default = "aarch64" }

## Variáveis da instancia aplicação secundaria
variable sec_instances { default = 1 }
variable sec_shape { default = "VM.Standard.A1.Flex" }
variable sec_ocpus { default = 2 }
variable sec_memory { default = 16 }
variable sec_platform { default = "aarch64" }

## Variáveis da instancia banco de dados
variable db_shape { default = "VM.Standard.A1.Flex" }
variable db_ocpus { default = 2 }
variable db_memory { default = 16 }
variable db_platform { default = "aarch64" }

## Variáveis de configuração
variable ssh_file_public_key { default = "secrets/id_rsakey.pub" }
variable ssh_private_key { default = "secrets/id_rsakey" }

## Variáveis de configuração cloud
variable OCI_AD {
  description = "Available AD's in OCI"
  default     = 1
}
# Para obter os ocid das imagens consulte o site 
# https://docs.oracle.com/en-us/iaas/images/
variable source_id {
  type = map
  default = {
    "aarch64" = "ocid1.image.oc1.iad.aaaaaaaaur2oxnruuagwwy6ylptayez46vh4njlzoudotaa6xjohdtr7dzra"
    "X86_64"  = "ocid1.image.oc1.iad.aaaaaaaazjw36jmwmqtiej2popvqqfmhphvhdwjbfr7te4kcne6tx56kj3mq"
    "WINDOWS" = "ocid1.image.oc1.iad.aaaaaaaadbx5xdg2fmdfqy5ij3dk6vzgrcqlj7jjswflly26g4o3ya2p6qua"
  }
}

## Variáveis de configuração dos artefatos
variable bundle_name { default = "protheus_bundle_12.1.2210.tar.gz" }

## Datasource recupera os ADs do compartment
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}
