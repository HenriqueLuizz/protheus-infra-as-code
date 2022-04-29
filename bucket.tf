data "oci_objectstorage_namespace" "namespace" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "bucket_universo" {
  #Required
  compartment_id = var.compartment_ocid
  name           = "bucket-universo"
  namespace      = "idhydepc7nrr"
  #Optional
  access_type = "ObjectRead"
  # metadata = var.bucket_metadata
}

resource "oci_objectstorage_object" "bucket_object" {
  #Required
  bucket    = oci_objectstorage_bucket.bucket_universo.name
  source    = "${path.module}/artefatos/protheus_bundle_12.1.33.tar.gz"
  namespace = oci_objectstorage_bucket.bucket_universo.namespace
  object    = "protheus.tar.gz"
}

resource "oci_objectstorage_preauthrequest" "bucket_preauthenticated_request" {
  #Required
  access_type  = "ObjectRead"
  bucket       = oci_objectstorage_bucket.bucket_universo.name
  name         = "tfrom_preauth_request"
  namespace    = oci_objectstorage_bucket.bucket_universo.namespace
  time_expires = timeadd(timestamp(), "24h")
  object_name  = oci_objectstorage_object.bucket_object.object
}
