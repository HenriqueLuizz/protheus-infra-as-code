## Variáveis de controle
variable prefix { default = "prod" }

## Variáveis da instancia aplicação
variable instances { default = 1 }
variable shape { default = "VM.Standard.E4.Flex" }
variable ocpus { default = 2 }
variable memory { default = 16 }

## Variáveis da instancia aplicação secundaria
variable sec_instances { default = 1 }
variable sec_shape { default = "VM.Standard.E3.Flex" }
variable sec_ocpus { default = 2 }
variable sec_memory { default = 16 }

## Variáveis da instancia banco de dados
variable db_shape { default = "VM.Standard.A1.Flex" }
variable db_ocpus { default = 2 }
variable db_memory { default = 16 }

## Variáveis de configuração
variable ssh_file_public_key { default = "secrets/id_rsakey.pub" }
variable ssh_private_key { default = "secrets/id_rsakey" }

## Variáveis de configuração cloud
variable OCI_AD {
  description = "Available AD's in OCI"
  type        = map
  default = {
    "AD1" = "FqkF:US-ASHBURN-AD-1"
    "AD2" = "FqkF:US-ASHBURN-AD-2"
    "AD3" = "FqkF:US-ASHBURN-AD-3"
  }
}
# Para obter os ocid das imagens consulte o site 
# https://docs.oracle.com/en-us/iaas/images/
variable source_id {
  type = map
  default = {
    "aarch64"    = "ocid1.image.oc1.iad.aaaaaaaajpsx7e3rlozmcgczok5u2wpgsxsikzpbachb42h26ztp3i3d7o7a"
    "X86_64"     = "ocid1.image.oc1.iad.aaaaaaaazcrj3jkhp6tglg65qn7gjgxqgq5z7k4lvjoiunqwskb24t6sf6nq"
    "X86_64_7.9" = "ocid1.image.oc1.iad.aaaaaaaapfdqrbk6n4txcqv5h5da3d5wyfi4h7jweomf4y5wb3tw2mfmn4dq"
    "WINDOWS"    = "ocid1.image.oc1.iad.aaaaaaaadbx5xdg2fmdfqy5ij3dk6vzgrcqlj7jjswflly26g4o3ya2p6qua"
  }
}