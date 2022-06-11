####################################################################################################
## Os blocos "dada" é utilizado para buscar os dados no cloud provider configurado e também pode
## ser usado para buscar informações de um recurso que já está provisionado.
####################################################################################################
####################################################################################################
## Retorna o namespace do cloud provider configurado. Doc: https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/objectstorage_namespace
data "oci_objectstorage_namespace" "namespace" {
  compartment_id = var.compartment_ocid
}