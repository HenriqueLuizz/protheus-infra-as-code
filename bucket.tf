########################################################################################################################
# Doc: https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/objectstorage_bucket
# Cria um bucket no Oracle Object Storage
resource "oci_objectstorage_bucket" "bucket_universo" {
  #Required
  compartment_id = var.compartment_ocid                                       # Compartimento onde o bucket será criado
  name           = "bucket-universo"                                          # Nome do bucket
  namespace      = data.oci_objectstorage_namespace.namespace.namespace       # Namespace onde o bucket será criado (estamos buscando esta informação no data_sources.tf)
  #Optional
  access_type = "ObjectRead"                                                  # Tipo de acesso ao bucket         
}
########################################################################################################################
########################################################################################################################
# Doc: https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/objectstorage_object
# Bloco que carrega um arquivo para a bucket criada anteriormente
resource "oci_objectstorage_object" "bucket_object" {
  #Required
  bucket    = oci_objectstorage_bucket.bucket_universo.name                   # Nome do bucket   
  source    = "${path.module}/artefatos/protheus_bundle_12.1.33.tar.gz"       # Caminho do arquivo a ser carregado
  namespace = oci_objectstorage_bucket.bucket_universo.namespace              # Namespace onde o bucket será criado
  object    = "protheus.tar.gz"                                               # O nome que o arquivo terá dentro da bucket
}
########################################################################################################################
########################################################################################################################
# Doc: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_preauthrequest
# Bloco que cria a chave preautenticada para acesso ao bucket criado anteriormente
resource "oci_objectstorage_preauthrequest" "bucket_preauthenticated_request" {
  #Required
  access_type  = "ObjectRead"                                                 # Tipo de acesso da chave preautenticada
  bucket       = oci_objectstorage_bucket.bucket_universo.name                # Nome do bucket
  name         = "tfrom_preauth_request"                                      # Nome da chave preautenticada
  namespace    = oci_objectstorage_bucket.bucket_universo.namespace           # Namespace onde o bucket será criado
  time_expires = timeadd(timestamp(), "1h")                                   # Data de expiração da chave preautenticada
  object_name  = oci_objectstorage_object.bucket_object.object                # Nome do arquivo a ser acessado
}
